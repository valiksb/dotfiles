{ user, ... }:

{
  # Determinate already manages the Nix daemon, so nix-darwin shouldn't.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin"; # use x86_64-darwin for Intel CPU
  nixpkgs.overlays = [
    # Upstream tesla_auth hardcodes Linux GTK/webkitgtk deps (webkitgtk is broken
    # on darwin). On macOS it uses the system WebKit, so drop them.
    (final: prev: {
      tesla_auth = prev.tesla_auth.overrideAttrs (old: {
        nativeBuildInputs = final.lib.remove final.wrapGAppsHook3 old.nativeBuildInputs;
        buildInputs = [ ];
      });
    })
  ];

  system.primaryUser = user;
  users.users.${user} = {
    home = "/Users/${user}";
  };
  system.stateVersion = 6;
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;          # fast key repeat
      InitialKeyRepeat = 15;  # short delay before repeat
      _HIHideMenuBar = false;
      AppleShowAllExtensions = true;
    };
    dock.autohide = true;
    finder.FXPreferredViewStyle = "Nlsv";  # list view by default
    finder.CreateDesktop = false;          # clean desktop
    trackpad.Clicking = true;              # tap to click
    CustomSystemPreferences."com.apple.controlcenter".AutoHideMenuBarOption = 3; # macOS 26: 3 = "Never" (always show menu bar)
  };
  system.activationScripts.extraActivation.text = ''
    sudo -u ${user} defaults -currentHost write com.apple.screensaver idleTime -int 300
  '';

  nix-homebrew = {
    enable = true;
    inherit user;
    autoMigrate = true;
  };
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";  # remove anything not listed here
    onActivation.autoUpdate = true;
    onActivation.extraFlags = [ "--force" ];
    brews = [
      "herdr"
      "node"
      "podman-compose"
      "treehouse"
      "terraform"
      "gh"
    ];
    casks = [
      "wezterm"
      "claude-code"
      "fluidvoice"
      "gcloud-cli"
    ];
  };

  launchd.user.agents.podman-login = {
    script = ''
      export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"

      start_output=$(podman machine start 2>&1)
      start_exit=$?
      if [ "$start_exit" -ne 0 ]; then
        case "$start_output" in
          *"already running"*|*"is currently running"*|*"VM already running"*)
            echo "podman machine already running, continuing"
            ;;
          *)
            echo "podman machine start failed: $start_output"
            ;;
        esac
      else
        echo "podman machine started"
      fi

      echo "Starting TeslaMate..."
      ( cd /Users/${user}/Documents/github/teslamate-podman && podman-compose up -d 2>&1 ) || \
        echo "TeslaMate failed to start, continuing"

      echo "Starting Immich..."
      ( cd /Users/${user}/Documents/immich-app && podman-compose up -d 2>&1 ) || \
        echo "Immich failed to start, continuing"
    '';
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = false;
      StandardOutPath = "/Users/${user}/Library/Logs/podman-login.log";
      StandardErrorPath = "/Users/${user}/Library/Logs/podman-login.log";
    };
  };
}
