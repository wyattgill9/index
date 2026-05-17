{ index }:

index.lib.mkFleet {
  # The tag is shared by every replacement image this example builds, so
  # registry destinations read `factions:factions-server` instead of `:latest`.
  defaults = [ { ix.image.tag = "factions-server"; } ];

  nodes.factions = {
    deployment.ipv4 = true;
    modules = [ ./minecraft.nix ];
  };
}
