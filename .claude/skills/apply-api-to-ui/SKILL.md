---
name: apply-api-to-ui
description: Wire a real API endpoint to an existing UI using Clean Architecture. Use for: "connect API", "fetch real data", "integrate backend", or "replace mocks".
---

# API Integration Skill

## Phase 1: Dependency Mapping & Generation

**Rule:** Never write files from scratch. Always generate via mason — Claude runs these directly, not the user:

```bash
mason make usecase    --module_name <module> --usecase_name <name>
mason make dto        --module_name <module> --dto_name <name>
mason make entity     --module_name <module> --entity_name <name>
mason make store      --module_name <module> --store_name <module>
mason make repository --module_name <module> --repository_name <name>
mason make controller --module_name <module> --controller_name <name>
mason make presenter  --module_name <module> --presenter_name <name>
```

After generating any store, DTO, form, or entity, always run:
```bash
melos run build
```

1. **Identify Missing Layers:** Search `lib/src/<module>/` for: `entity`, `store`, `controller`, `repository`, `gateway`, `presenter`, `usecase`.
2. **Generate** the required mason commands for any missing layer.
   - **Gateway rule:** Each module has its own gateway class extending `ApiGateway` from `lib/core/services/api.gateway.dart`. There is no mason brick for gateways — create `lib/src/<module>/interfaces/gateways/<module>.gateway.dart` manually by extending `ApiGateway`.
   - **Store rule:** The store is module-scoped and named after the module (e.g., `auth.store.dart` / `AuthStore`). If `lib/src/<module>/entities/<module>.store.dart` already exists, **do not generate a new one** — add new observables to the existing store instead.
   - **Store registration:** Add the store as a field on the root `Store` in `lib/store.dart` (e.g., `final AuthStore authStore = AuthStore()`).
   - **Observable naming:** Since one store serves multiple features, prefix observable names with the feature (e.g., `loginIsLoading` not `isLoading`) to avoid collisions.
3. **Read base classes** before implementing to ensure correct inheritance:
   - `lib/core/utils/api.dart`
   - `lib/core/utils/base_api_mapped.entity.dart`
   - `lib/core/services/api.gateway.dart`

## Phase 2: API Contract Definition

1. **Define the DTO:** Generate with `mason make dto` and fill in the `@JsonKey`-annotated fields matching the API response shape. DTOs use `snake_case` JSON keys (configured in `build.yaml`). Always run `melos run build` after.
2. **Update the module Gateway:** Add a typed method using `this.get`, `this.post`, etc. from the base `Api` class.

```dart
// lib/src/auth/interfaces/gateways/auth.gateway.dart
class AuthGateway extends ApiGateway {
  AuthGateway({required super.store});

  Future<BaseApiResponse<LoginResponseDTO>> login(LoginFormModel form) {
    return post<LoginResponseDTO>(
      '/auth/login',
      data: {'email': form.email, 'password': form.password},
      fromJson: LoginResponseDTO.fromJson,
    );
  }
}
```

## Phase 3: Layer Implementation

For each generated file, follow these rules:

- **DTO:** One DTO per API response shape. Use `@freezed` with `json_serializable`. Fields map snake_case API → camelCase Dart via `build.yaml` `field_rename: snake`. Never put multiple DTOs in one file.

- **Entity:** One entity per file. Extend `BaseApiMappedEntity<TDto, TFormModel>` and use the MobX code-gen mixin pattern. Declare `@observable` public properties with default values. Implement `setFromApiModel(dto)` mapping DTO fields to observables.

  ```dart
  class UserEntity = UserEntityBase with _$UserEntity;

  abstract class UserEntityBase extends BaseApiMappedEntity<UserDTO, UserFormModel> with Store {
    @observable
    String id = '';

    @observable
    String name = '';

    @override
    void setFromApiModel(UserDTO data) {
      id = data.id;
      name = data.name;
    }
  }
  ```

- **Store:** Module-scoped. Add feature-prefixed observables (e.g., `loginIsLoading`, `loginError`). Must be registered in `lib/store.dart`. If the store already exists, add new observables — do not create a second store.

