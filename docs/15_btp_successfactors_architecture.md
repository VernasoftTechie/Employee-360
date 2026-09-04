# 15 — BTP + SuccessFactors Target Architecture

**Status:** planning reference (continuation doc — read this first if the context
window resets on the BTP/SF track)
**Date:** 2026-09-04
**Supersedes for the SF track:** `01_solution_architecture.md`,
`03_persistence_and_source_model.md`, `04_cds_design.md` (those describe the
S/4-on-stack build, which stays as-is for on-prem but is **not** the SF target).

---

## 1. Decision record (locked with the client)

| # | Question | Answer |
|---|---|---|
| 1 | SuccessFactors as HR system of record, or hybrid with S/4 HCM? | **SF is the system of record.** Full rebuild of the data + data-quality layer off ABAP. |
| 2 | BTP runtime | **Cloud Foundry** — already provisioned. |
| 3 | Source tenant | SuccessFactors **TDD** — a full Employee Central test tenant, OData API enabled. |
| 4 | Dashboard technology | **Keep CAP + Fiori (freestyle UI5 dashboard + Fiori Elements Employee 360).** Not SAC. Rationale in §12. |

### What this means

- The ABAP CDS work (`ZI_HR360_*`, `ZC_HR360_*`, the 12-branch `ZI_HR360_ISSUE`
  UNION, `ZHR360_UI_SRVD`) **does not carry to BTP**. CDS cannot read a remote
  OData source. The *logic* (12 checks, completeness %, org rollups) is
  re-implemented in SQL/CAP.
- The **"read from standard tables only / zero custom persistence"** rule was an
  S/4 constraint. On BTP it is **dropped** — SF is an API, not a database, so an
  HR-wide quality scan needs a replicated store (SAP HANA Cloud). This must be
  signed off explicitly; it is the single biggest change from the original spec.
- The two Fiori apps and their entity-set contract survive almost unchanged
  (§11) — only the OData endpoint URL and the annotation location move.

### Effort

Rough, one developer, TDD data only, no production cutover:

| Phase | Work | Duration |
|---|---|---|
| 1 | BTP foundation + entitlements + auth trust | 1 week |
| 2 | SF OAuth client, API user, destination, connectivity proof | 3–5 days |
| 3 | Extraction job + HANA Cloud replica + 12 checks re-mapped in SQL | 4–6 weeks |
| 4 | CAP OData V4 service (same entity sets) | 1–2 weeks |
| 5 | Repoint + deploy both Fiori apps, Work Zone site, roles | 1 week |
| 6 | Volume test, monitoring, CI/CD | 1 week |
| **Total** | | **~2.5–3 months** |

---

## 2. Target architecture

```
 SAP SuccessFactors  (TDD tenant, Employee Central)
        │
        │  OData v2 API   https://<tdd-api-server>/odata/v2
        │  (or Compound Employee API for bulk delta — see §7)
        ▼
 ┌─────────────────────────────────────────────────────────────┐
 │ SAP BTP — Cloud Foundry (one subaccount, one space)          │
 │                                                             │
 │  Extraction job  ── scheduled (SAP Job Scheduling service)   │
 │    CAP module or Node worker, OAuth2 SAML Bearer to SF       │
 │        │  nightly full + delta                              │
 │        ▼                                                     │
 │  SAP HANA Cloud                                              │
 │    · replica tables  (hdbtable)  — SF entities, trimmed      │
 │    · DQ views (hdbview / CAP CDS): 12 checks, per-employee   │
 │      issue rows, completeness %                              │
 │    · aggregate views: status split, by-check, by-org, KPI    │
 │        ▲                                                     │
 │        │                                                     │
 │  CAP service  (Node)  ── OData V4 out                        │
 │    exposes: Employee + 8 detail sets + 4 dashboard aggregates│
 │    row-level auth from IAS user attributes                   │
 │        ▲                                                     │
 │        │  /odata/v4/hr360/                                   │
 │  HTML5 App Repository                                        │
 │    · employee360   (Fiori Elements V4)                       │
 │    · dashboard      (freestyle UI5)                          │
 └─────────────────────────────────────────────────────────────┘
        ▲
        │
 SAP Build Work Zone (standard edition)  — tiles, roles, site
        ▲
        │  SSO
 SAP Cloud Identity Services (IAS)  ── federated with SF for login
```

