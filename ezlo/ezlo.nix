{ pkgs, targetAttrpath }:
let
  inherit (pkgs) lib;

  resolveAttrPath = pathStr:
    lib.attrByPath (lib.splitString "." pathStr) null pkgs;

  pkg = resolveAttrPath targetAttrpath;

  rulesDir = ./rules;
  loadRule = file: import (rulesDir + "/${file}") { inherit lib; };

  ruleFiles = lib.filter
    (name: lib.hasSuffix ".nix" name)
    (lib.attrNames (builtins.readDir rulesDir));

  rules = lib.map loadRule ruleFiles;

  result = {
    attrpath = targetAttrpath;
    found = pkg != null;
    warnings = [];
   };
in result // lib.optionalAttrs result.found {
  warnings = lib.concatMap (rule:
    if (rule.require pkg) && !(rule.check pkg)
    then [ rule.message ]
    else []
  ) rules;
}
