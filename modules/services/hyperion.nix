{
  config,
  ix,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.services.hyperion;
  inherit (cfg) dataDir;
  openssl = lib.getExe pkgs.openssl;
  proxyAddress = "${cfg.proxy.bindAddress}:${toString cfg.proxy.port}";
  isIpv4Address = address: builtins.match "^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$" address != null;
  isIpv6Address = address: lib.hasInfix ":" address;
  sanForHost = host: if isIpv4Address host || isIpv6Address host then "IP:${host}" else "DNS:${host}";
  serverSubjectAltNames = lib.concatStringsSep "," (
    lib.unique [
      (sanForHost cfg.proxy.serverHost)
      "DNS:localhost"
      "IP:127.0.0.1"
    ]
  );
in
{
  options.services.hyperion = {
    enable = mkEnableOption "Hyperion Bedwars server with embedded Minecraft proxy";

    package = mkOption {
      type = types.package;
      default = ix.packages.hyperion;
      defaultText = lib.literalExpression "ix.packages.hyperion";
      description = "Hyperion package providing the bedwars and hyperion-proxy binaries.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/hyperion";
      description = "State directory for generated mTLS material and Hyperion runtime data.";
    };

    logLevel = mkOption {
      type = types.str;
      default = "info";
      description = "RUST_LOG value for Hyperion.";
    };

    certificateDays = mkOption {
      type = types.ints.positive;
      default = 365;
      description = "Validity period for the locally generated Hyperion mTLS certificates.";
    };

    game = {
      bindAddress = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Address the Bedwars game server binds for proxy-to-server traffic.";
      };

      port = mkOption {
        type = types.port;
        default = 35565;
        description = "TCP port the Bedwars game server binds for proxy-to-server traffic.";
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to open the internal Bedwars game-server port in the in-guest firewall.";
      };
    };

    proxy = {
      bindAddress = mkOption {
        type = types.str;
        default = "0.0.0.0";
        description = "Address the embedded Hyperion proxy binds for Minecraft clients.";
      };

      port = mkOption {
        type = types.port;
        default = 25565;
        description = "TCP port the embedded Hyperion proxy exposes to Minecraft clients.";
      };

      serverHost = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Host name or IP address the embedded proxy uses to reach the Bedwars game server.";
      };

      openFirewall = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to open the embedded proxy port in the in-guest firewall.";
      };
    };
  };

  config = mkIf cfg.enable {
    ix.networking.portClaims = {
      hyperion-bedwars = {
        protocol = "tcp";
        inherit (cfg.game) port;
        address = cfg.game.bindAddress;
        description = "Hyperion Bedwars game server";
      };

      hyperion-proxy = {
        protocol = "tcp";
        inherit (cfg.proxy) port;
        address = cfg.proxy.bindAddress;
        description = "Hyperion Minecraft proxy";
      };
    };

    networking.firewall.allowedTCPPorts =
      lib.optionals cfg.proxy.openFirewall [ cfg.proxy.port ]
      ++ lib.optionals cfg.game.openFirewall [ cfg.game.port ];

    users.groups.hyperion = { };
    users.users.hyperion = {
      description = "Hyperion service user";
      isSystemUser = true;
      group = "hyperion";
      home = dataDir;
    };

    systemd.services.hyperion = {
      description = "Hyperion Bedwars server";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      environment = {
        RUST_LOG = cfg.logLevel;
        BEDWARS_IP = cfg.game.bindAddress;
        BEDWARS_PORT = toString cfg.game.port;
        BEDWARS_PROXY_ADDR = proxyAddress;
      };
      preStart = ''
        set -eu

        cd ${lib.escapeShellArg dataDir}
        if [ -f root_ca.crt ] \
          && [ -f server.crt ] \
          && [ -f server_private_key.pem ] \
          && [ -f proxy.crt ] \
          && [ -f proxy_private_key.pem ]; then
          exit 0
        fi

        rm -f root_ca.key root_ca.crt root_ca.srl \
          server_private_key.pem server.csr server.crt \
          proxy_private_key.pem proxy.csr proxy.crt

        ${openssl} req -new -nodes -newkey rsa:4096 \
          -keyout root_ca.key \
          -x509 \
          -out root_ca.crt \
          -days ${toString cfg.certificateDays} \
          -subj "/CN=ix Hyperion local CA"

        ${openssl} req -nodes -newkey rsa:4096 \
          -keyout server_private_key.pem \
          -out server.csr \
          -subj "/CN=hyperion-bedwars"

        ${openssl} x509 -req \
          -in server.csr \
          -CA root_ca.crt \
          -CAkey root_ca.key \
          -CAcreateserial \
          -out server.crt \
          -days ${toString cfg.certificateDays} \
          -sha256 \
          -extfile <(printf '%s\n' 'subjectAltName=${serverSubjectAltNames}')

        ${openssl} req -nodes -newkey rsa:4096 \
          -keyout proxy_private_key.pem \
          -out proxy.csr \
          -subj "/CN=hyperion-proxy"

        ${openssl} x509 -req \
          -in proxy.csr \
          -CA root_ca.crt \
          -CAkey root_ca.key \
          -CAcreateserial \
          -out proxy.crt \
          -days ${toString cfg.certificateDays} \
          -sha256

        rm -f server.csr proxy.csr root_ca.srl
        chmod 0600 root_ca.key server_private_key.pem proxy_private_key.pem
      '';
      serviceConfig = ix.systemdHardening // {
        Type = "simple";
        User = "hyperion";
        Group = "hyperion";
        StateDirectory = "hyperion";
        WorkingDirectory = dataDir;
        ExecStart = lib.escapeShellArgs [
          (lib.getExe' cfg.package "bedwars")
          "--ip"
          cfg.game.bindAddress
          "--port"
          (toString cfg.game.port)
          "--root-ca-cert"
          "${dataDir}/root_ca.crt"
          "--cert"
          "${dataDir}/server.crt"
          "--private-key"
          "${dataDir}/server_private_key.pem"
        ];
        Restart = "on-failure";
        LimitNOFILE = 32768;
      };
    };
  };
}
