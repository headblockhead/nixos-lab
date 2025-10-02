{ inputs, nixosModules, useCustomNixpkgsNixosModule, hostname, ... }:
let
  system = "x86_64-linux";
in
{
  nixosConfiguration = inputs.nixpkgs.lib.nixosSystem {
    inherit system;

    specialArgs = {
      inherit inputs system;
    };

    modules = with nixosModules; [
      useCustomNixpkgsNixosModule

      {
        networking.hostName = hostname;
        system.stateVersion = "25.05";
      }

      ./config.nix
      ./hardware.nix

      basicConfig
      fileSystems
      bootloader
      activeDirectory
    ];
  };
  inherit system;
}
