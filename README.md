# Slutbook

A private shared journal with a static GitHub Pages frontend and Supabase Auth, PostgreSQL row-level security, and private photo storage.

## Features

- Two provisioned members; no public registration in this application.
- Read both Slutbooks; edit only records belonging to the authenticated account.
- People, chronological journal entries, optional profile details and Instagram links.
- Optional 0–100% scales for rich, schniepi and noice. Zero is a value; untouched or removed scales stay hidden.
- Phone layout with fixed bottom navigation, safe-area spacing, single-column forms, 44px touch targets and 16px form text.
- Connections across people: dating, friends, family, work and custom relationships.
- Private image uploads, client-side resizing, metadata stripping and authenticated downloads.
- Search, status filters, mobile layouts, empty-field omission, account password changes and JSON export.
- Semantic username/password fields for Safari Password AutoFill.
- Original pink/cyan pole-dancer app icon with an eighties Miami neon aesthetic.

## Run

Serve this directory with a static HTTP server. No build step is needed. The Supabase SDK is vendored at an exact version. Do not open index.html via file://.

## Hosting

Canonical domain: https://sekkemache.info/

GitHub Pages serves the root of `main`. The root `CNAME` binds `sekkemache.info` to this repository; `www.sekkemache.info` aliases the GitHub account hostname. IONOS manages the DNS, with all four GitHub IPv4 and IPv6 addresses. Existing mail records are preserved.

The domain is verified in the owner's GitHub account to restrict Pages publishing on the domain and its immediate subdomains. Keep the verification TXT record in DNS. HTTPS certificate issuance was requested on 16 October 2026; final validation is recorded in DOMAIN-SETUP.md.


## Security boundary

Only the generic frontend and database schema belong in Git. Never commit passwords, access/refresh tokens, service-role keys, database exports or user uploads.

The publishable browser API key is intentionally public. Every sb_* table has RLS. An administrator-maintained membership table controls access; authorization never uses editable user metadata. Database constraints preserve ownership relationships between people and journal entries. Update policies enforce both USING and WITH CHECK. The private membership lookup function is outside exposed schemas with restricted execution permissions.

Membership also requires a live matching Supabase Auth session. A revoked session loses database and photo access immediately, including with an otherwise unexpired JWT. Restrictive photo policies separately guard anonymous access and owner-only updates/deletes. The application refuses to expose its login inside a frame or over plain HTTP; external scripts, inline scripts and unsafe links are restricted.

Photos use the private storybook-photos bucket, UUID-based owner paths and authenticated downloads. No signed or public image links are exposed. Object URLs are revoked on logout. Password hashes and identities are held only in Supabase Auth. Authentication sessions are persisted by the SDK; journal content is not written into local storage. External Instagram links do not send a Referer.

Backend additions are isolated under the sb_ prefix and storybook_private schema in the existing Supabase project. Existing application tables and authentication settings are untouched. The deployment therefore shares the project's availability, quotas and administrators. It is access-controlled storage, not end-to-end encryption.

## Validation

The 22 recorded API checks are in tests/access-results.json. Nine render/security assertions are recorded in tests/render-results.json. Safari was also used to verify live sign-in, profile creation, optional-field omission and chapter creation; the chapter was readable by the second account. They verify anonymous denial, mutual read access, write isolation, ownership constraints and protected photo upload/download/delete behavior. Additional SQL role tests verified that authenticated nonmembers see no records. Test data was removed.

After the security update, 27 live API checks passed in tests/security-results.json, including immediately revoked sessions, photo write isolation and unchanged account credentials. Five additional client checks passed in tests/client-security-results.json. The API test implementation is tests/security-audit.mjs and accepts credentials at runtime without storing them. All synthetic records and photos were removed, and test sessions were signed out. This is a targeted security check, not a guarantee against every possible vulnerability.

Ten rating validation checks are recorded in tests/ratings-results.json. Seventeen responsive/browser checks are recorded in tests/mobile-results.json, including both profiles, persisted 0/50/100 values, removal, omitted empty sections, iPhone-sized portrait/landscape viewports and desktop layout. These are browser viewport checks, not tests on a physical iPhone. Synthetic test data was removed.

## Operations

The initial source schema is in backend/schema.sql; apply backend/hardening.sql afterward. These are schema references, not idempotent migrations. Existing member IDs are not included. Accounts use internal email-shaped identifiers for username authentication; those are not recovery mailboxes. Passwords can be changed while signed in. Forgotten-password recovery currently requires the project administrator.

GitHub Pages does not provide custom response-header configuration. CSP is supplied through HTML, and the frame guard is a client-side fallback rather than a frame-ancestors/X-Frame-Options response header. The shared Supabase project also reports disabled leaked-password screening; that paid project-wide feature is not enabled by this application. Existing account passwords remain unchanged at the owner's explicit request. See the [Supabase password-security documentation](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection).

Future invitations should be implemented through an authenticated administrative path; do not add public provisioning endpoints. Never implement login by comparing a password in browser JavaScript.

## Dependencies

@supabase/supabase-js 2.118.0, MIT. See vendor/SUPABASE-LICENSE.txt.
