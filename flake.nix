{
  description = "Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, }:
  let
    configuration = { pkgs, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages = [
        pkgs.age
        pkgs.jq
        pkgs.librsvg
        pkgs.sops
        pkgs.ansible
        pkgs.python3Full
        pkgs.python3Full.pkgs.requests
        (import ./packages/psport.nix { inherit pkgs; })
        (import ./packages/killport.nix { inherit pkgs; })
      ];

      environment.shellAliases = {
        gti = "git";
        code = "\"/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code\"";
      };

      homebrew = {
        enable = true;
        casks = [
          "1password"
          "adobe-creative-cloud"
          "alacritty"
          "balenaetcher"
          "discord"
          "google-chrome"
          "notion"
          "ollama"
          "private-internet-access"
          "transmission"
          "visual-studio-code"
          "vlc"
          "zoom"
        ];
        masApps = {
          "Xcode" = 497799835; # Xcode IDE for macOS
          "Lungo" = 1263070803;
        };
      };

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
      nixpkgs.config = {
        allowUnfree = true;
        allowUnfreePredicate = (_: true);
      };

      security.pam.enableSudoTouchIdAuth = true;
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#xxx
    darwinConfigurations."xxx" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          users.users.willk.home = "/Users/willk";
          home-manager.users.willk.home = {
            stateVersion = "23.11"; # Changing this is dangerous
            username = "willk";          

            file = {
              ".gitconfig".source = ./homefiles/gitconfig;
            };
          
            sessionVariables = {
              EDITOR = "nano";
            };
          };
        }
      ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."xxx".pkgs;
  };
}
