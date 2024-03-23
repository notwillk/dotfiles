{ config, pkgs, ... }:

{
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
  };

  home.username = "willk";
  home.homeDirectory = "/Users/willk";

  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.11"; # Please read the comment before changing.

  home.packages = with pkgs;[
    hello
    jq
    (writeShellScriptBin "psport" "lsof -i TCP:$1 | grep LISTEN | awk '{print $2}' | xargs ps")
    (writeShellScriptBin "killport" "lsof -i TCP:$1 | grep LISTEN | awk '{print $2}' | uniq | xargs kill -9")
    (writeShellScriptBin "gti" "git")
  ];

  home.file = {
    ".gitconfig".source = ../gitconfig;
  };

  home.sessionVariables = {
    EDITOR = "nano";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager = {
    enable = false;
    path = "$HOME/.dotfiles/home-manager/home.nix";
  };
}
