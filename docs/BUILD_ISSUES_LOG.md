# Employee-360 — Build & Activation Issues Log

Running log of every error hit while activating this repo on the SAP system,
with the root cause and the fix. Use this to avoid repeating the same mistakes.

**Legend:** 🔴 blocked activation · 🟡 warning · ✅ fixed in the commit noted.

---

## A. CDS view-entity syntax

| # | Symptom | Root cause | Fix | Commit |
|---|---|---|---|---|
| A1 | 🔴 "Unexpected word WHERE (the keyword { was expected)" | In a **CDS view entity** the `WHERE` clause comes **after** the `{ … }` element list, not before it (unlike some examples that pre-date view entities). | Moved every `WHERE` to after the braces. | 22ed3f9 |
| A2 | 🔴 "Unexpected word IN" | `IN ( 'a', 'b' )` is **not allowed inside a JOIN `ON` condition** in CDS. It is allowed in `WHERE`. | Replaced `ON … AND x IN ('a','b')` with `AND ( x = 'a' OR x = 'b' )`. Single-value `IN` in `WHERE` → `=`. | 22ed3f9 |
| A3 | 🔴 "Operands of the division must be of decimal type" (shown as a generic activation failure of the KPI/root view) | CDS arithmetic `/` **requires decimal operands**. `( 12 - count ) * 100 / 12` is all-integer. | Use the built-in `division( dividend, divisor, decimals )` function. | 63ed426 |
| A4 | 🔴 "Keyword DISTINCT required for COUNT(DISTINCT CHECKID)" | `COUNT( col )` on a column coming from a `LEFT JOIN` to a view that can multiply rows: the compiler demands explicit `COUNT( DISTINCT col )`. | Write `count( distinct Iss.CheckID )`. | v0.9 |
| A5 | 🔴 "Key definition of branch N must match key definition of branch 1" | In a `UNION` view entity, **every** branch must carry the **same `key` markers** on the same elements. Removing `key` from branches 2..n is wrong. | `key` on `EmployeeID` + `CheckID` in **all 12** branches of `ZI_HR360_ISSUE`. | v0.9 |
| A6 | 🔴 UNION branch elements need names | In `UNION`, non-field expressions (`cast(...)`, `concat(...)`) must have an explicit `as <name>` in **every** branch; names must match branch 1. | Explicit `as <name>` on every element in every branch. | 5982fad |
| A7 | 🔴 "CAST of type INT1 to type NUMC is not possible" | `cast( 0 as abap.numc( 8 ) )` — the literal `0` is typed `INT1`; INT→NUMC cast is not allowed. | Cast a **char** literal: `cast( '00000000' as abap.numc( 8 ) )`, or drop the field. | v0.9 |
| A8 | 🟡 "CASE expression without ELSE branch can lead to NULL values" | `count( distinct case when … then … end )` with no `ELSE`. Intentional (NULL is ignored by `count`), but it is a warning. | Rewrote as `sum( case when … then 1 else 0 end )` where possible — also removes the warning. | 5982fad |
| A9 | 🟡 "Annotation value '…' length (44) too long. Type must be 'STRING(40)'" | `@EndUserText.label` (and other VDM annotations) are capped at **40 characters**. | Keep every label ≤ 40 chars. | v0.9 |
| A10 | 🔴 "The column <X> is unknown" (MOABW, QUOMO, SPRSL, STEXT, SLTP1, RESERVE, PRETX, MASSN, PREAS) | Text-table / helper-table joins written against **field names that don't exist** in that table on this system (my HR text-table knowledge was unreliable — e.g. time infotypes don't store `MOABW`; `TOAAT` has no `RESERVE`; `T556B` has no `SPRSL`). | **Removed every text-table join** from the interface views. Views expose the raw infotype codes only; readable texts are re-added later, verified against the live DDIC. | v0.9 |
| A11 | 🔴 "The column STAT2 is unknown" — **REPEATED across v0.7/v0.8/v0.9** | `PA0001` on this system does **not** expose `STAT2` (nor `STAT1`/`STAT3`). Employment status is not on the org-assignment infotype here. I kept `O.stat2` after it first errored — the exact "repeating the same mistake" the user called out. | Removed `EmploymentStatus` from `ZI_HR360_EMP_BASIC` entirely. Root/reports/KPI now use a literal placeholder or omit it. Re-source from `PA0000-STAT2` only after verifying that field exists in SE11. | v0.10 |
| A12 | 🔴 "POSITION is a reserved word (choose another field name)" | `Position` / `POSITION` is a reserved word in CDS / the generated DB view. Cannot be a CDS element name. | Renamed the element `Position` → `PositionId` everywhere (views, projections, root, report engine, tests). Other names to avoid: `CLIENT`, `KEY`, `USER`, `LANGUAGE`, `DATE`, `TIME`, `VALUE`, `LEVEL`, `NAME`, `TYPE` (context-dependent). | v0.10 |
| A13 | 🔴 "ZI_HR360_PAYROLL-ANNUALSALARY reference information missing or data type wrong" | A DDIC **CURR** (amount) or **QUAN** (quantity) field selected into a CDS element needs a **reference field** (currency/unit key) that is also in the view **and** a `@Semantics.amount.currencyCode` / `.quantity.unitOfMeasure` annotation — OR you must `cast` it to a plain type. Affected: `ANSAL` (CURR), `ANZHL`/`KVERB` (QUAN), `ABWTG`/`STDAZ` (QUAN). | `cast( <field> as abap.dec( n, 2 ) )` for every amount/quantity field — plain decimal, no reference needed. Proper `@Semantics.amount…` added later with the currency/unit column. | v0.10 |
| A14 | 🔴 "Field SEVERITYCRITICALITY contains a not supported expression" + "Could not parse DDL source for entity ZC_HR360_*" | A **projection view** (`as projection on …`) may only project existing elements, redirects, and a very small set of functions. Arbitrary `CASE … END` expressions are **not allowed in a projection** — they must live in the underlying **interface** view. Once one element fails, the whole projection "could not be parsed", which cascades to "not part of a business object" on every child projection and the service. | Moved the `CASE` criticality columns **into the interface views**: `SeverityCriticality` into `ZI_HR360_ISSUE`, `QualityStatusCriticality` into `ZI_HR360_EMPLOYEE`. Projections just list the element name. | v0.11 |
| A15 | 🔴 "Function AVG: Narrowing type DEC(11,1) not allowed" | `avg( CompletenessPercent as abap.dec( 5, 1 ) )` — the source is already `DEC(11,1)` (result of `division(…, 12, 1)`); `AVG( x AS <type> )` may only **widen**, never narrow. | Use plain `avg( CompletenessPercent )` (let the result type stand), or cast to a wider type. | v0.11 |
| A16 | 🟡 "CAST INT4 to identical type" / "CAST CHAR to identical type" | Redundant `cast( x as abap.int4 )` where `x` is already `int4` (e.g. `cast( coalesce( Kpi.TotalIssueCount, 0 ) as abap.int4 )` — `coalesce` of two int4 is already int4). Warning only, but noise. | Drop the redundant outer `cast`. | v0.11 |
| A17 | 🔴 "Function AVG is only allowed with addition 'as'" (after A15 removed the `as`) | `AVG()` in a CDS view **must** be `avg( x as <type> )` — the `as` is mandatory — but (A15) the type may only widen. Both constraints at once. | Give the source element a fixed type first (`cast( division(…) as abap.dec( 5, 1 ) ) as CompletenessPercent` in the root), then `avg( CompletenessPercent as abap.dec( 5, 1 ) )` — same type, satisfies both. | v0.12 |
| A18 | 🔴 "Could not parse DDL source for entity ZC_HR360_*" — **persisted through v0.9/v0.10/v0.11** despite clean-looking projection syntax | After ~10 rounds of whack-a-mole on the projection layer, the child projections + their `redirected to` wiring never parsed on this system. Root cause not fully isolated (candidates: `as projection on` for a non-composition child, `@Metadata.allowExtensions` interaction, cross-BO redirect). | **Stopped fighting it.** v0.12 ships a **minimal viable BO**: root `ZI_HR360_EMPLOYEE` **flattens** Personal + OrgAssignment as columns (LEFT JOIN, no associations); the only exposed entities are `Employee`, `DataQualityIssue`, `KpiOverview`. The 8 detail interface views stay active but unwired. Child projections/bdefs/pools **deleted**. Detail facets get re-added **one entity at a time**, verifying activation after each. | v0.12 |

