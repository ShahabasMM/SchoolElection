# GHSS EVM — Supabase Realtime Build

This version is connected to the existing **GHSS EVM** Supabase project.

## Backend
- Supabase project: GHSS EVM
- Project ref: `oyywlxzlxjtcchaporjl`
- Flutter package: `supabase_flutter: ^2.17.2`
- Publishable client key is stored in `lib/config/supabase_config.dart`.
- Existing `students`, `divisions`, and `candidates` tables are used as the realtime source of truth.
- `cast_vote(candidate_id, division_id)` is used first for atomic voting, with a direct-update fallback if the RPC is unavailable.
- HSS streams/batches are represented as generated `divisions` rows (`+1` / `+2`) so they also use the existing realtime `divisions` publication.

## UI fixes
- Add Candidate now uses a normal dialog instead of a modal bottom sheet.
- Add Division now uses a normal dialog instead of a modal bottom sheet.
- HSS Add Stream also uses a normal dialog.
- This avoids the `_dependents.isEmpty` deactivation assertion encountered when opening the add forms.
- Home uses a pure white background; only the three section modules carry solid accent colors.
- HSS Control has a dedicated header and cleaner +1/+2 management layout.
- Vote button always resets its active state and shows a useful error if the backend rejects the vote.
- Control shows LIVE/OFFLINE based on the Supabase realtime channel.

## Build

```bash
flutter clean
flutter pub get
flutter run
```

For a release APK:

```bash
flutter build apk --release --target-platform android-arm64
```

Note: the execution environment used to prepare this source does not contain the Flutter SDK, so a local `flutter analyze`/`flutter build` could not be executed here.


## Latest HSS + audio fixes
- HSS streams and batches are persisted in Supabase `hss_streams` and `hss_batches`.
- HSS structure is loaded from Supabase on startup and refreshed through realtime.
- HSS candidates continue to use the common `students`, `divisions`, and `candidates` tables so voting/results stay unified.
- Vote audio now explicitly stops, sets full volume, and plays the bundled WAV asset on every vote.
