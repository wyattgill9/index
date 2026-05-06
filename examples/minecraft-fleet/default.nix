{ ix }:
let
  secrets = {
    velocityForwarding = {
      generate = true;
      path = "/run/ix-secrets/velocity-forwarding";
      sharedWith = [
        "proxy"
        "lobby"
        "survival"
      ];
    };
  };
  forwardingSecret = secrets.velocityForwarding;
  survivalReplicas = 3;
  replicaNames = name: count: builtins.genList (index: "${name}-${toString index}") count;
  survivalNodes = replicaNames "survival" survivalReplicas;
  survival = import ./folia-node.nix {
    inherit forwardingSecret;
    motd = "ix survival";
    extraServerProperties = {
      view-distance = 10;
      simulation-distance = 8;
    };
  };
in
ix.lib.mkFleet {
  inherit secrets;

  nodes = {
    proxy = import ./proxy.nix {
      inherit forwardingSecret survivalNodes;
    };

    lobby = import ./folia-node.nix {
      inherit forwardingSecret;
      motd = "ix lobby";
    };

    survival = survival // {
      replicas = survivalReplicas;
    };
  };
}
