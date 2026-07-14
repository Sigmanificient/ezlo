import argparse
import contextlib
import logging
import subprocess
import sys
import tempfile
import urllib.request

from functools import wraps
from pathlib import Path
from typing import Generator

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("ezlo_runner")

EZLO_PATH = Path(__file__).resolve().parent


@wraps(subprocess.run)
def run_cmd(
    args: tuple[str, ...], check: bool = True, **kwargs
) -> subprocess.CompletedProcess:
    logger.info(f"Running: {' '.join(args)}")

    result = subprocess.run(args, text=True, **kwargs)

    if check and result.returncode != 0:
        logger.error(f"Command failed with exit code {result.returncode}")
        sys.exit(result.returncode)
    return result


def fetch_pr_patch(pr_number: int, dest_path: Path) -> None:
    url = f"https://github.com/NixOS/nixpkgs/pull/{pr_number}.patch"
    logger.info(f"Fetching PR #{pr_number} patch from GitHub...")

    try:
        urllib.request.urlretrieve(url, dest_path)
    except Exception as e:
        logger.error(f"Error downloading patch: {e}")
        sys.exit(1)


def run_git_on(
    repo_path: Path, *args: str, **kwargs
) -> subprocess.CompletedProcess:
    return run_cmd(("git", "-C", str(repo_path), *args), **kwargs)


@contextlib.contextmanager
def git_worktree(
    repo_path: Path, branch_name: str, worktree_path: Path
) -> Generator[Path, None, None]:
    run_git_on(repo_path, "branch", "-D", branch_name, check=False)
    run_git_on(
        repo_path,
        "worktree",
        "add",
        "-b",
        branch_name,
        str(worktree_path),
        "HEAD",
    )

    try:
        yield worktree_path
    finally:
        logger.info("Cleaning up git worktree...")
        run_git_on(
            repo_path,
            "worktree",
            "remove",
            "--force",
            str(worktree_path),
            check=False,
        )
        run_git_on(repo_path, "branch", "-D", branch_name, check=False)


def prepare_ezlo(worktree_path: Path, patch_file: Path) -> None:
    logger.info(f"Applying patch to worktree at {worktree_path}...")
    apply_res = run_git_on(worktree_path, "apply", str(patch_file))

    if apply_res.returncode != 0:
        logger.warning("'git apply' failed")


def run_ezlo(worktree_path: Path, target_attrpath: str) -> None:
    logger.info("Running ezlo check...")
    ezlo = (
        f"(import {EZLO_PATH}/ezlo.nix {{"
        f" pkgs = import {worktree_path} {{}};"
        f' targetAttrpath = "{target_attrpath}";'
        " })"
    )

    res = run_cmd(
        ("nix", "eval", "--json", "--impure", "--expr", ezlo),
        capture_output=True,
    )
    return res.stdout


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("pr", type=int)
    parser.add_argument("nixpkgs_repo", type=Path)
    parser.add_argument("--attr", type=str, default="")
    args = parser.parse_args()

    repo_path = args.nixpkgs_repo.resolve()
    if not (repo_path / ".git").is_dir():
        logger.error(f"{repo_path} is not a valid git repository.")
        sys.exit(1)

    branch_name = f"ezlo-{args.pr}"

    with tempfile.TemporaryDirectory() as tmpdir:
        tmp_path = Path(tmpdir)
        patch_file = tmp_path / f"pr-{args.pr}.patch"
        worktree_path = tmp_path / "worktree"

        fetch_pr_patch(args.pr, patch_file)

        with git_worktree(repo_path, branch_name, worktree_path) as wt:
            prepare_ezlo(wt, patch_file)
            res = run_ezlo(wt, args.attr)

    print(res)


if __name__ == "__main__":
    main()
