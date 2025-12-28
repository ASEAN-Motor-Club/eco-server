{ lib, config, ... }:
with lib;
let
  cfg = config;
  backendOptions = {
    enable = mkEnableOption "eco server";
    enableLogStreaming = mkEnableOption "log streaming";
    logsTag = mkOption {
      type = types.str;
      default = "amc-eco";
    };
    postInstallScript = mkOption {
      type = types.str;
      default = "";
    };
    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open the require ports for the game server";
    };
    gameServerPort = mkOption {
      type = types.int;
      default = 3000;
    };
    webServerPort = mkOption {
      type = types.int;
      default = 3001;
    };
    user = mkOption {
      type = types.str;
      default = "steam";
      description = "The OS user that the process will run under";
    };
    stateDirectory = mkOption {
      type = types.str;
      default = "eco-server";
      description = "The path where the server will be installed (inside /var/lib)";
    };
    environment = mkOption {
      type = types.attrsOf types.str;
      description = "The runtime environment";
      default = {};
    };
    credentialsFile = mkOption {
      type = types.path;
      description = "A file containing the user token";
    };
    ownerName = mkOption {
      type = types.str;
      default = "owner";
      description = "The player name that will be passed as the owner of the server";
    };
    mods = mkOption {
      type = types.attrsOf types.path;
      default = {};
      description = "A set of mods to install into Mods/UserCode. Key is the directory name, value is the path to the mod source.";
    };
  };

in {
  options = backendOptions;
}
