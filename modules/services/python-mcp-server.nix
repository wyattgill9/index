# Stdio MCP server exposing a persistent Python session.
{
  config,
  ix,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.services.python-mcp-server;
  json = pkgs.formats.json { };
  clientConfig = json.generate "ix-python-mcp-client.json" {
    mcpServers.${cfg.serverName} = {
      command = lib.getExe cfg.package;
      args = [ "serve" ];
    };
  };
in
{
  options.services.python-mcp-server = {
    enable = mkEnableOption "stdio Python MCP server";

    package = mkOption {
      type = types.package;
      default = ix.packages.python-mcp-server;
      defaultText = lib.literalExpression "ix.packages.python-mcp-server";
      description = "Python MCP server package to install.";
    };

    serverName = mkOption {
      type = types.str;
      default = "ix-python";
      description = "Server name written into the generated MCP client config.";
    };

    clientConfigPath = mkOption {
      type = types.str;
      default = "mcp/ix-python.json";
      description = "Path under /etc for the generated MCP client config.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    environment.etc.${cfg.clientConfigPath}.source = clientConfig;
  };
}
