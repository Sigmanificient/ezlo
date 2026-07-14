{ lib }:
{
  require = pkg: lib.hasAttr "meta" pkg && lib.hasAttr "homepage" pkg.meta;

  check = pkg: lib.hasPrefix "https://" pkg.meta.homepage;

  message = "package meta.homepage must use HTTPS.";
}
