#!/usr/bin/env bash
# Run ON THE BOX as root, from a checkout of github.com/wosool-ai/postiz:
#   git clone https://github.com/wosool-ai/postiz /opt/postiz-src && bash /opt/postiz-src/deploy/wosool/install.sh
# Idempotent: re-running keeps existing secrets and data.
set -euo pipefail
SRC="$(cd "$(dirname "$0")" && pwd)"
DST=/opt/postiz
SITES=/opt/wosool-hub/sites

docker network inspect wosool-hub_wosool-network >/dev/null   # the shared edge must exist
mkdir -p "$DST" && chmod 700 "$DST"
install -m 644 "$SRC/docker-compose.yml" "$DST/docker-compose.yml"

if [ ! -f "$DST/.env" ]; then
  sed -e "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$(openssl rand -hex 24)|" \
      -e "s|^JWT_SECRET=.*|JWT_SECRET=$(openssl rand -hex 48)|" \
      "$SRC/env.template" > "$DST/.env"
  chmod 600 "$DST/.env"
  echo "wrote $DST/.env (secrets generated)"
fi
grep -q '^TEMPORAL_DIGEST=sha256:' "$DST/.env" || {
  echo "STOP: set TEMPORAL_DIGEST=sha256:... in $DST/.env (from the mirror workflow run), then re-run."; exit 1; }

cd "$DST"
docker compose config -q
docker compose pull
docker compose up -d

# Edge: validate with the running Caddy's own binary before restarting it (all hosts blip on restart).
install -m 644 "$SRC/postiz.caddy" "$SITES/postiz.caddy"
docker exec wosool-caddy caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
docker restart wosool-caddy

echo "waiting for postiz..."
for i in $(seq 1 60); do
  code=$(curl -s -o /dev/null -w '%{http_code}' https://monitoring.wosool.ai/ || true)
  [ "$code" = 200 ] || [ "$code" = 307 ] || [ "$code" = 302 ] && break; sleep 5
done
echo "monitoring.wosool.ai -> HTTP $code"
# Positive control: the API answers (401/403 without a session is the expected, live answer).
echo "api -> HTTP $(curl -s -o /dev/null -w '%{http_code}' https://monitoring.wosool.ai/api/user/self)"
docker compose ps
docker inspect --format '{{.Name}} {{.Image}}' postiz postiz-postgres postiz-redis postiz-temporal
