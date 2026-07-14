{ lib }:
{
  require = pkg:
    lib.hasAttr "meta" pkg
    && lib.hasAttr "description" pkg.meta
    && builtins.hasAttr "pname" pkg;

  check = pkg:
    let
      desc = lib.toLower pkg.meta.description;
      pname = lib.toLower pkg.pname;
    in
      !(lib.hasPrefix pname desc);

  message = "package description must not start with the package name.";
}