**One codebase, one skillset (CAP + CDS + SQL + UI5).** No SAC licence, no
Datasphere licence. Datasphere/SAC remain a later option if analytics scope
grows (§12).

---

## 3. BTP entitlements checklist

In the CF subaccount, assign quota for:

| Service / plan | Purpose |
|---|---|
| Cloud Foundry runtime | app + job containers |
| SAP HANA Cloud (`hana` / tools) | replica + DQ views |
| HTML5 Application Repository (`app-host`, `app-runtime`) | serve the 2 Fiori apps |
| SAP Build Work Zone, standard edition | launchpad site, tiles, roles |
| Destination service (`lite`) | SF API destination, HTML5 dest |
| Connectivity service | only if any on-prem hop is added later (not needed for pure SF) |
| Authorization & Trust Management / XSUAA (`application`) | app auth, scopes, role collections |
| SAP Job Scheduling service (`standard`) | nightly extraction trigger |
| Application Logging (`standard`) | job + service logs |
| SAP Alert Notification (`standard`) | replication failure alerts |
| SAP Cloud Identity Services | IdP (usually already tenant-wide) |

**Booster:** BTP cockpit → Boosters → **"Set up Extensibility for SAP
SuccessFactors"**. It auto-creates the `sap_successfactors_extensibility`
destination and the subaccount↔IAS↔SF trust. Run it before doing §5 by hand.

---

## 4. Identity & trust

1. SAP Cloud Identity Services (IAS) tenant = the IdP for the BTP subaccount.
2. Establish subaccount → IAS trust (OpenID Connect).
3. Federate IAS with SuccessFactors so the same user logs into Work Zone and SF.
4. App authorisation is **XSUAA role collections** mapped to IAS groups.
   There is **no per-user call to SF** (SF is read via a technical destination in
   the batch job), so "who can see which company code / org unit" is enforced
   **inside the CAP service** from the logged-in user's IAS attributes
   (e.g. `companyCode`, `orgScope` groups) — see §10.

---

## 5. SuccessFactors setup (TDD)

### 5.1 In SuccessFactors admin

1. **OAuth client** — Admin Center → *Manage OAuth2 Client Applications* → Register:
   - generate an X.509 certificate (SF can generate it; download the private key)
   - note the **API Key** (client id)
2. **API / technical user** — a dedicated user id (e.g. `HR360_API`), no UI login
   needed, assigned an RBP permission role that grants:
   - *Admin > Manage Integration Tools > Allow Admin to Access OData API*
   - *Employee Central API > Employee Central Foundation OData API (read)*
   - entity-level read on every entity in §9
3. **Enable the OData entities** you need (most EC entities are on by default;
   MDF/custom ones may need enabling).
4. **Datacenter / API server** — record the TDD tenant's API host. It follows the
   datacenter, e.g. `api<N>.successfactors.com`, `api.successfactors.eu`,
   `api<N>preview.sapsf.*` for preview. Find it in *API Center* or SAP Note
   2215682. Also record the **Company ID**.

### 5.2 In BTP — Destination

Create destination `SF_ODATA_TDD`:

| Field | Value |
|---|---|
| Type | HTTP |
| URL | `https://<tdd-api-server>/odata/v2` |
| Proxy Type | Internet |
| Authentication | `OAuth2SAMLBearerAssertion` |
| Audience | `www.successfactors.com` |
| Client Key | *(API Key)* |
| Token Service URL | `https://<tdd-api-server>/oauth/token` |
| `nameIdFormat` | `urn:oasis:names:tc:SAML:2.0:nameid-format:unspecified` |
| `userIdSource` | `email` (or `loginName`) |
| `companyId` (additional prop) | *(Company ID)* |
| `apiKey` (additional prop) | *(API Key)* |
| assertion signing | upload the X.509 key pair |

