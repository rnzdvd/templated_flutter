---
name: figma-mcp-extract
description: Extract and convert Figma design data into Flutter-ready properties using the Figma MCP tool. Trigger this skill whenever a Figma URL is provided alongside any code generation task (screen, component, modal, etc.). Used as a shared base by ui-screenshot-to-code and ui-to-code-no-screen skills.
---

# Figma MCP Extract

## Phase 1: Validate Input

- Confirm URL contains `figma.com/file/` or `figma.com/design/`.
- If a specific node/frame is needed, ask the user to share the node link (right-click frame → Copy link in Figma).
- If no URL is provided, skip this skill entirely.

## Phase 2: Fetch via Figma MCP

Use the Figma MCP tool to fetch the target frame or component. Extract:

| Figma Property                             | Extract As                                                                    |
| ------------------------------------------ | ----------------------------------------------------------------------------- |
| Layer / component name                     | Widget class name, variable name                                              |
| Auto layout direction                      | `Row` (horizontal) or `Column` (vertical)                                    |
| Item spacing (gap)                         | `SizedBox(width: N)` between children in Row / `SizedBox(height: N)` in Column |
| Padding                                    | `Padding(padding: EdgeInsets.all(N))` / `EdgeInsets.symmetric(...)`          |
| Corner radius                              | `BorderRadius.circular(N)`                                                   |
| Fill color                                 | Map to `Theme.of(context)` color token or project color constant             |
| Stroke                                     | `Border(...)` via `BoxDecoration`                                             |
| Opacity                                    | `Opacity(opacity: N)` or `Color.withOpacity(N)`                              |
| Drop shadow                                | `BoxShadow(color, blurRadius, offset)` in `BoxDecoration`                    |
| Font size                                  | `TextStyle(fontSize: N)`                                                     |
| Font weight (Regular/Medium/SemiBold/Bold) | `FontWeight.w400` / `w500` / `w600` / `w700`                                 |
| Line height                                | `TextStyle(height: N / fontSize)` (Flutter uses ratio, not px)               |
| Frame width — fixed                        | `SizedBox(width: N)` or `ConstrainedBox`                                     |
| Frame width — fill container               | `Expanded` or `double.infinity` width                                        |
| Frame width — hug contents                 | No explicit size (let widget intrinsically size)                             |
| Component variants                         | Map to widget props / conditional rendering                                  |

> **Spacing:** Figma `px` maps 1:1 to Flutter logical pixels (`dp`). No conversion needed.

## Phase 3: Color Matching

- Match every extracted fill to the nearest `Theme.of(context)` color token (e.g., `colorScheme.primary`, `colorScheme.surface`, `colorScheme.onBackground`).
- If the project has a custom color constants file, match to that instead.
- If no match exists → **flag it to the user** and ask before proceeding. Never use raw hex codes.

## Phase 4: Typography Mapping

Flutter uses a `TextTheme` with named styles. Map Figma text styles to the nearest theme variant:

| Figma style (approx)   | Flutter TextTheme token      |
| ---------------------- | ---------------------------- |
| Large heading (32+)    | `displayMedium`              |
| Section heading (24)   | `headlineMedium`             |
| Card title (20)        | `titleLarge`                 |
| Subtitle (16, medium)  | `titleMedium`                |
| Body text (14–16)      | `bodyLarge` / `bodyMedium`   |
| Caption / label (12)   | `labelMedium`                |

Use `Theme.of(context).textTheme.headlineMedium` — never hardcode `TextStyle(fontSize: 24)`.

## Phase 5: Output a Design Summary

Before handing off to the screen or component skill, output a brief summary:

```
Frame: <name>
Layout: <Row|Column>, gap: N, padding: N
Colors: { background: colorScheme.X, text: colorScheme.Y, ... }
Typography: { style: textTheme.X, fontSize: N (reference only), fontWeight: wN }
Border: BorderRadius.circular(N)
Shadows: BoxShadow(blurRadius: N, offset: Offset(x, y))
Components detected: [list of Figma component instances]
Variants: [list if any]
Unmatched colors: [hex values to review]
```

This summary becomes the input spec for the next skill (`ui-screenshot-to-code` or `ui-to-code-no-screen`).
