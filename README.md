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

## Proposing New Mods

Community members can propose new mods to be added to the server. Mods are sourced from [mod.io/g/eco](https://mod.io/g/eco).

### How Mods Are Installed

When approved, mods are automatically extracted to `Mods/UserCode/` during server startup. The Nix configuration handles downloading and placing the mod files—no manual folder copying is needed.

### How to Propose a Mod

1. **Find the mod** on [mod.io/g/eco](https://mod.io/g/eco)

2. **Create a Pull Request** adding the mod to `flake.nix` using this format:
   ```nix
   mods = {
     "ModFolderName" = pkgs.fetchzip {
       url = "https://mod.io/download/...";  # Direct download URL from mod.io
       hash = "";  # Leave empty - CI will calculate this
     };
   };
   ```

3. **Submit the PR** with:
   - Mod name and link to its mod.io page
   - Brief description of what the mod adds
   - Leave the `hash` field empty (see below)

### About the Hash Field

Nix requires a hash for reproducible builds. Since calculating hashes requires Nix tooling, we've automated this:

> [!TIP]
> **You don't need to calculate the hash yourself!**
>
> When you submit a PR with an empty `hash = ""`:
> 1. GitHub Actions will attempt to build
> 2. The CI will fail and output the correct hash
> 3. A maintainer will update the PR with the correct hash, or
> 4. You can copy the hash from the CI logs and update your PR

#### For Contributors with Nix Installed

If you have Nix installed locally, you can pre-calculate the hash:
```bash
nix-prefetch-url --unpack "https://mod.io/download/..."
```

### PR Template Example

```markdown
## Mod Proposal: [Mod Name]

**Mod.io Link:** https://mod.io/g/eco/m/[mod-name]
**Download URL:** https://mod.io/download/...

### Description
Brief description of what this mod adds to the server.

### Why Add This Mod?
Explain how it benefits the community.
```

## Development

Enter the dev shell for development tools:

```bash
nix develop
```
