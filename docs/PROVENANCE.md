# Mod Conductor provenance

This inventory supports the [development policy](DEVELOPMENT-POLICY.md) and the
final GPL assessment in MC-067. It records provenance, not a legal conclusion or
permission to publish.

## Initial state — MC-001, 2026-09-05

The target was an existing empty Git repository on `main`, without commits,
remotes, or application files. MC-001 adds only the two documents listed below.
No MO2 code, translated code, assets, or branding has been adopted. No application
dependencies have been adopted. Planned technologies and package candidates are
not dependencies already incorporated into the project.

### Original MC work

| Paths | Origin and authorship basis | Terms / evidence |
| --- | --- | --- |
| `docs/DEVELOPMENT-POLICY.md`, `docs/PROVENANCE.md` | Newly written MC-001 documentation implementing the human's MC-D-005 direction; not copied or translated from MO2 | No selected project licence; recorded by the MC-001 Git commit |

### Actual third-party adoption

None at MC-001. Add entries as material or dependencies are introduced; do not
replace their notices with a project-wide unlicensed label.

| MC paths / dependency | Kind (copy, translation, asset, dependency) | Upstream origin and exact version / commit | Changes or adaptation | Licence and copyright notice evidence / retained location | Introducing MC commit / ticket |
| --- | --- | --- | --- | --- | --- |

For new original work, extend the original-work inventory by coherent component
or document group with its authorship basis and introducing ticket/commit. For
adopted material, fill every applicable column above and explain any missing or
uncertain evidence. Link retained notices and lockfiles/manifests when present;
record the resolved version, not only a floating version range. Keep the two
categories distinct, including when an existing component gains translated code.

## Investigation references — not adopted material

- MO2 feature/source investigation baseline:
  [`modorganizer2/modorganizer` at `efe2a02d5dc641946baaa8db1440800f38d07837`](https://github.com/modorganizer2/modorganizer/tree/efe2a02d5dc641946baaa8db1440800f38d07837).
  The inspected [`src/modinfo.cpp` notice](https://github.com/modorganizer2/modorganizer/blob/efe2a02d5dc641946baaa8db1440800f38d07837/src/modinfo.cpp#L1-L18)
  specifies GPL version 3 or later for that file. This is reference evidence, not
  an exhaustive upstream licence inventory or an MC licence declaration.
- Viset was inspected during planning for NativeAOT precedent at commit
  `a5e5880a8f6d7277ca3d8eb1b65a37e9dbbb5fbd`; no Viset source was adopted in MC-001.

The source-informed investigation is not claimed to be clean-room work.
Future reuse must be recorded as reuse rather than inferred to be original merely
because it is rewritten in another language. The initial absence of adoption is
not a prediction about later implementation or a final GPL determination.
