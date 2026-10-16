# Storybook

A private shared journal with a static GitHub Pages frontend and Supabase Auth, PostgreSQL row-level security, and private photo storage.

## Features

- Two provisioned members; no public registration in this application.
- Read both storybooks; edit only records belonging to the authenticated account.
- People, chronological journal entries, optional profile details and Instagram links.
- Connections across people: dating, friends, family, work and custom relationships.
- Private image uploads, client-side resizing, metadata stripping and authenticated downloads.
- Search, status filters, mobile layouts, empty-field omission, account password changes and JSON export.
- Semantic username/password fields for Safari Password AutoFill.

## Run

Serve this directory with a static HTTP server. No build step is needed. The Supabase SDK is vendored at an exact version. Do not open index.html via file://.

## Hosting

GitHub Pages: Settings → Pages → Deploy from a branch → main → / (root).

Set the intended custom domain in Pages before replacing any DNS records. For an IONOS apex domain use GitHub's documented A records, and point www with a CNAME at the GitHub account's github.io hostname. Preserve all existing mail records. Enable Enforce HTTPS after certificate issuance.

## Security boundary

Only the generic frontend and database schema belong in Git. Never commit passwords, access/refresh tokens, service-role keys, database exports or user uploads.

The publishable browser API key is intentionally public. Every sb_* table has RLS. An administrator-maintained membership table controls access; authorization never uses editable user metadata. Database constraints preserve ownership relationships between people and journal entries. Update policies enforce both USING and WITH CHECK. The private membership lookup function is outside exposed schemas with restricted execution permissions.

Photos use the private storybook-photos bucket, UUID-based owner paths and authenticated downloads. No signed or public image links are exposed. Object URLs are revoked on logout. Password hashes and identities are held only in Supabase Auth. Authentication sessions are persisted by the SDK; journal content is not written into local storage. External Instagram links do not send a Referer.

Backend additions are isolated under the sb_ prefix and storybook_private schema in the existing Supabase project. Existing application tables and authentication settings are untouched. The deployment therefore shares the project's availability, quotas and administrators. It is access-controlled storage, not end-to-end encryption.

## Validation

The recorded API checks are in tests/access-results.json. They verify anonymous denial, mutual read access, write isolation, ownership constraints and protected photo upload/download/delete behavior. Additional SQL role tests verified that authenticated nonmembers see no records. Test data was removed.

## Operations

The source schema is in backend/schema.sql. It is an initial schema reference, not an idempotent migration. Existing member IDs are not included. Accounts use internal email-shaped identifiers for username authentication; those are not recovery mailboxes. Passwords can be changed while signed in. Forgotten-password recovery currently requires the project administrator.

Future invitations should be implemented through an authenticated administrative path; do not add public provisioning endpoints. Never implement login by comparing a password in browser JavaScript.

## Dependencies

@supabase/supabase-js 2.118.0, MIT. See vendor/SUPABASE-LICENSE.txt.
