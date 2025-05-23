{
  description = "Omori's nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew }:
  let
    configuration = { pkgs, config,  ... }: {

      nixpkgs.config.allowUnfree = true;

      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [ 
          pkgs.mkalias
          pkgs.neovim
          pkgs.alacritty

        ];
      
      # Home-brew config 
      homebrew = {
          enable = true;
          brews = [
            "mas"
            "docker"
          ];
          casks = [
            # "GUI app you want to install"
            # "firefox"
            # "wezterm"
            # "alacritty"
            # "rectangle"
            # "discord"
            # "telegram-desktop"
            # "firefox"
            # "visual-studio-code"
            # "obsidian"
            # "keka"
            # "utm"
            # "dbeaver-community"
            # "postman"
            # "cloudflare-warp"
            # "mongodb-compass"
          ];
          masApps = {
           # "Yoink" = 457622435; 
          };
          onActivation.cleanup = "none"; # "zap" 
          onActivation.autoUpdate = true;
          onActivation.upgrade = true;
        };

      # Fonts config
      # fonts.packages = 
      #   [
      #     (pkgs.nerdfonts.override { fonts = ["JetBrainsMono"]; })
      #   ];

      system.activationScripts.applications.text = pkgs.lib.mkForce ''
        echo "Setting up /Applications/Nix Apps..." >&2
        rm -rf /Applications/Nix\ Apps
        mkdir -p /Applications/Nix\ Apps
        for app in ${pkgs.buildEnv {
          name = "system-applications";
          paths = config.environment.systemPackages;
          pathsToLink = "/Applications";
        }}/Applications/*.app; do
        if [ -d "$app" ]; then
          app_name=$(basename "$app")
          echo "Creating alias for $app_name..." >&2
            ${pkgs.mkalias}/bin/mkalias "$app" "/Applications/Nix Apps/$app_name"
          fi
        done
      '';


      # # System defaults settings 
      # system.defaults = {
      #   dock.autohide = true;
      #   dock.persistent-apps = [
      #     "/System/Applications/Music.app"
      #     "/System/Applications/Mail.app"
      #     "/System/Applications/System Settings.app"
      #     "/System/Applications/Calendar.app"
      #     "/System/Applications/Firefox.app"
      #     "/System/Applications/WezTerm.app"
      #     "/System/Applications/UTM.app"
      #     "/System/Applications/Obsidian.app"
      #     "/System/Applications/Docker Desktop.app"
      #   ]
      #   finder.FXPreferredViewStyle = "clmv";
      #   finder = {
      #       ShowPathBar = true;
      #       ShowPreviewPane = true;
      #       ShowExternalHardDrivesOnDesktop = true;
      #       ShowHardDrivesOnDesktop = false;
      #       ShowRemovableMediaOnDesktop = true;
      #       ShowSidebar = true;
      #       ShowStatusBar = true;
      #     };
      #   trackpad = {
      #       Clicking = true;
      #       TrackpadRightClick = true;
      #       TrackpadThreeFingerDrag = true;
      #       ActuateDetents = true;
      #       FirstClickThreshold = 1;
      #       SecondClickThreshold = 1;
      #       TrackpadScroll = true;
      #       TrackpadHorizScroll = true;
      #       TrackpadMomentumScroll = true;
      #       TrackpadPinch = true;
      #       TrackpadRotate = true;
      #       TrackpadHandResting = true;
      #       TrackpadCornerSecondaryClick = 0;
      #       TrackpadFiveFingerPinchGesture = 2;
      #       TrackpadFourFingerHorizSwipeGesture = 2;
      #       TrackpadFourFingerPinchGesture = 2;
      #       TrackpadFourFingerVertSwipeGesture = 2;
      #       TrackpadThreeFingerHorizSwipeGesture = 0;
      #       TrackpadThreeFingerTapGesture = 0;
      #       TrackpadThreeFingerVertSwipeGesture = 0;
      #       TrackpadTwoFingerDoubleTapGesture = 1;
      #       TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
      #       DragLock = false;
      #       Dragging = false;
      #     };
      #   loginwindow.GuestEnabled = false;
      #   NSGlobalDomain = {
      #       "com.apple.trackpad.forceClick" = true;
      #       "com.apple.trackpad.scaling" = 1.0;
      #     };
      #   NSGlobalDomain.AppleICUForce24HourTime = true;
      #   NSGlobalDomain.AppleInterfaceStyle = "Dark";
      #   NSGlobalDomain.KeyRepeat = 2;
      # };

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;
      programs.zsh.enable = true; 

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."air" = nix-darwin.lib.darwinSystem {
      modules = [ 
        configuration 
        nix-homebrew.darwinModules.nix-homebrew 
        {
          nix-homebrew = {
            enable = true;
            # Apple Silicon Only 
            enableRosetta = true;
            # User that own the homebrew prefix 
            user = "omori";

            autoMigrate = true;
          };
        }
      ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."air".pkgs;
  };
}
