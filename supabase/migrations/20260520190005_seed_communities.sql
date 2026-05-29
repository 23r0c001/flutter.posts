-- Seed starter communities so the app has something to render before
-- users have created their own. Idempotent via `on conflict (slug)`.
--
-- Slugs are chosen based on the target audience: parents/caregivers of
-- people with disabilities. We're seeding a few common topics so a
-- fresh sign-up isn't greeted by an empty community list.
--
-- This migration is data-only (no DDL); blowing away seed rows is safe
-- — re-running this file restores them.

insert into public.communities (slug, name, description) values
  ('intro', 'Welcome', 'Introduce yourself and meet others. Start here.'),
  ('autism-support', 'Autism Support', 'Parents and caregivers of people on the autism spectrum.'),
  ('downs-community', 'Down''s Community', 'For families of people with Down''s syndrome.'),
  ('cerebral-palsy', 'Cerebral Palsy', 'Resources and conversations for families dealing with CP.'),
  ('iep-and-school', 'IEP & School', 'Navigating IEPs, 504s, and the school system.'),
  ('siblings', 'Siblings', 'Conversations for siblings of people with disabilities.')
on conflict (slug) do nothing;
