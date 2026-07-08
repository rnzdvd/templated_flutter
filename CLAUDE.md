# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> Project type: **Flutter**

---

## Package Manager

Always use **flutter pub** to manage dependencies — never `npm install` or `yarn`.

```bash
flutter pub add <package>          # add a dependency
flutter pub add --dev <package>    # add a dev dependency
flutter pub remove <package>       # remove a package
flutter pub get                    # install/update packages
```

---

## Commands

```bash
# Development
flutter run                        # run on connected device/emulator
flutter run -d android             # run on Android
flutter run -d ios                 # run on iOS

# Quality
flutter analyze                    # Dart static analysis
flutter test                       # run all tests
flutter test <path>                # run a single test file
melos run format                   # dart format .
melos run fix                      # dart fix --apply

# Code generation (run after adding/changing models, stores, DTOs, forms)
melos run build                    # dart run build_runner build --delete-conflicting-outputs
melos run watch                    # dart run build_runner watch --delete-conflicting-outputs

# Scaffolding (always use these — never write feature files manually)
mason make component  --module_name <module> --component_name <name>   # container.dart + view.dart
mason make screen     --module_name <module> --screen_name <name>      # screen.dart
mason make usecase    --module_name <module> --usecase_name <name>     # case.dart
mason make controller --module_name <module> --controller_name <name>  # controller.dart
mason make presenter  --module_name <module> --presenter_name <name>   # presenter.dart
mason make repository --module_name <module> --repository_name <name>  # repository.dart
mason make store      --module_name <module> --store_name <name>       # store.dart
mason make entity     --module_name <module> --entity_name <name>      # entity.dart
mason make container  --module_name <module> --container_name <name>   # container.dart only
mason make form       --module_name <module> --form_name <name>        # form.dart (freezed)
mason make dto        --module_name <module> --dto_name <name>         # dto.dart (freezed)
```

> Dart SDK >= 3.7.2 required. Mason CLI must be installed globally: `dart pub global activate mason_cli`.

---

## Project Overview

This is a Flutter project enforcing **Clean Architecture** across all feature modules.

Every feature follows a strict layered structure: UI → Controller → UseCase → Gateway → Repository → Store → Presenter → UI. State is managed globally via **MobX**. HTTP calls go through **dio**. Navigation uses **go_router**. DI uses **get_it**. Forms use **reactive_forms** with **freezed** form models. API response shapes use **freezed DTOs**.

---

## Tech Stack

| Concern        | Library                                   |
| -------------- | ----------------------------------------- |
| Language       | Dart                                      |
| State          | MobX + flutter_mobx                       |
| Navigation     | go_router                                 |
| HTTP           | dio                                       |
| DI             | get_it                                    |
| UI Components  | Flutter Material (built-in)               |
| Forms          | reactive_forms                            |
| Form/DTO Models | freezed + json_serializable              |
| Toast          | toastification                            |
| Storage        | flutter_secure_storage                    |
| Bottom Sheet   | Built-in Flutter (showModalBottomSheet)   |
| Logging        | logger                                    |
| Env Config     | envied                                    |
| Code Generator | mason                                     |

---

## Project Structure

```
lib/
├── main.dart                  # Entry: GetIt setup → GoRouter → ToastificationWrapper → MaterialApp.router
├── store.dart                 # Root Store class — add module stores as fields here
└── core/
    ├── config/
    │   ├── env.dart           # Envied config: Env.apiUrl (obfuscated, switches .env.dev/.env.prod)
    │   └── env.g.dart         # Generated — do not edit
    ├── services/
    │   └── api.gateway.dart   # Base ApiGateway extending Api; module gateways extend this
    └── utils/
        ├── api.dart           # Base Api class: wraps dio; all HTTP methods return BaseApiResponse<T>
        ├── api_config.dart    # ApiConfig + defaultApiConfig (reads baseUrl from env.dart)
        ├── base_api_mapped.entity.dart  # Abstract BaseApiMappedEntity<Api, Form>
        ├── logger_util.dart   # LoggerUtil: static d/i/w/e/t log methods
        └── screen_registry.dart  # ScreenNames constants (add route path strings here)

lib/src/
└── <module>/                  # One folder per feature (e.g. auth, profile)
    ├── entities/
    │   ├── <n>.entity.dart    # Extends BaseApiMappedEntity; uses @observable fields + MobX codegen
    │   └── <n>.store.dart     # MobX store: abstract class with Store mixin + codegen
    ├── interfaces/
    │   ├── controllers/<n>.controller.dart   # Receives Store; instantiates use cases
    │   ├── gateways/<n>.repository.dart      # Receives Store; all mutations via runInAction
    │   └── presenters/<n>.presenter.dart     # Receives Store; read-only getters only
    ├── screens/<n>.screen.dart               # StatelessWidget; defines navigation functions
    ├── ui/<component>/
    │   ├── <component>.container.dart        # StatefulWidget; Observer wrapper; wires controller + presenter
    │   └── <component>.view.dart             # Pure UI widget — no store access; accepts typed model
    ├── usecases/<n>/
    │   └── <n>.case.dart      # Business logic; Future<void> execute()
    ├── forms/<n>/
    │   └── <n>.form.dart      # Freezed form model with json_serializable
    └── dtos/<n>/
        └── <n>.dto.dart       # Freezed API response DTO with json_serializable
```