**Process change (v0.12):** stop shipping ~150 objects per round. Grow from a
working core: root BO + service activating end-to-end, then ONE child entity per
commit, re-activating each time. Slower per feature, far fewer dead rounds.

| A19 | 🔴 BDEF: `The behavior definition is "strict", which means that every entity must be flagged either as "lock master" or as "lock dependent"` + `Operations need to be implemented for the entity …, which means an implementation class needs to be specified` | A `strict ( 2 )` unmanaged BDEF forces a `lock master`/`lock dependent` flag and at least the operations wired to a pool — neither fits a **pure read-only** entity with no persistent table. | **v0.14:** dropped the RAP BO wrapper for now. `ZC_HR360_EMPLOYEE` is a plain `define view entity … as select from` query view (no `provider contract`, no BDEF, no pool) — same as `ZC_HR360_ISSUE` / `ZC_HR360_KPI_OVERVIEW`, which activate fine. Deleted `zi/zc_hr360_employee.bdef` + `zbp_hr360_employee`. `ZI_HR360_EMPLOYEE` changed `define root view entity` → `define view entity`. The transactional/read-only RAP BO wrapper is re-added later once the strict-mode read-only pattern is settled against this release (likely `strict ( 1 )` or a managed BO). Read-only OData from CDS is still a valid S/4 delivery. | v0.14 |
| A20 | 🔴 Report: `"R" was already declared with the type "S_PERNR" and cannot be used with the type "S_BUKRS" here` | `build_scope` used one inline `FOR r IN s_pernr[]` then `FOR r IN s_bukrs[]` … — inline `FOR r` declares `r` **once**; the second loop reuses it with an incompatible row type. | Distinct loop variable per `FOR`: `FOR rp IN s_pernr[]`, `FOR rb IN s_bukrs[]`, `FOR rw IN …`, `FOR ro IN …`. | v0.14 |
| A21 | 🔴 Report: `"CONV BAL_S_EXTN( )" is not type-compatible with formal parameter "EXTERNAL_ID"` | `cl_bali_header_setter=>create( external_id = CONV bal_s_extn( … ) )` — `external_id` is not `BAL_S_EXTN`. | Dropped the `external_id` argument (optional); keep object/subobject only. | v0.14 |
| A22 | 🔴 Report: `Method "SAVE_LOG_TO_DB" does not exist. There is, however, a method with the similar name "SAVE_LOG"` | `cl_bali_log_db=>get_instance( )->save_log_to_db( )` — the method is `save_log( )`. | Renamed the call. | v0.15 |
| A23 | 🟡 Report: `The exception CX_SALV_EXISTING is not caught or declared in the RAISING clause` | `cl_salv_sorts->add_sort( )` raises `CX_SALV_EXISTING` / `CX_SALV_NOT_FOUND` on top of `CX_SALV_DATA_ERROR`; only the last was caught. | One `CATCH cx_salv_error` (the common superclass of every `cx_salv_*`) instead of narrow catches. | v0.15 |
| A24 | 🔴 **Fiori preview**: "Application could not be started due to technical issues — Do not use conversion ext PDATE here." | The **runtime** (not activation) error. A PA-infotype date field carries data element `BEGDA`/`ENDDA` whose domain has **conversion exit `PDATE`**; the OData V4 / Fiori Elements runtime cannot render a field with that conversion routine. Affected every date sourced from `BEGDA`/`ENDDA` (and `GBDAT` for birth date). | `cast( <field> as abap.dats )` on **every** infotype date element in the CDS — strips the data element + conversion exit, leaving a plain `DATS`. Same for time fields → `cast( … as abap.tims )`. | v0.16 |

