# Base runtime profile.
#
# Auto-enabled by `lib/ix-base.nix` so every image has the runtime tools needed
# for source switches. Images that want a smaller closure can opt out with
# `ix.profiles.base.enable = false;`.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.ix.profiles.base.enable = lib.mkEnableOption "base runtime tools for source switches";

  config = lib.mkIf config.ix.profiles.base.enable {
    # TODO: re-enable these when source switch is back. For now we publish OCI
    # images directly, so the auto-enabled base profile should add no packages.
    # environment.systemPackages = builtins.attrValues {
    #   inherit (pkgs)
    #     gzip
    #     gnutar
    #     zstd
    #     ;
    # };
  };
}
