# Base CLI profile.
#
# Auto-enabled by `lib/ix-base.nix` so every image gets a usable shell out of
# the box. Images that want a minimal closure can opt out with
# `ix.profiles.base.enable = false;`.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.ix.profiles.base.enable =
    lib.mkEnableOption "base CLI tools (editors, shells, network, files, debug, misc)";

  config = lib.mkIf config.ix.profiles.base.enable {
    environment.systemPackages = builtins.attrValues {
      # editors
      inherit (pkgs) neovim;

      # shells
      inherit (pkgs) nushell fish zsh;

      # net
      inherit (pkgs)
        curl
        wget
        openssh
        iproute2
        dnsutils
        ;

      # files
      inherit (pkgs)
        ripgrep
        fd
        file
        tree
        unzip
        less
        jq
        ;

      # debug
      inherit (pkgs)
        btop
        htop
        strace
        lsof
        gdb
        procps
        tcpdump
        perf
        ;

      # misc
      inherit (pkgs)
        tmux
        zellij
        git
        bat
        eza
        zoxide
        fzf
        delta
        dust
        duf
        hyperfine
        tokei
        ;
    };

    programs.bash.completion.enable = true;
    programs.zsh.enable = true;
    programs.fish.enable = true;
    environment.variables.EDITOR = "nvim";
  };
}
