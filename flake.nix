{
  description = "Vitali's Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
    }:
    let
      configuration =
        { pkgs, ... }:
        {
          # Allow unfree packages
          nixpkgs.config.allowUnfree = true;

          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages = [
            # Neovim and other tools neeeded for it.
            pkgs.neovim
            pkgs.lua-language-server
            pkgs.stylua
            # Nix language formatter and LSP
            pkgs.nixfmt-rfc-style
            pkgs.nixd
            # Terminal and CLI Utilities
            pkgs.chezmoi
            pkgs.ripgrep
            pkgs.fd
            pkgs.fzf
            pkgs.tmux
            # Other packages installed via Homebrew.
            pkgs.google-cloud-sdk
            # Development
            pkgs.zig
            pkgs.zls
          ];

          fonts.packages = [
            pkgs.nerd-fonts.zed-mono
          ];

          # Auto upgrade nix package and the daemon service.
          services.nix-daemon.enable = true;
          nix.package = pkgs.nix;

          nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          programs.zsh.enable = false;
          programs.fish.enable = true;
          programs.fish.useBabelfish = true;

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 4;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";

          users.users.vitali = {
            name = "vitali";
            home = "/Users/vitali";
          };

          environment.shells = [ pkgs.fish ];
          environment.variables = {
            EDITOR = "nvim";
          };

          system = {
            # activationScripts run every time you boot the system or execute `darwin-rebuild`
            activationScripts = {
              # https://github.com/LnL7/nix-darwin/issues/811
              setFishAsShell.text = ''
                dscl . -create /Users/vitali UserShell /run/current-system/sw/bin/fish
              '';
            };
          };
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#simple
      darwinConfigurations."macbook-air" = nix-darwin.lib.darwinSystem {
        modules = [ configuration ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."macbook-air".pkgs;
    };
}