{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.ix.profiles.base.enable = lib.mkEnableOption "base tools (btop, neovim, curl, git)";

  config = lib.mkIf config.ix.profiles.base.enable {
    environment.systemPackages = [
      # editors
      pkgs.neovim

      # shells
      pkgs.nushell
      pkgs.fish
      pkgs.zsh

      # net
      pkgs.curl
      pkgs.wget
      pkgs.openssh
      pkgs.iproute2
      pkgs.dnsutils

      # files
      pkgs.ripgrep
      pkgs.fd
      pkgs.file
      pkgs.tree
      pkgs.unzip
      pkgs.less
      pkgs.jq

      # debug
      pkgs.btop
      pkgs.htop
      pkgs.strace
      pkgs.lsof
      pkgs.gdb
      pkgs.linuxPackages.perf
      pkgs.procps
      pkgs.tcpdump

      # misc
      pkgs.tmux
      pkgs.zellij
      pkgs.git
      pkgs.bat
      pkgs.eza
      pkgs.zoxide
      pkgs.fzf
      pkgs.delta
      pkgs.dust
      pkgs.duf
      pkgs.hyperfine
      pkgs.tokei
    ];

    programs.bash.completion.enable = true;
    programs.zsh.enable = true;
    programs.fish.enable = true;
    environment.variables.EDITOR = "nvim";
  };
}
