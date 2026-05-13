{
  pkgs,
  writePythonApplication,
  src,
  dataDir,
  dropDir,
  managedRoot,
  plugmanReloadEnabled,
  ignoredPlugins,
  rconPort,
  rconPasswordFile,
}:
let
  inherit (pkgs) lib;
in
writePythonApplication pkgs {
  name = "minecraft-sync-managed";
  inherit src;
  args = [
    "--data-dir"
    dataDir
    "--drop-dir"
    dropDir
    "--managed-root"
    managedRoot
  ]
  ++ lib.optionals plugmanReloadEnabled [ "--plugman-reload" ]
  ++ lib.concatMap (plugin: [
    "--plugman-ignored-plugin"
    plugin
  ]) ignoredPlugins
  ++ [
    "--rcon-port"
    (toString rconPort)
    "--rcon-password-file"
    rconPasswordFile
  ];
}
