{ lib }:
{
  require = pkg:
    lib.hasAttr "meta" pkg
    && lib.hasAttr "description" pkg.meta
    && pkg.meta.description != "";

  check = pkg:
    let
      desc = lib.toLower pkg.meta.description;
      words = lib.splitString " " desc;
      firstWord = lib.head words;
    in
      !(lib.elem firstWord [ "a" "an" "the" ]);

  message = "package description must not start with an article ('a', 'an', or 'the').";
}
