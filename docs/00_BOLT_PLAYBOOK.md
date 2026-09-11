# The Bolt Playbook

**One document to shape every new requirement into perfect form, in the shortest time — every time.**

> "Bolt" is the AI engineer (Claude / Claude Code) working a Vernasoft SAP delivery.
> This playbook is written *to* Bolt. A human reviewer reads it to know what Bolt will do.
>
> It consolidates every situation and resolution learned building **Employee 360**, the
> **Data Health dashboard**, **VS-Tower**, **Salary Master**, the **Dangote BP API** and the
> **ZAB_V1_UT utility framework** — so none of it has to be re-learned in a fresh context window.

---

## 0. How to use this document

### 0.1 The trigger

When the user says any of:

> "This is my new requirement…" · "New requirement:" · "Let's build…" · "I want an app that…"

Bolt **immediately** runs the **New Requirement Protocol** (§2). No code, no repo, no
package assumption until §1 and §2 are satisfied.

### 0.2 The golden loop (memorise this)

```
SCOPE  →  PHASE  →  APPROVE  →  (per phase) SLICE → BUILD → PUSH → ACTIVATE → FIX-LOOP → GREEN → HAND-OFF
                                     ▲                                              │
                                     └──────────────── next increment ─────────────┘
```

### 0.3 Precedence — when guidance conflicts

1. The user's explicit words in the current conversation
2. The **client's** written standard captured in the scoping doc (§3)
3. This playbook and the project's own `BUILD_ISSUES_LOG.md`
4. The *Vernasoft ABAP & RAP Engineering Rulebook* (`~/Downloads/Vernasoft ABAP & RAP Engineering Rulebook.md`)
5. General ABAP / SAP best practice

### 0.4 This document is alive

Every time a **new** trap is hit and resolved:
- add a one-row entry to **Appendix A** here, **and**
- add the detailed entry to that project's `docs/BUILD_ISSUES_LOG.md`.

Never let a mistake happen twice across projects. That is the entire point of this file.

---

## 1. The Commit Gate 🔒 (NON-NEGOTIABLE)

**Bolt must not run `git commit` until every line below is checked and true.**
If any single item cannot be confirmed → **STOP, ask the user, wait.**

### 1.1 Pre-commit checklist

| # | Check | How |
|---|---|---|
| 1 | **Repo** is the correct one for this project | `git remote -v` matches the Project Register (§1.3) exactly |
| 2 | **Branch** is correct | `git branch --show-current` = the Register's branch, **or** an approved feature branch. Never commit straight to `main`/`master` unless the Register says "direct push" for that project |
| 3 | **Package** is correct | Every new ABAP object is destined for the Register's package. If the repo ships `src/package.devc.xml`, it names that package. If the Register says "assigned on pull", there is **no** `package.devc.xml` in the repo |
| 4 | **Naming** — every new object matches the project stem and the type rules (§1.4) | List new objects, eyeball each against `Z<TYPE>_<STEM>_*` |
| 5 | **Client naming** overrides applied | If the scoping doc records a client namespace/prefix, it wins over the default stem (§1.5) |
| 6 | **abapGit hygiene** | `.xml` metadata files carry a UTF-8 BOM; source files (`.asddls`, `.abap`, `.asbdef`, `.srvdsrv`) carry **none**. New DDLS has a `.ddls.baseinfo`. (§5.4) |
| 7 | **BUILD_ISSUES_LOG.md read** this session | Confirm no rule about to be violated |
| 8 | **Build compiles in principle** | Key/element counts on UNION branches match; divisors updated; no known reserved word; char-literal lengths ≤ their `CHAR(n)` |
| 9 | **Commit message** follows §Appendix C (version bump + what + why + trailer) |
| 10 | **Scope** — this commit is one coherent increment, not a 150-object dump (§4.3) |

### 1.2 Commit-gate helper

```bash
# Run from the repo root before every commit. Read the output, do not skip.
echo "REPO:";   git remote -v | head -1
echo "BRANCH:"; git branch --show-current
echo "PKG FILE:"; (cat src/package.devc.xml 2>/dev/null | grep -i '<DEVCLASS>\|DESCRIPT') || echo "  (no package.devc.xml — package is assigned in abapGit on pull)"
echo "NEW/CHANGED OBJECTS:"; git status --porcelain
echo "BOM CHECK (xml must show 'with BOM', source must not):"
for f in $(git diff --cached --name-only 2>/dev/null); do
  case "$f" in
    *.xml) printf '  %s ' "$f"; head -c3 "$f" | od -An -tx1 | grep -q 'ef bb bf' && echo "with BOM ✓" || echo "NO BOM ✗";;
    *.asddls|*.abap|*.asbdef|*.srvdsrv) printf '  %s ' "$f"; head -c3 "$f" | od -An -tx1 | grep -q 'ef bb bf' && echo "HAS BOM ✗" || echo "no BOM ✓";;
  esac
done
```

### 1.3 Project Register — the single source of truth for landing zones

> Confirm the row with the user at scoping time. If the project is **not listed**, it is
> **NEW** — create the row, get the user to confirm repo + package + stem, then add it here.

