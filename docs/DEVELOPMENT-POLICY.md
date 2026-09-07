# Development policy

Original Mod Conductor source has no selected project license. Do not add a
license grant or publish source or binaries without explicit human approval.
Local builds and tests do not authorize distribution. Preserve third-party terms
and notices. Record actual adoption in [Provenance](PROVENANCE.md).

The investigation consulted Mod Organizer 2 source. No clean-room claim is made.
A language change or process boundary does not settle obligations for reused
material. The final license assessment remains separate from development.

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
