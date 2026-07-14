{ lib }:
{
  require = pkg:
    lib.hasAttr "meta" pkg
    && lib.hasAttr "description" pkg.meta
    && pkg.meta.description != "";

  check = pkg:
    let
      desc = pkg.meta.description;
      firstChar = builtins.substring 0 1 desc;
    in
      firstChar == lib.toUpper firstChar;

  message = "package description must start with a capital letter.";
}
