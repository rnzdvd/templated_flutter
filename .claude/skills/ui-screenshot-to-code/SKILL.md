---
name: ui-screenshot-to-code
description: Convert UI screenshots OR Figma designs into full Flutter screens using Clean Architecture. Trigger on "build this screen", "convert this image", "use this Figma", or when a screenshot is uploaded or a Figma URL is provided.
---

# UI Screenshot to Code

## Phase 0: Input Source

- **Screenshot** → analyze image visually, proceed to Phase 1.
- **Figma URL** → run `figma-mcp-extract` skill first, use its design summary as the spec, then proceed to Phase 1.
- **Both** → Figma is source of truth; screenshot is visual reference only.
- **Neither** → ask the user for one before continuing.

## Phase 1: Environment Alignment

Never create files manually. Always generate via mason — Claude runs these directly, not the user:

```bash
mason make screen    --module_name <module> --screen_name <name>
mason make component --module_name <module> --component_name <name>
```

**Naming rule:** screen and component must share the same base name. If the screen is `login`, the component is also `login`.

Ask for the target module (e.g. `auth`, `profile`) if not already provided.

## Phase 2: UI Analysis

Identify from the screenshot or Figma summary:

- **Bottom navigation bar?** → each tab needs its own `Screen → Container → View`.
- **Tabs inside the screen?** → use `TabBar` or `SegmentedButton` state in Container; no extra screen wrapper.
- **Form inputs?** → use reactive_forms pattern (see Phase 3).
- **Scrollable list?** → `ListView.builder` in the View; pass typed item list as prop.
- **Floating action button, app bar, drawer?** → configure on the `Scaffold` in the Screen.

## Phase 3: Implementation Patterns

**Screen → Container → View rule (always enforced):**

- **Screen** — `StatelessWidget`. Wraps the Container inside a `Scaffold` with `SafeArea`. **All navigation calls belong in the Screen.** Define `navigateTo<Destination>` functions and pass them as typed callbacks to the Container. Register in `screen_registry.dart` and `main.dart` GoRouter after creation.

  ```dart
  class LoginScreen extends StatelessWidget {
    const LoginScreen({super.key});

    @override
    Widget build(BuildContext context) {
      void navigateToHome() => context.go(ScreenNames.home);
      void navigateBack() => context.pop();

      return Scaffold(
        body: SafeArea(
          child: LoginContainer(
            onNavigateToHome: navigateToHome,
            onBack: navigateBack,
          ),
        ),
      );
    }
  }
  ```

- **Container** — `StatefulWidget`. `build` must return `Observer(builder: (_) => ...)`. Instantiates `controller` and `presenter` from `GetIt.instance<Store>()` in `initState`. **Never accesses the store directly** — all state reads go through the Presenter. Handler methods are named class methods, not inline closures.

- **View** — pure `StatelessWidget`. All data via typed props. No store or context access beyond `Theme.of(context)`.

**Function naming:**
- Props callbacks → `on` prefix: `onLogin`, `onSubmit`
- Internal handlers on State class → `_handle` prefix: `_handleLogin`
- Navigation functions in Screen → `navigateTo<Destination>`: `navigateToHome`, `navigateToProfile`

**Bottom Navigation Tabs** — each tab has its own `Screen → Container → View`.

- Check `main.dart` GoRouter for existing shell route / tab structure.
- Use `NavigationBar` (Material 3) or `BottomNavigationBar`.
- Figma: use frame/layer names as route names.

**Inner-Screen Tabs** — `Container → View` only, no extra screen.

- `TabController` in Container `State` or `SegmentedButton` with `setState`.
- Figma: map active/inactive variants to current tab state.

**Data Entry (reactive_forms)** — always use `reactive_forms` for any form with user input.

- **Container** creates the `FormGroup` in `initState` and disposes in `dispose`.
- **Container** passes `formGroup` and `onSubmit` callback to the View.
- **View** wraps with `ReactiveForm` and uses `ReactiveTextField` / `ReactiveDropdownField`.
- Validation messages defined inline on each `ReactiveTextField` via `validationMessages`.
- **UI first rule:** `onSubmit` is always a no-op placeholder. Do NOT wire controller calls or API calls until the user explicitly asks to connect the API.

## Phase 4: Output Requirements

In this order:

1. Run `mason make screen` and `mason make component` using the same `<name>` for both.
2. Fill in the generated scaffold:
   - Screen: `Scaffold` + `SafeArea` + navigation functions + Container.
   - Container: `Observer` wrapper, `controller`/`presenter` in `initState`, handler methods.
   - View: pure UI matching the screenshot/Figma spec pixel-accurately.
3. Use `Theme.of(context)` color and text tokens. No hardcoded hex values.
4. Extract exact values from the Figma summary (spacing, border radius, font sizes).

## UI Component Reference

| Visual Element    | Flutter Widget                                              |
| :---------------- | :---------------------------------------------------------- |
| Headings          | `Text(style: Theme.of(context).textTheme.headlineMedium)`  |
| Buttons           | `ElevatedButton` / `OutlinedButton` / `TextButton`          |
| Text inputs       | `ReactiveTextField` (inside `ReactiveForm`)                 |
| List              | `ListView.builder`                                          |
| Loading indicator | `CircularProgressIndicator`                                 |
| Bottom nav        | `NavigationBar` or `BottomNavigationBar`                    |
| Tab bar           | `TabBar` + `TabBarView` or `SegmentedButton`                |
| App bar           | `AppBar` on `Scaffold`                                      |
| Avatar / image    | `CircleAvatar` / `Image.network`                            |
| Icon              | `Icon(Icons.xxx)`                                           |
