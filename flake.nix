{
  description = "Example Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs }:
  let
    configuration = { pkgs, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages = with pkgs; [
          vim
          hello
        ];

      # Auto upgrade nix package and the daemon service.
      services.nix-daemon.enable = true;
      # nix.package = pkgs.nix;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Create /etc/zshrc that loads the nix-darwin environment.
      programs.zsh.enable = true;  # default shell on catalina
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 4;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#xxx
    darwinConfigurations."xxx" = nix-darwin.lib.darwinSystem {
      modules = [ configuration ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."xxx".pkgs;
  };
}



# {
#   description = "Darwin configuration";

#   inputs = {
#     nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
#     # darwin.url = "github:lnl7/nix-darwin";
#     # darwin.inputs.nixpkgs.follows = "nixpkgs";
#     home-manager.url = "github:nix-community/home-manager";
#     home-manager.inputs.nixpkgs.follows = "nixpkgs";
#     nix-darwin.url = "github:LnL7/nix-darwin";
#     nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
#     sops-nix.url = "github:Mic92/sops-nix";
#     sops-nix.inputs.nixpkgs.follows = "nixpkgs";
#   };

#   outputs = inputs@{ self, nixpkgs, home-manager, nix-darwin, ... }:
#   let configuration = { pkgs }: {
#     environment.systemPackages = [ nixpkgs.vim nixpkgs.hello ];
#     services.nix-daemon.enable = true;
#     nix.settings.experimental-features = "nix-command flakes";

#     programs.zsh.enable = true;
#     system.configurationRevision = self.rev or self.dirtyRev or null;

#     nixpkgs.hostPlatform = "aarch64-darwin";

#     security.pam.enableSudoTouchIdAuth = true;

#     # darwinConfigurations = {
#     #   hostname = nix-darwin.lib.darwinSystem {
#     #     system = "aarch64-darwin";
#     #     modules = [
#     #       # ./nix/configuration.nix
#     #       home-manager.darwinModules.home-manager
#     #       {
#     #         home-manager.useGlobalPkgs = true;
#     #         home-manager.useUserPackages = true;
#     #         # home-manager.users.willk = import ./home-manager/home.nix;

#     #         # Optionally, use home-manager.extraSpecialArgs to pass
#     #         # arguments to home.nix
#     #       }
#     #     ];
#     #   };
#     # };
#   };
# in
#   {
#     # Build darwin flake using:
#     # $ darwin-rebuild build --flake .#simple
#     darwinConfigurations."simple" = nix-darwin.lib.darwinSystem {
#       modules = [ configuration ];
#     };

#     # Expose the package set, including overlays, for convenience.
#     darwinPackages = self.darwinConfigurations."simple".pkgs;
#   };
# }
