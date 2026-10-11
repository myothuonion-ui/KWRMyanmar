# KWR Myanmar

Android app for Myanmar-speaking workers in Korea. Read structured Myanmar guides and complete original Korean booklets offline; save private records; ask questions using selected, confirmed context with your own AI API key.

## App

- **Handbook:** 55 structured Myanmar guides / 114 sections in 8 categories: work, pay, insurance, visa, housing, health, everyday life and emergencies.
- **Practical help:** 30 priority guides include case questions, preparation documents, official office links, Korean phrases and a completed-step checklist. Encrypted private notes/checklists also appear in Saved.
- **Sources:** 11 offline documents / 610 searchable pages, including 10 complete official PDFs. Text/PDF modes, source editions, direct page navigation and page bookmarks. See [source attribution](docs/SOURCE_LICENSES.md).
- **Search:** Entire guide bodies/sections and every original page; Burmese/Korean/English aliases, source-only filtering, excerpts and exact-page opening.
- **Design:** Calm green/navy surfaces, bundled Noto Myanmar, readable spacing, contents navigation and adjustable guide text. Five tabs: Home, Handbook, Search, Saved and My files.
- **AI:** Separate case conversations with resumable history; follow-up retrieval keeps the problem, and online requests replay up to four previewed question/answer pairs. Evidence prioritizes linked exact original pages within a bounded text budget. Answers require status and per-claim citations. Supports Gemini, OpenAI Responses, Claude, NVIDIA NIM, DeepSeek and custom OpenAI-compatible chat.
- **Models:** Per-provider keys and model preferences; drafts survive provider switching and are saved together; fetch model IDs from each API or enter a custom ID. No embedded key or fixed model list.
- **Visa:** Separate termination, workplace-change application and official deadline dates; calendar-month milestones. D-2/D-4 eligibility stays marked for current official verification.
- **Pay:** Ordinary hourly wage, non-overlapping work hours, overlapping night premiums, holiday premiums, manual deductions and payslip comparison. Applicability must be confirmed.
- **My files:** PDF/JPG/PNG import, local PDF extraction, bundled Korean/Latin OCR, editable confirmed text, profile, events and explicit AI-context selection.

## Download and setup

Install the APK from [GitHub Releases](https://github.com/myothuonion-ui/KWRMyanmar/releases). Android 6.0+ is required. This is a preview signed with a development identity, not a Play Store production release.

1. Read guides/original sources, use calculators and import records offline without an account.
2. Open **Settings**, choose your AI provider and enter your provider's API key.
3. Refresh the model list online, choose an authorized chat model (or enter its ID), and save.
4. In **AI**, enable online mode. Confirm imported text/profile before selecting context.
5. Review the question, selected context, recent conversation and public passages in the send preview; turn off prior turns if unnecessary, then approve that request.
6. Use **အကြောင်းအရာသစ်** for another case; **အရင်စကားဝိုင်းများ** resumes a saved case. Pre-upgrade history is archived and never silently included in a new request.

API charges, quotas, availability and provider data policies apply. A ChatGPT consumer subscription is not an OpenAI API key. Offline mode uses bundled source search; it does not run an on-device language model.

## Privacy and evidence

Private records, originals and history snapshots are encrypted locally with AES-256-GCM and a random key in platform secure storage. API keys are stored separately in secure storage. Android backup is disabled. Never commit personal files or API keys to this public repository.

Only confirmed, selected profile/document context appears in the request preview. Up to four question/answer pairs from the active case can be replayed after preview; old profile/document snapshots, original PDF/images and guide notes are not automatically added. Historical replies are untrusted notes, never legal authority. Common IDs, long numeric identifiers and emails are masked in replay, but users must still remove other private details manually. Export includes readable notes/checklists/history JSON without original attachments or API keys. Uninstall/app-data clearing may lose local records.

Source snapshots were collected on **2026-10-09**; each source retains its actual edition date; they are not a comprehensive lawyer-reviewed corpus. AI citations are restricted to retrieved guide IDs and exact original-page IDs, which does not prove that every generated claim is correct. Verify unresolved rules with official sources, 1350 (labor) or 1345 (immigration). Imported contracts are personal evidence, not statutes.

## Build and verification

Flutter 3.47.6 / Java 17. The Android host is generated in CI so its wrapper stays consistent with the pinned Flutter SDK:

```sh
flutter create --platforms=android --org=com.myothuonion --project-name=kwrmyanmar --no-pub /tmp/kwr_host
cp -R /tmp/kwr_host/android .
python3 scripts/prepare_android.py
# Requires Python 3 and Poppler (pdftotext); network only during this build step.
python3 scripts/build_sources.py --restore-pinned-release
python3 scripts/enrich_handbook.py --check
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build apk --release
```

`.github/workflows/android.yml` builds the APK, runs native integration tests on Android API 35, launches the exact release APK, captures screen images, and publishes a preview with SHA-256 checksums. Commits labeled `[bootstrap]` only build and test; they do not publish.

Tests cover full-pack integrity, colloquial Burmese/multi-intent ranking, scoped/bounded replay, linked original pages, per-claim citations, notes/checklists, page bookmarks, compact UI, offline chat, pay/calendar/dismissal conditions, encryption, selected-context isolation, all five providers' single/multi-turn formats, pagination and API errors. Native integration verifies encrypted note/checklist persistence, secure storage, PDF extraction, image OCR and rendering page 17 of the bundled source. No paid API key is used in CI; live account compatibility needs the user's own supported key/model.

Image OCR supports Korean/Latin text. Burmese image text needs manual entry. Imports are limited to 20 MB and 40 PDF pages; extraction may be truncated and always needs checking.

Generated PDFs, source index and font bytes are reproduced from the pinned manifest. If a publisher changes bytes at the same URL, `--restore-pinned-release` can recover the exact reviewed assets from the checksum-pinned v0.2.2 APK; archive and individual asset hashes are verified. It never accepts a new edition implicitly. The app performs no startup content/font downloads. See [content maintenance](docs/CONTENT_WORKFLOW.md) before adding or refreshing sources.
