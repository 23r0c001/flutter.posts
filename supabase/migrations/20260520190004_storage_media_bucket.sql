-- Storage bucket for user-uploaded media.
--
-- We register the bucket via SQL (rather than dashboard) so the schema
-- is fully reproducible from `supabase db reset`. Settings:
--   - `public = false`: files require authenticated requests or signed URLs.
--   - 5 MB max file size: lets us add larger video later by raising this.
--   - Whitelist of safe image MIME types only. Add `video/mp4` later.
--
-- `on conflict (id) do nothing` makes this migration idempotent —
-- running it twice (or running `supabase db reset` mid-development)
-- won't error.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'media',
  'media',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
on conflict (id) do nothing;

-- Storage RLS policies.
--
-- Upload path convention: `media/<user_id>/<uuid>.<ext>`. The first
-- folder of the storage path is the owner's user_id; policies enforce
-- this so one user can't overwrite another's files.

-- Any signed-in user can READ any file in the media bucket. (Media
-- visibility is governed by the post visibility — if you can see the
-- post, you can see its media.)
create policy "authenticated users can read media"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'media');

-- Users can INSERT (upload) files only into their own `<user_id>/` folder.
-- `storage.foldername(name)[1]` returns the first path segment.
create policy "authenticated users can upload to their own folder"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Users can DELETE files only in their own folder.
create policy "users can delete their own media"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
