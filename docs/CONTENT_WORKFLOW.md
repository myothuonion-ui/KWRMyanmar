# Maintaining the Korea handbook

Version 0.3.0 adds preparation workflows to 30 existing guides. It does not claim
to complete Korean law coverage or certify individual eligibility. The offline
pack remains 11 documents / 610 pages. Offices may require different documents
for a person's actual case.

`assets/cards.json` is the merged app data. `scripts/enrich_handbook.py` defines
the 30 workflows: questions, preparation documents, office URLs, Korean/Myanmar
phrases, steps, colloquial aliases and exact `source_refs`. Run it after generating
base cards, then run `--check`. `prepared` is an editorial date, not a replacement
for the guide's legal check date or original source edition.

`source_refs.page` is the physical one-based PDF page. Open the page and check
its applicable passage, scope, exceptions and edition. Do not attach a general
worker PDF to unrelated tax claims. The tax guide currently links to the NTS
publication online and has no bundled primary tax PDF.

## Source updates

1. Use the responsible institution: MOEL/EPS for labor and workplace changes,
   HiKorea for immigration, COMWEL for injury, NHIS for health/long-term care,
   NPS for pension, NTS for tax and courts/legal-aid sources for housing.
2. Record publication URL, publication/effective dates, visa/worker scope,
   corrections and reuse terms. Access date alone is not an effective date.
3. Preserve originals unchanged. Review changed editions before updating their
   SHA-256 in `assets/source_manifest.json`; never disable checksum checking.
4. Build the page index with `scripts/build_sources.py`; inspect extraction and
   rejected encodings, then add exact relevant page references.
5. Write clear Myanmar conditions, exceptions, case questions, preparation
   evidence, office routes and Korean phrases. Keep uncertain eligibility
   `pending`. Record legal/language review separately when it actually occurs.
6. Run content, retrieval and citation tests with realistic questions and their
   follow-ups; verify the finished APK opens the cited page offline.

Pinned-release restoration only recovers reviewed v0.2.2 bytes. Archive and asset
hashes must match. It neither refreshes law nor runs the downloaded APK.

## Next priorities

Expand visa-specific procedures, labor complaint forms, housing deposits,
hospital/insurance navigation and family/student routes. Collect anonymized
community questions with consent and use them for retrieval/abstention cases.
Remove identifying details before committing public fixtures. Every FAQ needs
its source, applicable conditions and review date.

Review content around official rule changes and publication cycles. The app
does not yet have a live legal-update monitor; fresh information needs explicit
editorial review.
