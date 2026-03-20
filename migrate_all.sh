#!/usr/bin/env bash
set -e

echo "=============================="
echo " SUPABASE MIGRATION MANAGER"
echo "=============================="

# Load secrets
source /config/migration.env

# --- Supabase CLI wrapper (via Docker) -------------------
supabase() {
  docker run --rm \
    -v /tmp:/tmp \
    -v /config:/config \
    -v /var/run/docker.sock:/var/run/docker.sock \
    supabase/cli:latest "$@"
}

########################################
# DATABASE MIGRATION
########################################

echo "🔄 Dumping roles..."
supabase db dump --db-url "$CLOUD_DB_URL" -f /tmp/roles.sql --role-only

echo "🔄 Dumping schema..."
supabase db dump --db-url "$CLOUD_DB_URL" -f /tmp/schema.sql

echo "🔄 Dumping data..."
supabase db dump --db-url "$CLOUD_DB_URL" -f /tmp/data.sql --use-copy --data-only

echo "📦 Restoring into local Postgres..."
psql "$SELF_HOSTED_DB_URL" -v ON_ERROR_STOP=1 -f /tmp/roles.sql
psql "$SELF_HOSTED_DB_URL" -v ON_ERROR_STOP=1 -f /tmp/schema.sql
psql "$SELF_HOSTED_DB_URL" -v ON_ERROR_STOP=1 \
  -c "SET session_replication_role = replica" \
  -f /tmp/data.sql

########################################
# STORAGE BUCKET MIGRATION
########################################

echo "📦 Exporting buckets from Cloud..."
mkdir -p /tmp/bucket_export

BUCKETS=$(curl -s \
  -H "Authorization: Bearer $CLOUD_SERVICE_KEY" \
  -H "apikey: $CLOUD_SERVICE_KEY" \
  "$CLOUD_PROJECT_URL/storage/v1/bucket")

echo "$BUCKETS" | jq -r '.[].name' | while read BUCKET; do
  echo "➡️ Bucket: $BUCKET"
  mkdir -p "/tmp/bucket_export/$BUCKET"

  OBJECTS=$(curl -s -X POST \
      -H "Authorization: Bearer $CLOUD_SERVICE_KEY" \
      -H "apikey: $CLOUD_SERVICE_KEY" \
      -H "Content-Type: application/json" \
      -d '{"prefix":""}' \
      "$CLOUD_PROJECT_URL/storage/v1/object/list/$BUCKET")

  echo "$OBJECTS" | jq -r '.[]?.name' | while read NAME; do
    echo "⬇️ $NAME"
    mkdir -p "/tmp/bucket_export/$BUCKET/$(dirname "$NAME")"
    curl -s \
      -H "Authorization: Bearer $CLOUD_SERVICE_KEY" \
      -H "apikey: $CLOUD_SERVICE_KEY" \
      -o "/tmp/bucket_export/$BUCKET/$NAME" \
      "$CLOUD_PROJECT_URL/storage/v1/object/$BUCKET/$NAME"
  done
done

echo "🚀 Uploading buckets to local storage..."
for BUCKET in $(ls /tmp/bucket_export); do

  curl -s -X POST \
    -H "Authorization: Bearer $SELF_SERVICE_KEY" \
    -H "apikey: $SELF_SERVICE_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"$BUCKET\"}" \
    "$SELF_URL/storage/v1/bucket" >/dev/null || true

  find "/tmp/bucket_export/$BUCKET" -type f | while read FILE_PATH; do
    REL_PATH="${FILE_PATH#"/tmp/bucket_export/$BUCKET/"}"
    echo "⬆️ $REL_PATH"
    curl -s -X POST \
      -H "Authorization: Bearer $SELF_SERVICE_KEY" \
      -H "apikey: $SELF_SERVICE_KEY" \
      -F "file=@${FILE_PATH}" \
      "$SELF_URL/storage/v1/object/$BUCKET/$REL_PATH" >/dev/null
  done
done

echo "🎉 Migration completed!"