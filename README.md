# Flutter Clean Architecture Scaffold

A Flutter project template enforcing strict Clean Architecture across all feature modules.

**Stack:** Flutter · MobX · go_router · dio · get_it · reactive_forms · freezed · mason · melos · envied

---

## Using this as a scaffold

Run these commands inside an existing Flutter project directory.

### Option A — Global activation (recommended)

Install once, use anywhere:

```bash
flutter pub global activate --source git https://github.com/rnzdvd/flutter-scaffold
```

Then inside any Flutter project:

```bash
flutter_scaffold
```

> If `flutter_scaffold` is not found, add the pub-cache bin to your PATH:
> - **Windows:** `$env:PATH += ";$env:LOCALAPPDATA\Pub\Cache\bin"`
> - **macOS/Linux:** `export PATH="$PATH:$HOME/.pub-cache/bin"`

---

### Option B — Clone and run (no setup needed)

**Windows (PowerShell):**

```powershell
$t = "$env:TEMP\flutter-scaffold"
git clone https://github.com/rnzdvd/flutter-scaffold $t --depth 1 --quiet
dart run "$t\bin\scaffold.dart"
Remove-Item $t -Recurse -Force
```

**macOS / Linux:**

```bash
t=$(mktemp -d)
git clone https://github.com/rnzdvd/flutter-scaffold $t --depth 1 --quiet
dart run $t/bin/scaffold.dart
rm -rf $t
```

---

### What the scaffold copies into your project

| Path | Purpose |
| ---- | ------- |
| `_templates/` | Mason bricks for code generation |
| `CLAUDE.md` | Claude Code architecture guide |
| `.claude/skills/` | Claude Code skill definitions |
| `lib/core/` | Base API, entity, config, logger utilities |
| `lib/main.dart` | App entry point wired with GetIt + GoRouter |
| `lib/store.dart` | Root MobX store |
| `analysis_options.yaml` | Linter config |
| `build.yaml` | json_serializable field_rename config |
| `mason.yaml` | Mason brick registry |
| `melos.yaml` | Melos script shortcuts |
| `install_packages.ps1` | Installs and pins all required packages |
| `.env.dev` / `.env.prod` | Environment variable templates |

> `pubspec.yaml` is **never overwritten.** All `package:templated_flutter/` imports are automatically replaced with your project's package name.

---

### After scaffolding

```bash
# 1. Install Mason CLI
dart pub global activate mason_cli

# 2. Register the bricks
mason get

# 3. Install Flutter dependencies
# Windows PowerShell:
#   .\install_packages.ps1
#
# macOS:
#   1. Install PowerShell first: brew install --cask powershell
#   2. Then run: pwsh install_packages.ps1
#
# or manually: flutter pub add mobx flutter_mobx reactive_forms ...

# 4. Run code generation
melos run build
```

---

## Architecture

```
View (pure UI)
  ↑ typed props
Container (StatefulWidget + Observer)
  ↓ calls                    ↑ reads
Controller                 Presenter
  ↓ calls                    ↑ reads
UseCase                    Store (MobX)
  ↓ calls       ↓ calls       ↑ runInAction
ApiGateway    Repository
```

Every feature is scaffolded with Mason bricks — never write boilerplate by hand.

```bash
mason make component  --module_name auth --component_name login
mason make usecase    --module_name auth --usecase_name login
mason make controller --module_name auth --controller_name auth
mason make presenter  --module_name auth --presenter_name auth
mason make repository --module_name auth --repository_name auth
mason make store      --module_name auth --store_name auth
mason make entity     --module_name auth --entity_name user
mason make dto        --module_name auth --dto_name login_response
mason make form       --module_name auth --form_name login
mason make screen     --module_name auth --screen_name login
```

See `CLAUDE.md` for the full convention guide.
