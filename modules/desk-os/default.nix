{
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    ../systemd-boot
  ];

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = ["nix-command" "flakes"];

  boot = {
    consoleLogLevel = 0;
    kernelParams = ["quiet" "splash" "systemd.show_status=auto" "rd.udev.log_level=3"];
    initrd.verbose = false;
    loader.systemd-boot.enable = true;
    loader.systemd-boot.configurationLimit = 3;
    loader.efi.canTouchEfiVariables = true;
    plymouth = {
      enable = true;
      logo = ../../assets/blank-plymouth-logo.png;
    };
  };

  system.nixos.distroName = "deskOS 1";

  system.autoUpgrade = {
    enable = true;
    flake = "/etc/nixos";
    operation = "boot";
    randomizedDelaySec = "45min";
    flags = [
      "--refresh"
      "--commit-lock-file"
      "--update-input"
      "nixpkgs"
      "--update-input"
      "desk-os"
    ];
  };

  services.printing.enable = true;
  hardware.bluetooth.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };

  networking.networkmanager.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  i18n.inputMethod.enabled = "ibus";

  programs.dconf.enable = true;
  programs.dconf.profiles = {
    user.databases = [
      {
        settings = {
          "org/gnome/desktop/background" = {
            picture-uri = "file://${pkgs.gnome.gnome-backgrounds}/share/backgrounds/gnome/geometrics-l.jxl";
            picture-uri-dark = "file://${pkgs.gnome.gnome-backgrounds}/share/backgrounds/gnome/geometrics-d.jxl";
          };

          "org/gnome/desktop/screensaver" = {
            picture-uri = "file://${pkgs.gnome.gnome-backgrounds}/share/backgrounds/gnome/geometrics-l.jxl";
          };

          "org/gnome/desktop/interface" = {
            enable-hot-corners = false;
            show-battery-percentage = true;
          };

          "org/gnome/shell" = {
            favorite-apps = [
              "firefox.desktop"
              "org.gnome.Nautilus.desktop"
            ];
            enabled-extensions = [
              "${pkgs.gnomeExtensions.appindicator.extensionUuid}"
              "${pkgs.gnomeExtensions.arcmenu.extensionUuid}"
              "${pkgs.gnomeExtensions.dash-to-panel.extensionUuid}"
              "${pkgs.gnomeExtensions.printers.extensionUuid}"
              "${pkgs.gnomeExtensions.removable-drive-menu.extensionUuid}"
            ];
          };

          "org/gnome/mutter" = {
            edge-tiling = true;
            experimental-features = ["scale-monitor-framebuffer"];
          };

          "org/gnome/shell/extensions/dash-to-panel" = {
            panel-element-positions = builtins.toJSON {
              "0" = [
                {
                  element = "showAppsButton";
                  visible = false;
                  position = "stackedTL";
                }
                {
                  element = "activitiesButton";
                  visible = false;
                  position = "stackedTL";
                }
                {
                  element = "leftBox";
                  visible = true;
                  position = "stackedTL";
                }
                {
                  element = "taskbar";
                  visible = true;
                  position = "stackedTL";
                }
                {
                  element = "centerBox";
                  visible = true;
                  position = "stackedBR";
                }
                {
                  element = "rightBox";
                  visible = true;
                  position = "stackedBR";
                }
                {
                  element = "systemMenu";
                  visible = true;
                  position = "stackedBR";
                }
                {
                  element = "dateMenu";
                  visible = true;
                  position = "stackedBR";
                }
                {
                  element = "desktopButton";
                  visible = true;
                  position = "stackedBR";
                }
              ];
            };
            hide-overview-on-startup = true;
          };

          "org/gnome/shell/extensions/arcmenu" = {
            menu-layout = "Windows";
            pinned-apps = lib.gvariant.mkArray [
              [(lib.gvariant.mkDictionaryEntry "id" "firefox.desktop")]
              [(lib.gvariant.mkDictionaryEntry "id" "org.gnome.Geary.desktop")]
              [(lib.gvariant.mkDictionaryEntry "id" "org.gnome.Calendar.desktop")]
              [(lib.gvariant.mkDictionaryEntry "id" "org.gnome.Nautilus.desktop")]
              [(lib.gvariant.mkDictionaryEntry "id" "writer.desktop")]
              [(lib.gvariant.mkDictionaryEntry "id" "calc.desktop")]
              [(lib.gvariant.mkDictionaryEntry "id" "impress.desktop")]
            ];
          };
        };
      }
    ];
  };

  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  services.udev.packages = with pkgs; [gnome.gnome-settings-daemon];

  environment.systemPackages = with pkgs; [
    firefox
    gnomeExtensions.appindicator
    gnomeExtensions.arcmenu
    gnomeExtensions.dash-to-panel
    gnomeExtensions.printers
    gnomeExtensions.removable-drive-menu
    libreoffice
  ];

  environment.gnome.excludePackages = with pkgs; [
    pkgs.gnome-tour
    pkgs.gnome.epiphany
  ];

  # Fix scaling issues with electron apps
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Let QT apps follow Gnome theme settings
  qt.enable = true;
  qt.platformTheme = "qt5ct";

  services.flatpak.enable = true;
}
