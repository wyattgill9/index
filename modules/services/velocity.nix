{ lib, ... }:
{
  options.services.velocity = {
    enable = lib.mkEnableOption "Velocity proxy";
    bind = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0:25565";
    };
    onlineMode = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    forwarding = {
      mode = lib.mkOption {
        type = lib.types.str;
        default = "modern";
      };
      secret = lib.mkOption { type = lib.types.anything; };
    };
    servers = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
    };
    try = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };
}
