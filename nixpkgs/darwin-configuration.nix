# { config, pkgs, ... }:

# {
#   imports = [ <home-manager/nix-darwin> ];

#   nix.settings.experimental-features = [ "nix-command" ];

#   nix = {
#     package = pkgs.nixFlakes;
#     extraOptions = ''
#       experimental-features = nix-command flakes
#     '';
#   };

#   # List packages installed in system profile. To search by name, run:
#   # $ nix-env -qaP | grep wget
#   environment.systemPackages =
#     [ pkgs.vim
#       pkgs.sops
#     ];

#   users.users.willk = {
#     name = "willk";
#     home = "/Users/willk";
#   };

#   home-manager.users.willk = { pkgs, ... }: {
#   home.packages = [
#     pkgs.atool
#     pkgs.httpie
#   ];
#   programs.bash.enable = true;

#     # The state version is required and should stay at the version you
#     # originally installed.
#     home.stateVersion = "23.11";
#   };

#   # Use a custom configuration.nix location.
#   # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
#   # environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

#   # Auto upgrade nix package and the daemon service.
#   services.nix-daemon.enable = true;
#   # nix.package = pkgs.nix;

#   # Create /etc/zshrc that loads the nix-darwin environment.
#   programs.zsh.enable = true;  # default shell on catalina
#   # programs.fish.enable = true;

#   # Used for backwards compatibility, please read the changelog before changing.
#   # $ darwin-rebuild changelog
#   system.stateVersion = 4;
# }
