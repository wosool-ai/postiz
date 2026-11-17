# Postiz at monitoring.wosool.ai

Fork of gitroomhq/postiz-app (AGPL-3.0). Upstream code is untouched; Wosool adds only `deploy/wosool/`
and `.github/workflows/wosool-mirror-temporal.yml`. Upstream workflows are disabled in this fork.
Sync upstream: `git fetch upstream && git merge upstream/main` (no conflicts: our files are our own paths).

## Install (owner, on the box)
1. Temporal is already mirrored (run 44032007805, digest pinned in the compose). Re-run
   `wosool-mirror-temporal` only when upgrading Temporal.
2. On the box:
   ```
   git clone https://github.com/wosool-ai/postiz /opt/postiz-src
   bash /opt/postiz-src/deploy/wosool/install.sh      # writes .env secrets, pulls, starts, adds the edge site, probes
   ```
3. Open https://monitoring.wosool.ai, register the admin account, then set `DISABLE_REGISTRATION=true`
   in `/opt/postiz/.env` and `cd /opt/postiz && docker compose up -d`.

DNS: `monitoring.wosool.ai` already points at 77.42.70.107. Caddy issues the certificate on first request.
Note: `docker restart wosool-caddy` blips every host on the box for a few seconds.

## Social channels
Redirect URI in each developer console: `https://monitoring.wosool.ai/integrations/social/<provider>`
(`facebook`, `instagram`, `instagram-standalone`, `youtube`, `tiktok`, …). Put the keys in
`/opt/postiz/.env`, then `docker compose up -d`.
- Meta (Facebook/Instagram): Business app, Facebook Login for Business; IG must be Business/Creator.
- YouTube: Google Cloud project, YouTube Data API v3, OAuth client (Web).
- TikTok: Login Kit + Content Posting API; posts are private until TikTok's app audit passes.

## Claude Code (MCP)
Settings → Public API in Postiz gives the key/endpoint, then:
`claude mcp add --transport http postiz https://monitoring.wosool.ai/api/mcp-oauth-claude`

## Rollback / remove
`cd /opt/postiz && docker compose down` (add `-v` to delete data), `rm /opt/wosool-hub/sites/postiz.caddy`,
`docker restart wosool-caddy`.
