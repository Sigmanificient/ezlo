{
  lib,
  python3Packages,
  gitMinimal,
  nix,
}:

python3Packages.buildPythonApplication {
  pname = "ezlo";
  version = "0.0.1";
  pyproject = true;

  src = ./.;

  build-system = [ python3Packages.setuptools ];

  postPatch = ''
    mkdir -p $out/share/ezlo
    cp -r ${./ezlo/ezlo.nix} $out/share/ezlo/ezlo.nix
    cp -r ${./ezlo/rules} $out/share/ezlo/rules

    substituteInPlace ezlo/__main__.py \
     --replace-fail \
        'EZLO_PATH = Path(__file__).resolve().parent' \
        'EZLO_PATH = Path("${placeholder "out"}/share/ezlo")'
  '';

  makeWrapperArgs = [
    "--prefix" "PATH" ":" (lib.makeBinPath [ gitMinimal nix ])
  ];

  meta = {
    description = "I have to find a description";
    mainProgram = "ezlo";
  };
}