---

## Clean Architecture Data Flow

```
View (pure UI, typed model only)
  ↑ typed props
Container (StatefulWidget + Observer, wires controller + presenter)
  ↓ calls                          ↑ reads
Controller (orchestrates usecases)   Presenter (read-only getters from store)
  ↓ calls                               ↑ reads
UseCase (business logic)             Store (MobX @observable state)
  ↓ calls               ↓ calls          ↑ runInAction writes
ApiGateway (dio HTTP)  Repository (mutates store via runInAction)
```

No layer skips another. Data flows down through calls and up through MobX observables.

---

## Key Conventions

**File creation rule** — always use mason generators (`mason make component`, `mason make screen`, `mason make usecase`, etc.) to scaffold any new feature file. Never hand-write a container, view, screen, use case, controller, presenter, repository, store, or entity file from scratch — run the generator first, then edit the generated output.

**API responses** are always wrapped in `BaseApiResponse<T>`. Use `response.isSuccess()` (checks `statusCode >= 200 && < 300`) as the only success guard — never add `&& response.data.<field>` checks alongside it.

**MobX** stores use the code-gen mixin pattern:

```dart
import 'package:mobx/mobx.dart';
part 'auth.store.g.dart';

class AuthStore = AuthStoreBase with _$AuthStore;

abstract class AuthStoreBase with Store {
  @observable
  bool isLoading = false;

  @observable
  String? error;

  @observable
  bool isSuccess = false;
}
```

Run `melos run build` after creating or modifying a store. All store mutations must go through the Repository layer wrapped in `runInAction(() { ... })`. Never mutate store state outside a Repository.

**Registration checklist** when adding a new screen/module:
1. Add route path constant to `lib/core/utils/screen_registry.dart`
2. Register a `GoRoute` entry in the `_router` in `lib/main.dart`
3. Add the module's store instance as a field on `Store` in `lib/store.dart`

**Store split rule** — one store per module by default. Split into a second store when: (1) the store exceeds ~10 observables, or (2) two distinct feature domains exist in the same module. Name split stores after the feature: `login.store.dart`, `profile.store.dart`.

**Entity file split rule** — never put multiple entities in one file. Each entity gets its own file. Each entity class must extend `BaseApiMappedEntity`, use the `with Store` mixin and code-gen, declare `@observable` properties with default values, and implement `setFromApiModel()` and `setFromFormModel()`. Raw API shapes live in a DTO (`<n>.dto.dart`), not inside the entity file.

**DTO rule** — API response shapes are defined as `freezed` classes with `json_serializable`. DTOs live in `lib/src/<module>/dtos/<n>/<n>.dto.dart`. Generate with `mason make dto`. Always run `melos run build` after creating a DTO.

**Form model rule** — form input shapes are defined as `freezed` classes. Form models live in `lib/src/<module>/forms/<n>/<n>.form.dart`. Generate with `mason make form`. The `FormGroup` definition (with `reactive_forms` validators) lives in the Container — not in the form model file.

**reactive_forms pattern** — the Container creates the `FormGroup` in `initState` and passes it to the View as a prop. The View wraps with `ReactiveForm(formGroup: formGroup, ...)` and uses `ReactiveTextField` / `ReactiveDropdownField` etc. On submit, the View calls an `onSubmit` callback from its props — never calls the controller directly.

```dart
// Container
late final FormGroup _form;

@override
void initState() {
  super.initState();
  _form = FormGroup({
    'email': FormControl<String>(validators: [Validators.required, Validators.email]),
    'password': FormControl<String>(validators: [Validators.required, Validators.minLength(6)]),
  });
}

// View receives: final FormGroup form; final VoidCallback onSubmit;
```

