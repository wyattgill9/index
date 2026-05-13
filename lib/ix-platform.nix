# Target platform applied to every image.
#
# All images run on EPYC Gen 5 (Turin, Zen 5). Setting hostPlatform.gcc.arch
# propagates -march=znver5 -mtune=znver5 to every package in the closure.
# No binary cache hits: everything builds from source.
{ config, lib, ... }:
{
  # Networking policy (per-port filtering, L7, WAF, rate limiting, gateway
  # behavior) belongs to the image, not to ix. ix exposes two primitives:
  # east-west group membership (which VMs can reach each other) and
  # north-south on/off (whether the VM has internet ingress / egress).
  # Anything finer lives in `networking.firewall.*` inside the image, in a
  # sidecar, or behind a user-built gateway VM. `eastWest.hostName` stays
  # here because it is a name, not a policy.
  options.ix.networking.eastWest.hostName = lib.mkOption {
    type = lib.types.str;
    default = config.networking.hostName;
  };

  config = {
    nixpkgs.hostPlatform = {
      system = "x86_64-linux";
      # TODO: add back znver5 tuning for EPYC Gen 5
      # gcc = {
      #   arch = "znver5";
      #   tune = "znver5";
      # };
    };

    boot.isContainer = true;
    networking = {
      # ix provisions the guest address, route, and DNS before systemd reaches
      # normal service startup. Leaving NixOS DHCP enabled makes dhcpcd wait
      # for a lease that will never arrive, which keeps network-online.target
      # pending and blocks services such as minecraft.
      useDHCP = false;

      # In-guest firewall is the NixOS nftables backend, enforcing each
      # module's `services.*.openFirewall` and `networking.firewall.allowed*`
      # declarations. ix VMs are `boot.isContainer = true` and share the
      # host's linux-ix kernel (CONFIG_NF_TABLES); nft rules run in this
      # container's own net namespace.
      #
      # This is the primary mechanism for port-level policy. ix provides only
      # the coarse primitives (east-west group membership, north-south
      # on/off); per-port allowlists, L7, WAF, rate limiting, etc. live here
      # in the image or in a user-built gateway VM. The "primitives only"
      # rule is recorded in `ix/AGENTS.md` under "Architecture that must not
      # drift". Tracking the ix-side north-south primitive in
      # https://github.com/indexable-inc/index/issues/41.
      firewall.enable = true;
    };
    system.stateVersion = "25.05";
  };
}
