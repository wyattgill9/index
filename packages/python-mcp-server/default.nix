{
  ix,
  lib,
  pkgs ? ix.pkgs,
}:
let
  fs = lib.fileset;
  src = fs.toSource {
    root = ./.;
    fileset = fs.unions [
      ./pyproject.toml
      ./src
      ./uv.lock
    ];
  };
in
ix.buildUvApplication pkgs {
  pname = "python-mcp-server";
  version = "0.1.0";
  inherit src;
  mainProgram = "ix-python-mcp";
}
