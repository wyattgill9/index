# Base runtime profile.
#
# Auto-enabled by `lib/ix-base.nix`, but intentionally empty while the image
# flow publishes raw OCI archives. Runtime dependencies belong in the specific
# image or service that needs them.
{
  config,
  lib,
  ...
}:
{
  options.ix.profiles.base.enable = lib.mkEnableOption "empty base runtime profile";

  config = lib.mkIf config.ix.profiles.base.enable { };
}
