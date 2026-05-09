{ lib, ... }:
{
  options.services.floodgate = {
    enable = lib.mkEnableOption "Floodgate identity bridge";
    platform = lib.mkOption { type = lib.types.str; };
  };
}
