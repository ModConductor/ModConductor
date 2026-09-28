# Development policy

Original Mod Conductor-authored code, documentation, and artwork in this
repository are licensed under the GNU General Public License, version 3 or
(at your option) any later version (GPL-3.0-or-later). See the root
[LICENSE](../LICENSE). Separately licensed third-party material retains its
own terms and notices; this grant does not relicense it. Record actual adoption
in [Provenance](PROVENANCE.md).

The licence selection does not authorize this workflow to publish source or
binaries. Local builds and tests do not authorize distribution. The remaining
licence compliance, source-delivery, package, and publication gates require
separate review and explicit human approval.

The investigation consulted Mod Organizer 2 source. No clean-room claim is made.
A language change or process boundary does not settle obligations for reused
material. The final licence assessment remains separate from development.

Use F# for authored engine logic and Flutter for presentation. Keep engine policy
out of Dart. UI dependencies must be FOSS, without commercial/FOSS dual licensing
or proprietary required components. Confine CMake to Flutter native integration.

Keep mockup apps, fixtures, preview runners, and captures untracked under
`.agent-workspace/<session-id>/`. Production components and behavioral tests belong
in source. Do not create a README yet.

Keep separate Protobuf files for each cohesive feature under `modconductor.v1`.
A protocol major change requires explicit human instruction. Internal prototype
changes do not authorize a version increase.

Use private displays or isolated guests for native UI tests. Do not send input
to the user's desktop, change its display mode, or take its focus.
