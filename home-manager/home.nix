# { config, pkgs, ... }:

# {
#   nixpkgs = {
#     config = {
#       allowUnfree = true;
#       allowUnfreePredicate = (_: true);
#     };
#   };

#   # home.username = "willk";
#   # home.homeDirectory = "/Users/willk";
#   home = "/Users/willk";
#   # users.users.xxx.home

#   # You should not change this value, even if you update Home Manager. If you do
#   # want to update the value, then make sure to first check the Home Manager
#   # release notes.
#   # home.stateVersion = "23.11"; # Please read the comment before changing.

#   home.packages = [
#     (pkgs.writeShellScriptBin "psport" "lsof -i TCP:$1 | grep LISTEN | awk '{print $2}' | xargs ps")
#     (pkgs.writeShellScriptBin "killport" "lsof -i TCP:$1 | grep LISTEN | awk '{print $2}' | uniq | xargs kill -9")
#     (pkgs.writeShellScriptBin "gti" "git")
#   ];

#   home.file = {
#     ".gitconfig".source = ../gitconfig;
#   };

#   home.sessionVariables = {
#     EDITOR = "nano";
#   };

#   # Let Home Manager install and manage itself.
#   # programs.home-manager = {
#   #   enable = false;
#   #   path = "$HOME/.dotfiles/home-manager/home.nix";
#   # };
# }
