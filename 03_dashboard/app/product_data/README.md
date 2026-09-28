# Dashboard production data policy

This directory intentionally commits only small final status/control tables. The tested production dashboard also used larger OECD/IEA-derived aggregate bundles and country-level profiles. Those bytes are omitted from Git until redistribution rights are explicitly confirmed.

`PRODUCTION_DATA_MANIFEST.csv` is the authoritative inventory of the tested production-data files and their SHA-256 hashes. Regenerate them from the frozen analysis or install a controlled release data bundle matching those hashes.
