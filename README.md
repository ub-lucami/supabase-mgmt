# Supabase Migration Manager

This repository contains a **management Docker container** that safely migrates:

- Supabase Cloud → Self-Hosted Supabase
- Database roles, schema, data
- Storage buckets and files

Your **host VM stays clean**  
✔ No Supabase CLI installed  
✔ No jq / curl clutter  
✔ No psql installed  
✔ All tools run inside the mgmt container  

---

## 🚀 Features

- Single-command Cloud → Self-hosted migration
- Full DB export and import
- Storage bucket + file export/import
- Clean separation of secrets (kept OUTSIDE the repo)
- Production-grade, reproducible container environment

---

## 🔐 Secrets Handling

**Do NOT store secrets in the repo.**

Create:
/home/youruser/secrets/migration.env

Example (fill real values):


CLOUD_PROJECT_URL=https://your-cloud.supabase.co
CLOUD_DB_URL=postgres://...
CLOUD_SERVICE_KEY=...
SELF_HOSTED_DB_URL=postgres://postgres:password@db:5432/postgres
SELF_SERVICE_KEY=...
SELF_URL=http://storage:5000

---

## 🛠 Setup

1. Ensure your Supabase self-hosted stack uses:


networks:
supabase-network:
name: supabase-network

2. Build management container:


make build

3. Run full migration:


make run

This will:

- Dump Cloud DB
- Restore into local DB
- Export buckets
- Import buckets locally

---

## 📚 Commands

| Action | Command |
|--------|---------|
| Build container | `make build` |
| Run migration | `make run` |
| Open mgmt shell | `make shell` |
| Clean images | `make clean` |

---

## 🧩 Notes

- This repo is safe to commit and share.
- Never commit the `migration.env` secret file.
- The mgmt container is disposable and stateless.

---

## 📝 License
MIT