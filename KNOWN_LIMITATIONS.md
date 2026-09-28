# Known limitations

The final release is complete as a product release with local, explicit caveats. The authoritative per-issue status is `02_analysis/release_registers/FINAL_OPEN_POINTS_STATUS.csv`.

Key remaining non-blocking items:

- **PISA 2003 Korea reading supplement:** one supplement task failed a plausible-value integrity range check; preserved baseline rows remain untouched.
- **PIRLS 2006 Spain language-within-assessment sorting:** 73/75 replicates are finite; no released SE for that specific statistic.
- **Strict external TIMSS checks:** Iran 2003 mathematics, Philippines 2003 science and Italy 2011 mathematics remain `REVIEW_REQUIRED`; tolerances were not widened.
- **PISA 2025 gender:** source fields that are all-missing or combine Female/Other are not recoded into a clean girl/boy split.
- **School sorting:** all-target and modal-ISCED specifications remain available; claims are restricted to conclusions robust to both where necessary.
- **Replicate arrays:** large per-task aggregate-replicate caches are retained locally and not committed.
- **Data rights:** public redistribution of some OECD/IEA-derived aggregates/source bytes is not assumed. The production-data manifest records exact hashes without committing restricted result bytes.
