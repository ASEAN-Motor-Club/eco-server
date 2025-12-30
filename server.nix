{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
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
  steam-run = (pkgs.steam.override {extraPkgs = pkgs: [pkgs.openssl pkgs.libgdiplus];}).run;

  # Pre-compiled DLLs from mod.io - DiscordLink
  discordLinkMod = pkgs.fetchzip {
    url = "https://g-6.modapi.io/v1/games/6/mods/77/files/6844411/download";
    hash = "sha256-pGD25hIZvK2bfr+QxrjyEDcNpB+QehkTYIBKxk3D9eo=";
    extension = "zip";
    stripRoot = false;
  };

  # Pre-compiled DLLs from mod.io - MightyMooseCore (required dependency for DiscordLink)
  mightyMooseCore = pkgs.fetchzip {
    url = "https://g-6.modapi.io/v1/games/6/mods/3561559/files/6844389/download";
    hash = "sha256-jbwUJ3YkW9GZA2b3+lkD3VO/vMrYL7m40jWKP9VgDaw=";
    extension = "zip";
    stripRoot = false;
  };
in {
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

    nixpkgs.config.allowUnfreePredicate = lib.mkDefault (pkg:
      builtins.elem (lib.getName pkg) [
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
      members = [cfg.user "amc"];
      gid = 987;
    };

    systemd.sockets.eco-server = {
      description = "Command Input FIFO for Eco Server";
      wantedBy = ["sockets.target"];
      socketConfig = {
        ListenFIFO = "/run/eco-server/server.fifo";
        SocketUser = cfg.user;
        SocketGroup = "modders";
        SocketMode = "0660"; # Read/Write for User & Group
        DirectoryMode = "0770"; # Ensure parent directory is accessible by group
        RemoveOnStop = "true";
      };
    };

    systemd.services.eco-server = {
      wantedBy = ["multi-user.target"];
      after = ["network.target" "eco-server.socket"];
      requires = ["eco-server.socket"];
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
        StandardInput = "socket";
        StandardOutput = "journal";
        WorkingDirectory = "/var/lib/${cfg.stateDirectory}";
      };
      script = ''
        ${lib.getExe serverUpdateScript}
        # Remove potential staley symlink from previous attempts to avoid compilation errors
        rm -rf Mods/UserCode/DiscordLink

        # Copy Configs
        cp --no-preserve=mode,ownership ${./Configs}/*.eco ./Configs
        # Copy Config templates from mods (if any)
        cp -n ${mightyMooseCore}/Configs/*.template ./Configs/ 2>/dev/null || :
        cp -n ${discordLinkMod}/Configs/*.template ./Configs/ 2>/dev/null || :

        # Inject DiscordLink bot token from secret if provided
        ${lib.optionalString (cfg.discordlinkSecretFile != null) ''
          ${pkgs.jq}/bin/jq --arg token "$(cat ${cfg.discordlinkSecretFile})" \
            '.BotToken = $token' ./Configs/DiscordLink.eco > ./Configs/DiscordLink.eco.tmp
          mv ./Configs/DiscordLink.eco.tmp ./Configs/DiscordLink.eco
        ''}

        # Install MightyMoose mods (pre-compiled DLLs from mod.io)
        # Copy instead of symlink because Eco server needs write access to asset bundles (Permission Denied error)
        rm -rf Mods/MightyMoose
        mkdir -p Mods/MightyMoose
        cp -r --no-preserve=mode ${mightyMooseCore}/Mods/MightyMoose/* Mods/MightyMoose/
        cp -r --no-preserve=mode ${discordLinkMod}/Mods/MightyMoose/DiscordLink Mods/MightyMoose/DiscordLink

        # Install any additional user mods to UserCode
        mkdir -p Mods/UserCode
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: path: "ln -sfn ${path} Mods/UserCode/${name}") cfg.mods)}
        exec ${steam-run}/bin/steam-run ./EcoServer -userToken="$(cat ${cfg.credentialsFile})"
      '';
    };

    users.users.${cfg.user} = lib.mkDefault {
      isNormalUser = true;
      packages = [
        pkgs.steamcmd
      ];
    };

    services.eco-server-logger = {
      enable = cfg.enableLogStreaming;
      serverLogsPath = "/var/lib/${cfg.stateDirectory}/Logs/*.log";
      tag = "eco";
    };
  };
}
