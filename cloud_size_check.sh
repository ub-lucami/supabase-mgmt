#!/bin/sh
set -e

. /config/migration.env

echo "======================================="
echo " Supabase Cloud Project Size Summary"
echo "======================================="
echo ""

##############################################
# DATABASE SIZE (working endpoint)
##############################################

echo "🔍 Fetching database size..."

DB=$(curl -s \
  -H "Authorization: Bearer $CLOUD_SERVICE_KEY" \
  -H "apikey: $CLOUD_SERVICE_KEY" \
  "$CLOUD_PROJECT_URL/platform/usage/db")

# API returns: {"db_size":1234567}
DB_SIZE=$(echo "$DB" | jq -r '.db_size // 0')
DB_HUMAN=$(numfmt --to=iec $DB_SIZE 2>/dev/null)

echo "📦 Database size: $DB_HUMAN"
echo ""

##############################################
# STORAGE SIZE (this already worked)
##############################################

echo "🔍 Fetching buckets..."
BUCKETS=$(curl -s \
  -H "Authorization: Bearer $CLOUD_SERVICE_KEY" \
  -H "apikey: $CLOUD_SERVICE_KEY" \
  "$CLOUD_PROJECT_URL/storage/v1/bucket" \
  | jq -r '.[].name')

echo "Buckets:"
echo "$BUCKETS"
echo ""

TOTAL=0

echo "🔍 Calculating storage usage (per bucket)..."

for B in $BUCKETS; do
  ST=$(curl -s \
    -H "Authorization: Bearer $CLOUD_SERVICE_KEY" \
    -H "apikey: $CLOUD_SERVICE_KEY" \
    "$CLOUD_PROJECT_URL/storage/v1/object/list/$B?limit=10000" \
    | jq '[.[].metadata.size // 0] | add')

  ST=${ST:-0}
  HUMAN=$(numfmt --to=iec $ST 2>/dev/null)

  echo "➡ $B: $HUMAN"

  TOTAL=$(( TOTAL + ST ))
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