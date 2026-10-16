# sekkemache.info

Status checked on 16 October 2026: the domain is registered at IONOS and still points to IONOS hosting. The DNS change is pending because no authenticated IONOS browser/API control is available in this session. This is an access/capability issue, not a missing user authorization.

The working site is https://nicoalexanderbauer-design.github.io/storybook/.

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
