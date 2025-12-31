{ config, lib, ... }:
let
  inherit (lib)
    filterAttrs
    mapAttrs
    mkEnableOption
    mkIf
    pipe
    ;
in
{
  options.topology.extractors.nix-minecraft.enable =
    mkEnableOption "topology nix-minecraft extractor"
    // {
      default = true;
    };

  config =
    let
      minecraft-servers = config.services.minecraft-servers or null;
    in
    mkIf
      (
        config.topology.extractors.nix-minecraft.enable
        && minecraft-servers != null
        && minecraft-servers.enable
        && minecraft-servers.eula
      )
      {
        topology.self.services.nix-minecraft = {
          name = "Minecraft";
          icon = "services.minecraft";
          details = pipe minecraft-servers.servers [
            (filterAttrs (_: s: s.enable && s.openFirewall))
            (mapAttrs (_: v: { text = "127.0.0.1:${toString v.serverProperties.server-port or 25565}"; }))
          ];
        };
      };
}
