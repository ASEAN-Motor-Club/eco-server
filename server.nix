{ lib, pkgs, config, ...}:
with lib;
let
  cfg = config.services.eco-server;

  # Game Settings
  gameAppId = "739590"; # Steam App ID

  serverUpdateScript = pkgs.writeScriptBin "eco-update" ''
    set -xeu

    ${pkgs.steamcmd}/bin/steamcmd \
      +force_install_dir $STATE_DIRECTORY \
      +login anonymous \
      +app_update ${gameAppId} validate \
      +quit
  '';
  steam-run = (pkgs.steam.override {extraPkgs = pkgs: [ pkgs.openssl pkgs.libgdiplus ]; }).run;
in
{
  imports = [
    ./logger.nix
  ];
  options.services.eco-server = mkOption {
    type = types.submodule (import ./backend-options.nix);
  };

  config = mkIf cfg.enable {
    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [cfg.webServerPort];
      allowedUDPPorts = [cfg.gameServerPort];
    };

    nixpkgs.config.allowUnfreePredicate = lib.mkDefault (pkg: builtins.elem (lib.getName pkg) [
      "steam"
      "steamcmd"
      "steam-original"
      "steam-unwrapped"
      "steam-run"
      "motortown-server"
      "steamworks-sdk-redist"
    ]);

    programs.steam = {
      enable = lib.mkDefault true;
      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];
      protontricks.enable = lib.mkDefault true;
    };

    users.groups.modders = {
      members = [ cfg.user "amc" ];
      gid = 987;
    };

    systemd.sockets.eco-server = {
      description = "Command Input FIFO for Eco Server";
      wantedBy = [ "sockets.target" ];
      socketConfig = {
        ListenFIFO = "/run/eco-server/server.fifo";
        SocketUser = cfg.user;
        SocketGroup = "modders";
        SocketMode = "0660";     # Read/Write for User & Group
        DirectoryMode = "0770";  # Ensure parent directory is accessible by group
        RemoveOnStop = "true";
      };
    };

    systemd.services.eco-server = {
      wantedBy = [ "multi-user.target" ]; 
      after = [ "network.target" "eco-server.socket" ];
      requires = [ "eco-server.socket" ];
      description = "Eco Dedicated Server";
      environment = cfg.environment;
      restartIfChanged = false;
      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = "modders";
        # EnvironmentFile = lib.mkIf (cfg.credentialsFile != null) cfg.credentialsFile;
        StateDirectory = cfg.stateDirectory;
        StateDirectoryMode = "770";
        StandardInput="socket";
        StandardOutput="journal";
        WorkingDirectory = "/var/lib/${cfg.stateDirectory}";
      };
      script=''
        ${lib.getExe serverUpdateScript}
        cp --no-preserve=mode,ownership ${./Configs}/*.eco ./Configs
        exec ${steam-run}/bin/steam-run ./EcoServer -userToken="$(cat ${cfg.credentialsFile})"
      '';
    };

    users.users.${cfg.user} = lib.mkDefault {
      isNormalUser = true;
      packages = [
        pkgs.steamcmd
        mods.installModsScriptBin
      ];
    };

    services.eco-server-logger = {
      enable = cfg.enableLogStreaming;
      serverLogsPath = "/var/lib/${cfg.stateDirectory}/Logs/*.log";
      tag = "eco";
    };
  };
}