**Proof of life:** Destination → *Check Connection*, then from BAS or a curl in
the job: `GET /User?$top=1&$format=json`.

---

## 6. Live vs replicated — decided: **replicated**

A per-request scan of ~40k employees × 12 checks against the SF OData API would
blow the tenant's API call quota and time out. So:

- **Nightly batch** replicates the needed SF entities into HANA Cloud.
- DQ + aggregates run as **SQL views on the replica** — the dashboard and the
  Employee-360 list read pre-computed data (fast, no SF load).
- The Employee-360 **detail page** can optionally do 1 live SF read for the
  freshest single-person view (low volume, fine).

---

## 7. Extraction — two options

### Option A — OData v2 API (recommended to start)

- `cds import` the trimmed SF `$metadata` → external service; consume via CAP
  remote services or plain `@sap-cloud-sdk/http-client`.
- One paged call per entity: `?$format=json&$top=1000` + **cursor pagination**
  (`?paging=cursor`), `$select` to trim payload.
- Effective-dated entities: pass `asOfDate=<today>` for the current-state scan
  (§8).
- Delta: filter `lastModifiedDateTime gt <last run>` where the entity supports it;
  otherwise full reload (TDD volume makes full reload acceptable nightly).
- **Pros:** easy tooling, JSON, simple to debug. **Cons:** many calls, you handle
  paging + effective dating + joins yourself.

### Option B — Compound Employee API (`CompoundEmployee`)

- SOAP API, purpose-built for bulk person extraction with **delta**
  (`last_modified_on`) — this is what SAP's own EC→ECP / EC→S/4 integrations use.
- One paged query returns nested person + employment + job + comp + email + phone.
- **Pros:** fewest calls, native delta, designed for volume. **Cons:** SOAP/XML,
  deeply nested payload to flatten, steeper first build.

**Recommendation:** build with **Option A** for TDD and the first working
version. If call volume / runtime becomes a problem at production scale, swap the
extraction module to **Option B** — nothing downstream (HANA views, CAP, apps)
changes.

---

## 8. Effective dating

EC splits into two shapes:

| Shape | Entities | Query for "current state" |
|---|---|---|
| Effective-dated (date-ranged records) | `EmpJob`, `EmpCompensation`, `EmpEmployment` (partly), `PerPersonal`, `HomeAddress`/`PerAddressDEFLT`, `EmpPayCompRecurring` | `asOfDate=<today>` — returns the row valid today |
| As-of-now with change deltas | `PerPerson`, `PerEmail`, `PerPhone`, `PerNationalId` | plain read; use `lastModifiedDateTime` for delta |

The DQ scan is a **point-in-time (today)** check → always pass `asOfDate=today`
to the effective-dated entities, then treat "no row valid today" as the
equivalent of the infotype-gap checks in the old design.

---

## 9. The 12 checks — infotype → SuccessFactors re-mapping

**Highest-risk rework.** Each check must be re-validated against real TDD data;
the "Confidence" column flags what to confirm first.