**UseCase store access rule** — use cases must never inject or access a store directly. If a use case needs to read from a store, it must do so through a Repository getter method.

**Single Store parameter rule** — controllers, presenters, and repositories must each accept exactly one parameter: the root `Store` from `lib/store.dart`. Never pass individual module stores as separate constructor arguments. Access the module slice internally via `store.authStore`, `store.profileStore`, etc.

**Controller-to-UseCase rule** — controllers must never call repository methods directly. Every store mutation must be routed through a use case: `Controller → UseCase → Repository → Store`. If no use case exists for an action, create one.

**Controller getter rule** — controllers must never expose getter methods or return data. Controllers only orchestrate use cases. All data reads belong in the Presenter.

**UseCase execute void rule** — `execute()` must always return `Future<void>`. Use cases must never return data to their caller. Write results to the store via the Repository and expose them through the Presenter.

**UseCase injection rule** — never pass a use case as a constructor argument to another use case. If two use cases must run in sequence, the controller calls them one after the other.

**Screen navigation rule** — all `context.go()`, `context.push()`, and `context.pop()` calls must live in the Screen widget. Define `navigateTo<Destination>` functions in the screen and pass them as typed callbacks to the Container. Containers must never call `GoRouter.of(context)` or `context.go`/`context.push` directly.

```dart
class FooScreen extends StatelessWidget {
  const FooScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void navigateToBar() => context.go(ScreenNames.bar);
    void navigateBack() => context.pop();

    return Scaffold(
      body: SafeArea(
        child: FooContainer(
          onNavigateToBar: navigateToBar,
          onBack: navigateBack,
        ),
      ),
    );
  }
}
```

**Container Observer rule** — the Container's `build` method must wrap its return in `Observer(builder: (_) => ...)` from `flutter_mobx`. This ensures reactive rebuilds when MobX observables change.

**Container controller/presenter declaration rule** — every Container is a `StatefulWidget`; its `State` declares `store`, `controller`, and `presenter` as `late final` fields and assigns them in `initState`, in that order (`store` first, since controller/presenter both depend on it):

```dart
class _FooContainerState extends State<FooContainer> {
  late final Store store;
  late final FooController controller;
  late final FooPresenter presenter;

  @override
  void initState() {
    super.initState();
    store = GetIt.instance<Store>();
    controller = FooController(store: store);
    presenter = FooPresenter(store: store);
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => FooView(
        isLoading: presenter.isLoading,
        onSubmit: controller.submit,
      ),
    );
  }
}
```

Rules that apply to this pattern:
- Resolve `Store` from `GetIt.instance<Store>()` — never construct a `Store()` directly or accept it as a widget constructor parameter.
- `controller` and `presenter` are non-nullable `late final` fields, always assigned in `initState`, never lazily created inside `build` or inside the `Observer` builder (re-instantiating them on every rebuild would drop controller-held state such as in-flight use cases).
- Field names are `store`, `controller`, `presenter` — no leading underscore. They're read only within the same `State` class, but the plain name keeps generated code consistent across containers.
- The Container itself must never read `store` fields directly (e.g. `store.authStore.isLoading`) — all reads go through `presenter` getters, all writes go through `controller` methods, per the Single Store parameter rule and Controller getter rule above.
- If a Container also owns a `FormGroup` (see reactive_forms pattern above), declare it as its own `late final` field alongside `store`/`controller`/`presenter` and initialize it in the same `initState`, after `store` is assigned.
- `dispose()` does not need to null these fields out; only close/dispose objects that own resources (e.g. `_form.dispose()` if applicable).

**Single controller/presenter per container rule** — a Container may declare exactly one `controller` field and exactly one `presenter` field, each typed to exactly one Controller class and one Presenter class. Never declare a second controller/presenter, and never call methods or getters from a different module's controller/presenter inside a Container. If a screen needs to orchestrate more than one module's use cases or reads, that composition belongs in the Screen (composing multiple Containers, each with its own single controller/presenter) — not inside one Container. If a single module's Controller or Presenter is growing unwieldy, split the module's use cases/getters further within that same Controller/Presenter rather than adding a second one to the Container.

**Context7** — always use Context7 MCP to fetch current library/API documentation instead of relying on training data. This applies to setup questions, code generation, API references, and anything involving specific packages.
