#!/bin/sh
set -e

echo "======================================="
echo " Supabase Cloud Size Report (IPv4 Safe)"
echo "======================================="
echo ""

. /config/migration.env

HDR="-H apikey: $CLOUD_SERVICE_KEY -H Authorization: Bearer $CLOUD_SERVICE_KEY -H Content-Type: application/json"

#############################################
# DATABASE SIZE (via supported SQL passthrough)
#############################################

echo "🔍 Fetching database size..."

DB=$(curl -s $HDR \
  -d '{"query":"SELECT pg_database_size(current_database()) AS size"}' \
  "$CLOUD_PROJECT_URL/rest/v1/rpc/pass_through")

DB_SIZE=$(echo "$DB" | jq -r '.[0].size // 0')
DB_HUMAN=$(numfmt --to=iec $DB_SIZE 2>/dev/null)

echo "📦 Database size: $DB_HUMAN"
echo ""

#############################################
# STORAGE BUCKET LIST
#############################################

echo "🔍 Fetching buckets..."

BUCKETS=$(curl -s \
  -H "apikey: $CLOUD_SERVICE_KEY" \
  -H "Authorization: Bearer $CLOUD_SERVICE_KEY" \
  "$CLOUD_PROJECT_URL/storage/v1/bucket" | jq -r '.[].name')

echo "📦 Buckets:"
echo "$BUCKETS"
echo ""

#############################################
# STORAGE SIZE (safe parsing)
#############################################

TOTAL=0
echo "🔍 Calculating storage usage..."

for B in $BUCKETS; do
  echo "➡ $B"

  RAW=$(curl -s \
    -H "apikey: $CLOUD_SERVICE_KEY" \
    -H "Authorization: Bearer $CLOUD_SERVICE_KEY" \
    -H "Content-Type: application/json" \
    -d '{"prefix":""}' \
    "$CLOUD_PROJECT_URL/storage/v1/object/list/$B")

  # Če je string (prazno "{}"), vrni 0
  if echo "$RAW" | jq -e 'type=="array"' >/dev/null 2>&1; then
      BYTES=$(echo "$RAW" | jq '[.[].metadata.size // 0] | add')
  else
      BYTES=0
  fi

  HUMAN=$(numfmt --to=iec $BYTES 2>/dev/null)
  echo "   size: $HUMAN"

  TOTAL=$((TOTAL + BYTES))
done

TOTAL_HUMAN=$(numfmt --to=iec $TOTAL)

echo ""
echo "📦 Total Storage: $TOTAL_HUMAN"
echo ""

echo "======================================="
echo " SUMMARY"
echo " Database: $DB_HUMAN"
echo " Storage : $TOTAL_HUMAN"
echo "======================================="