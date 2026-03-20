#!/bin/bash
set -e

# Entrypoint for management container
# This simply executes the migration script.
# No Supabase CLI is called here directly (handled inside migrate_all.sh)

exec /scripts/migrate_all.sh