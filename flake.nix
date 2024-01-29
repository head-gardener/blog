{
  description = "Cool blog? Cool blog";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      version = "0.1.${nixpkgs.lib.substring 0 8 self.lastModifiedDate}.${self.shortRev or "dirty"}";
      nixpkgsFor = system:
        import nixpkgs {
          inherit system;
          overlays = nixpkgs.lib.attrsets.attrValues self.overlays;
        };
    in
    {
      overlays.default = import ./overlay.nix version;

      nixosModules.default = self.nixosModules.blog;
      nixosModules.blog = import ./module.nix;
    } // flake-utils.lib.eachDefaultSystem (system: {
      packages = {
        inherit (nixpkgsFor system) blog-render;
      };
    });
}
