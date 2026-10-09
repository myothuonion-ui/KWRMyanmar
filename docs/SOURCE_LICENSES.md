# Offline source pack and attribution

Snapshot collected 9 October 2026. The pack contains **11 documents / 610 pages**:
9 complete Korean EasyLaw booklets, one complete 2-page NPS country table, and
one 1-page NHIS 2026 rate notice transcribed as searchable text. Myanmar guides
are project-authored explanations, not official translations.

| ID | Official title | Pages | Edition |
| --- | --- | ---: | --- |
| workers | 외국인근로자 취업 | 42 | 2026-09-15 |
| wages | 임금 | 50 | 2026-09-15 |
| dismissal | 해고근로자 | 102 | 2026-09-15 |
| injury | 산업재해보상보험Ⅰ(업무상 재해) | 70 | 2026-09-15 |
| benefits | 산업재해보상보험Ⅱ(보험급여) | 153 | 2026-09-15 |
| housing | 주택임대차 | 87 | 2026-09-15 |
| equality | 성희롱 피해자 | 47 | 2026-09-15 |
| contract | 기간제 및 단시간근로자 | 27 | 2026-09-15 |
| parental | 여성근로자 | 29 | 2026-09-15 |
| pension | 외국 연금제도 조사 내용 | 2 | 2025-02-01 |
| healthrates | 2026년 건강보험료 및 장기요양보험료 인상 안내 | 1 | 2026 |

Publisher names, original download URLs, edition dates and SHA-256 values are
in `assets/source_manifest.json`, and visible in the source reader. All PDF
pages are bundled byte-for-byte, including publisher notices. Source extraction
is a search aid; PDF mode retains the original tables and layout. Future-dated
amendments in a booklet are not automatically today's rules.

## EasyLaw

Publisher: **법제처 · 찾기쉬운 생활법령정보 (Ministry of Government Legislation)**.
Reuse policy: https://www.easylaw.go.kr/CSP/InfoCopyright.laf . The policy allows
reuse, including commercial reuse, with attribution; third-party copyrighted
material is excluded. This project preserves publisher attribution and the
notices in each original PDF. The booklets' notice asks users of substantial
or commercial content to notify 법제정보담당관 (044-200-6900); a commercial
publisher should handle that notice and any third-party rights before launch.
The project does not claim to have sent a publisher notification.

The retirement booklet csmSeq=999 returned visibly broken publisher encoding
and was excluded after rendering inspection. Related Myanmar guidance links
other included official booklets and remains marked for current verification.

## NPS and NHIS

NPS: **국민연금공단**, https://www.nps.or.kr/ . The country table is a dated
official factual reference, not a 2026 eligibility guarantee. It specifically
lists Myanmar in the workplace/regional exclusion group as of 2025-02-01.

NHIS: **국민건강보험공단**, https://www.nhis.or.kr/ . The included notice states
the official 2026 health and long-term-care rates. It is transcribed without
logos or decorative website material. The source URL is retained for checking.

Other primary links in the authored guides include MOEL, Immigration, Government24,
Danuri, 119 and FSS. Those entire websites are not bundled; the app clearly labels
external source buttons `Online`.

## Font

**Noto Sans Myanmar**, Google / Noto contributors. SIL Open Font License 1.1.
The complete license is in `assets/fonts/OFL.txt`. The build fetches the exact
font bytes pinned by SHA-256 in the source manifest. No runtime font download.

## Updating

`python3 scripts/build_sources.py` regenerates the per-page index from verified
PDF bytes. It fails on changed hashes, invalid PDF headers or broken extraction.
A content maintainer must review a new official edition, update its hash/date,
review affected guides and tests, and publish a new app build. Current sources
are snapshots, not a live legal-update service.
