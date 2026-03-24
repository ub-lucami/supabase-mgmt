#!/bin/sh
set -e

echo "======================================="
echo "  Supabase Cloud Size Report (No IPv6)"
echo "======================================="
echo ""

. /config/migration.env

HEADER="-H apikey: $CLOUD_SERVICE_KEY -H Authorization: Bearer $CLOUD_SERVICE_KEY"

#######################################
# DATABASE SIZE
#######################################

echo "🔍 Fetching database size..."

DB=$(curl -s \
  -H "apikey: $CLOUD_SERVICE_KEY" \
  -H "Authorization: Bearer $CLOUD_SERVICE_KEY" \
  "$CLOUD_PROJECT_URL/platform/usage/db_size")

DB_SIZE=$(echo "$DB" | jq -r '.db_size' 2>/dev/null)

echo "📦 Database size: $(numfmt --to=iec $DB_SIZE 2>/dev/null)"
echo ""

#######################################
# STORAGE BUCKET LIST
#######################################

echo "🔍 Fetching buckets..."

BUCKETS=$(curl -s \
  -H "apikey: $CLOUD_SERVICE_KEY" \
  -H "Authorization: Bearer $CLOUD_SERVICE_KEY" \
  "$CLOUD_PROJECT_URL/storage/v1/bucket" | jq -r '.[].name')

echo "📦 Buckets:"
echo "$BUCKETS"
echo ""

#######################################
# STORAGE SIZE
#######################################

TOTAL_BYTES=0

echo "🔍 Calculating storage usage..."

for B in $BUCKETS; do
  OBJ=$(curl -s \
    -H "apikey: $CLOUD_SERVICE_KEY" \
    -H "Authorization: Bearer $CLOUD_SERVICE_KEY" \
    "$CLOUD_PROJECT_URL/platform/usage/storage/$B")

  SIZE=$(echo "$OBJ" | jq -r '.usage_bytes // 0')
  TOTAL_BYTES=$((TOTAL_BYTES + SIZE))

  HUMAN=$(numfmt --to=iec $SIZE 2>/dev/null)
  echo "➡ Bucket $B: $HUMAN"
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
echo " Database: $(numfmt --to=iec $DB_SIZE)"
echo " Storage : $TOTAL_HUMAN"
echo "======================================="