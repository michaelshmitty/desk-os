{
  description = "deskOS - An easy to use, stable desktop operating system";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixos-generators,
  } @ inputs: let
    supportedSystems = [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-darwin"
      "x86_64-linux"
    ];

    # Function to generate a set based on supported systems:
    forAllSystems = inputs.nixpkgs.lib.genAttrs supportedSystems;

    # Attribute set of nixpkgs for each system:
    nixpkgsFor = forAllSystems (system:
      import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      });
  in {
    nixosConfigurations = {
      installer = nixpkgs.lib.nixosSystem {
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
          ./machines/installer
        ];
        specialArgs = {inherit inputs;};
      };
    };

    nixosModules = {
      desk-os = import ./modules/desk-os;
    };

    packages = forAllSystems (system: let
      pkgs = nixpkgsFor.${system};
    in {
      default = self.packages.${system}.demo;
      demo =
        (inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./modules/desk-os
            (import ./machines/demo {inherit pkgs;})
          ];
        })
        .config
        .system
        .build
        .vm;

      installer-demo = pkgs.writeShellScript "installer-demo" ''
        set -euo pipefail
        disk=installer-demo-root.img
        ${pkgs.qemu}/bin/qemu-img create -f qcow2 "$disk" 80G
        ${pkgs.qemu}/bin/qemu-system-x86_64 \
          -cpu host \
          -enable-kvm \
          -m 8G \
          -vga virtio \
          -display gtk,full-screen=on,grab-on-hover=on \
          -bios ${pkgs.OVMF.fd}/FV/OVMF.fd \
          -cdrom ${self.packages.${system}.installer-iso}/iso/*.iso \
          -hda "$disk"
      '';

      installer-iso = inputs.self.nixosConfigurations.installer.config.system.build.isoImage;
    });

    apps = forAllSystems (system: {
      default = self.apps.${system}.demo;
      demo = let
        clean-state-demo = nixpkgsFor.${system}.writeShellScriptBin "run" ''
          ${self.packages.${system}.demo}/bin/run-desk-os-demo-vm
          # Remove disk image forcing demo VM to start with a clean state every time
          if [ -f ./desk-os-demo.qcow2 ]; then
            rm ./desk-os-demo.qcow2
          fi
        '';
      in {
        type = "app";
        program = "${clean-state-demo}/bin/run";
      };

      installer-demo = {
        type = "app";
        program = "${self.packages.${system}.installer-demo}";
      };
    });

    formatter = forAllSystems (system: nixpkgsFor.${system}.alejandra);
  };
}
