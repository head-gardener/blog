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
      default = { };
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
}