- **Repository:** Constructor accepts exactly one parameter: `Store store` from `lib/store.dart`. Access the module slice via `store.authStore`. Wrap all mutations in `runInAction(() { ... })`. Create setter methods: `setX(data)`, `setIsLoading(bool)`, `setError(String?)`, `clearError()`. Add getter methods (e.g., `getSelectedTopicId()`) when a UseCase needs to read from the store.

  ```dart
  class AuthRepository {
    final Store _store;

    AuthRepository({required Store store}) : _store = store;

    void setIsLoading(bool value) =>
        runInAction(() => _store.authStore.loginIsLoading = value);

    void setError(String? message) =>
        runInAction(() => _store.authStore.loginError = message);

    void clearError() => setError(null);

    void setUser(UserEntity user) =>
        runInAction(() => _store.authStore.user = user);
  }
  ```

- **UseCase:** Never inject or access a store directly — all store reads must go through a Repository getter. Wrap body in `try/catch/finally`. Pattern: (1) `setIsLoading(true)`; (2) call gateway; (3) check `response.isSuccess()` — **this is the only success check; never add `&& response.data.<field>`**; (4) if success: map DTO to Entity, call `repository.setX()`; (5) if fail: call `repository.setError('Something went wrong')`; (6) `setIsLoading(false)` in `finally`. **Never call `showToast` here** — toasts belong in the Container.

  ```dart
  class LoginCase {
    final AuthRepository _repository;
    final AuthGateway _gateway;

    LoginCase({required AuthRepository repository, required AuthGateway gateway})
        : _repository = repository,
          _gateway = gateway;

    Future<void> execute(LoginFormModel form) async {
      try {
        _repository.setIsLoading(true);
        final response = await _gateway.login(form);
        if (response.isSuccess()) {
          final user = UserEntity()..setFromApiModel(response.data!);
          _repository.setUser(user);
          _repository.setIsSuccess(true);
          _repository.clearError();
        } else {
          _repository.setError('Something went wrong');
          _repository.setIsSuccess(false);
        }
      } catch (_) {
        _repository.setError('Something went wrong');
      } finally {
        _repository.setIsLoading(false);
      }
    }
  }
  ```

- **Controller:** Constructor accepts exactly one parameter: `Store store`. Instantiate Repository, Gateway, and UseCases internally. Expose action methods only — **never expose getters or return data**; all data reads belong in the Presenter. **Never call repository methods directly** — every action must go through a use case.

  ```dart
  class AuthController {
    late final LoginCase _loginCase;

    AuthController({required Store store}) {
      final repository = AuthRepository(store: store);
      final gateway = AuthGateway(store: store);
      _loginCase = LoginCase(repository: repository, gateway: gateway);
    }

    Future<void> login(LoginFormModel form) async {
      await _loginCase.execute(form);
    }
  }
  ```

- **Presenter:** Constructor accepts exactly one parameter: `Store store`. Expose read-only getters accessing `store.<moduleStore>.*`.

  ```dart
  class AuthPresenter {
    final Store _store;

    AuthPresenter({required Store store}) : _store = store;

    bool get isLoading => _store.authStore.loginIsLoading;
    String? get errorMessage => _store.authStore.loginError;
    bool get isSuccess => _store.authStore.loginIsSuccess;
  }
  ```

## Phase 4: UI Wiring

- **Container:** Get `store` from `GetIt.instance<Store>()`. Instantiate `controller` and `presenter` in `initState`. Wrap `build` return in `Observer(builder: (_) => ...)`. Handler functions must be defined as class methods (not inside `Observer` builder) so they are not recreated on each rebuild. After `await controller.x()`, read outcome via `presenter.isSuccess` / `presenter.errorMessage` and show a toast here — not in the UseCase. **Never read from the store directly in a Container** — always go through the Presenter.

  ```dart
  Future<void> _handleLogin() async {
    if (!_form.valid) return;
    await controller.login(LoginFormModel.fromJson(_form.value));
    if (presenter.isSuccess) {
      widget.onNavigateToHome?.call();
    } else {
      Toastification().show(
        context: context,
        type: ToastificationType.error,
        title: Text(presenter.errorMessage ?? 'Error'),
      );
    }
  }
  ```

