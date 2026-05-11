{
  jdk25,
  maven,
}:
maven.buildMavenPackage {
  pname = "claude-code-demo-scoreboard-plugin";
  version = "1.0.0";
  src = ./.;
  mvnJdk = jdk25;
  mvnHash = "sha256-73BlPe8XtIJL6k86nrwqoWQWlZG6ErXQKA5nqbpcuAo=";

  installPhase = ''
    cp target/claude-code-demo-scoreboard-plugin-1.0.0.jar "$out"
  '';
}
