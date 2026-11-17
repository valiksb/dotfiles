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
      # nixpkgs marks osxphotos broken (unverified build failure, not platform-restricted).
      # The package declares aarch64-darwin support; override here until upstream clears the flag.
      python3 = prev.python3.override {
        packageOverrides = _: super: {
          osxphotos = super.osxphotos.overridePythonAttrs (_: { meta = super.osxphotos.meta // { broken = false; }; });
        };
      };
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

  launchd.user.agents.photos-mount = {
    script = ''
      export PATH="/sbin:/usr/sbin:/usr/bin:/bin"

      waited=0
      until /sbin/route -n get default >/dev/null 2>&1 || [ "$waited" -ge 60 ]; do
        sleep 5
        waited=$((waited + 5))
      done

      mount_point="/Users/${user}/SolorzanoPhotos"

      if [ ! -d "$mount_point" ]; then
        mkdir -p "$mount_point"
      fi

      if /sbin/mount | grep -qF " on $mount_point "; then
        echo "Already mounted at $mount_point"
        exit 0
      fi

      # Credentials are read from the macOS Keychain; no password in args.
      /sbin/mount_smbfs "//valiksb@Acts-10-4/Photos" "$mount_point"
    '';
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = false;
      StandardOutPath = "/Users/${user}/Library/Logs/photos-mount.log";
      StandardErrorPath = "/Users/${user}/Library/Logs/photos-mount.log";
    };
  };

  launchd.user.agents.photo-export = {
    script = ''
      export PATH="/Users/${user}/.nix-profile/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
      exec /Users/${user}/Documents/immich-app/scripts/export_photos.sh
    '';
    serviceConfig = {
      StartCalendarInterval = [{ Hour = 2; Minute = 0; }];
      StandardOutPath = "/Users/${user}/Library/Logs/photo_export.log";
      StandardErrorPath = "/Users/${user}/Library/Logs/photo_export.log";
    };
  };

  launchd.user.agents.podman-login = {
    script = ''
      export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"

      podman machine start 2>&1 || echo "podman machine start exited non-zero, continuing"

      echo "Starting TeslaMate..."
      ( cd /Users/${user}/Documents/github/teslamate-podman && podman-compose up -d 2>&1 ) || \
        echo "TeslaMate failed to start, continuing"

      waited=0
      until route -n get default >/dev/null 2>&1 || [ "$waited" -ge 60 ]; do
        sleep 5
        waited=$((waited + 5))
      done
      if route -n get default >/dev/null 2>&1; then
        echo "Network is up after $waited seconds"
      else
        echo "Network not up after $waited seconds, starting Immich anyway"
      fi

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
