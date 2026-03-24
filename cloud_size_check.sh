#!/bin/sh
set -e

echo "======================================="
echo "  Supabase Cloud Size Report (No IPv6)"
echo "======================================="
echo ""

# Load secrets
. /config/migration.env

#######################################
# 1) Database Size (via SQL API)
#######################################

echo "🔍 Checking database size..."

DB_SIZE=$(curl -s \
  -H "apikey: $CLOUD_SERVICE_KEY" \
  -H "Authorization: Bearer $CLOUD_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query":"SELECT pg_size_pretty(pg_database_size(current_database())) AS size;"}' \
  "$CLOUD_PROJECT_URL/rest/v1/rpc/sql" \
  | jq -r '.[0].size'
)

echo "📦 Database size: $DB_SIZE"
echo ""

#######################################
# 2) Table Sizes (via SQL API)
#######################################

echo "🔍 Checking table sizes (top 20)..."

TABLE_SIZES=$(curl -s \
  -H "apikey: $CLOUD_SERVICE_KEY" \
  -H "Authorization: Bearer $CLOUD_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query":"SELECT relname AS table, pg_size_pretty(pg_total_relation_size(relid)) AS total FROM pg_catalog.pg_statio_user_tables ORDER BY pg_total_relation_size(relid) DESC LIMIT 20;"}' \
  "$CLOUD_PROJECT_URL/rest/v1/rpc/sql")

echo "$TABLE_SIZES" | jq . 
echo ""


#######################################
# 3) Storage Bucket List
#######################################

echo "🔍 Getting bucket list..."

BUCKETS=$(curl -s \
  -H "apikey: $CLOUD_SERVICE_KEY" \
  -H "Authorization: Bearer $CLOUD_SERVICE_KEY" \
  "$CLOUD_PROJECT_URL/storage/v1/bucket" | jq -r '.[].name')

echo "📦 Buckets:"
echo "$BUCKETS"
echo ""

#######################################
# 4) Storage bucket sizes
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

  BUCKET_BYTES=$(echo "$OBJECTS" | jq '[.[].metadata.size] | add')
  BUCKET_BYTES=${BUCKET_BYTES:-0}

  HUMAN=$(numfmt --to=iec $BUCKET_BYTES 2>/dev/null || echo "${BUCKET_BYTES}B")

  echo "   size: $HUMAN"
  TOTAL_BYTES=$((TOTAL_BYTES + BUCKET_BYTES))
done

echo ""
TOTAL_HUMAN=$(numfmt --to=iec $TOTAL_BYTES 2>/dev/null || echo "${TOTAL_BYTES}B")
echo "📦 Total storage size: $TOTAL_HUMAN"
echo ""

echo "======================================="
echo " SUMMARY"
echo " Database: $DB_SIZE"
echo " Storage : $TOTAL_HUMAN"
echo "======================================="