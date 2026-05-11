{
  jdk25,
  paperServer,
  runCommand,
}:
runCommand "claude-code-demo-scoreboard-plugin.jar" { nativeBuildInputs = [ jdk25 ]; } ''
  mkdir -p classes
  javac \
    -cp ${paperServer} \
    -d classes \
    ${./src/dev/ix/minecraft/TimeScoreboardPlugin.java}
  cp ${./plugin.yml} classes/plugin.yml
  jar --create --file "$out" -C classes .
''
