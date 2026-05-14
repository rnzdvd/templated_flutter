---
name: ui-from-description
description: Build Flutter screens or components from a text description — no screenshot or Figma URL required. Trigger on "create a screen", "create a form", "create a component", "build a UI", or any UI request that has no image or Figma link attached.
---

# UI from Description

## Phase 0: Clarify Intent

Before generating any files, confirm these two things if not already clear from the user's message:

1. **Module** — which feature folder does this belong to? (e.g. `auth`, `profile`, `dashboard`). Ask if not stated.
2. **Scope** — is this a full screen or a component/modal/overlay?
   - Full screen → uses `Screen → Container → View` pattern.
   - Component / modal / bottom sheet / inline UI → uses `Container → View` pattern only.

Do not generate files until both are known.

## Phase 1: Scaffold via Mason

Never create files manually. Always generate via mason — Claude runs these directly, not the user:

**Naming rule:** screen and component must share the same base name. If the screen is `login`, the component is also `login`.

**Full screen:**
```bash
mason make screen    --module_name <module> --screen_name <name>
mason make component --module_name <module> --component_name <name>
```

**Component / modal only:**
```bash
mason make component --module_name <module> --component_name <name>
```

Run the commands, then fill in the scaffolded files with the actual implementation.

## Phase 2: Layout Detection

Read the user's description and identify the layout pattern:

- **Form inputs present?** → use reactive_forms + freezed pattern (see Phase 3).
- **Tabs inside the screen?** → `TabBar` / `SegmentedButton` state in Container to toggle views.
- **List of items?** → use `ListView.builder` or `ListView.separated` in the View; pass `items` as a prop.
- **Modal / bottom sheet / dialog?** → see Phase 4 overlay patterns.
- **Mixed (e.g. list + form)?** → combine patterns.

## Phase 3: Implementation Patterns

### Screen → Container → View (full screen)

- **Screen** — `StatelessWidget`. Wraps the Container in a `Scaffold` with `SafeArea`. All navigation calls (`context.go`, `context.push`, `context.pop`) live here — define `navigateTo<Destination>` functions and pass them as typed callback props to the Container. Register in `screen_registry.dart` and `main.dart` GoRouter after creation.

  ```dart
  class LoginScreen extends StatelessWidget {
    const LoginScreen({super.key});

    @override
    Widget build(BuildContext context) {
      void navigateToHome() => context.go(ScreenNames.home);

      return Scaffold(
        body: SafeArea(
          child: LoginContainer(onNavigateToHome: navigateToHome),
        ),
      );
    }
  }
  ```

- **Container** — `StatefulWidget`. Wraps its `build` return in `Observer(builder: (_) => ...)`. Instantiates `controller` and `presenter` from `GetIt.instance<Store>()` in `initState`. **Never reads from the store directly** — all state reads go through the Presenter. Handler methods are class methods (not inside `Observer` builder).

- **View** — pure `StatelessWidget`. All data via a typed model class (e.g., `LoginViewModel`) passed as a constructor param. No store access.

### Container → View (component / modal)

- **Container** — same Observer pattern. Owns `FormGroup` lifecycle if the component has a form.
- **View** — pure `StatelessWidget` with typed props.

### Handler placement rule

Define handler methods as named class methods on the `State` class — not inline inside `Observer(builder: (_) => ...)` — so they are not recreated on each rebuild.

### Function naming convention

- **Props callbacks** (passed to a child widget) → `on` prefix: `onLogin`, `onDelete`, `onSubmit`
- **Internal handlers** (not passed as props) → `_handle` prefix: `_handleLogin`, `_handleDelete`
- **Navigation functions in a Screen** → `navigateTo<Destination>` prefix: `navigateToHome`, `navigateToProfile`

### Data Entry (reactive_forms)

Always use `reactive_forms` for any form with user input. Never use `TextEditingController` directly for form fields.

