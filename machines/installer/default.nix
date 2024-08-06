{
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ../../modules/installer
  ];

  isoImage.isoName = lib.mkForce "nixup-desk-os-installer.iso";

  nixpkgs = {
    hostPlatform = lib.mkDefault "x86_64-linux";
    config.allowUnfree = true;
  };

  nix = {
    settings.experimental-features = ["nix-command" "flakes"];
    extraOptions = "experimental-features = nix-command flakes";
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    supportedFilesystems = lib.mkForce ["btrfs" "reiserfs" "vfat" "f2fs" "xfs" "ntfs" "cifs"];
  };

  networking.hostName = "desk-os-installer-demo";

  services.qemuGuest.enable = true;

  services.openssh.enable = lib.mkForce false;

  # Inhibit sleep, suspend, hibernate
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  environment.systemPackages = with pkgs; [
    git
  ];
}
