{
  description = "Pre-built OCI images for ix VMs";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.llm-agents = {
    url = "github:numtide/llm-agents.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.claude-code-nix = {
    url = "github:sadjow/claude-code-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.codex-cli-nix = {
    url = "github:sadjow/codex-cli-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      llm-agents,
      claude-code-nix,
      codex-cli-nix,
    }:
    let
      ix = import ./lib {
        inherit nixpkgs llm-agents claude-code-nix codex-cli-nix;
      };
    in
    {
      lib = ix;
      modules = import ./modules;

      packages.${ix.system} = ix.discoverImages ./images;
      checks.${ix.system}.eval = import ./tests { inherit nixpkgs ix; };
      formatter.${ix.system} = nixpkgs.legacyPackages.${ix.system}.nixfmt;

      templates.default = {
        path = ./template;
        description = "Starter ix image";
      };
    };
}
