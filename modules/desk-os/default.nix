{
  pkgs,
  lib,
  config,
  ...
}: {
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = ["nix-command" "flakes"];

  boot = {
    consoleLogLevel = 0;
    kernelParams = ["quiet"];
    initrd.verbose = false;
    loader.systemd-boot.enable = true;
    loader.systemd-boot.configurationLimit = 3;
    loader.efi.canTouchEfiVariables = true;
    plymouth = {
      enable = true;
      theme = "breeze";
    };
  };

  system.autoUpgrade.enable = true;

  services.printing.enable = true;
  hardware.bluetooth.enable = true;

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

  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome = {
      enable = true;
      extraGSettingsOverrides = ''
        [org.gnome.desktop.background]
        picture-uri='file://${pkgs.gnome.gnome-backgrounds}/share/backgrounds/gnome/geometrics-l.jxl'
        picture-uri-dark='file://${pkgs.gnome.gnome-backgrounds}/share/backgrounds/gnome/geometrics-d.jxl'

        [org.gnome.desktop.screensaver]
        picture-uri='file://${pkgs.gnome.gnome-backgrounds}/share/backgrounds/gnome/geometrics-l.jxl'

        [org.gnome.desktop.interface]
        enable-hot-corners=false
        show-battery-percentage=true

        [org.gnome.shell]
        favorite-apps=['firefox.desktop', 'org.gnome.Geary.desktop', 'org.gnome.Calendar.desktop', 'org.gnome.Nautilus.desktop']
        enabled-extensions=['${pkgs.gnomeExtensions.arcmenu.extensionUuid}','${pkgs.gnomeExtensions.dash-to-panel.extensionUuid}']

        [org.gnome.mutter]
        edge-tiling=true
        experimental-features=['scale-monitor-framebuffer']

        [org.gnome.shell.extensions.dash-to-panel]
        panel-element-positions='{"0":[{"element":"showAppsButton","visible":false,"position":"stackedTL"},{"element":"activitiesButton","visible":false,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":true,"position":"stackedBR"}]}'
        hide-overview-on-startup=true

        [org.gnome.shell.extensions.arcmenu]
        menu-layout='Windows'
      '';

      extraGSettingsOverridePackages = [
        pkgs.gsettings-desktop-schemas # for org.gnome.desktop
        pkgs.gnome.gnome-shell # for org.gnome.shell
        pkgs.gnome.mutter # for org.gnome.mutter
      ];
    };
  };

  services.udev.packages = with pkgs; [gnome.gnome-settings-daemon];

  environment.systemPackages = with pkgs; [
    firefox
    gnomeExtensions.arcmenu
    gnomeExtensions.dash-to-panel
  ];

  environment.gnome.excludePackages = with pkgs; [
    pkgs.gnome-tour
    pkgs.gnome.epiphany
  ];
}
