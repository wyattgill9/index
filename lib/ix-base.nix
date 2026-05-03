{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.ix = {
    image.name = lib.mkOption { type = lib.types.str; };
    image.tag = lib.mkOption {
      type = lib.types.str;
      default = "latest";
    };
    build.ociImage = lib.mkOption {
      type = lib.types.package;
      internal = true;
    };
  };

  config = {
    boot.isContainer = true;
    system.stateVersion = "25.05";
    ix.profiles.base.enable = lib.mkDefault true;

    ix.build.ociImage =
      let
        toplevel = config.system.build.toplevel;

        stream = pkgs.dockerTools.streamLayeredImage {
          name = config.ix.image.name;
          tag = config.ix.image.tag;
          maxLayers = 67;
          contents = [
            toplevel
            (pkgs.runCommand "system-root" { __structuredAttrs = true; } ''
              mkdir -p $out
              ln -s ${toplevel}/init $out/init
              ln -s ${toplevel}/etc $out/etc
              ln -s ${toplevel}/sw/bin $out/bin
              ln -s ${toplevel}/sw/sbin $out/sbin
              ln -s ${toplevel}/sw/lib $out/lib
              mkdir -p $out/usr
              ln -s ${toplevel}/sw/bin $out/usr/bin
              ln -s ${toplevel}/sw/lib $out/usr/lib
              ln -s ${toplevel}/sw/sbin $out/usr/sbin
              mkdir -p $out/tmp $out/var $out/run $out/proc $out/sys $out/dev $out/root
            '')
          ];
          config = {
            Entrypoint = [ "${toplevel}/init" ];
          };
        };
      in
      pkgs.runCommand "${config.ix.image.name}-oci.tar" {
        __structuredAttrs = true;
        nativeBuildInputs = [ pkgs.python3 ];
      } ''
        ${stream} | python3 ${./docker-to-oci.py} > "$out"
      '';
  };
}
