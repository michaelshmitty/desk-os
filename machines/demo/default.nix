{pkgs}: {modulesPath, ...}: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/virtualisation/qemu-vm.nix")
  ];

  config = {
    virtualisation = {
      memorySize = 8192;
      qemu.options = [
        "-enable-kvm"
        "-vga virtio"
      ];
    };

    networking.hostName = "desk-os-demo";

    # Localization
    time.timeZone = "Europe/Brussels";
    i18n.defaultLocale = "en_US.UTF-8";
    services.xserver.xkb.layout = "us";
    services.xserver.xkb.variant = "dvorak";

    services.displayManager.autoLogin = {
      enable = true;
      user = "demo";
    };
    security.sudo.wheelNeedsPassword = false;
    users.users.demo = {
      createHome = true;
      isNormalUser = true;
      extraGroups = ["networkmanager" "wheel"];
      initialPassword = "demo";
    };
  };
}
