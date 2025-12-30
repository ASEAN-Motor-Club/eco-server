# Eco Discord Integration Plan

## Overview

This document outlines the integration strategy between the Eco game server and Discord, using a hybrid approach that combines **EcoDiscordLink** for real-time features with **amc-backend** for custom business logic.

## Architecture Decision

**Approach: Hybrid Integration**

```
┌─────────────────────────────────────────────────────────────────┐
│                        Eco Game Server                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ Game :3000   │  │ Web API :3001│  │ RCON :3002   │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
         │                   │                   │
         ▼                   ▼                   ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  EcoDiscordLink │  │   amc-backend   │  │   amc-backend   │
│ (C# Server Mod) │  │ (Celery Tasks)  │  │ (Discord.py)    │
│                 │  │                 │  │                 │
│ • Chat Sync ←→  │  │ • Poll data     │  │ • /eco commands │
│ • Event Feeds   │  │ • Store in DB   │  │ • Custom logic  │
│ • Role Sync     │  │ • Analytics     │  │ • Integrations  │
└────────┬────────┘  └────────┬────────┘  └────────┬────────┘
         │                    │                    │
         └────────────────────┴────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │     Discord     │
                    └─────────────────┘
```

## Component Responsibilities

### EcoDiscordLink (C# Mod)
Handles real-time, event-driven features:

| Feature | Direction | Notes |
|---------|-----------|-------|
| Chat Sync | Eco ↔ Discord | Bidirectional, immediate |
| Trade Notifications | Eco → Discord | Instant trade events |
| Player Join/Leave | Eco → Discord | Immediate status updates |
| Election Events | Eco → Discord | Vote/election changes |
| Role Sync | Eco → Discord | Demographics, specialties |
| Account Linking | Both | Built-in verification flow |

### amc-backend (Django + discord.py)
Handles custom business logic and data persistence:

| Feature | Purpose |
|---------|---------|
| Eco Data Polling | Periodic sync of players, elections, currencies |
| Database Persistence | Store Eco data in PostgreSQL for analytics |
| Custom Discord Commands | `/eco status`, `/eco trades`, `/eco players` |
| Cross-Game Integration | Link Eco data with Necesse, Radio systems |
| Analytics & Leaderboards | Player stats, economy reports |
| Custom Business Logic | Jobs, subsidies, ministry integration |

---

## Implementation Phases

### Phase 1: EcoDiscordLink Setup
**Status:** Not Started

- [ ] Install EcoDiscordLink mod on Eco server
- [ ] Configure bot token and Discord server ID
- [ ] Set up chat channel links (General, Trade, etc.)
- [ ] Configure role sync for demographics/specialties
- [ ] Test bidirectional chat sync

### Phase 2: Eco API Client (amc-backend)
**Status:** Not Started

- [ ] Create `eco` Django app in amc-backend
- [ ] Implement `EcoAPIClient` service class
- [ ] Add Celery tasks for periodic data polling
- [ ] Create models for persisting Eco data
- [ ] Add API endpoints for frontend access

### Phase 3: Discord Commands
**Status:** Not Started

- [ ] Create `eco` cog in amc-backend
- [ ] Implement `/eco status` command
- [ ] Implement `/eco players` command  
- [ ] Implement `/eco elections` command
- [ ] Implement `/eco trades` command

### Phase 4: Cross-Game Integration
**Status:** Not Started

- [ ] Link Eco players with existing Player model
- [ ] Add Eco data to player profiles
- [ ] Create combined leaderboards
- [ ] Add Eco events to activity feeds

---

## EcoDiscordLink Configuration

### Required Discord Bot Setup

1. Create bot at https://discord.com/developers/applications
2. Enable intents: `Server Members`, `Message Content`
3. Required permissions: `268659776`
4. Invite bot to Discord server

### DiscordLink.eco Config Template

