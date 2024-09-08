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
  calamares-desk-os = lowPrio (
    (pkgs.calamares.override {nixos-extensions = true;})
    .overrideAttrs {
      patches = [
        ../../packages/calamares/0001-Modifies-the-users-module-to-only-set-passwords-of-u.patch
        ../../packages/calamares/0002-Makes-calamares-search-run-current-system-sw-share-c.patch
        ../../packages/calamares/0003-Uses-pkexec-within-modules-in-order-to-run-calamares.patch
        ../../packages/calamares/0004-Adds-unfree-qml-to-packagechooserq.patch
        ../../packages/calamares/0005-Modifies-finished-module-to-add-some-NixOS-resources.patch
        ../../packages/calamares/0006-Remove-options-for-unsupported-partition-types.patch
        ../../packages/calamares/0007-Fix-setting-the-kayboard-layout-on-GNOME-wayland.patch
        ../../packages/calamares/0008-Change-default-location-where-calamares-searches-for.patch
      ];
    }
  );
  calamares-extensions-desk-os = pkgs.callPackage ../../packages/calamares-extensions {};
  calamares-nixos-autostart = pkgs.makeAutostartItem {
    name = "io.calamares.calamares";
    package = calamares-desk-os;
  };
in {
  imports = [
    ./iso-image.nix
    (modulesPath + "/profiles/all-hardware.nix")
    (modulesPath + "/profiles/base.nix")
    (modulesPath + "/profiles/installation-device.nix")
  ];

  system.nixos.distroName = "deskOS 1";

  # FIXME(m): Disable squashfs compression during development
  # isoImage.squashfsCompression = null;

  boot = {
    consoleLogLevel = 0;
    kernelParams = ["quiet" "splash" "systemd.show_status=auto" "rd.udev.log_level=3"];
    initrd.verbose = false;
    loader.systemd-boot.enable = true;
    loader.timeout = lib.mkForce 0;
    plymouth = {
      enable = true;
      logo = ../../assets/blank-plymouth-logo.png;
    };

    # NOTE(m): Enable kernel modules that improve wifi support on
    # Macbooks during installation.
    # See https://nixos.org/manual/nixos/stable/#sec-building-image-drivers
    # FIXME(m): See if this can be cleaned up and go somewhere else and
    # ensure this doesn't break non-Apple hardware.
    initrd.kernelModules = ["wl"];
    kernelModules = ["kvm-intel" "wl"];
    extraModulePackages = [config.boot.kernelPackages.broadcom_sta];
  };

  # Adds terminus_font for people with HiDPI displays
  console.packages = options.console.packages.default ++ [pkgs.terminus_font];

  # ISO naming.
  isoImage.isoName = "${config.isoImage.isoBaseName}-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";

  # An installation media cannot tolerate a host config defined file
  # system layout on a fresh machine, before it has been formatted.
  swapDevices = mkImageMediaOverride [];
  fileSystems = mkImageMediaOverride config.lib.isoFileSystems;

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
  # NOTE(m): Silence noisy hyper-v kernel modules by disabling hyper-V guest
  # FIXME(m): Find a better way like figure out how to prevent log messages from
  # appearing at boot even more than already done above.
  virtualisation.hypervGuest.enable = false;
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
    calamares-desk-os
    calamares-nixos-autostart
    calamares-extensions-desk-os
    # Get list of locales
    glibcLocales
    gnomeExtensions.no-overview
  ];

  # Support choosing from any locale
  i18n.supportedLocales = ["all"];

  isoImage.edition = "gnome";

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
      [org.gnome.desktop.background]
      picture-uri='file://${pkgs.gnome.gnome-backgrounds}/share/backgrounds/gnome/geometrics-l.jxl'
      [org.gnome.desktop.screensaver]
      picture-uri='file://${pkgs.gnome.gnome-backgrounds}/share/backgrounds/gnome/geometrics-l.jxl'
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
