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

  console.useXkbConfig = true;

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
        picture-uri='file://${pkgs.nixos-artwork.wallpapers.mosaic-blue.gnomeFilePath}'
        picture-options='scaled'

        [org.gnome.shell]
        # Favorite apps in gnome-shell
        # favorite-apps=['org.gnome.Console.desktop', 'org.gnome.Nautilus.desktop']
        # Enabled extensions
        enabled-extensions=['${pkgs.gnomeExtensions.arcmenu.extensionUuid}','${pkgs.gnomeExtensions.dash-to-panel.extensionUuid}']

        [org.gnome.mutter]
        edge-tiling=true
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

  system.stateVersion = "24.05"; # Did you read the comment?
}
