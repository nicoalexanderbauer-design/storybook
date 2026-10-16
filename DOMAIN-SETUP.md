# sekkemache.info

Status checked on 16 October 2026: the domain is registered at IONOS and still points to IONOS hosting. The DNS change is pending because no authenticated IONOS browser/API control is available in this session. This is an access/capability issue, not a missing user authorization.

The working site is https://nicoalexanderbauer-design.github.io/storybook/.

## Registration verified

The authoritative INFO registry RDAP reports registration on 16 October 2026 at 18:47:20 UTC (20:47 Berlin), expiration on 16 October 2027, and status `client transfer prohibited` / `add period`. There is no `client hold` or `server hold` status. Public DNS resolves through IONOS nameservers. These facts confirm a registered, delegated domain; they do not reveal the account's invoice/payment status.

Registry: https://rdap.identitydigital.services/rdap/domain/sekkemache.info

## Alternative access without browser automation

IONOS provides an authenticated DNS API. A GitHub Pages DomainConnect template was not available in the published DomainConnect templates checked on 16 October 2026.

1. Create an API key at https://developer.hosting.ionos.de/keys, named `Slutbook-DNS`.
2. On this Mac, open `deployment/IONOS-Zugang.command`. Enter the prefix and secret in the hidden terminal prompts. Do not paste the key into chat, a repository, a screenshot or a website form belonging to this project.
3. The helper verifies that the key can access `sekkemache.info`, then saves it locally in `.local/ionos-dns-key` with owner-only permissions. The directory is excluded from Git. It does not change DNS.
4. Once access is ready, set GitHub's custom domain, read and back up the current IONOS zone, and update only the apex A/AAAA groups and the www CNAME. The official API supports `PATCH /dns/v1/zones/{zoneId}` to replace matching name/type groups without replacing the complete zone. Preserve unrelated records and verify them afterward.
5. Remove the local key after completion and revoke the temporary key in IONOS.

Official API specification: https://developer.hosting.ionos.de/assets/kms-swagger-specs/dns.yaml

## Pending changes

1. In https://github.com/nicoalexanderbauer-design/storybook/settings/pages set Custom domain to `sekkemache.info`. This creates the root `CNAME` file.
2. In the IONOS DNS settings for **sekkemache.info only**, replace the existing apex A value `217.160.0.153` and the existing AAAA value `2001:8d8:100f:f000::200` with the records below. Add the `www` CNAME. Do not change nameservers, MX, TXT, mail configuration, or other domains.

| Type | Host | Value |
|---|---|---|
| A | @ | 185.199.108.153 |
| A | @ | 185.199.109.153 |
| A | @ | 185.199.110.153 |
| A | @ | 185.199.111.153 |
| AAAA | @ | 2606:50c0:8000::153 |
| AAAA | @ | 2606:50c0:8001::153 |
| AAAA | @ | 2606:50c0:8002::153 |
| AAAA | @ | 2606:50c0:8003::153 |
| CNAME | www | nicoalexanderbauer-design.github.io |

3. Wait for GitHub's DNS check and certificate, then enable Enforce HTTPS.
4. Verify both `https://sekkemache.info/` and `https://www.sekkemache.info/`, the HTTP-to-HTTPS redirects, and a real login. The generic login page may be public; journal data and photos must still require authentication.
5. Verify domain ownership in the GitHub account Pages settings if available, using the exact GitHub-generated TXT challenge. No challenge value has been fabricated or prefilled.

Reference: [GitHub's custom-domain documentation](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site).
