## Quick orientation for AI coding agents

This Flutter app tracks walking/driving routes (Android + iOS). The goal of this document is to provide concise, codebase-specific guidance that lets an AI agent be productive immediately.

Key entry points and contracts
- `lib/main.dart` — app entry. Initializes date formatting, creates app folders (`TrackData.createAppFolder()`), and wires global providers using `MultiProvider`.
- State models: `lib/models/track_data.dart` (track persistence, file IO, merge logic) and `lib/models/location_service.dart` (runtime trace data in `LocaData`).
- Permissions: centralized in `lib/models/permission_handler.dart` (use `handleTrackingPermissions` for location/notification flows).

Core patterns to preserve
- Single-instance ChangeNotifiers: `TrackData` and `LocaData` are constructed once in `main.dart` and provided with `ChangeNotifierProvider.value(...)`. Keep this unless you update all consumers.
- File format & IO: tracks are plain `.txt` files under the app documents directory. `TrackData` expects a 7-line header followed by lat/lon lines; use its helpers for reading/writing to avoid subtle bugs.
- Route registration: routes and `initialRoute` are defined in `main.dart` and screens expose `*.id` constants — use them for navigation.

Why these decisions matter
- Using plain text files keeps persistence simple and backwards-compatible between app versions.
- Centralizing permission and IO logic prevents duplicate dialogs and inconsistent storage paths.

Concrete commands (PowerShell)
- Install deps: flutter pub get
- Run on device/emulator: flutter run -d <deviceId>
- Run tests: flutter test
- Analyze: flutter analyze
- Build APK (release): flutter build apk --release

Files to read for immediate context
- Provider setup & routes: `lib/main.dart`
- Track persistence: `lib/models/track_data.dart` (methods: `createAppFolder`, `listTracks`, `writeTrack`, `mergeTracks`)
- Live location model: `lib/models/location_service.dart` (class `LocaData`, `updatePosition`)
- Permission flow & UI: `lib/models/permission_handler.dart`
- UI: `lib/screens/*`, small widgets in `lib/components/*` (look at `track_tile.dart`, `map_controls.dart` for typical usage)

Developer conventions & gotchas
- Locale: `main.dart` initializes `fr_FR` and `en_US` formatting — tests/UI may depend on French formatting.
- Do not alter track file serialization without adding a migration path in `TrackData`.
- Many widgets assume ChangeNotifier events for refresh; refactoring this can cause wide breakage if done incrementally.

Integration notes
- Native: Android manifests live in `android/app/src/{main,debug,profile}/AndroidManifest.xml`. Gradle uses Kotlin DSL (`build.gradle.kts`). For background location or foreground services update both manifest and native config carefully.
- Dependencies: see `pubspec.yaml` (e.g. `geolocator`, `google_maps_flutter`, `permission_handler`, `path_provider`). Keep additions minimal and run `flutter pub get`.

If you want more detail (exact track header layout, example track file, or locations where selected tracks names are consumed in UI), tell me which file(s) and I'll extract the precise snippets and add them here.

-- end
