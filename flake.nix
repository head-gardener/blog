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

        styles_css = final.writeText "styles.css" ''
          ${builtins.readFile ./static/styles.css}
        '';

        blog-render = with final; (stdenvNoCC.mkDerivation rec {
          pname = "org-render";
          inherit version;

          src = ./org;

          publish-doc = final.writeText "publish-doc.el" ''
            (setq blog-rev "${toString (self.lastModifiedDate)}")
            ${builtins.readFile ./publish-doc.el}
          '';

          buildPhase = ''
            export HOME=$(pwd)
            ${emacs-render}/bin/emacs -batch --load ${publish-doc} --eval '(org-publish "org")'
          '';

          installPhase = ''
            cp build $out -rv
            mkdir $out/static
            cp ${favicon_ico} $out/favicon.ico -v
            cp ${robots_txt} $out/robots.txt -v
            cp ${styles_css} $out/static/styles.css -v
          '';
        });
      };

      packages = forAllSystems (system:
        {
          inherit (nixpkgsFor.${system}) blog-render;
        });

      nixosModules.default = nixosModules.blog;
      nixosModules.blog =
        { lib, pkgs, config, ... }:
          with lib;
          let
            cfg = config.services.blog;
          in
          {
            options.services.blog = {
              enable = mkEnableOption "blog server";
              host = mkOption {
                type = types.str;
                default = "default";
              };
              vhostConfig = mkOption {
                type = types.attrs;
                default = {};
              };
            };

            config = mkIf cfg.enable {
              nixpkgs.overlays = [ self.overlays.default ];

              services.nginx.virtualHosts.${cfg.host} = {
                locations = {
                  "/" = {
                    root = "${pkgs.blog-render}/";
                  };
                };
              } // cfg.vhostConfig;
            };

          };

    };
}
