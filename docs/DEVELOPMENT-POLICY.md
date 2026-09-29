# Development policy

Original Mod Conductor-authored code, documentation, and artwork in this
repository are licensed under the GNU General Public License, version 3 or
(at your option) any later version (GPL-3.0-or-later). See the root
[LICENSE](../LICENSE). Separately licensed third-party material retains its
own terms and notices; this grant does not relicense it. Record actual adoption
in [Provenance](PROVENANCE.md).

The licence assessment is complete. Local builds and tests do not authorize
publication. Release packages must pass their package checks, and publication
requires explicit human approval.

The investigation consulted Mod Organizer 2 source. No clean-room claim is made.
The GPL-3.0-or-later licence is the result of the final assessment.

Use F# for authored engine logic and Flutter for presentation. Keep engine policy
out of Dart. UI dependencies must be FOSS, without commercial/FOSS dual licensing
or proprietary required components. Confine CMake to Flutter native integration.

Keep mockup apps, fixtures, preview runners, and captures untracked under
`.agent-workspace/<session-id>/`. Production components and behavioral tests belong
in source.

Keep separate Protobuf files for each cohesive feature under `modconductor.v1`.
A protocol major change requires explicit human instruction. Internal prototype
changes do not authorize a version increase.

Use private displays or isolated guests for native UI tests. Do not send input
to the user's desktop, change its display mode, or take its focus.
