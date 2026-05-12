{
  python3,
  writeNushellApplication,
}:

writeNushellApplication {
  name = "minecraft-rcon";
  runtimeInputs = [ python3 ];
  text = ''
    def main [...args] {
      exec python3 ${./minecraft-rcon.py} ...$args
    }
  '';
}
