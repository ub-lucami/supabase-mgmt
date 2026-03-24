#!/bin/sh
set -e

echo "======================================="
echo "  Supabase Cloud Size Report (No IPv6)"
echo "======================================="
echo ""

. /config/migration.env

#######################################
# 1) DATABASE SIZE via PostgREST
#######################################

echo "🔍 Fetching database size..."

DB_QUERY='SELECT pg_size_pretty(pg_database_size(current_database())) AS size'

DB_RESPONSE=$(curl -s \
  -H "apikey: $CLOUD_SERVICE_KEY" \
  -H "Authorization: Bearer $CLOUD_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  --data "{\"query\":\"$DB_QUERY\"}" \
  "$CLOUD_PROJECT_URL/rest/v1/rpc/sql")

DB_SIZE=$(echo "$DB_RESPONSE" | jq -r '.[0].size // empty')

echo "📦 Database size: ${DB_SIZE:-Unknown}"
echo ""

#######################################
# 2) STORAGE BUCKETS
#######################################

echo "🔍 Fetching bucket list..."

BUCKETS=$(curl -s \
  -H "apikey: $CLOUD_SERVICE_KEY" \
  -H "Authorization: Bearer $CLOUD_SERVICE_KEY" \
  "$CLOUD_PROJECT_URL/storage/v1/bucket" \
  | jq -r '.[].name')

echo "📦 Buckets:"
echo "$BUCKETS"
echo ""

#######################################
# 3) STORAGE SIZES
#######################################

TOTAL_BYTES=0

echo "🔍 Calculating storage usage..."

for BUCKET in $BUCKETS; do
  echo "➡️ Bucket: $BUCKET"

  OBJECTS=$(curl -s -X POST \
    -H "apikey: $CLOUD_SERVICE_KEY" \
    -H "Authorization: Bearer $CLOUD_SERVICE_KEY" \
    -H "Content-Type: application/json" \
    -d '{"prefix":""}' \
    "$CLOUD_PROJECT_URL/storage/v1/object/list/$BUCKET")

  # Sum sizes correctly (handles missing .metadata.size safely)
  BUCKET_BYTES=$(echo "$OBJECTS" | jq '[.[].metadata.size // 0] | add')

  HUMAN=$(numfmt --to=iec $BUCKET_BYTES 2>/dev/null || echo "${BUCKET_BYTES}B")

  echo "   size: $HUMAN"

  TOTAL_BYTES=$((TOTAL_BYTES + BUCKET_BYTES))
done

TOTAL_HUMAN=$(numfmt --to=iec $TOTAL_BYTES)

echo ""
echo "📦 Total storage size: $TOTAL_HUMAN"
echo ""

#######################################
# SUMMARY
#######################################

echo "======================================="
echo " SUMMARY"
echo " Database: ${DB_SIZE:-Unknown}"
echo " Storage : $TOTAL_HUMAN"
echo "======================================="