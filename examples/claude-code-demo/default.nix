{
  ix,
  hostSystem ? ix.lib.system,
}:
let
  pkgs = ix.lib.pkgs;
  paperVersion = "1.21.11";
  paperServer = ix.lib.artifacts.minecraft.paperServers.${paperVersion};
  claudeCodeScoreboardPlugin = pkgs.callPackage ./claude-code-scoreboard-plugin {
    paperServer = paperServer.src;
  };
in
(ix.lib.mkFleetFor hostSystem) {
  deployment.switch = {
    # Build the target NixOS system on ix infrastructure. The local machine only
    # evaluates the plan and sends the derivation path to the switch command.
    buildOn = "remote";

    # This example flake depends on `github:indexable-inc/index`. During local
    # development, point that input back at the checkout running the command so
    # `nix run .#switch` uses your edited modules instead of the published repo.
    overrideInputs.index = ".";
  };

  nodes = {
    minecraft = {
      deployment.expose.northSouth.tcp = [ 25565 ];
      modules = [
        (
          { ... }:
          {
            # Fleets default ix.image.name to the node name (`minecraft` here).
            # Set a tag anyway so replacement images are named
            # `minecraft:claude-code-demo` instead of the less-informative
            # `minecraft:latest`.
            ix.image.tag = "claude-code-demo";

            services.minecraft = {
              enable = true;

              paper = {
                enable = true;
                version = paperVersion;
                build = paperServer.build;
              };

              plugins = {
                # Empty `{}` means "resolve this by slug from Paper's pinned
                # plugin catalog". The catalog owns the URL and locked source.
                luckperms = { };

                # A plugin can also point at a jar built by this fleet. The
                # same option handles public catalog plugins and private/local
                # plugins; Paper places both in `/var/lib/minecraft/plugins`.
                claude-code-scoreboard = {
                  src = claudeCodeScoreboardPlugin;
                  pluginName = "ClaudeCodeDemoScoreboard";
                };
              };

              # Paper uses PlugManX for hot reloads. Managed plugin changes run
              # systemd reload, then PlugManX loads/reloads only changed jars.
              autoReload = {
                enable = true;
                driver = "plugman";
              };

              serverFiles."server.properties" = {
                motd = "Claude Code Demo";
                max-players = 20;
                online-mode = true;
                view-distance = 10;
                simulation-distance = 8;
              };
            };
          }
        )
      ];
    };
  };
}
