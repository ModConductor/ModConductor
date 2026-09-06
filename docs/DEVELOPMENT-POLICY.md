# Mod Conductor development policy

## Unlicensed during development

Original Mod Conductor (MC) source and documentation have **no selected project
licence**. This temporary status follows human decision MC-D-005 and remains in
place pending final assessment MC-067 and a subsequent human licence decision.
This document grants no licence and is not a public-domain dedication.

Do not add a project `LICENSE`, a licence grant, or a project-wide SPDX licence
declaration while MC-067 is pending. Third-party material retains its own terms:
preserve its copyright and licence notices rather than replacing them with MC's
unlicensed status.

## Development and publication boundary

Local development, tests, builds, and packaging for internal qualification may
proceed. This includes local `dotnet publish` and Flutter packaging; these
commands do not authorize external distribution.

Public source or binary publication, forge publication, package uploads, releases,
and other external distribution remain blocked until all of the following hold:

1. MC-067 assesses the actual implementation, reused or translated material,
   dependencies, and proposed distribution after the selected implementation and
   local qualification work.
2. Applicable obligations and any required remediation are resolved and verified,
   and the human approves the project licence decision. Material unresolved legal
   questions require qualified review, not an unsupported assurance.
3. MC-065's publication requirements and explicit human publication authority are
   satisfied.

Completing MC-067 does not itself select a licence or authorize publication.
Neither final assessment nor licence selection is a prerequisite to starting
local development under this policy.

## Record provenance as work is introduced

Maintain the [provenance inventory](PROVENANCE.md) in the same change that
introduces original work, copied or translated code, assets, or dependencies.
Record actual adoption, not candidate packages. Preserve third-party notices and
existing dependency-adoption gates, including the FOSS-only UI requirement and
its exclusion of commercial/FOSS dual-licensed toolkits and proprietary required
components.

The investigation consulted Mod Organizer 2 (MO2) source. This is not evidence of
a clean-room process; none is claimed. Reading that source or implementing similar
features does not settle the eventual GPL assessment, and neither a language
change nor a gRPC boundary establishes that reused material is exempt. Do not
reuse MO2 branding by default. MC-067, not this startup policy, owns the final
assessment.

## Temporary previews

Keep design previews and captures under `.agent-workspace/<session-id>/`.
Do not commit mockup apps, mockup fixtures, preview runners, or captures.
Production component libraries and their behavioral tests belong in the source
tree. Keep required upstream notices with the production dependency inventory,
not inside a temporary preview.