| # | CheckID | Old S/4 source | SF entity · field | Rule on the replica | Confidence |
|---|---|---|---|---|---|
| 1 | `MAND_DOB` | PA0002-GBDAT | `PerPerson.dateOfBirth` | null → CRITICAL | High |
| 2 | `MAND_GENDER` | PA0002-GESCH | `PerPersonal.gender` | null/blank → CRITICAL | High |
| 3 | `STAT_NATION` | PA0002 nationality | `PerPersonal.nationality` | null → CRITICAL | High |
| 4 | `ORG_COSTCTR` | PA0001-KOSTL | `EmpJob.costCenter` | null (asOfDate today) → CRITICAL | High |
| 5 | `ORG_POSITION` | PA0001-PLANS | `EmpJob.position` | null → CRITICAL | High |
| 6 | `PAY_BASICPAY` | PA0008 missing | `EmpPayCompRecurring` (or `EmpCompensation`) | no recurring pay component row valid today → WARNING | Medium — confirm which comp entity the tenant uses |
| 7 | `CONTACT_MAIL` | comms / PA0105 | `PerEmail` where `emailType` = business | no business-email row → WARNING | High |
| 8 | `BANK_IBAN` | PA0009-IBAN | `PaymentInformationV3` + `PaymentInformationDetailV3.ibanCode` | no payment info / blank IBAN → CRITICAL | Medium — confirm `PaymentInformationV3` enabled in TDD |
| 9 | `EDU_MISSING` | PA0022 | `Background_Education` | zero rows for the person → WARNING | High |
| 10 | `QUAL_MISSING` | PA0024 | *(EC has no single standard "qualifications" entity)* — usually an MDF (`cust_Qualification…`) or `Background_*` | zero rows in the tenant's chosen entity → WARNING | **Low — confirm the entity with the client** |
| 11 | `CONTACT_ADDR` | PA0006 | `PerAddressDEFLT` / `HomeAddress` | no primary address row → WARNING | Medium — confirm address entity name in TDD |
| 12 | `INVALID_DOB` | implausible GBDAT | `PerPerson.dateOfBirth` | future-dated, or age <15 / >75 → CRITICAL | High |

Completeness % keeps the current formula:
`(12 − distinct failed CheckID count) / 12 × 100`, computed per employee in a
HANA view.

Org rollup dimensions come from `EmpJob` (company, businessUnit, department,
costCenter, location) + `FOCompany` / `FODepartment` / `FOBusinessUnit` /
`FOCostCenter` foundation objects for the texts — the drill stays
Company → Department/Personnel-area-equivalent → Org-unit.

---

## 10. CAP service

- `db/` — CDS entities mirroring the HANA replica tables + the DQ/aggregate views
  (as CDS views or `@cds.persistence.exists` over `.hdbview`).
- `srv/hr360-service.cds` — projections that reproduce **exactly the current
  entity-set names** so the Fiori apps barely change:
  `Employee`, `Education`, `Qualification`, `LeaveBalance`, `Attendance`,
  `PayrollItem`, `Document`, `TimelineEvent`, `DataQualityIssue`,
  `KpiOverview`, `CheckFailure`, `StatusSplit`, `AreaHealth`.
- `@readonly` throughout (no RAP, no draft — same as today).
- `@UI` annotations: move the current inline CDS annotations into CAP CDS
  annotations or a `srv/annotations.cds` file. The minimal safe set from
  `BUILD_ISSUES_LOG.md` A32 still applies — keep it to `LineItem`,
  `SelectionFields`, `Identification`, `Facets`, `Criticality`.
- **Row-level auth:** a service handler `before READ` adds a `WHERE company IN
  :userCompanies` / `orgUnit IN :userScope` filter built from the JWT's IAS
  attributes / XSUAA scopes. This replaces the ABAP DCL (`P_ORGIN`) from the
  on-stack build.

---

## 11. Fiori apps — what changes

| File | Change |
|---|---|
| `employee360/webapp/manifest.json` | `dataSources.mainService.uri` → `/odata/v4/hr360/`; add the app to `xs-app.json` routes; wrap in an `mta.yaml` module |
| `dashboard/webapp/manifest.json` | same URI repoint; the `sap.m.App` / height fixes from v0.35 stay |
| both | add `ui5-deploy` → replace `deploy-to-abap` custom task with `mta` build (`mbt build`) + `cf deploy` into HTML5 App Repo |
| both | `xs-app.json` + `ui5.yaml` `fiori-tools-appreload`; auth via `@sap/approuter` or Work Zone's managed approuter |
| annotations | Employee-360 `@UI` moves to the CAP layer (§10) |

Cross-navigation (`dashboard` → `Employee-display` intent) keeps working — it
becomes a Work Zone intent instead of an FLP-on-ABAP intent.

**Everything else in the two apps — controllers, views, VizFrame charts, the org
drill-down logic, the JSON view model, the KPI formulas — is unchanged.**

---

## 12. Why not SAC / Datasphere (for now)

