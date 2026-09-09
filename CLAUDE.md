# CLAUDE.md — read this first

## Before writing any code

1. **Read [`docs/00_BOLT_PLAYBOOK.md`](docs/00_BOLT_PLAYBOOK.md)** — the cross-project
   engineering playbook: the Commit Gate, the New Requirement Protocol, the phasing
   doctrine, the full situation→resolution rulebook, the utility-framework reference.
2. **Read [`docs/BUILD_ISSUES_LOG.md`](docs/BUILD_ISSUES_LOG.md)** — every activation
   error hit on this repo + its fix. Append to it whenever a new one is hit.
3. For the Data Health dashboard work, also read
   [`docs/16_dashboard_interactive_severity_spec.md`](docs/16_dashboard_interactive_severity_spec.md).

## When the user says "this is my new requirement"

Run the **New Requirement Protocol** in the playbook (§2): scope → phase → get approval →
build one increment per commit → activate/fix-loop → hand off. Produce a scoping document
from the §3 template first. **No repo / package / naming assumptions** until the Commit
Gate (§1) is satisfied.

## This repo — landing zone (never cross this without asking)

| | Value |
|---|---|
| GitHub repo | `VernasoftTechie/Employee-360` |
| ABAP package | `ZHR_UTIL` (ships `src/package.devc.xml`, description only) |
| Object stem | `HR360` → `ZI_HR360_*`, `ZC_HR360_*`, `ZBP_HR360_*`, `ZCL_HR360_*`, `ZHR360_*`, `ZMSG_HR360`, `ZCX_HR360` |
| Branch | `main`, direct push (push each green increment so the user can pull) |
| System | S/4HANA 2023 on-prem, SAP_BASIS 7.58, HANA, live HR data |

## Commit message trailer (always)

```
Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
```
