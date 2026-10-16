#!/usr/bin/env python3
"""Prepare local IONOS DNS access without disclosing the key in chat or Git."""
import getpass
import json
import os
from pathlib import Path
import re
import sys
import urllib.error
import urllib.request

DOMAIN = 'sekkemache.info'
API = 'https://api.hosting.ionos.com/dns/v1/zones'
PROJECT = Path(__file__).resolve().parent.parent


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        # Do not forward an account credential to a redirected endpoint.
        return None


def main():
    print('IONOS-Zugang für Slutbook vorbereiten')
    print('Schlüssel erstellen: https://developer.hosting.ionos.de/keys')
    print('Die Eingaben bleiben unsichtbar. Der Schlüssel wird nicht in den Chat übertragen.')
    prefix = getpass.getpass('Präfix (oder vollständiger Schlüssel): ').strip()
    key = prefix if '.' in prefix else prefix + '.' + getpass.getpass('Geheimer Schlüssel: ').strip()
    if not re.fullmatch(r'[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+', key):
        raise ValueError('Ungültiges Format. Bitte die beiden Teile aus IONOS verwenden.')

    request = urllib.request.Request(API, headers={
        'X-API-Key': key, 'Accept': 'application/json',
        'User-Agent': 'Slutbook-Domain-Setup/1.0',
    })
    with urllib.request.build_opener(NoRedirect()).open(request, timeout=30) as response:
        zones = json.load(response)
    if not isinstance(zones, list) or not any(
        zone.get('name', '').rstrip('.').lower() == DOMAIN for zone in zones
    ):
        raise ValueError('Dieser Zugang zeigt sekkemache.info nicht. Bitte das passende IONOS-Konto verwenden.')

    private = PROJECT / '.local'
    if private.is_symlink():
        raise ValueError('Der lokale Zugangsordner darf keine Verknüpfung sein.')
    private.mkdir(mode=0o700, exist_ok=True)
    os.chmod(private, 0o700)
    key_file = private / 'ionos-dns-key'
    fd = os.open(key_file, os.O_WRONLY | os.O_CREAT | os.O_TRUNC | os.O_NOFOLLOW, 0o600)
    with os.fdopen(fd, 'w') as handle:
        os.fchmod(handle.fileno(), 0o600)
        handle.write(key + '\n')
    print('\nZugang geprüft. sekkemache.info ist verfügbar.')
    print('Der Schlüssel liegt nur lokal und ist von Git ausgeschlossen.')
    print('DNS wurde noch nicht geändert. Schreibe jetzt im Chat: Zugang bereit.')


if __name__ == '__main__':
    try:
        main()
    except urllib.error.HTTPError as error:
        print(f'IONOS lehnt den Zugang ab (HTTP {error.code}). Nichts geändert.', file=sys.stderr)
        sys.exit(1)
    except (urllib.error.URLError, TimeoutError):
        print('IONOS ist gerade nicht erreichbar. Nichts geändert.', file=sys.stderr)
        sys.exit(1)
    except (ValueError, OSError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
    except (KeyboardInterrupt, EOFError):
        print('\nAbgebrochen. Nichts geändert.', file=sys.stderr)
        sys.exit(1)
