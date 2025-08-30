# SPDX-FileCopyrightText: 2025 Jure Varlec <jure@varlec.si>
#
# SPDX-License-Identifier: MIT

{
  description = "GPU driver setup for Nix on non-NixOS Linux systems";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-25.05";

  outputs =
    { self, nixpkgs }: let
      # to work with older version of flakes
      lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

      # Generate a user-friendly version number.
      version = builtins.substring 0 8 lastModifiedDate;

      # System types to support.
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in {
      # Provide some binary packages for selected system types.
      packages = forAllSystems (system: rec {
        env = nixpkgsFor.${system}.callPackage ./gpu-libs-env.nix {};
        setup = nixpkgsFor.${system}.callPackage ./setup { non-nixos-gpu-env = env; };
      });

      # The default package for 'nix build'. This makes sense if the
      # flake provides only one package or there is a clear "main"
      # package.
      defaultPackage = forAllSystems (system: self.packages.${system}.setup);
    };
}
