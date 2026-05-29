# Supabase

Backend definition. See [`SupabaseSetup.md`](../SupabaseSetup.md) at the
repo root for the full step-by-step setup walkthrough — this file is
just a quick reference for the migration workflow.

## Files

```
supabase/
├── README.md                              # this file
└── migrations/
    ├── 20260520190000_profiles.sql        # auth profile mirror + on-signup trigger
    ├── 20260520190001_communities.sql     # communities + memberships
    ├── 20260520190002_posts_comments.sql  # posts + threaded comments
    ├── 20260520190003_media.sql           # media metadata table
    ├── 20260520190004_storage_media_bucket.sql  # storage bucket + policies
    └── 20260520190005_seed_communities.sql      # starter community seed data
```

## Workflow

```bash
# One-time install:
brew install supabase/tap/supabase

# Link this folder to your Supabase project (uses the project ref from
# the URL: https://<ref>.supabase.co):
supabase login
supabase link --project-ref <your-project-ref>

# Apply all pending migrations to the remote DB:
supabase db push

# Or, for local dev (spins up Docker, applies migrations to local DB):
supabase start
supabase db reset    # drops + recreates local DB from these migrations
```

## Adding new migrations

```bash
supabase migration new <descriptive_name>
# edits the new file
supabase db push
```

## Portability check

The whole point of using Supabase over Firebase is that `pg_dump` works:

```bash
pg_dump "postgresql://postgres:<password>@db.<project-ref>.supabase.co:5432/postgres" \
  --schema=public --no-owner --no-privileges > backup.sql
```

Open `backup.sql` and you should see all 6 tables + indexes + policies
spelled out in plain Postgres SQL. That file restores into ANY vanilla
Postgres (RDS, Neon, self-hosted) — Supabase is not load-bearing.