| Project | GitHub repo | ABAP package | Object stem | Branch / push mode | `package.devc.xml` in repo? | Read-first files |
|---|---|---|---|---|---|---|
| **Employee 360** + Data Health dashboard | `VernasoftTechie/Employee-360` | `ZHR_UTIL` | `HR360` | `main`, direct push | **yes** (`src/package.devc.xml`, description only) | `docs/00_BOLT_PLAYBOOK.md` (this), `docs/BUILD_ISSUES_LOG.md`, `docs/16_dashboard_interactive_severity_spec.md` |
| **Salary Master** | `VernasoftTechie/Salary-Master` | `ZHR_UTIL` | `HR_SALMST` | `main` (was unpushed — confirm) | **no** (assigned on pull) | `docs/12_adaptation_points.md` |
| **VS-Tower** (SF Control Tower) | `VernasoftTechie/VS-Tower` | `ZABAP_UTIL` | `TWR` | `main`, direct push | check | `docs/00_context_and_decisions.md` (change-log at end = live state), `docs/BUILD_ISSUES_LOG.md` §0/§1 |
| **ZAB_V1_UT utility framework** | `VernasoftTechie/Utility-Class-and-Method` | `ZABAP_UTIL` | `AB_V1_UT` | `main`, staged commits | **yes** (`src/package.devc.xml`) | `docs/00_engineering_log.md`, root `CLAUDE.md`, `docs/07_object_package_map.md` |
| **Dangote Customer BP API** | `VernasoftTechie/Dangote_Requirements` | `ZABAP_UTIL` | `CUST_BP` | `main`, direct push | check | its own build notes; abapGit XML format notes (§5.4) |
| **ESS Loan Request** | *(confirm before commit)* | *(confirm)* | `ESS` / `ZESS_*` | *(confirm)* | *(confirm)* | `memory:ess_project_context` |
| **Smart Form to Adobe Form Migration** | `VernasoftTechie/Smartform-Adobe-Migration` | `ZABAP_UTIL` (shared, existing) | `SF2AF` | `main`, direct push | **yes** (`src/package.devc.xml`, repo-specific CTEXT, Dangote-style) | `docs/01_scope.md` (risk framework + phase plan), `docs/02_legacy_grab_spec.md`, `memory:smartform_adobe_migration_project` |

> ⚠️ **`ZBP_` is reserved for RAP behaviour pools.** Never use `ZBP_*` for a normal class,
> DDIC object or API handler (Dangote hit this — renamed `ZBP_CUST_*` → `ZCUST_BP_*`).

### 1.4 Default naming convention (Vernasoft)

`<STEM>` = the project's object stem from the Register (`HR360`, `TWR`, `HR_SALMST`, …).

| Object | Pattern | Example | Notes |
|---|---|---|---|
| Interface CDS view | `ZI_<STEM>_*` | `ZI_HR360_EMP_BASIC` | all computed columns / CASE / cast live **here** |
| Consumption / projection CDS | `ZC_<STEM>_*` | `ZC_HR360_EMP_DQ` | thin — names elements only (§5.1) |
| Helper / dimension CDS | `ZI_<STEM>_*` | `ZI_HR360_DIM_TEXT` | one row per key, always |
| Service definition | `Z<STEM>_UI_SRVD` or `ZUI_<STEM>_O4` | `ZHR360_UI_SRVD` | be consistent within a project |
| Service binding (OData V4 UI) | `Z<STEM>_UI_SRVB_O4` | `ZHR360_UI_SRVB_O4` | **ship it in the repo**, `PUBLISHED=true` (G1) |
| RAP behaviour definition / pool | `ZI_<STEM>_*` / `ZBP_<STEM>_*` | `ZBP_HR360_EMPLOYEE` | `ZBP_` **only** here |
| Query provider class | `ZCL_<STEM>_*_QRY` | `ZCL_TWR_SHORTDUMP_QRY` | `IF_RAP_QUERY_PROVIDER` |
| Class / interface | `ZCL_<STEM>_*` / `ZIF_<STEM>_*` | `ZCL_HR360_REPORT_ENGINE` | |
| Exception class | `ZCX_<STEM>` | `ZCX_HR360` | one per project |
| Message class | `ZMSG_<STEM>` | `ZMSG_HR360` | `&` → `&amp;` in `.msag.xml` (C1) |
| BAL log object (SLG0) / number range (SNRO) | `Z<STEM>` | `ZHR360` | created manually in the system, noted in docs |
| Executable report | `Z<STEM>_*_REPORT` / `Z<STEM>_R_*` | `ZHR_SALMST_REPORT` | `.prog.xml` needs `<TPOOL>` for titles/sel-texts |
| DDIC table | `Z<STEM>_<NAME>` | `ZHR360_LOG`, `ZCUST_BP_LOG` | **no `_` at char 2 or 3** — so `ZT_*` is **invalid** for tables |
| DDIC structure / table type | `Z<STEM>_S_*` / `Z<STEM>_T_*` | `ZCUST_BP_S_ADDR` | |
| Custom data element | `Z<STEM>_*` | `ZCUST_BP_TEXT` | **must be domain-backed** for abapGit (domain-less `STRG` fails to import) |
| Domain | `Z<STEM>_*` | `ZAB_V1_UT_AREA` | `SCRLEN` must be ≥ its text lengths; `SCRTEXT_S≤10 / _M≤20 / _L≤40` |
| BSP application (freestyle UI) | `Z<SHORTNAME>` **≤ 15 chars** | `ZCONTROL_TOWER` | UI5 app id can be longer; the BSP name cannot |
| Freestyle UI folder | `/ui/<app>` | `/ui/dashboard` | |
| Check-ID / code literal in CDS | ≤ the declared `CHAR(n)` | `LEAVE_NOQTA` (11 ≤ 12) | `cast('…' as abap.char(12))` **truncates silently**; a later `= '…'` then rejects it (A37) |

### 1.5 Client-specific naming

- The scoping doc (§3, field 6) records the **client's** ABAP naming standard.
- If the client has a **registered namespace** (`/CLIENT/…`) or a **mandated prefix**, that
  **overrides** the default `Z<STEM>` — apply it to every object.
- If the client only mandates a package (e.g. Dangote → `ZSD` originally), keep Vernasoft
  object naming inside it unless told otherwise.
- **Never assume** a client convention. Absent an explicit client standard, use §1.4.
- Record whatever is decided in the Register row and the scoping doc — both.

---

## 2. New Requirement Protocol

### Step 1 — Capture & scope (do not skip, even for "small" asks)

1. Quote the requirement **verbatim** back to the user.
2. Fill the **Scoping Document** (§3) as far as current knowledge allows.
3. List every **assumption** and every **open question**, each with a **proposed default**
   so work is not blocked (see Employee 360 `docs/16` §12 for the pattern).
4. Name the **landing zone**: repo / package / stem / branch — from the Register, or flag NEW.
5. Present the scope + phase plan. **Ask for concerns before building** (the user asked for
   this explicitly and repeatedly — "share your concerns before concluding or committing").