- **Container** creates the `FormGroup` in `initState` and disposes it in `dispose`:

  ```dart
  late final FormGroup _form;

  @override
  void initState() {
    super.initState();
    _form = FormGroup({
      'email': FormControl<String>(validators: [Validators.required, Validators.email]),
      'password': FormControl<String>(validators: [Validators.required, Validators.minLength(6)]),
    });
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }
  ```

- **Container** passes `_form` and an `onSubmit` callback to the View.

- **View** wraps with `ReactiveForm` and uses `ReactiveTextField`:

  ```dart
  ReactiveForm(
    formGroup: widget.form,
    child: Column(
      children: [
        ReactiveTextField<String>(
          formControlName: 'email',
          decoration: const InputDecoration(labelText: 'Email'),
          validationMessages: {
            ValidationMessage.required: (_) => 'Required',
            ValidationMessage.email: (_) => 'Enter a valid email',
          },
        ),
        ReactiveTextField<String>(
          formControlName: 'password',
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
          validationMessages: {
            ValidationMessage.required: (_) => 'Required',
            ValidationMessage.minLength: (_) => 'Min 6 characters',
          },
        ),
        ElevatedButton(
          onPressed: widget.onSubmit,
          child: const Text('Login'),
        ),
      ],
    ),
  )
  ```

- **UI first rule:** `onSubmit` is always a no-op placeholder. Do NOT wire controller calls or API calls until the user explicitly asks to connect the API.

## Phase 4: Overlay Patterns (component scope only)

**Standard Bottom Sheet** — call from Container using built-in Flutter:

```dart
void _showBottomSheet() {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const MyBottomSheetView(),
  );
}
```

**Standard Dialog:**

```dart
void _showDialog() {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Title'),
      content: const MyDialogView(),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Confirm')),
      ],
    ),
  );
}
```

**Draggable Bottom Sheet** — for resizable sheets:

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (_) => DraggableScrollableSheet(
    initialChildSize: 0.5,
    minChildSize: 0.25,
    maxChildSize: 0.9,
    expand: false,
    builder: (_, controller) => MyBottomSheetView(scrollController: controller),
  ),
);
```

**Tabs / Segmented Control:**

```dart
// Container manages active tab state
SegmentedButton<String>(
  segments: const [
    ButtonSegment(value: 'tab1', label: Text('Tab 1')),
    ButtonSegment(value: 'tab2', label: Text('Tab 2')),
  ],
  selected: {_activeTab},
  onSelectionChanged: (values) => setState(() => _activeTab = values.first),
)
```

## Phase 5: Rules

- **Presenter-only store access** — Containers must never read from the store directly. Always use the Presenter. If a Presenter getter is missing, add it before wiring the Container.
- **No inline styles** — use `Theme.of(context)` color tokens and `TextStyle` from the theme. Avoid hardcoded hex colors.
- **New screen** — after creating, register the route in `lib/core/utils/screen_registry.dart` and add a `GoRoute` to `lib/main.dart`.

## UI Component Reference

| Visual Element    | Flutter Widget                                          |
| :---------------- | :------------------------------------------------------ |
| Headings          | `Text('...', style: Theme.of(context).textTheme.headlineMedium)` |
| Body text         | `Text('...', style: Theme.of(context).textTheme.bodyMedium)` |
| Contained button  | `ElevatedButton`                                        |
| Outlined button   | `OutlinedButton`                                        |
| Text button       | `TextButton`                                            |
| Text inputs       | `ReactiveTextField` (inside ReactiveForm)               |
| Inline error      | Built-in `validationMessages` on `ReactiveTextField`    |
| List              | `ListView.builder` / `ListView.separated`               |
| Tab toggle        | `SegmentedButton`                                       |
| Dialog            | `showDialog` + `AlertDialog`                            |
| Bottom sheet      | `showModalBottomSheet`                                  |
| Loading indicator | `CircularProgressIndicator`                             |