**Rule:** never expose a raw PA-infotype `BEGDA`/`ENDDA`/`GBDAT`/`DESTA`/`DEEND`/…
date to OData. Always `cast( x as abap.dats )`. Times → `cast( x as abap.tims )`.

| A25 | 🔴 **Fiori preview**: loads to a **blank white screen**, no error | A Fiori Elements List Report renders **nothing** without `@UI` annotations — at minimum `@UI.headerInfo` + one `@UI.lineItem`. The service had zero UI annotations (metadata extensions were removed in C2/A18 because the hand-written abapGit DDLX format failed to import). | v0.17: added **minimal `@UI` inline** in `ZC_HR360_EMPLOYEE` / `ZC_HR360_ISSUE` (headerInfo, ~8 lineItems, ~4 selectionFields, criticality on QualityStatus). Rulebook §2 wants these in a Metadata Extension — that move happens once the correct abapGit DDLX serialization is confirmed by creating one MDE in ADT and reading back how abapGit serializes it. | v0.17 |
| A26 | 🔴 **Fiori preview**: List Report renders with filter bar + columns, but **"Go" returns no rows** (tested in client 400) | Under investigation. Candidates: (a) the `P_ORGIN` DCL denies every row because the previewing user has no HR display authorization; (b) no PA0001/PA0002 data in that client; (c) test data's `BEGDA`/`ENDDA` not valid on the system date. | v0.18 diagnostic: temporarily `#NOT_REQUIRED` on the anchor views (DCL off) + `pa0002` INNER→LEFT JOIN. If rows appear → authorization (assign a role with `P_ORGIN` activity Display, or relax the DCL); restore `#CHECK`. If still empty → data/date issue in that client. | v0.18 |

