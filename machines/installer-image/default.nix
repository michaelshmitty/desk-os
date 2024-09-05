{
  config,
  lib,
  options,
  pkgs,
  inputs,
  modulesPath,
  ...
}:
with lib; let
  calamares-nixos-autostart = pkgs.makeAutostartItem {
    name = "io.calamares.calamares";
    package = pkgs.calamares-nixos;
  };
  calamares-extensions-desk-os = pkgs.callPackage ../../packages/calamares-extensions {};
in {
  imports = [
    (modulesPath + "/profiles/all-hardware.nix")
    (modulesPath + "/profiles/base.nix")
    (modulesPath + "/profiles/installation-device.nix")
  ];

  nixpkgs = {
    hostPlatform = lib.mkDefault "x86_64-linux";
    config.allowUnfree = true;
  };

  nix = {
    settings.experimental-features = ["nix-command" "flakes"];
    extraOptions = "experimental-features = nix-command flakes";
  };

  boot = {
    supportedFilesystems = lib.mkForce ["btrfs" "reiserfs" "vfat" "f2fs" "xfs" "ntfs" "cifs"];
  };

  networking.hostName = "desk-os-installer";

  services.openssh.enable = lib.mkForce false;

  # Inhibit sleep, suspend, hibernate
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  boot = {
    consoleLogLevel = 0;
    kernelParams = ["quiet"];
    initrd.verbose = false;
    loader.systemd-boot.enable = true;
    loader.timeout = lib.mkForce 0;
    plymouth = {
      enable = true;
      theme = "breeze";
    };
  };

  # Adds terminus_font for people with HiDPI displays
  console.packages = options.console.packages.default ++ [pkgs.terminus_font];

  # An installation media cannot tolerate a host config defined file
  # system layout on a fresh machine, before it has been formatted.
  swapDevices = mkImageMediaOverride [];
  # fileSystems = mkImageMediaOverride config.lib.isoFileSystems;

  boot.postBootCommands = ''
    for o in $(</proc/cmdline); do
      case "$o" in
        live.nixos.passwd=*)
          set -- $(IFS==; echo $o)
          echo "nixos:$2" | ${pkgs.shadow}/bin/chpasswd
          ;;
      esac
    done
  '';

  system.stateVersion = lib.mkDefault lib.trivial.release;

  # Whitelist wheel users to do anything
  # This is useful for things like pkexec
  #
  # WARNING: this is dangerous for systems
  # outside the installation-cd and shouldn't
  # be used anywhere else.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

  services.xserver.enable = true;

  # Provide networkmanager for easy wireless configuration.
  networking.networkmanager.enable = true;
  networking.wireless.enable = mkImageMediaOverride false;

  # KDE complains if power management is disabled (to be precise, if
  # there is no power management backend such as upower).
  powerManagement.enable = true;

  # Enable sound in graphical iso's.
  hardware.pulseaudio.enable = true;

  # VM guest additions to improve host-guest interaction
  services.spice-vdagentd.enable = true;
  services.qemuGuest.enable = true;
  virtualisation.vmware.guest.enable = pkgs.stdenv.hostPlatform.isx86;
  virtualisation.hypervGuest.enable = true;
  services.xe-guest-utilities.enable = pkgs.stdenv.hostPlatform.isx86;
  # The VirtualBox guest additions rely on an out-of-tree kernel module
  # which lags behind kernel releases, potentially causing broken builds.
  virtualisation.virtualbox.guest.enable = false;

  environment.defaultPackages = with pkgs; [
    # Include gparted for partitioning disks.
    gparted

    # Include some editors.
    vim
    nano

    # Include some version control tools.
    git
    rsync
  ];

  environment.systemPackages = with pkgs; [
    # Calamares for graphical installation
    libsForQt5.kpmcore
    calamares-nixos
    calamares-nixos-autostart
    calamares-extensions-desk-os
    # Get list of locales
    glibcLocales
    gnomeExtensions.no-overview
  ];

  # Support choosing from any locale
  i18n.supportedLocales = ["all"];

  services.xserver.desktopManager.gnome = {
    favoriteAppsOverride = ''
      [org.gnome.shell]
      favorite-apps=[ 'io.calamares.calamares.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Console.desktop' ]
      enabled-extensions=[ '${pkgs.gnomeExtensions.no-overview.extensionUuid}' ]
    '';

    # Override GNOME defaults to disable GNOME tour and disable suspend
    extraGSettingsOverrides = ''
      [org.gnome.shell]
      welcome-dialog-last-shown-version='9999999999'
      [org.gnome.desktop.session]
      idle-delay=0
      [org.gnome.settings-daemon.plugins.power]
      sleep-inactive-ac-type='nothing'
      sleep-inactive-battery-type='nothing'
    '';

    extraGSettingsOverridePackages = [pkgs.gnome.gnome-settings-daemon];

    enable = true;
  };

  # Fix scaling for calamares on wayland
  environment.variables = {
    QT_QPA_PLATFORM = "$([[ $XDG_SESSION_TYPE = \"wayland\" ]] && echo \"wayland\")";
  };

  services.xserver.displayManager.gdm = {
    enable = true;
    autoSuspend = false;
  };

  services.displayManager.autoLogin = {
    enable = true;
    user = "nixos";
  };
}