- The dashboard is a **custom data-quality tool**, not standard workforce
  analytics — the value is the 12 bespoke checks + drill + hand-off to
  Employee 360. SAC would still need the same HANA modelling underneath and adds
  a licence + a second build tool + a second skillset.
- Keeping CAP + UI5 means **one repo, one language, one deploy pipeline**, and
  the apps already exist and work.
- **Revisit if:** the client later wants ad-hoc slice-and-dice, blending with
  other HR data, or scheduled PDF/story distribution → then put **Datasphere**
  as the replication + modelling layer (it ships prebuilt SuccessFactors
  replication flows and content) and **SAC** on top for those analytics, while
  this tool keeps running on the same HANA Cloud.

---

## 13. Phased plan

1. **Foundation** — subaccount space, entitlements (§3), run the SF
   extensibility booster, IAS trust (§4), HANA Cloud instance.
2. **Connect SF** — OAuth client + API user + entities in TDD (§5.1), destination
   `SF_ODATA_TDD` (§5.2), prove `GET /User?$top=1`.
3. **Extract + persist** — `cds import` trimmed metadata; extraction job (Option
   A); HANA replica tables for the §9 entities; SAP Job Scheduling nightly
   trigger; Alert Notification on failure.
4. **DQ layer** — re-implement the 12 checks as HANA/CDS views against the
   replica; **validate each against TDD data**; build completeness + the 4
   aggregate views.
5. **CAP service** — the 13 read-only entity sets (§10), row-level auth, `@UI`
   annotations.
6. **Apps** — repoint + `mta` build + deploy both to HTML5 App Repo; Work Zone
   site + tiles + role collections; test cross-nav.
7. **Harden** — 40k-row volume/timing test, API quota check, Application Logging
   dashboards, CI/CD (SAP CI&D or GitHub Actions + `cf` CLI), promote TDD → prod
   config as a destination swap.

---

## 14. Open items to confirm with the client / in TDD

1. **Check 10 (`QUAL_MISSING`)** — which SF entity holds "qualifications"?
   (standard `Background_*`, or an MDF `cust_*`, or not tracked in EC at all).
2. **Check 6 (`PAY_BASICPAY`)** — `EmpPayCompRecurring` vs `EmpCompensation` vs a
   pay-scale model; is comp even maintained in TDD?
3. **Check 8 (`BANK_IBAN`)** — is `PaymentInformationV3` enabled and populated in
   TDD?
4. **Check 11 (`CONTACT_ADDR`)** — address entity name (`PerAddressDEFLT` /
   `HomeAddress` / country-specific).
5. TDD **API call quota** and whether it's representative of production.
6. Org structure: which Foundation Objects the client treats as
   "Company Code equivalent" / "Personnel Area equivalent" / "Org Unit".
7. Does the client have **SAP Integration Suite** or **Datasphere** entitlement
   already? (would change §7 toward prebuilt content).
8. Sign-off that **persistence in HANA Cloud** is acceptable (breaks the original
   "no custom persistence" rule — unavoidable for SF).

---

## 15. What carries over from the current repo

| Keep | Rebuild |
|---|---|
| Both Fiori apps (controllers, views, charts, drill logic, KPI formulas) | ABAP CDS interface + consumption views |
| The 12-check **definitions** and completeness formula (as spec) | Their **implementation** (ABAP UNION → HANA SQL) |
| Entity-set contract / names (`Employee`, `StatusSplit`, …) | The service (`ZHR360_UI_SRVD` → CAP OData V4) |
| `docs/14_dashboard_requirement_spec.md` (card layout, KPIs, navigation) | `03_persistence_and_source_model.md`, `04_cds_design.md` (S/4-specific) |
| `BUILD_ISSUES_LOG.md` UI rules (A32 `@UI` minimal set, v0.34/0.35 fixes) | DCL `P_ORGIN` → CAP row-level auth |
| Executable-report logic **as a spec** | `ZCL_HR360_REPORT_ENGINE` (ABAP-only; not on BTP) |
