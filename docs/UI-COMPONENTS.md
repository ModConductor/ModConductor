# Desktop components

`ui/packages/mc_ui_foundation` owns the shared visual controls. `mc_workspaces` owns workspace presentation and forms. The app owns navigation and appearance drafts. The foundation does not import features or engine policy.

| Contract | Actual consumers | Shared behavior |
| --- | --- | --- |
| `mcTheme`, `McSpacing` | Workspaces; Preferences; design preview | Colors, bundled Roboto, spacing and light/dark themes |
| `McPage`, `McSection` | Workspace entry; profiles; Preferences | Headings, scrolling and sections |
| `McChoice<T>` | Preferences theme and text size | Typed values, keyboard selection and SDK semantics |
| `McAction` | Workspace actions; profile actions; Preferences; dialogs | SDK buttons, emphasis, focus and enabled state |
| `McStatus` | Workspace failure/recovery; Preferences; connection error | Text and icon status without color-only meaning |
| `McFormDialog` | Workspace create/open; profile create/clone/rename/delete; preview | Scrollable SDK dialog, cancel, submit and focus restoration |
| `McNameField`, `McNameDialog` | Workspace name; profile create/clone/rename; preview | Display-name input, validation and submission |
| `WorkspaceDialog` | Create workspace; Open workspace | Native directory chooser, cancel and full selected path |
| Profile row | Every loaded profile, including selected profile outside the current page | Selection, scoped menu and selected indicator |

The preview imports the production forms rather than retaining a second toolbox. Its folder list is a simulation only. Production uses the native directory chooser. [Workspace behavior](WORKSPACES.md) describes actual saved state and recovery.

`DesktopHost` owns the process lifecycle through `mc_client`. `WorkspaceController` consumes its typed client and ignores stale completions from an old connection. Leaving a page does not cancel an accepted mutation. No widgets or page state live in the transport library.

## Controls

- **Alt+1** opens Workspaces.
- **Alt+2** or **Ctrl+,** opens Preferences.
- **Ctrl+Q** or **Quit** requests native application exit.
- **Tab** and **Shift+Tab** move focus. **Enter** activates a focused control.
- **Escape** closes a dialog and returns focus to its control.

Preference drafts remain when you change pages or resize the window. **Apply** updates the current appearance and text size. **Cancel** restores active values. The header's appearance control changes the theme immediately. Appearance preferences are not saved after exit.

The active-preferences comparison dialog remains private to Preferences. Native window behavior and folder selection require actual platform checks, not only widget tests. [Build commands](BUILDING.md) include the shared packages.
