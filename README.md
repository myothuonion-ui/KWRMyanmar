# KWR Myanmar

Android app for Myanmar-speaking workers in Korea. Read structured Myanmar guides and complete original Korean booklets offline; save private records; ask questions using selected, confirmed context with your own AI API key.

## App

- **Handbook:** 55 structured Myanmar guides / 114 sections in 8 categories: work, pay, insurance, visa, housing, health, everyday life and emergencies.
- **Sources:** 11 offline documents / 610 searchable pages, including 10 complete official PDFs. Text/PDF modes, source editions, direct page navigation and page bookmarks. See [source attribution](docs/SOURCE_LICENSES.md).
- **Search:** Entire guide bodies/sections and every original page; Burmese/Korean/English aliases, source-only filtering, excerpts and exact-page opening.
- **Design:** Calm green/navy surfaces, bundled Noto Myanmar, readable spacing, contents navigation and adjustable guide text. Five tabs: Home, Handbook, Search, Saved and My files.
- **AI:** Offline answers search guides and original pages; online answers receive the same dated evidence with exact-page citations and a reviewable send preview. Supports Gemini, OpenAI Responses, Claude, NVIDIA NIM, DeepSeek and custom OpenAI-compatible chat.
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
5. Review and edit the question and context in the send preview, then approve that request.

API charges, quotas, availability and provider data policies apply. A ChatGPT consumer subscription is not an OpenAI API key. Offline mode uses bundled source search; it does not run an on-device language model.

## Privacy and evidence

Private records, originals and history snapshots are encrypted locally with AES-256-GCM and a random key in platform secure storage. API keys are stored separately in secure storage. Android backup is disabled. Never commit personal files or API keys to this public repository.

Only confirmed, selected context appears in the request preview. Original PDF/images and old chat snapshots are not sent automatically. Common IDs, long numeric identifiers and emails are masked, but users must still remove other private details manually. Export deliberately writes readable JSON without original attachments or API keys. Uninstall/app-data clearing may lose local records.

Source snapshots were collected on **2026-10-09**; each source retains its actual edition date; they are not a comprehensive lawyer-reviewed corpus. AI citations are restricted to retrieved guide IDs and exact original-page IDs, which does not prove that every generated claim is correct. Verify unresolved rules with official sources, 1350 (labor) or 1345 (immigration). Imported contracts are personal evidence, not statutes.

## Build and verification

Flutter 3.47.6 / Java 17. The Android host is generated in CI so its wrapper stays consistent with the pinned Flutter SDK:

```sh
flutter create --platforms=android --org=com.myothuonion --project-name=kwrmyanmar --no-pub /tmp/kwr_host
cp -R /tmp/kwr_host/android .
python3 scripts/prepare_android.py
# Requires Python 3 and Poppler (pdftotext); network only during this build step.
python3 scripts/build_sources.py
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build apk --release
```

`.github/workflows/android.yml` builds the APK, runs native integration tests on Android API 35, launches the exact release APK, captures screen images, and publishes a preview with SHA-256 checksums. Commits labeled `[bootstrap]` only build and test; they do not publish.

Tests cover full-pack integrity, original-only page retrieval, multilingual aliases, page bookmarks, compact UI, offline chat, pay/calendar/dismissal conditions, authenticated encryption, selected-context isolation, all five provider request formats, model pagination, API errors, citation validation and offline navigation. Native integration verifies secure storage, encrypted files, PDF extraction and image OCR using synthetic fixtures, and opening/rendering page 17 of the bundled official source without downloading it. No paid API key is used in CI; live account compatibility needs the user's own supported key/model.

Image OCR supports Korean/Latin text. Burmese image text needs manual entry. Imports are limited to 20 MB and 40 PDF pages; extraction may be truncated and always needs checking.

Generated PDFs, source index and font bytes are build assets, reproduced from the pinned manifest rather than committed binaries. The finished APK bundles them all; the app performs no startup content/font downloads. Update manifest hashes only after reviewing new official editions.
