{
  description = "NixOS configuration for a lab.";

  nixConfig = {
    extra-substituters = [
      "https://cache.edwardh.dev"
    ];
    extra-trusted-public-keys = [
      "cache.edwardh.dev-1:+Gafa747BGilG7GAbTC/1i6HX9NUwzMbdFAc+v5VOPk="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs, nixpkgs-unstable, ... }@inputs:
    let
      # Packages in nixpkgs that I want to override.
      nixpkgs-overlay = (
        final: prev: {
          # Make pkgs.unstable.* point to nixpkgs unstable.
          unstable = import inputs.nixpkgs-unstable {
            system = final.system;
            config = {
              allowUnfree = true;
            };
          };

          google-chrome = prev.google-chrome.overrideAttrs (oldAttrs: {
            commandLineArgs = [ "--ozone-platform=wayland" "--disable-features=WaylandFractionalScaleV1" ];
          });
          gnome-keyring = prev.gnome-keyring.overrideAttrs (oldAttrs: { mesonFlags = (builtins.filter (flag: flag != "-Dssh-agent=true") oldAttrs.mesonFlags) ++ [ "-Dssh-agent=false" ]; });
          librespot = prev.librespot.override { withDNS-SD = true; };
          go-migrate = prev.go-migrate.overrideAttrs (oldAttrs: { tags = [ "postgres" ]; });
        }
      );

      # Configuration for nixpkgs.
      nixpkgs-config = {
        allowUnfree = true;
      };

      systemNames = [
        "dell-client-01"
      ];

      # An array of all the NixOS modules in ./modules.
      nixosModuleNames = map (name: inputs.nixpkgs.lib.removeSuffix ".nix" name) (builtins.attrNames (builtins.readDir ./modules));
      # An attribute set of all the NixOS modules in ./modules.
      nixosModules = inputs.nixpkgs.lib.genAttrs nixosModuleNames (module: ./modules/${module}.nix);

      # A mini-module that configures nixpkgs to use our custom overlay and configuration.
      useCustomNixpkgsNixosModule = {
        nixpkgs = {
          overlays = [ nixpkgs-overlay ];
          config = nixpkgs-config;
        };
      };

      # A function that returns for a given system's name:
      # - its NixOS configuration (nixosConfiguration)
      # - its system architecture (system)
      callSystem = (hostname: import ./systems/${hostname} {
        # Pass on the inputs and nixosModules.
        inherit inputs nixosModules hostname useCustomNixpkgsNixosModule;
      });
    in
    {
      inherit nixosModules;

      # Gets the NixOS configuration for every system in ./systems.
      nixosConfigurations = inputs.nixpkgs.lib.genAttrs systemNames (hostname: (callSystem hostname).nixosConfiguration);
    };
}