- **View:** Add `isLoading` to its props model and show a loading indicator. For form submissions, disable the submit button when `isLoading` is true.

### Function naming convention

| Location                              | Prefix                    | Example                               |
| ------------------------------------- | ------------------------- | ------------------------------------- |
| Passed as a prop to a child widget    | `on`                      | `onLogin`, `onDelete`, `onSubmit`     |
| Internal handler (not a prop)         | `_handle`                 | `_handleLogin`, `_handleDelete`       |
| Navigation function in a Screen       | `navigateTo<Destination>` | `navigateToHome`, `navigateToProfile` |

## Phase 5: Mock Data Cleanup

**Gate:** Only remove mock data once the API is confirmed wired and working end-to-end. Never delete mock data speculatively or as part of implementing the wiring itself.

1. **Verify first, then clean up.** Treat wiring as "successfully implemented" only when all of the following hold:
   - `flutter analyze` passes with no new errors on the touched files.
   - `melos run build` completed without error if a store/DTO/form/entity changed.
   - The Container calls the real `controller` method and reads results via the real `presenter` getters (not a stubbed/local value).
   - The data flow traces cleanly: Gateway → UseCase → Repository → Store → Presenter → Container → View, with no remaining shortcut back to a mock.
   - Ideally, the flow has been run (`flutter run` / existing test) and observed to load real data — if that can't be verified, say so explicitly rather than assuming success.
2. **Locate mock data tied to this feature.** Search only within the module(s) just wired — hardcoded lists/maps in the View or Container, `Future.delayed` fake-latency stubs, static fixture files, dummy default values on entities that exist solely to simulate the API, or commented-out real calls left behind from a mock phase.
3. **Remove only what the real API now replaces.** Delete the mock data source and any now-dead imports/helpers it needed. Do not touch:
   - Mock data belonging to other, still-unwired features.
   - Fallback/default values on entities that are legitimate initial state (e.g., `bool isLoading = false`), not simulated API data.
   - Fixtures used by tests, unless the test itself is being updated to hit the real flow.
4. **If verification fails or is inconclusive,** leave the mock data in place, report which check failed, and stop — do not remove mocks "optimistically" while wiring is still uncertain.

---

## Checklist for Claude

- [ ] No direct store access from View, Controller, or Container — all state reads go through the Presenter.
- [ ] All business logic stays in the UseCase.
- [ ] UseCase success check uses `response.isSuccess()` only — no `&& response.data.<field>` checks.
- [ ] UseCase never calls `showToast` — toast notifications go in the Container.
- [ ] Controller methods return `Future<void>` — never return data from a controller.
- [ ] Container reads outcome via `presenter.isSuccess` / `presenter.errorMessage` after awaiting the controller.
- [ ] Each entity is in its own file; API response shapes live in a DTO file, not inside entity files.
- [ ] MobX code-gen pattern (`= XBase with _$X`) is used for stores and entities that need observables.
- [ ] `melos run build` was run after creating/modifying any store, DTO, form, or entity.
- [ ] Repository, Controller, and Presenter each take exactly one constructor parameter: `Store store`.
- [ ] UseCase never injects a store directly — reads go through Repository getter methods.
- [ ] Controller never calls repository methods directly — every mutation routes through a use case.
- [ ] Controller exposes no getters and returns no data — data reads belong in the Presenter.
- [ ] Props callbacks use `on` prefix; internal handlers use `_handle` prefix.
- [ ] Navigation functions in Screens use `navigateTo<Destination>` prefix.
- [ ] Mock data for this feature is removed only after confirming: `flutter analyze` passes, codegen ran if needed, and the Container/View demonstrably read real data through Controller → Presenter.
- [ ] Mock data belonging to other unwired features, legitimate default state, and test fixtures were left untouched.
- [ ] If wiring could not be verified as working, mock data was left in place and the blocker was reported instead of removing it speculatively.