**⚠ Self-note:** before every "column unknown / reserved / reference" conclusion,
check this table first. STAT2 (A11) was flagged in an earlier screenshot and I
did not act on it — do not repeat.

### CDS reserved words seen so far → never use as an element name
`POSITION`. (SAP list also includes `CLIENT KEY USER LANGUAGE DATE TIME VALUE
LEVEL NAME TYPE UNION ALL DISTINCT` in various contexts — when in doubt add an
`Id`/`Code`/`Text` suffix.)

### DDIC field types that need a `cast` (or a reference field + `@Semantics`)
- **CURR** (amounts): `PA0008-ANSAL`, wage-type `BETxx` — `cast( … as abap.dec(15,2) )`
- **QUAN** (quantities/hours/days): `PA2006-ANZHL/KVERB`, `PA2002-ABWTG/STDAZ`,
  `PA0008-DIVGV`, `PA0024-AUSPR` — `cast( … as abap.dec(n,2) )`

### Projection views (`as projection on …`) — rules
- Only project **existing element names**, `redirected to` associations, and a
  narrow function set. **No `CASE`, no arithmetic, no `cast`, no literals.**
  Put every computed column in the **interface** view; the projection just names it.
- `AVG( x AS <type> )` may only **widen** the type, never narrow.
- Compact one-line element lists (`key A, B, C,`) parse fine, but if a projection
  "could not be parsed", reformat one-element-per-line and check for a stray
  computed column first.

---

## B. RAP behavior / BO structure

