#!/bin/sh
set -e

. /config/migration.env

echo "Storage usage:"
echo ""

BUCKETS=$(curl -s \
  -H "Authorization: Bearer $CLOUD_SERVICE_KEY" \
  -H "apikey: $CLOUD_SERVICE_KEY" \
  "$CLOUD_PROJECT_URL/storage/v1/bucket" | jq -r '.[].name')

TOTAL=0

for B in $BUCKETS; do
  echo "➡ Bucket: $B"

  RAW=$(curl -s \
    -H "Authorization: Bearer $CLOUD_SERVICE_KEY" \
    -H "apikey: $CLOUD_SERVICE_KEY" \
    -H "Content-Type: application/json" \
    -d '{"prefix":""}' \
    "$CLOUD_PROJECT_URL/storage/v1/object/list/$B")

  if echo "$RAW" | jq -e 'type=="array"' >/dev/null 2>&1; then
    BYTES=$(echo "$RAW" | jq '[.[].metadata.size // 0] | add')
  else
    BYTES=0
  fi

  HUMAN=$(numfmt --to=iec $BYTES)
  TOTAL=$((TOTAL + BYTES))

  echo "   size: $HUMAN"
done

echo ""
echo "Total storage: $(numfmt --to=iec $TOTAL)"