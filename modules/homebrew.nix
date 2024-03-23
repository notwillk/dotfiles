{...}: {
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
      upgrade = true;
    };
    brews = [
      
    ];
    taps = [
      "homebrew/cask"
      "koekeishiya/formulae" # yabai
    ];
    caskArgs = {
      appdir = "~/Applications";
      require_sha = true;
    };
    casks = [
      "google-chrome"
      "notion"
    ];
    masApps = {
      "Xcode" = 497799835; # Xcode IDE for macOS
    };
  };
}
