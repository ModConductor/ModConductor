# Desktop components

## Ownership

`mc_ui_foundation` owns themes, typography, spacing, actions, fields, dialogs, and
status controls. It does not import feature clients or engine policy.

`mc_ui_collections` owns typed collection models, virtual table/tree rendering,
display filters, sorting, selection, and keyboard navigation. IDs come from the
consumer. Immutable row values and explicit callbacks replace dynamic feature maps.
Nonstructural deltas update cached rows without recalculating the visible list.

`mc_workspaces` owns workspace/profile forms, lifecycle state, and the profile
collection. `mc_mod_library` owns inventory, profile selection, and saved-version
presentation, category forms, and query state. Its profile controller applies
revision-pinned queries after selection changes. The query cache keeps matching,
context, and inspected rows separate. The library controller retains metadata
actions and pinned file state. `mc_game_contexts` owns the installation form, context controller, and evidence
view. Steam and Proton choosers edit the outer installation draft; only Save
commits it. Their searches are cancelable session state, and late results cannot
replace a newer choice. The app
binds these libraries to `mc_client` and owns global navigation and appearance.

Use the foundation's actions, menus, statuses, and name fields instead of
reproducing their styles. `McDialog` owns the modal shell and a single Close
action. `McFormDialog` uses that shell for Cancel and Submit forms. `McPage` provides a scrollable document layout.
Collections need bounded height and must not sit inside an unbounded page scroll.

## Collection behavior

Row selection is presentation state. **Use profile** changes the current profile.
Selecting a mod does not enable it. Display sorting does not change precedence.

Profiles, installed mods, and saved files use `McCollection`. Consumers supply
columns and typed row IDs. File node IDs include the pinned version and original
path components. Arrival of another page does not replace selection or focus.
A hidden or temporarily unloaded selected ID remains selected until explicit
removal. Actions require a currently available row.

Local file, profile, and category filters use **Filter loaded** labels when pages
are incomplete. Installed-mod filters query the engine, not cached labels. They
keep the typed query and reject old responses after text, view, or sort changes.
Their footer distinguishes matches from loaded rows and context. A failed continuation
preserves prior rows and offers Retry. Canceling a load invalidates its late reply.
It does not cancel a committed engine operation. Saved files remain pinned until
the user selects another mod, saves a version, or opens the latest version.

The narrow layout provides a pane selector. Each pane retains its model and
scroll state. File rows support expansion with Left/Right. Up/Down, Home/End, and
Page Up/Page Down move selection within the visible rows. Enter or Space selects
or expands a row. Multi-selection keeps a stable set separate from the inspected
row. Ctrl-click and Ctrl+Space toggle membership. Shift-click and Shift navigation
select a range. The optional **Select multiple** mode supports pointer-only use.
Ctrl+Up/Down invokes the same profile move as the arrow buttons. These actions
are unavailable in a name-sorted or grouped view. **Show priority** restores the saved-order
view. Checkboxes change one mod. **Enable** and **Disable** target the selected
set, including explicitly counted hidden selections. Row semantics expose selection, focus, and expansion.

Category assignment, category filtering, and category management reuse one tree
picker. The picker searches raw loaded labels while visibly marking missing and
whitespace-only labels. Assignment inside mod details remains a local draft until
the outer **Save**. Category management commits each command and has **Close**,
not a session-wide Cancel. Filter controls remain behind **Filters**.

The collection supports externally supplied filter text, sort callbacks, and a
stable-ID visibility set. These are presentation inputs, not matching policy.
Optional visual titles, node icons, and expander placement preserve default file
and profile behavior. Decorative icons do not add semantic names.

## Global controls

- **Alt+1** opens Workspaces.
- **Alt+2** or **Ctrl+,** opens Preferences.
- **Ctrl+Q** or **Quit** requests native application exit.
- **Tab** and **Shift+Tab** move focus. **Escape** dismisses a dialog unless an accepted Save is still in progress.

Preference drafts remain across navigation and resize. **Apply** updates the
current appearance and text size. **Cancel** restores active values. Appearance
preferences are not saved after exit.

See [Architecture](ARCHITECTURE.md) for state ownership and
[Build instructions](BUILDING.md) for component and native checks.

## Game selection

The workspace's Game mode retains the Profiles and Mods views. The installation
form uses `McFormDialog`, the shared folder action, and inline errors. Save
validates and commits without a separate Check step. Cancel closes an unsubmitted draft without changing the binding.
The app requests folder selection. The standard Windows picker can still expose
file actions; it is not a read-only sandbox.

`McFormDialog.canCancel` defaults to true. The installation form disables dismissal
while Save is in progress, then restores it on failure. A stale form preserves
its folder draft and shows the current saved path after Reload. Change restores
focus when the dialog closes. Refresh checks the saved installation. On first
attachment in an engine session,
a saved binding from a previous session receives one startup check through that
same operation. Failed checks require manual Refresh; navigation does not retry
them. Ordinary output and deployment actions reuse the checked session snapshot.

## File views

`mc_file_plans` composes the existing mod browser and pinned Saved files tree with
the Skyrim Data view. `McInspector` supplies a dismissible, scrollable details area
and fixed action footer. It is docked on wide layouts and used in a drawer on
smaller layouts. The narrow browser uses one pane selector.

The engine supplies winners, hidden states, allowed actions and paged tree rows.
Filters match file paths; display choices do not change precedence. Hide and
Unhide affect one saved copy across all workspace profiles. Cold Load and Refresh
are cancellable. Previous observations remain visible after a failed check.

`mc_generated_outputs` supplies Tool outputs and Writable game files as named
`ModFilePane` inputs to the same browser. They use engine-filtered pages and the
same inspector and drawer. The deployment action distinguishes the configured
profile, prepared plan, and known active deployment. A base-only view is Not deployed.
Unfinished output reviews are read by their durable action IDs before explicit
continuation. Promotion and location forms keep their drafts after an unknown
reply; they do not imply cancellation while submitting.
