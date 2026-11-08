# Recipe: Adding a Store Setting or General Configuration

Follow this checklist when adding a new setting to `/settings/general` (or dual-backend store settings).

---

### Step 1: Update Domain Model (`lib/models/app_settings.dart`)
1. Add property with appropriate default to `AppSettings` class.
2. Update constructor.
3. Update `fromMap()` with a safe default fallback.
4. Update `toMap()`.
5. Update `copyWith()` and `defaultSettings()` or initial factory method.

---

### Step 2: Wire Settings Dialog (`lib/views/distributor/store_settings_dialog.dart`)
1. Add input widget / toggle in `StoreSettingsDialog`.
2. Bind to controller and initialize from current provider settings.
3. Include field in `updateSettings(updatedSettings)` payload via `RepositoryManager.instance.updateSettings()`.

---

### Step 3: Verification Gate
Run:
```bash
flutter analyze
flutter test
```
Both must pass with zero issues.
