{
  description = "Cool blog? Cool blog";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }@inputs:
    let
      version = "0.1.${nixpkgs.lib.substring 0 8 self.lastModifiedDate}.${self.shortRev or "dirty"}";
    in
    {
      overlays.default = import ./overlay.nix version;

      nixosModules.default = self.nixosModules.blog;
      nixosModules.blog = import ./module.nix inputs;

      checks."x86_64-linux" = {
        inherit (self.hydraJobs."x86_64-linux") build;
      };

      hydraJobs."x86_64-linux" = {
        build = self.packages.x86_64-linux.blog-render;
        test = nixpkgs.lib.nixos.runTest {
          name = "blog";

          nodes = {
            server = { ... }: {
              imports = [ self.nixosModules.blog ];
              services.blog = {
                enable = true;
                host = "localhost";
              };
              services.nginx.enable = true;
            };
          };

          hostPkgs = nixpkgs.legacyPackages."x86_64-linux";

          testScript = ''
            start_all()
            server.wait_for_unit("multi-user.target")
            server.succeed("curl localhost")
          '';
        };
      };
    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = nixpkgs.lib.attrsets.attrValues self.overlays;
        };
      in
      {
        packages = {
          inherit (pkgs) blog-render;
        };

        devShells.default = pkgs.mkShell {
          packages = [
            (pkgs.writeScriptBin "serve"
              "${pkgs.python3}/bin/python3 -m http.server 8000 -d result/")
          ];
        };
      });
}
