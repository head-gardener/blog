{
  description = "Cool blog? Cool blog";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "i686-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems f;
      version = "0.1.${nixpkgs.lib.substring 0 8 self.lastModifiedDate}.${self.shortRev or "dirty"}";
      nixpkgsFor = forAllSystems
        (system: import nixpkgs { inherit system; overlays = nixpkgs.lib.attrsets.attrValues self.overlays; });
    in
    rec {

      overlays.default = final: prev: rec {
        emacs-render = final.emacs-nox;

        favicon_ico = final.stdenvNoCC.mkDerivation {
          pname = "favicon-ico";
          version = "01072024";

          src = ./static;

          buildPhase = ''
            ${final.imagemagick}/bin/convert -resize 16x16 ./favicon.png ./16x16.png
            ${final.imagemagick}/bin/convert -resize 32x32 ./favicon.png ./32x32.png
            ${final.imagemagick}/bin/convert -resize 48x48 ./favicon.png ./48x48.png
            ${final.imagemagick}/bin/convert 16x16.png 32x32.png 48x48.png favicon.ico
          '';

          installPhase = ''
            cp favicon.ico $out
          '';
        };

        robots_txt = final.writeText "robots.txt" ''
          User-agent: *
          Disallow:
        '';

        blog-render = with final; (stdenvNoCC.mkDerivation {
          pname = "org-render";
          inherit version;

          src = ./org;

          buildPhase = ''
            export HOME=$(pwd)
            ${emacs-render}/bin/emacs -batch --load ${./publish-doc.el} --eval '(org-publish "org")'
          '';

          installPhase = ''
            cp build $out -rv
            cp ${favicon_ico} $out/favicon.ico -v
            cp ${robots_txt} $out/robots.txt -v
          '';
        });
      };

      packages = forAllSystems (system:
        {
          inherit (nixpkgsFor.${system}) blog-render;
        });

      nixosModules.default = nixosModules.blog;
      nixosModules.test = { pkgs, ... }: { };
      nixosModules.blog =
        { pkgs, ... }:
        {
          nixpkgs.overlays = [ self.overlays.default ];

          services.nginx = {
            enable = true;
            commonHttpConfig = "limit_req_zone $binary_remote_addr zone=common:10m rate=10r/s;";
            virtualHosts = {
              "flake-test" = {
                # enableACME = true;
                # forceSSL = true;
                extraConfig = "limit_req zone=common;";
                locations = {
                  "/" = {
                    root = "${pkgs.blog-render}/";
                  };
                };
              };
            };
          };

        };

    };
}