### Step 2 — Phase it (Bolt decides the phases, §4)

- Bolt proposes **Phase 1 … Phase N**. Phase 1 is always a thin end-to-end slice.
- Each phase: goal · objects · "done when" · risks that apply (from Appendix A).
- Parked / out-of-scope items get a label: **"Based on Customer Specification"**,
  **"Action pending for discussions"**, **"Additional scope"** (Employee 360 Payroll pattern).

### Step 3 — Architecture approval gate

- **No implementation before the architecture is approved** (Vernasoft Rulebook, hard rule).
- Approval = the user says "approved" / "defaults fine" / "go".
- The scoping doc + phase plan is the artefact approved.

### Step 4 — Build the phase, one increment per commit

- An **increment** = the smallest set of objects that can be activated and verified in one
  ADT **"Activate All Inactive"** pass. Past the core: roughly **one new CDS view + its
  wiring** per increment. **Never ship ~150 objects a round** (that cost Employee 360 ~10
  dead rounds — Appendix A / A18).
- After each increment: **push → user pulls → Activate All (twice) → user pastes errors**.

### Step 5 — Activation & verification fix-loop

- **Fix the first real error, re-activate, repeat.** Downstream "does not exist / unknown
  type" lines are ~95% cascade noise (B1).
- **abapGit "activate" does not reliably catch syntax errors.** The authoritative check is
  **ATC / SLIN** — ask the user to run ATC and paste *all* "syntax error / prerequisites
  for extended check" findings; each maps 1:1 to a code fix. Repeat until zero (the
  ZAB_V1_UT loop).
- For a freestyle UI: verify against a **static harness** or the user's local `npm start`
  HAR + console log before asking for a deploy.
- Log every new trap (§0.4).

### Step 6 — Hand-off

