#!/bin/zsh
set -e
cd -- "${0:A:h}"
/usr/bin/python3 prepare_ionos_access.py
read '?Zum Schließen Enter drücken … '
