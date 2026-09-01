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
  `PA0008-DIVGV` — `cast( … as abap.dec(11,2) )`

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
