# Eco Dedicated Server - NixOS Flake

A NixOS flake for deploying an [Eco](https://play.eco) dedicated game server. Eco is a collaborative survival game where players must work together to build a civilization while balancing the ecosystem.

## Features

- **SteamCMD integration**: Automatically downloads and updates the Eco server via Steam
- **Systemd service**: Runs as a managed systemd service with socket activation for FIFO command input
- **Log streaming**: Optional rsyslog-based log streaming to centralized logging
- **Firewall management**: Automatic firewall rule configuration via `openFirewall` option

## Usage

### Adding to your NixOS configuration

```nix
{
  inputs.eco-server.url = "github:your-org/eco-server";

  outputs = { self, nixpkgs, eco-server, ... }: {
    nixosConfigurations.myserver = nixpkgs.lib.nixosSystem {
      modules = [
        eco-server.nixosModules.default
        {
          services.eco-server = {
            enable = true;
            openFirewall = true;
            credentialsFile = /path/to/user-token;
            # See backend-options.nix for all available options
          };
        }
      ];
    };
  };
}
```

### Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `enable` | `false` | Enable the Eco server |
| `openFirewall` | `false` | Open required firewall ports |
| `gameServerPort` | `3000` | UDP port for game traffic |
| `webServerPort` | `3001` | TCP port for web interface |
| `user` | `steam` | OS user to run the server as |
| `stateDirectory` | `eco-server` | Directory under `/var/lib` for server files |
| `credentialsFile` | - | Path to file containing your Eco user token |
| `enableLogStreaming` | `false` | Enable rsyslog-based log forwarding |

## Submitting Server Config Changes

Game configuration is managed via files in the `Configs/` directory:

1. Copy the template file to a new file (if it doesn't exist):
   ```bash
   cp Configs/Sleep.eco.template Configs/Sleep.eco
   ```

2. Edit the config file with your desired settings

3. Submit a Pull Request

### Key Configuration Files

| File | Purpose |
|------|---------|
| `Network.eco` | Server name, description, ports, max players (`MaxConnections`) |
| `Difficulty.eco` | Game difficulty settings |
| `Users.eco` | Admin list, whitelist, blacklist |
| `WorldGenerator.eco` | World generation parameters |

For detailed configuration options, see the [Eco Server Configuration Wiki](https://wiki.play.eco/en/Server_Configuration).

## Server Management

### Sending commands

The server listens on a FIFO socket at `/run/eco-server/server.fifo`. Send commands via:

```bash
echo "/help" > /run/eco-server/server.fifo
```

### Viewing logs

```bash
journalctl -u eco-server -f
```

## Development

Enter the dev shell for development tools:

```bash
nix develop
```
