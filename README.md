# GHSS EVM — GHSS MEZHATHUR

   install : https://betadrop.app/install/LsPdbB



<img width="256" height="256" alt="image" src="https://github.com/user-attachments/assets/dcd3ec78-c340-40eb-ad55-ce61ca620cb3" />




A clean, warm, physical-EVM-inspired Flutter school election app.

## Storage

This version is **fully local**.

- No Supabase
- No cloud database
- No internet dependency
- Students, divisions, HSS streams/batches, candidates and votes are stored on the device using `SharedPreferences`.
- Closing/reopening the app keeps the election data on that device.

> Because this is local-only, multiple phones do **not** share vote counts. If Phone 1 votes, Phone 2 will not automatically receive that vote.

## HSS

Home includes **HSS SECTION** with `+1` and `+2`.

From **Control → HSS Manage** you can:

- Add/remove streams such as Science, Commerce and Humanities.
- Add a custom stream name.
- Leave a stream without batches for direct voting.
- Enable batches for a stream.
- Add multiple batches such as Batch A, Batch B, Batch 1, Batch 2, etc.
- Manage candidates separately for every direct stream or batch.

Voting flow:

```text
HSS SECTION
   ↓
+1 / +2
   ↓
Stream
   ├── no batches → Voting
   └── batches → Select Batch → Voting
```

## Vote sound

The vote sound is preloaded when the app starts and the vote action does not wait for audio playback. This removes the noticeable delay from the previous implementation.

## Run

```bash
flutter pub get
flutter run
```

For Android:

```bash
flutter build apk --debug
```

For a smaller release APK:

```bash
flutter build apk --release --split-per-abi
```

## Notes

- There are no demo candidates.
- Existing HS classes: 8, 9, 10.
- Existing UP classes: 5, 6, 7.
- HSS classes: +1 and +2.
