{ lib }:
{
  require = pkg: builtins.hasAttr "phases" pkg;

  check = pkg: false;

  message = "explicit setting of 'phases' is deprecated; use standard phase hooks instead.";
}
