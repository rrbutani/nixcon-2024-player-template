{
  description = "NixCon 2024 - NixOS on garnix: Production-grade hosting as a game";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  inputs.garnix-lib = {
    url = "github:garnix-io/garnix-lib";
    inputs = {
      nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, garnix-lib, flake-utils }:
    let
      system = "x86_64-linux";
      np = nixpkgs.legacyPackages.${system};
    in
    (flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let pkgs = import nixpkgs { inherit system; };
      in rec {
        packages = {
          webserver = np.rustPlatform.buildRustPackage {
            name = "garnix-game";
            src = ./.;
            cargoLock.lockFile = ./Cargo.lock;

            buildInputs = [ np.cowsay ];
            COWSAY = np.lib.getExe np.cowsay;
          };
          default = packages.webserver;
        };
        apps.default = {
          type = "app";
          program = pkgs.lib.getExe (
            pkgs.writeShellApplication {
              name = "start-webserver";
              runtimeEnv = {
                PORT = "8080";
              };
              text = ''
                ${pkgs.lib.getExe packages.webserver}
              '';
            }
          );
        };

        devShells.default = np.mkShell {
          inputsFrom = [ self.packages.${system}.default ];
          nativeBuildInputs = with np; [ rust-analyzer cargo rustc ];
          COWSAY = np.lib.getExe np.cowsay;
          PORT = "8080";
        };
      }))
    //
    {
      nixosConfigurations.server = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          garnix-lib.nixosModules.garnix
          self.nixosModules.nixcon-garnix-player-module
          ({ pkgs, ... }: {
            playerConfig = {
              # Your github user:
              githubLogin = "rrbutani";
              # You only need to change this if you changed the forked repo name.
              githubRepo = "nixcon-2024-player-template";
              # The nix derivation that will be used as the server process. It
              # should open a webserver on port 8080.
              # The port is also provided to the process as the environment variable "PORT".
              webserver = self.packages.${system}.webserver;
              # If you want to log in to your deployed server, put your SSH key
              # here:
              sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMHLIww+c/ZszUrnZXn8EEdUFLRr0icq/TJarihnLdMh";
            };
          })
        ];
      };

      nixosModules.nixcon-garnix-player-module = ./nixcon-garnix-player-module.nix;
      nixosModules.default = self.nixosModules.nixcon-garnix-player-module;

      # Remove before starting the workshop - this is just for development
      checks = import ./checks.nix { inherit nixpkgs self; };
    };
}
