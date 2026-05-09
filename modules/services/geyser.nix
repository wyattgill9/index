{ lib, ... }:
{
  options.services.geyser = {
    enable = lib.mkEnableOption "Geyser protocol bridge";
    platform = lib.mkOption { type = lib.types.str; };
    bedrock = {
      address = lib.mkOption {
        type = lib.types.str;
        default = "0.0.0.0";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 19132;
      };
    };
    remote = {
      address = lib.mkOption { type = lib.types.str; };
      port = lib.mkOption { type = lib.types.port; };
      authType = lib.mkOption {
        type = lib.types.str;
        default = "floodgate";
      };
    };
  };
}
