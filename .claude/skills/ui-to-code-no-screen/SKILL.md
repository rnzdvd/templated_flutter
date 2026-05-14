---
name: ui-to-code-no-screen
description: Build modals, bottom sheets, dialogs, or inline components (Container + View only) from screenshots or Figma designs. Trigger on: "create a modal", "build a bottom sheet", "make a popup", "add a dialog", Figma URL provided, or when UI is an overlay/partial screen.
---

# UI to Code — No Screen

## Phase 0: Input Source

- **Screenshot** → analyze image visually, proceed to Phase 1.
- **Figma URL** → run `figma-mcp-extract` skill first, use its design summary as the spec, then proceed to Phase 1.
- **Both** → Figma is source of truth; screenshot is visual reference only.
- **Neither** → ask the user for one before continuing.

## Phase 1: Alignment

Never create files manually. Always generate via mason — Claude runs this, not the user:

```bash
mason make component --module_name <module> --component_name <name>
```

**Naming rule:** the component name should match the feature name — no suffixes like `-form` or `-modal`. If the feature is `login`, the component is `login`.

After generation, fill in the scaffolded container and view files.

**Container → View rule:**

- **Container** — `StatefulWidget`. `build` wraps return in `Observer(builder: (_) => ...)`. Owns form state (`FormGroup`) and triggers overlay display. **Never accesses the store directly** — all state reads must go through the Presenter. Handler methods are named class methods on the `State`, not inline closures.
- **View** — pure `StatelessWidget`. No store access; all data via typed props.

**Function naming:**
- Props callbacks → `on` prefix: `onSubmit`, `onDismiss`
- Internal handlers → `_handle` prefix: `_handleSubmit`

## Phase 2: Form Detection

**Has form inputs?** → always use `reactive_forms`. Never use `TextEditingController` directly for form fields.

- **Container** creates `FormGroup` in `initState` and disposes in `dispose`:

  ```dart
  late final FormGroup _form;

  @override
  void initState() {
    super.initState();
    _form = FormGroup({
      'email': FormControl<String>(validators: [Validators.required, Validators.email]),
    });
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }
  ```

- **Container** passes `_form` and `onSubmit` callback to the View.
- **View** wraps with `ReactiveForm` and uses `ReactiveTextField`.
- **UI first rule:** set `onSubmit: () {}` as a no-op. Do NOT wire controller calls or API calls until the user explicitly asks to connect the API.

## Phase 3: Pattern Selection

**Standard Bottom Sheet** — triggered by the parent Container:

```dart
void _showBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(24),
      child: MyBottomSheetView(onSubmit: _handleSubmit),
    ),
  );
}
```

**Draggable Bottom Sheet** — for resizable content:

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (_) => DraggableScrollableSheet(
    initialChildSize: 0.5,
    minChildSize: 0.25,
    maxChildSize: 0.9,
    expand: false,
    builder: (_, controller) => MyView(scrollController: controller),
  ),
);
```

**Alert Dialog:**

```dart
void _showDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Title'),
      content: const MyDialogView(),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _handleConfirm, child: const Text('Confirm')),
      ],
    ),
  );
}
```

**Inline Tabs / Segmented Control:**

```dart
SegmentedButton<String>(
  segments: const [
    ButtonSegment(value: 'tab1', label: Text('Tab 1')),
    ButtonSegment(value: 'tab2', label: Text('Tab 2')),
  ],
  selected: {_activeTab},
  onSelectionChanged: (values) => setState(() => _activeTab = values.first),
)
```

## Phase 4: Implementation Rules

- **Presenter-only store access** — Containers must never read from the store directly. Always use the Presenter. If a getter is missing, add it to the Presenter before wiring the Container.
- **View** — no store access; data via typed props only.
- **No hardcoded colors** — use `Theme.of(context)` tokens.
- **Spacing** — use `const EdgeInsets` and `SizedBox` — no magic numbers without context.

## Output Checklist

- [ ] `mason make component` command was run first.
- [ ] Container is a `StatefulWidget` with `Observer` in its `build`.
- [ ] View is a pure `StatelessWidget` with typed props.
- [ ] Parent usage snippet included (showing how to trigger the overlay).
- [ ] Form fields use `ReactiveTextField` inside `ReactiveForm` (if applicable).