- Update `docs/12_version_history.md` (or the project's change-log).
- Update the relevant memory file.
- Tell the user, in order: **pull → Activate All Inactive on `<package>` → preview
  `<entities>` → (re)publish service binding → redeploy `<ui>`**.
- State what changed in the data (e.g. "`LEAVE_NOQTA` now appears where `LEAVE_NOQUOT` did").

---

## 3. The Scoping Document — template

> Copy this into `docs/NN_<requirement>_scope.md` in the project repo at Step 1.
> `NN` = next number. It is the artefact the user approves.

```markdown
# <Requirement name> — Scoping & Phase Plan

## 1. Requirement (verbatim)
> <paste exactly what the user said>

**Business outcome:** <one sentence — what is true for the business when this is done>
**Primary users:** <role(s)>

## 2. System context
- SAP: <S/4HANA 2023 on-prem / BTP CF / …>, SAP_BASIS <7.58 / …>, DB <HANA / …>
- ABAP language version: <Standard ABAP / ABAP for Cloud>
- Clients: <e.g. 100 live, 400 test>
- Data currency: <live / snapshot / replicated>

## 3. Data sources
| Source (table / infotype / API / CDS) | Fields needed | Verified in SE11 / API docs? | Risk |
|---|---|---|---|
| PA0002 | GBDAT, GESCH, NATIO, FAMST | ☐ | date needs cast to abap.dats (A24) |
| … | | | |

> Rule: **never invent an SAP field name.** Every row above is confirmed against the
> target system, or it is an open question in §7.

## 4. Consumers & authorisation
- Who sees what: <…>
- Auth object(s): <P_ORGIN / company-code / custom Z…>, enforced by <DCL / imperative class>
- Row-level filtering: <DCL / query provider / none>

## 5. Non-functional
- Volume: <~N employees / rows>
- Performance budget: <page < Xs; no O(n²) paging>
- Refresh / batch: <on demand / nightly / …>

## 6. Naming & landing zone
| | Value | From Register? |
|---|---|---|
| Repo | `VernasoftTechie/<…>` | ☐ existing ☐ NEW (confirmed by user) |
| Package | `<…>` | ☐ |
| Object stem | `<…>` | ☐ |
| Branch / push mode | `<main, direct / feature branch + PR>` | ☐ |
| Client naming override | `<none / /CLIENT/ / prefix>` | ☐ |

## 7. Assumptions & open questions (each with a working default)
| # | Question | Working default (used until answered) |
|---|---|---|
| 1 | <…> | <…> |

## 8. Out of scope / parked
| Item | Label | Re-open when |
|---|---|---|
| <…> | Based on Customer Specification / Action pending for discussions / Additional scope | <…> |

## 9. Phase plan
| Phase | Goal (independently valuable) | Key objects | Done when |
|---|---|---|---|
| 1 | thin end-to-end slice: <…> | <…> | activates green, returns real data, one screen works |
| 2 | <breadth: …> | <…> | <…> |
| N | <…> | <…> | <…> |

## 10. Phase 1 — increment plan
| Increment | Objects | Verify |
|---|---|---|
| 1a | <…> | Activate All → preview <entity> |
| 1b | <…> | … |

## 11. Applicable traps (from Bolt Playbook Appendix A)
- <e.g. A5/A6 UNION key discipline; A24 date casts; A34 one-row-per-key; U3 Page height>

## 12. Definition of Done (per phase)
- [ ] Activates green on the target system (Activate All, twice)
- [ ] ATC / SLIN clean (no syntax findings)
- [ ] Entity previews / screen renders with real data
- [ ] Unit tests run (CDS test-double / ABAP Unit) and reported
- [ ] `BUILD_ISSUES_LOG.md` updated with anything hit
- [ ] Docs + memory + version history updated
- [ ] Hand-off steps given to the user
```

---

## 4. Phasing Doctrine

### 4.1 What makes a phase

A phase is a slice that is **independently valuable, independently demoable, and
independently shippable**. "Requestor app" then "approver app". "Tier 1 checks" then
"Tier 2 checks". "Live cards" then "date-range analytics".

### 4.2 Phase 1 is always a thin vertical slice

The smallest thing that goes **end to end and activates green with real data** —
one CDS view → one service entity → one screen. Everything else is a later phase that
**adds breadth without re-opening the core** (Employee 360 `A18` process change:
"grow from a working core").

### 4.3 Increment sizing inside a phase

| Situation | Increment size |
|---|---|
| First green build | the core only — root view + service + one entity, nothing else |
| Adding entities / checks / cards | ~1 new CDS view (+ helper) + its wiring per commit |
| Field additions to existing views | group by source view; one commit; state the divisor/count change |
| UI redesign | one commit, verified against a harness before deploy |

**Never** batch many risky objects "to save round-trips" — each dead activation round
costs more than the commits saved.

### 4.4 The per-increment ritual

`push → user pulls → Activate All Inactive (×2) → user pastes the error list → fix the
first real error → repeat → green → ATC → next increment.`

---

## 5. Engineering Rulebook — hard-won rules

> The full symptom → cause → fix table is **Appendix A**. This section is the
> "know before you write" digest, by area.

### 5.1 CDS view entities

- `WHERE` comes **after** the `{ … }` element list (A1).
- **No `IN ( … )` in a JOIN `ON`** — use `AND ( x = 'a' OR x = 'b' )`. `IN` is fine in `WHERE` (A2).
- Arithmetic `/` needs decimal operands — use `division( dividend, divisor, decimals )` (A3).
- `COUNT` over a join that can multiply rows → `count( distinct … )` (A4).
- `UNION`: **every branch** carries the **same `key` markers** on the same elements, and
  **every** expression has an explicit `as <name>` matching branch 1 (A5, A6).
- `CASE` without `ELSE` → warning; prefer `sum( case when … then 1 else 0 end )` (A8).
- `@EndUserText.label` and VDM annotation values ≤ **40 characters** (A9).
- **Don't `cast` integer literals to `NUMC`** — cast a char literal: `cast('00000000' as abap.numc(8))` (A7).
- **`LANG` fields cannot be `cast`** — select raw or drop (A33). (Contrast: `DATS`/`TIMS` *must* be cast for OData, A24.)
- **Never expose a raw PA-infotype date** (`BEGDA/ENDDA/GBDAT/DESTA/DEEND`) to OData —
  `cast( x as abap.dats )`; times → `cast( x as abap.tims )` (A24). Conversion-exit code
  fields (`SPRAS`, etc.) break OData V4 too → `cast( x as abap.char(n) )`.
- **`GROUP BY` cannot contain a `cast()` or `CASE` expression** — only plain element names.
  Compute the column once in a flat view, then group by the plain field (A29, A31).
- **`string_agg` is not an aggregate function** on SAP_BASIS 7.58 view entities. For a
  "list per group", use a **failure bitmask**: `cast( sum( max( <0/1 per-check flag> ) *
  2^i ) as abap.int4 )`, bit `i` pinned to the client-side catalogue order. `max()` of
  `0/1` is idempotent so a duplicate row can't double a bit (A35, A36).
- A char literal compared with `=` against `CHAR(n)` must be **≤ n chars** — longer ones
  are silently truncated by `cast(...)` but rejected by `=` (A37).
- **One row per key.** Any view exposed as an OData V4 entity set **or** feeding a `UNION`
  branch must be one row per its key. Infotypes with subtypes/overlaps (PA0006, PA0105,
  PA0009, PA0008) → `max( field ) … group by pernr`. Add `GROUP BY` (all columns) on the
  exposed projection as a belt-and-braces guard (A34).
- A view over raw tables that pulls annotations it shouldn't → `@Metadata.ignorePropagatedAnnotations: true`, and split ZI (raw) / ZC (projection).
- **Don't invent HR text-table joins** — expose raw codes; add texts only after verifying
  the text table's key in SE11 on the target system (A10). Employee status is **not** on
  PA0001 here (`STAT2` unknown — A11); it's PA0000.

### 5.2 Projection views (`as projection on …`)

- Project **existing element names + `redirected to` + a tiny function set only**.
  **No `CASE`, no arithmetic, no `cast`, no literals** — those go in the interface view (A14).
- `AVG( x AS <type> )` — the `as` is mandatory and may only **widen** the type (A15, A17).
- If a projection "could not be parsed", reformat one element per line and hunt the stray
  computed column first (A18).

### 5.3 RAP behaviour / BO

- A **transactional projection** must belong to a BO — its interface view must be a
  **composition child** of the root, reachable by `redirected to`. Plain associations are
  not enough (B2).
- A **pure read-only** entity with no persistent table does **not** fit a `strict(2)`
  unmanaged BDEF (it forces lock-master/dependent + operations). Ship it as a plain
  `define view entity … as select from` query view, or use an **unmanaged query**
  (`IF_RAP_QUERY_PROVIDER`) for custom entities (A19; Salary Master / VS-Tower pattern).
- Root ↔ child composition/association circularity is **normal** — resolves only with
  **"Activate All Inactive"** on the package, sometimes two passes (B4).
- `authorization master ( global )` + `get_global_authorizations` (one `AUTHORITY-CHECK`);
  row filtering by DCL (B5).
- One `bdef` for the whole composition tree; one pool with `lhc_<child>` per child (B3).

### 5.4 abapGit serialization / import

- **`.xml` metadata files need a UTF-8 BOM (`EF BB BF`). Source files
  (`.asddls / .abap / .asbdef / .srvdsrv`) must NOT.** Wrong BOM state = "delete and
  recreate on every pull" (G3).
- Every DDLS also needs a **`.ddls.baseinfo`** (JSON: `FROM` = every `select from`/`join`
  source, `ASSOCIATED`, `BASE` for projections). Missing = drop+recreate churn (G4).
- **Definitive cure for pull churn:** after the next clean pull, do abapGit
  **Stage → Commit (push) *from the SAP system* once** — the repo then mirrors abapGit's
  exact serialization and every later pull is clean (G4).
- `.msag.xml`: escape `&` as `&amp;`; `<item>` row wrappers for T100 (C1).
- **Hand-written DDLX / MDE XML is fragile** — a failed *import* aborts the whole
  "Activate All Inactive" batch. Prefer object types with simple proven abapGit formats
  (DDLS, CLAS, PROG, BDEF-source), or create the object in ADT and read back how abapGit
  serialises it. UI annotations: author in a metadata extension against a live system (C2, A25).
- **Ship the service binding in the repo** (`.srvb.xml` + `.g4ba.xml`, `PUBLISHED=true`) —
  otherwise it vanishes on every pull (G1).
- `.abapgit.xml` = bare `<asx:abap>` (no `<abapGit>` wrapper).
- `.tabl.xml` DD03P: no `<POSITION>`/`<TABNAME>`; yes `<ADMINFIELD>0</ADMINFIELD>` +
  `<COMPTYPE>` (`E` elem / `L` table-type with `<DATATYPE>TTYP</DATATYPE>` / `S` struct).
- `.ttyp.xml` DD40V: no `<TYPELEN>`.
- **Never leave a dangling `.clas.xml` with no `.abap`** (or vice versa) — breaks the pull.
- Only `/src/` is processed (`STARTING_FOLDER=/src/`). WIP can live elsewhere but then
  abapGit wants to delete the still-active object — prefer keeping only green objects in `/src`.

### 5.5 ABAP class / report code

- A method with **`RETURNING` must not also have `EXPORTING`/`CHANGING`** (only `IMPORTING`).
- **`RETURNING` must be fully typed** — no generic `TYPE p` / numeric / `any`. Use
  `decfloat34` for numeric returns.
- **`TYPE c LENGTH n` is rejected in `METHODS` parameters** on the strict Class Builder here
  — use a data element. Classic reports passing DDIC-field `iv_*` to a `string` param: use
  a `CONV` / `string()` workaround.
- Identifiers (incl. **test method names**) ≤ **30 chars**.
- `CLASS ltcl_x DEFINITION DEFERRED.` line is needed before `… DEFINITION LOCAL FRIENDS ltcl_x`.
- Distinct loop variable per inline `FOR` (`FOR rp IN …`, `FOR rb IN …`) — one `FOR r`
  can't be reused with a different row type (A20).
- Catch the common `cx_salv_error` superclass, not each `cx_salv_*` (A23).
- No `TABLES` statement — `DATA gv_x TYPE …` + `SELECT-OPTIONS … FOR gv_x` (D3).
- Dynamic-token gotchas: `DELETE ADJACENT DUPLICATES … COMPARING (lv_list)` needs a
  **char-like comma-list**, not a table — one bad statement makes the whole class fail to
  load with an **uncatchable `SYNTAX_ERROR`** (ZAB_V1_UT lesson).
- Report `.prog.xml` needs `<TPOOL>` (title, selection texts, block titles) or the screen
  shows technical names. A domain-typed `LISTBOX` parameter is **not** auto-filled —
  `VRM_SET_VALUES` in `AT SELECTION-SCREEN OUTPUT`.
- **ATC/SLIN is the real syntax gate**, not abapGit activate. Converge to zero findings.

### 5.6 Freestyle SAPUI5 dashboards

- **Model naming:** if the manifest declares the OData V4 model as default (`""`) *and*
  `onInit` sets a JSONModel as default, they collide → `requestContexts is not a function`.
  Name the OData model (`"odata"`); JSONModel stays default (U1).
- **i18n:** add `supportedLocales: [""]` + `fallbackLocale: ""` or you get `_en_GB` 404s (U2).
- **Root control must not be a bare `sap.m.Page`** as the component root view — height
  collapses to 0, header shows, body blank. Wrap in `sap.m.App`; `height="100%"` on the
  view; `html,body{height:100%}` in `index.html` (U3).
- `$batch` 403 then token fetch then 200 = normal V4 CSRF self-heal, not a bug (U4).
- **Paging:** always send `$orderby` (a `Sorter` per key) — HANA `LIMIT/OFFSET` is not
  stable between pages otherwise (U5). **The gateway page-caps a response below the
  requested `$top`** — loop against `$count`/`getCount()`, never "stop when the window
  isn't full" (U7).
- **Deep `$skip`/`$top` paging of an aggregating (`GROUP BY`) view is ~O(n²)** — every page
  re-runs the whole union+group+sort. Send one compact row per employee (e.g. a
  `FailureBitmask`) and aggregate **client-side** instead (A35).
- **`sap.ui.core.HTML` content must have exactly ONE root element** — it only manages the
  first root on re-render; extra roots accumulate as strays (U7).
- Hand-roll compact charts as **SVG/CSS inside `core:HTML`** (donut, stacked bars) rather
  than `sap.viz.VizFrame` — smaller, tighter, themeable. Trim libs to `sap.m` + `sap.ui.core`.
- One **delegated** click listener on the view root reading `[data-drill]` attributes;
  bind once (guard flag).
- Keep CDS `@UI` to the four basics (`lineItem` / `selectionField` / `identification` /
  `facet`) + `criticality`. Charts / datapoints / presentation variants → one at a time in
  an MDE, tested individually (A32).
- BSP application name ≤ 15 chars.

### 5.7 Performance

- Aggregate from the **flattest** join that gives the grain — never aggregate over an
  aggregate over a union across a whole company code (that dumped `RAISE_SHORTDUMP` — A28).
- Push per-row work to the DB; page against `$count`; prefer one wide read + client-side
  math over many deep-offset reads.

### 5.8 HR / infotype specifics

- Verify every infotype field in SE11 on the **target** system before using it (A10, A11).
- Dates: cast to `abap.dats` (A24). Amounts (`CURR`) / quantities (`QUAN`): `cast( … as
  abap.dec(n,2) )` or add a reference field + `@Semantics` (A13).
- Infotypes with subtypes/time-slices → one-row-per-employee helper via `max() … group by
  pernr` (A34).
- Org-unit / position texts (HRP1000) are plan-version + validity dependent — defer unless
  in scope; company/personnel-area texts (`T001`, `T500P`) are safe.

---

## 6. The Utility Framework — `ZAB_V1_UT` (use it before you hand-roll)

**Repo:** `VernasoftTechie/Utility-Class-and-Method` · **Package:** `ZABAP_UTIL` ·
**Facade class:** `ZCL_AB_V1_UT` · **Object stem:** `AB_V1_UT`

A general-purpose ABAP utility catalogue: a **static facade with lazy singletons** plus
one interface per area, each with `set_<area>` / `reset` test seams. Headless core has
**zero** static dependency on SAP GUI — GUI helpers are quarantined in `ZCL_AB_V1_UT_GUI`
(called directly by classic reports, never via the facade).

### 6.1 Areas — check here first

| Area | Use it for |
|---|---|
| `STR` | string ops, alpha in/out (with length), split/join, casing |
| `CONV` | conversions, unit/currency, dates, workdays, rounding (`decfloat34` returns) |
| `TAB` | internal-table helpers, distinct, grouping |
| `DB` *(gated)* | dynamic `SELECT`, table/view name validation |
| `FILE` *(gated, app-server)* | `OPEN DATASET` read/write behind an interface |
| `EXCEL` | `.xlsx` build/read (OOXML via `cl_abap_zip` / `xco_cp_xlsx`) |
| `JSON` | `/ui2/cl_json` + `xco_cp_json` wrappers |
| `LOG` | Application Log (BAL) — `create` guards on SLG0 object existence |
| `MSG` | message handling, `symsg_to_bapiret`, bapiret → text |
| `AUTH` | `AUTHORITY_CHECK` FM, `AGR_USERS`, `USR02` (user id ≤ 12 chars) |
| `NUM` | number ranges — guards `TNRO` before `cl_numberrange_runtime` |
| `MAIL` | `cl_bcs` send (default sender = system address) |
| `ATTACH` (`_GOS` / `_STUB`) | GOS attachments; `_STUB` is the working adapter, resolved from `ZAB_V1_UT_ADPT` |
| `SYS` | system info helpers |
| `CFG` | config / domain value reads (`DD_DOMVALUES_GET`) |
| `RAP` | `new_cid`, messages → bapiret, `corresponding_control` |
| `JOB` | `schedule_job`, `is_finished` |
| `ALV` *(GUI only)* | SALV show / dynamic / fieldcat — **direct call, never via facade** |
| `HTTP` *(v1.1)* | REST + OData + SOAP client over `cl_http_client` |
| `BULK` *(v1.1)* | packaged / resumable / parallel mass processing (`cl_abap_parallel`), caller-provided persistence |
| `BAPI` *(v1.1)* | dynamic `CALL FUNCTION PARAMETER-TABLE`, `call_by_name` auto-bind, mass + `BAPI_TRANSACTION_COMMIT`, BDC |
| `CUTOVER` *(v1.1)* | task runner, readiness checks, user lock/unlock (report-only for job suspend) |
| `TRANSPORT` *(v1.1)* | E070/E071/WBCROSSGT/TADIR/TDEVC reads, where-used, code inventory (no cross-system) |

### 6.2 How to consume

```abap
DATA(json) = zcl_ab_v1_ut=>json( )->serialize( data ).
DATA(bapiret) = zcl_ab_v1_ut=>msg( )->symsg_to_bapiret( ).
" tests: zcl_ab_v1_ut=>set_json( lo_double ). ... zcl_ab_v1_ut=>reset( ).
```

- Every method carries a RAP-mode tag: **Core / Defer / GUI / Gated**. `set_phase()` guards
  `Defer` methods.
- Gated areas (`DB`, `FILE`) sit behind their own interfaces + own ATC exemption.

### 6.3 When NOT to use it

Some projects are deliberately **self-contained** — Salary Master and Employee 360 carry
their own SALV / xlsx / auth / BAL and do **not** depend on `ZAB_V1_UT`. Follow the
project's locked decision. If a project *is* allowed to consume it, prefer it over
hand-rolling anything in §6.1.

---

## 7. Reference Library

### 7.1 Governing document

- **Vernasoft ABAP & RAP Engineering Rulebook** — `~/Downloads/Vernasoft ABAP & RAP
  Engineering Rulebook.md`. Key rule: **no implementation before architecture approval.**
  Also: `ZT_` tables *(but see §1.4 — table names can't have `_` at char 2/3)*, `ZMSG_`
  message class, `ZCL_`/`ZIF_`, no `TABLES` statement, `AUTHORITY-CHECK`, all errors via
  the message class.

### 7.2 Reference repos (known-good abapGit serialization to copy from)

- `VernasoftTechie/Utility-Class-and-Method` — full framework, `.clas.xml` full `VSEOCLASS` form
- `ZRAP_MT` clone — reference for `.xml` BOM + `.ddls.baseinfo` shape
- `abap2xlsx` — reference `.tabl.xml` / `.ttyp.xml` / `.dtel.xml` formats

### 7.3 Per-project "read first" (also in the Register §1.3)

| Project | Read before touching code |
|---|---|
| Employee 360 | this playbook · `docs/BUILD_ISSUES_LOG.md` · `docs/16_dashboard_interactive_severity_spec.md` · `docs/PROJECT_OVERVIEW.md` |
| VS-Tower | `docs/00_context_and_decisions.md` (change-log = live state) · `docs/BUILD_ISSUES_LOG.md` §0/§1 |
| Salary Master | `docs/12_adaptation_points.md` |
| ZAB_V1_UT | `docs/00_engineering_log.md` · root `CLAUDE.md` |
| Dangote BP API | project build notes · §5.4 XML formats |

### 7.4 Memory files (Claude auto-memory — background context, verify before asserting)

`employee_360_project` · `vs-tower-project` · `salary_master_project` ·
`zcl_abap_util_framework` · `ess_project_context` · `dangote-bp-api-project`

---

## 8. Definition of Done (every phase, every project)

- [ ] **Commit Gate (§1.1) passed** — repo, branch, package, naming, client override, BOM/baseinfo
- [ ] Activates green on the target system — "Activate All Inactive", run twice
- [ ] **ATC / SLIN clean** — zero "syntax error / prerequisites for extended check" findings
- [ ] Entity previews / screen renders with **real data** in the target client
- [ ] Unit tests (CDS test-double / ABAP Unit) run and results reported (failures ≠ activation block, but must be reported)
- [ ] Service binding re-activated / re-published if entities changed
- [ ] `BUILD_ISSUES_LOG.md` updated with every trap hit + **Appendix A** here updated if new
- [ ] Docs updated (`12_version_history.md` / project change-log) + memory file updated
- [ ] Hand-off steps given in order (pull → activate → preview → publish → redeploy)
- [ ] Data-change note given (renamed values, new fields, divisor changes)

---

## Appendix A — Situation → Resolution index

> Condensed. Full detail in each project's `docs/BUILD_ISSUES_LOG.md`. `A#` = CDS/OData,
> `B#` = RAP, `C#` = abapGit import, `D#` = ABAP code, `G#` = repo hygiene, `U#` = freestyle UI.

### CDS view entities
| # | Situation | Resolution |
|---|---|---|
| A1 | "Unexpected word WHERE" | `WHERE` goes after `{ }` |
| A2 | "Unexpected word IN" in a JOIN `ON` | `AND ( x = 'a' OR x = 'b' )`; `IN` only in `WHERE` |
| A3 | "Operands of the division must be decimal" | `division( n, d, dec )` |
| A4 | "DISTINCT required for COUNT" | `count( distinct col )` on multiplying joins |
| A5 | "Key definition of branch N must match branch 1" | identical `key` markers in **every** UNION branch |
| A6 | UNION branch elements need names | explicit `as <name>` in every branch, matching branch 1 |
| A7 | "CAST INT1 to NUMC not possible" | cast a **char** literal: `cast('00000000' as abap.numc(8))` |
| A8 | "CASE without ELSE → NULL" warning | `sum( case when … then 1 else 0 end )` |
| A9 | "Annotation value length > 40" | `@EndUserText.label` ≤ 40 chars |
| A10 | "Column MOABW/QUOMO/SPRSL/… unknown" | remove invented text-table joins; expose raw codes; verify in SE11 |
| A11 | "Column STAT2 unknown" (repeated) | employment status is **not** on PA0001 here — use PA0000; **don't re-try a flagged field** |
| A12 | "POSITION is a reserved word" | rename → `PositionId`; avoid `CLIENT/KEY/USER/LANGUAGE/DATE/TIME/VALUE/LEVEL/NAME/TYPE` |
| A13 | "CURR/QUAN reference info missing" | `cast( field as abap.dec(n,2) )` or reference field + `@Semantics` |
| A14 | "not supported expression" / "could not parse DDL" (projection) | move `CASE`/arithmetic/`cast`/literals to the **interface** view |
| A15/A17 | `AVG` narrowing / "AVG only with 'as'" | fix source type first, then `avg( x as <same wider type> )` |
| A16 | "CAST to identical type" warning | drop the redundant `cast` |
| A18 | projection layer never parses after many rounds | **stop fighting** — minimal viable BO, flatten to columns, add entities one per commit |
| A24 | runtime "Do not use conversion ext PDATE here" | `cast( date as abap.dats )` / `cast( time as abap.tims )` on **every** infotype date/time |
| A27 | EDM "same name as entity type" | never name an element `<X>Type` when `<X>` is an entity-set name → `<X>TypeCode` |
| A28 | `$batch` `RAISE_SHORTDUMP` on a filtered aggregate | aggregate from the flat `EMP_BASIC ⋈ EMP_KPI`, not aggregate-over-aggregate-over-union |
| A29/A31 | "Unexpected keyword CASE/CAST" in `GROUP BY` | compute once in a flat view; group by the plain field |
| A32 | Fiori "FilterBar / Trailing text in XML" | strip `@UI` to the 4 basics + criticality; advanced annotations one at a time in an MDE |
| A33 | "CAST: Source type LANG is not supported" | `LANG` fields select raw, never `cast` |
| A34 | OData V4 "Duplicate key predicate" / all KPIs 0 | one row per key — `max() … group by pernr`; `GROUP BY` all cols on the projection |
| A35 | dashboard stuck loading (O(n²) deep paging) | `string_agg` unavailable → **FailureBitmask** `sum( max(0/1) * 2^i )`; aggregate client-side |
| A36 | bitmask bit doubles on a duplicate row | `sum( max( 0/1 flag ) * 2^i )` — `max()` is idempotent |
| A37 | "Literal not compatible with CHAR(000012): 'LEAVE_NOQUOTA'" | code literal ≤ its `CHAR(n)`; `cast()` truncates silently, `=` rejects |

### RAP / BO
| # | Situation | Resolution |
|---|---|---|
| B1 | huge error list on BDEF/service | fix the **first real CDS error**, re-activate, repeat — rest is cascade |
| B2 | "Transactional Projection View must be part of a business object" | interface view must be a **composition child** reachable by `redirected to` |
| B4 | root ↔ child circular dependency | normal — "Activate All Inactive" on the package, sometimes twice |
| B5 | instance-auth handler missing | `authorization master ( global )` + `get_global_authorizations`; rows via DCL |
| A19 | `strict(2)` read-only BDEF won't fit | plain query view, or unmanaged query (`IF_RAP_QUERY_PROVIDER`) for custom entities |

### abapGit / import
| # | Situation | Resolution |
|---|---|---|
| C1 | "XML parser error" importing message class | `&` → `&amp;` in `.msag.xml`; `<item>` row wrappers |
| C2 | "The description is missing" — MDE import aborts the batch | remove hand-written DDLX; author UI annotations in ADT/BAS |
| G1 | service binding disappears on every pull | ship `.srvb.xml` + `.g4ba.xml` in `/src`, `PUBLISHED=true` |
| G3 | every object "delete and recreate" on every pull | `.xml` needs UTF-8 BOM; source files must not have one |
| G4 | still churning after BOM fix | add `.ddls.baseinfo`; then abapGit **Stage→Commit from SAP once** |
| — | `.abapgit.xml` format | bare `<asx:abap>`, no `<abapGit>` wrapper |
| — | `.tabl.xml` / `.ttyp.xml` | DD03P: no `<POSITION>`/`<TABNAME>`, yes `<ADMINFIELD>0</ADMINFIELD>`+`<COMPTYPE>`; DD40V: no `<TYPELEN>` |
| — | dangling `.clas.xml` without `.abap` | always write both together |

### ABAP code
| # | Situation | Resolution |
|---|---|---|
| D3 | `TABLES` statement in a report | `DATA gv_x` + `SELECT-OPTIONS … FOR gv_x` |
| D5 | `FILTER … USING KEY` in a test | use `SELECT COUNT(*)` |
| D6 | Dump `CALL_FUNCTION_CONFLICT_TYPE` passing a `TYPE string` actual to a classic FM | classic (pre-Unicode-era) function modules (`SSF_*`, old BAPIs) often have fixed-length `C`/`N`/`D`/`T` typed parameters, not `STRING` — declare a fixed-length local, assign the string to it, pass that instead |
| D7 | "X must be a character-like field (data type C, N, D, or T)" on a classic offset/length access (`field+off(len)`) | that variable is `TYPE string`, not fixed `C/N/D/T` — classic offset/length notation only works on fixed-length types. An inline `DATA(x) = to_upper( ... )` (or any string built-in) infers `TYPE string`; declare the target explicitly as a fixed type (e.g. a DDIC char field) and assign via `=` instead of inline `DATA()` when it will later need offset/length access **or** by-reference `IMPORTING` binding to a fixed-type formal (Utility-Class-and-Method engineering log T2/T3: by-reference `IMPORTING` needs an exactly-compatible type, not just a convertible one) |
| A20 | "R already declared with type S_PERNR" | distinct loop var per inline `FOR` |
| A23 | `CX_SALV_EXISTING` not caught | catch `cx_salv_error` (the superclass) |
| — | `RETURNING` + `EXPORTING` together | `RETURNING` takes only `IMPORTING` alongside |
| — | `RETURNING TYPE p` | fully type it — `decfloat34` for numerics |
| — | `TYPE c LENGTH n` in `METHODS` | use a data element |
| — | identifiers > 30 chars (incl. test methods) | shorten |
| — | `DEFINITION LOCAL FRIENDS ltcl_x` | precede with `CLASS ltcl_x DEFINITION DEFERRED.` |
| — | `DELETE ADJACENT DUPLICATES COMPARING (tab)` | needs a char comma-list; wrong form = uncatchable `SYNTAX_ERROR` |
| — | report shows technical names | `.prog.xml` `<TPOOL>`; `VRM_SET_VALUES` for `LISTBOX` |
| — | DDIC table name `ZT_*` | invalid — no `_` at char 2/3; DB fields can't be `MESSAGE`/`TYPE`/`NUMBER` |
| — | domain-less custom data element | must be domain-backed for abapGit |

### Freestyle UI
| # | Situation | Resolution |
|---|---|---|
| U1 | `requestContexts is not a function` | name the OData model `"odata"`; JSONModel stays default |
| U2 | `i18n_en_GB.properties` 404 | `supportedLocales:[""]` + `fallbackLocale:""` |
| U3 | header shows, body blank | wrap `Page` in `sap.m.App`; `height:100%` on view; `html,body{height:100%}` |
| U4 | `$batch` 403 then 200 | normal V4 CSRF self-heal — no fix |
| U5 | rows missed/duplicated between pages | send `$orderby` (a `Sorter` per key) |
| U7a | only ~5000 rows load | gateway page-caps below `$top` — loop against `$count`/`getCount()` |
| U7b | drill-click history stacks on the page | `core:HTML` content must have exactly one root element |
| A35 | slow dashboard | one compact row per employee + client-side aggregation, not deep paging of a GROUP BY view |

---

## Appendix B — cheat-sheets

### Reserved / risky CDS element names
`POSITION` (confirmed). Also avoid: `CLIENT KEY USER LANGUAGE DATE TIME VALUE LEVEL NAME
TYPE UNION ALL DISTINCT`. When in doubt, suffix `Id` / `Code` / `Text`.

### DDIC types that need a `cast` in CDS
| Type | Fields seen | Cast to |
|---|---|---|
| `DATS`/`TIMS` (infotype dates, conv-exit `PDATE`) | `BEGDA ENDDA GBDAT DESTA DEEND` | `abap.dats` / `abap.tims` — **mandatory for OData** |
| `LANG` | `SPRSL` | **cannot cast** — select raw or drop |
| conv-exit code fields | `SPRAS`, etc. | `abap.char(n)` — breaks OData V4 otherwise |
| `CURR` (amounts) | `PA0008-ANSAL`, wage-type `BETxx` | `abap.dec(15,2)` (or ref field + `@Semantics`) |
| `QUAN` (quantities) | `PA2006-ANZHL/KVERB`, `PA2002-ABWTG/STDAZ`, `PA0008-DIVGV`, `PA0024-AUSPR` | `abap.dec(n,2)` |
| integer literal → `NUMC` | — | cast a **char** literal instead |

### DDIC name rules
- Table name: **no `_` at position 2 or 3** → `ZT_FOO` invalid, `ZHR360_FOO` fine.
- DB table field: not `MESSAGE` / `TYPE` / `NUMBER` → use `LEAD_MSG` / `MSGTY` / `MSGNO`.
- Domain: `SCRLEN` ≥ text lengths; `SCRTEXT_S ≤ 10`, `_M ≤ 20`, `_L ≤ 40`.
- Custom data element: domain-backed.
- BSP application: ≤ 15 chars.

---

## Appendix C — commit & version convention

- **Version tag** in every commit subject: `vX.YZ - <what>`. Bump `Z` per increment,
  `Y` per phase, `X` per major re-architecture. (Employee 360 is on `v0.49`.)
- **Subject:** `vX.YZ - <imperative, what changed>` — and, for a trap fix, the code
  `(A37: <one-line cause>)`.
- **Body:** what + why (the symptom, the root cause, the fix), which files, any data-change note.
- **Trailer** (exactly):
  ```
  Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
  ```
- PR body trailer (when a PR is used):
  ```
  🤖 Generated with [Claude Code](https://claude.com/claude-code)
  ```
- **Push only when the user asks** — unless the Register row says "direct push" for that
  project (then push each green increment so the user can pull).

---

*Maintained by Bolt. Last shaped: 2026-09-11. Add every new trap to Appendix A the day it is hit.*
