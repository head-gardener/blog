{
  description = "Cool blog? Cool blog";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      version = "0.1.${nixpkgs.lib.substring 0 8 self.lastModifiedDate}.${self.shortRev or "dirty"}";
    in
    {
      overlays.default = import ./overlay.nix version;

      nixosModules.default = self.nixosModules.blog;
      nixosModules.blog = import ./module.nix;
    } // flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs {
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
