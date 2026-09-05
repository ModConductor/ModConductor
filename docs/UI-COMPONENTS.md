# Desktop components

`ui/packages/mc_ui_foundation` contains the components that Welcome and Preferences
share. The app owns navigation, preference drafts and status selection. The
foundation does not import app features or engine policy.

| Contract | Actual consumers | Shared behavior |
| --- | --- | --- |
| `mcTheme`, `McSpacing` | Welcome; Preferences | Colors, Roboto fonts, spacing, control styles and light/dark themes |
| `McPage`, `McSection` | Welcome; Preferences | Page headings, scrollable content and sections |
| `McChoice<T>` | Welcome theme; Preferences theme/text size | Typed values, labels, keyboard selection and SDK field semantics |
| `McAction` | Welcome actions; Preferences actions | SDK buttons, emphasis, focus and enabled state |
| `McStatus` | Welcome connection/save state; Preferences save state | Text and icon status that does not rely on color |

The active-preferences comparison dialog is private to Preferences. It is available
when a draft differs from the active values.

The app's shell, pages and preference state are private to its Dart library.
`DesktopStatus` is a presentation input consumed by shell composition. Production
starts with `DesktopDisconnected`. Tests inject `DesktopFailure` to check that
Preferences and Quit remain usable. This does not detect or recover from real
startup or engine failures. There is no error selector in the production app.

## Controls

- **Alt+1** opens Welcome.
- **Alt+2** or **Ctrl+,** opens Preferences.
- **Ctrl+Q** or **Quit** requests native application exit.
- **Tab** and **Shift+Tab** move focus. **Enter** activates a focused control.
- **Escape** closes a detail dialog and returns focus to its control.

Preference drafts remain when the user changes pages or resizes the window.
**Apply** updates the current appearance and text size. **Cancel** restores the
active values. Welcome's appearance control updates the active theme immediately.
The app does not save preferences after exit. System appearance follows the
platform until the user selects Light or Dark.

The [build guide](BUILDING.md) includes workspace checks and native bundle paths.
The seven app interaction checks cover both consumers. Native platform checks
remain necessary for window behavior and the actual Quit route.
