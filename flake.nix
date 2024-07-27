{
  description = "Desk OS - A simple, general purpose operating system for desktop computers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  };

  outputs = {
    self,
    nixpkgs,
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
    });

    apps = forAllSystems (system: {
      default = self.apps.${system}.demo;
      demo = let
        clean-state-demo = nixpkgsFor.${system}.writeShellScriptBin "run" ''
          ${self.packages.${system}.demo}/bin/run-desk-os-demo-vm
          if [ -f ./desk-os-demo.qcow2 ]; then
            rm ./desk-os-demo.qcow2
          fi
        '';
      in {
        type = "app";
        program = "${clean-state-demo}/bin/run";
      };
    });

    formatter = forAllSystems (system: nixpkgsFor.${system}.alejandra);
  };
}
