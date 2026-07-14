{ lib }:
{
  require = pkg: builtins.hasAttr "meta" pkg && builtins.hasAttr  "description" pkg.meta;

  check = pkg: !(lib.strings.hasSuffix "." pkg.meta.description);

  message = "package description must not end with trailing dot.";
}
