# sekkemache.info

Configuration applied on 16 October 2026. IONOS DNS and the GitHub Pages custom-domain binding are configured. Domain ownership is verified in the GitHub account `nicoalexanderbauer-design`. HTTPS is active and GitHub Pages Enforce HTTPS is enabled. Direct Safari access and both account logins passed on the custom domain.

## DNS configuration

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
| TXT | _github-pages-challenge-nicoalexanderbauer-design | d7711d7e97a0326d5232c6abac1c09 |

TTL is 300 seconds for these new web and verification records. The TXT value is a public domain-ownership challenge, not an authentication credential.

Only IONOS's Default Site A, AAAA and `_dep_ws_mutex` records were replaced/deactivated. The following existing records are preserved:

- MX @: 10 mx00.ionos.de and 10 mx01.ionos.de.
- TXT @: v=spf1 include:_spf-eu.ionos.com ~all.
- CNAME _dmarc: dmarc.ionos.de.
- CNAME s1-ionos._domainkey: s1.dkim.ionos.com.
- CNAME s2-ionos._domainkey: s2.dkim.ionos.com.
- CNAME autodiscover: adsredir.ionos.info.
- CNAME _domainconnect: _domainconnect.ionos.com.
- Existing IONOS nameservers.

The browser was used to apply the configuration. No IONOS API key was created or required. The optional local helper in deployment/ is not needed for this completed DNS configuration.

## Completed validation

- GitHub Pages shows the custom domain sekkemache.info and deploys the root CNAME from main.
- The IONOS DNS table shows all required records and preserved mail records.
- Cloudflare's public DNS resolver returns all four A records, all four AAAA records, the www CNAME and the verification TXT.
- GitHub account Pages settings reports: Successfully verified sekkemache.info.
- All four authoritative IONOS nameservers return the intended A, AAAA and www CNAME records.
- TLS certificate validates for sekkemache.info and www.sekkemache.info; GitHub Pages Enforce HTTPS is checked.
- HTTP returns 301 to HTTPS; HTTPS apex returns 200; HTTPS www returns 301 to the canonical apex.
- Safari loads the custom domain over HTTPS without a warning. Both existing accounts sign in; own-book editing and other-book read-only controls are correct. Test sessions were signed out.
- Completed checks and certificate details are recorded in tests/domain-results.json.

## Registration

The authoritative INFO registry reports registration on 16 October 2026 and expiration on 16 October 2027, without a client/server hold. The IONOS account also shows the domain as active. Billing status was not inspected.

## Management

- GitHub repository Pages: https://github.com/nicoalexanderbauer-design/storybook/settings/pages
- GitHub verified domains: https://github.com/settings/pages
- IONOS DNS: https://mein.ionos.de/domain-dns-settings/sekkemache.info

Keep the root CNAME and the ownership TXT record in place. Do not remove authentication or database/storage RLS to troubleshoot DNS or HTTPS.