| # | Symptom | Root cause | Fix | Commit |
|---|---|---|---|---|
| B1 | 🔴 Cascade: "Type ZI_HR360_EMPLOYEE is unknown" on every BDEF; "Entity ZC_HR360_* does not exist" on the service | A single upstream CDS view failing to activate blocks the entire BO + service + programs. The long error list is 95 % cascade — always fix the **first real CDS error**, re-activate, repeat. | — (process note) | — |
| B2 | 🔴 "Transactional Projection View must be part of a business object" | `define view entity ZC_X as projection on ZI_X` creates a *transactional projection* that **must** belong to a BO — i.e. `ZI_X` must be a **composition child** of the root, and `ZC_X` reachable by `redirected to`. Plain associations are not enough. | Children modelled as **compositions** of the root again (with `association to parent` back on each child). | v0.9 |
| B3 | 🔴 "…where-used list for CLAS ZBP_HR360_* … check for syntax errors" | The behavior-pool class fails because its `FOR BEHAVIOR OF <bdef>` target isn't active yet (cascade of B1), **or** the bdef `define behavior for` entity has no matching `lhc_*` handler in the pool's CCIMP include. | One bdef file for the whole composition tree; one pool `ZBP_HR360_EMPLOYEE` with `lhc_employee` **plus one `lhc_<child>` read handler per child**. | v0.9 |
| B4 | 🔴 Behavior definition ordering / circular dependency (root `composition of` child ↔ child `association to parent` root) | This circularity is **normal** for RAP. It only resolves with ADT **"Activate All Inactive ABAP Development Objects"** on the package — never file-by-file, and sometimes needs **two passes**. | — (process note; documented in README) | — |
| B5 | 🔴 `authorization master ( instance )` needs `get_instance_authorizations`; `( global )` needs `get_global_authorizations` | Declaring instance auth without the handler method fails. | Use `authorization master ( global )` + `get_global_authorizations` (a single `AUTHORITY-CHECK 'P_ORGIN'`); row-level filtering is done by DCL. | v0.9 |

---

## C. abapGit serialization / import