```json
{
  "BotToken": "<YOUR_BOT_TOKEN>",
  "DiscordServerId": "<YOUR_SERVER_ID>",
  "ChatChannelLinks": [
    {
      "DiscordChannelId": "<CHANNEL_ID>",
      "EcoChannel": "General",
      "Direction": "Duplex",
      "UseTimestamp": true
    }
  ],
  "ServerInfoDisplayChannels": [
    {
      "DiscordChannelId": "<STATUS_CHANNEL_ID>",
      "UseName": true,
      "UsePlayerCount": true,
      "UsePlayerList": true,
      "UseIngameTime": true
    }
  ],
  "PlayerStatusFeedChannels": [
    {
      "DiscordChannelId": "<FEED_CHANNEL_ID>"
    }
  ],
  "TradeFeedChannels": [
    {
      "DiscordChannelId": "<TRADE_CHANNEL_ID>"
    }
  ],
  "UseLinkedAccountRole": true,
  "UseDemographicRoles": true,
  "UseSpecialtyRoles": true
}
```

---

## amc-backend Integration

### New Files to Create

```
src/
├── eco/                          # New Django app
│   ├── __init__.py
│   ├── apps.py
│   ├── models.py                 # EcoPlayer, EcoElection, etc.
│   ├── services.py               # EcoAPIClient
│   ├── tasks.py                  # Celery polling tasks
│   └── tests.py
├── amc_cogs/
│   └── eco.py                    # New Discord cog
```

### Environment Variables

```bash
# Add to .env
ECO_SERVER_URL=http://eco-server:3001
ECO_API_KEY=<your_api_key>
ECO_RCON_HOST=eco-server
ECO_RCON_PORT=3002
ECO_RCON_PASSWORD=<your_rcon_password>
```

### API Endpoints Available

| Endpoint | Data |
|----------|------|
| `GET /api/v1/info` | Server status, version |
| `GET /api/v1/users` | Player list, online status |
| `GET /api/v1/elections` | Active elections |
| `GET /api/v1/laws` | Current laws |
| `GET /api/v1/currencies` | Currency info |
| `GET /api/v1/stores` | Trade listings |
| `GET /api/v1/map` | World map image |

---

## Data Models (Planned)

```python
# eco/models.py

class EcoPlayer(models.Model):
    """Links Eco player to Django Player model"""
    player = models.OneToOneField('amc.Player', on_delete=models.CASCADE)
    eco_steam_id = models.CharField(max_length=50, unique=True)
    eco_username = models.CharField(max_length=100)
    specialties = models.JSONField(default=list)
    demographics = models.JSONField(default=list)
    last_seen = models.DateTimeField(null=True)
    last_synced = models.DateTimeField(auto_now=True)

class EcoElection(models.Model):
    """Cached election data"""
    eco_id = models.CharField(max_length=100, unique=True)
    name = models.CharField(max_length=200)
    state = models.CharField(max_length=50)
    candidates = models.JSONField(default=list)
    votes = models.JSONField(default=dict)
    created_at = models.DateTimeField()
    ends_at = models.DateTimeField(null=True)
    last_synced = models.DateTimeField(auto_now=True)

class EcoServerSnapshot(models.Model):
    """Periodic server status snapshots"""
    timestamp = models.DateTimeField(auto_now_add=True)
    players_online = models.IntegerField()
    player_list = models.JSONField(default=list)
    server_time = models.CharField(max_length=50)
    meteor_time = models.CharField(max_length=50, null=True)
```

---

## Discord Commands (Planned)

| Command | Description |
|---------|-------------|
| `/eco status` | Show server status, players online |
| `/eco players` | List online players |
| `/eco elections` | Show active elections |
| `/eco trades [item]` | Search trade listings |
| `/eco link` | Link Discord account to Eco player |

---

## Next Steps

1. **Review this plan** and confirm the approach
2. **Set up EcoDiscordLink** on the Eco server (Phase 1)
3. **Implement API client** in amc-backend (Phase 2)
4. **Add Discord commands** (Phase 3)

---

## References

- [EcoDiscordLink GitHub](https://github.com/Eco-DiscordLink/EcoDiscordPlugin)
- [Eco ModKit Documentation](https://docs.play.eco)
- [Eco Server Wiki](https://wiki.play.eco/en/Server_Configuration)