| # | Symptom | Root cause | Fix | Commit |
|---|---|---|---|---|
| C1 | 🔴 "XML parser error: unexpected symbol; expected '<'" — Import of `ZMSG_HR360` failed | Message texts contained a raw `&` (`&1`, `&2` placeholders). `&` must be XML-escaped. | `&1` → `&amp;1` in the `.msag.xml`; `<item>` row wrappers for the `T100` table. | 22ed3f9 |
| C2 | 🔴 "The description is missing" — Import of `ZC_HR360_*_MDE` failed (×12) | My hand-written `.ddlx.xml` abapGit metadata used the wrong structure (`<DDLXS><DDLXNAME><DDTEXT>`). A failed **import** aborts the whole "Activate All Inactive" batch. | **Removed all 12 metadata extensions.** UI annotations will be authored in ADT / BAS against the live system (BUGS_AND_ISSUES #007). Projections keep `@Metadata.allowExtensions`. | 9468059 |
| C3 | (avoided) `.tabl.xml` for custom tables | Not applicable — this project has **zero custom DDIC** (standard tables only). | — | — |

---

## D. Clean-ABAP / report code

| # | Symptom | Root cause | Fix | Commit |
|---|---|---|---|---|
| D1 | 🔴 "Type TY_SCOPE is unknown" in the 3 report programs | `ZIF_HR360_REPORT_ENGINE` not active (cascade), plus a fragile definition: `TYPE RANGE OF` inline in a structure and `CHAR8`/`CHAR12` data elements that may not exist. | Separate named `RANGE OF` types; explicit `c LENGTH n` instead of `CHARn` data elements. | 63ed426 |
| D2 | 🔴 Invalid `DO iv_max_depth = 20 TIMES` and undefined table type in `ZCL_HR360_ORG_READER` | Hand-written OM traversal with syntax errors. | Rewrote the class: `DO iv_max_depth TIMES`, local types, no `SELECT` in `LOOP`. | 22ed3f9 |
| D3 | Rulebook §5: `TABLES` statement in reports | `SELECT-OPTIONS … FOR pa0001-pernr` needs a declared field. | `DATA gv_pernr TYPE pernr_d.` + `SELECT-OPTIONS … FOR gv_pernr`. | 22ed3f9 |
| D4 | 🔴 `SELECT FROM zc_hr360_kpi_overview` (an `@Analytics.query`) in the report engine | Analytical query views are not meant to be read with a plain `SELECT`. | Engine aggregates from `ZI_HR360_EMP_KPI` + `ZI_HR360_EMP_BASIC` instead; `ZC_HR360_KPI_OVERVIEW` is now a plain aggregating view (no `@Analytics.query`). | 63ed426 / v0.9 |
| D5 | 🔴 `FILTER … USING KEY primary_key` in the test class | `FILTER` needs the internal table to have a declared sorted/hashed key. | Use `SELECT COUNT(*)`; keep 3 focused tests. | 63ed426 |

---

## E. Scope decisions forced by activation problems

| Item | Decision | Reason | Re-add when |
|---|---|---|---|
| Metadata extensions (12 `*_MDE`) | Removed | abapGit DDLX format issue (C2) | Fiori app generation in BAS |
| `ZI_HR360_ORG_HIER` / `ZI_HR360_ORG_NODE` (org tree) | Removed | `define hierarchy` too fragile to debug blind | Phase 2, against live system |
| `ZI_HR360_MANAGER` (manager resolution) | Removed / blank | HRP1001 chief-position path unverified | when client confirms the relationship IDs |
| All text-table joins (names, `*Name` columns) | Removed | Unreliable field names (A10) | verify each text table's key in DDIC, add back one at a time |
| `ZI_HR360_QUALIF` catalog joins | Removed | HRP1000/1001 `QUALI` cast risk | when OM qualifications catalog is confirmed |
| Wage-type-level pay detail | Out of scope | needs a table function | later phase |

---

## F. Process notes for future work

1. **Fix the first real error, re-activate, repeat.** Downstream "does not exist / unknown type" lines are cascade noise.
2. **Always "Activate All Inactive" on the package**, run it twice, before reading the error list as final.
3. **CDS view-entity gotchas to check before writing:** `WHERE` after `{}`; no `IN()` in `ON`; `/` needs decimals (use `division()`); `UNION` needs identical `key` + named elements in every branch; `@EndUserText.label` ≤ 40 chars; don't `cast` integer literals to NUMC.
4. **Don't invent HR text-table field names.** Expose raw codes; add texts only when verified against DDIC (SE11) on the target system.
5. **RAP read-only children must be compositions** to be exposed as projection entity sets with `redirected to`.
6. **Hand-written abapGit metadata XML is risky** for DDLX/MSAG/SRVD. Prefer object types whose abapGit format is simple and proven (DDLS, CLAS, PROG, BDEF-source), or create the object in ADT and let abapGit serialize it.

---

## G. Repo hygiene

| # | Issue | Fix | Commit |
|---|---|---|---|
| G1 | Service binding `ZHR360_UI_SRVB_O4` disappeared / needed recreating after every `abapGit` pull | The binding was **not in the repo** (we had left it "for the implementer"). Now shipped as `src/zhr360_ui_srvb_o4.srvb.xml` + `.g4ba.xml` with `PUBLISHED=true` — a pull recreates and publishes it. | v0.19 |
| G2 | `/src` cluttered with unwired WIP objects → longer, noisier activation runs | Only the **active green-build** objects stay in `/src`. Unwired detail views (`orgassign`, `education`, `qualif`, `leave`, `attendance`, `payroll`, `document`, `timeline`) moved to `/staging/detail_views/` — abapGit only processes `STARTING_FOLDER=/src/`, so it ignores them. They keep the fixes already applied (date casts, no text joins). | v0.19 |
| G3 | 🔴 abapGit pull shows **every** DDLS/CLAS/PROG/SRVD/DCLS as "different" / "Delete and recreate local object" on **every** pull, even with no real change | abapGit writes its `.xml` metadata files **with a UTF-8 BOM** (`EF BB BF`) — confirmed by inspecting a known-good abapGit repo (`ZRAP_MT`). Every hand-written `.xml` in this repo lacked the BOM, so abapGit's local re-serialization (with BOM) never byte-matched the repo file → perpetual diff. Source files (`.asddls` / `.asbdef` / `.abap` / `.srvdsrv`) correctly have **no** BOM. | Added `EF BB BF` to all 36 `*.xml` + `.abapgit.xml`. **Rule: every abapGit `.xml` metadata file needs a UTF-8 BOM; source files must not have one.** Also shipped the auto-generated `*.sush.xml` (S_START auth default from the service binding) and reverted the `/staging` split (it made abapGit want to delete the still-active detail views). | v0.20 |
