# Employee-360 — Service Definition & Binding (Doc 06)

**Status:** DRAFT — awaiting approval (batch a).

---

## 1. Service Definition — `ZHR360_UI_SRVD`

```abap
@EndUserText.label: 'HR Employee 360 - UI Service'
define service ZHR360_UI_SRVD {
  // --- transactional query: employee + all read-only child facets ---
  expose ZC_HR360_EMPLOYEE     as Employee;
  expose ZC_HR360_PERSONAL     as Personal;
  expose ZC_HR360_ORGASSIGN    as OrgAssignment;
  expose ZC_HR360_EDUCATION    as Education;
  expose ZC_HR360_QUALIF       as Qualification;
  expose ZC_HR360_LEAVE        as LeaveBalance;
  expose ZC_HR360_ATTENDANCE   as Attendance;
  expose ZC_HR360_PAYROLL      as PayrollItem;
  expose ZC_HR360_DOCUMENT     as Document;
  expose ZC_HR360_TIMELINE     as TimelineEvent;
  expose ZC_HR360_ISSUE        as DataQualityIssue;

  // --- organizational navigation (hierarchy) ---
  expose ZI_HR360_ORG_HIER     as OrgNode;

  // --- HR-wide analytical audit ---
  expose ZC_HR360_KPI_OVERVIEW as KpiOverview;

  // --- value helps ---
  expose I_CompanyCode            as CompanyCode;
  expose I_PersonnelArea          as PersonnelArea       @Consumption.derivation: { } ;
  expose I_ControllingArea        as ControllingArea;
}
```

> Value-help entities: use **released** SAP basic interface views
> (`I_CompanyCode`, `I_PersonnelArea`, `I_CostCenter`, …) where a released
> version exists on the target release; otherwise a small `ZI_HR360_VH_*`
> wrapper over the T-table. Final list pinned in build (does not affect the BO).

---

## 2. Why one service, not two

The PoC suggested splitting transactional vs analytical bindings. Here a
**single service definition** with **one OData V4 UI binding** is enough:

- OData V4 supports transactional, analytical (`@Analytics.query`) and hierarchy
  entity sets in the same service.
- The Object Page, List Report, ALP and the freestyle tree section all consume
  one `$metadata`, one destination, one Fiori tile target — simpler operations,
  one authorization default (`/IWFND/…` + service group).

If a later phase needs an OData V2 consumer (e.g. an older WebDynpro/BSP), add a
second binding on the **same** service definition — no CDS change.

---

## 3. Service Binding

| Property | Value |
|---|---|
| Name (suggested) | `ZHR360_UI_SRVB_O4` |
| Binding type | **OData V4 - UI** |
| Owned by | **you** (per project note) |
| Draft | none (read-only BO) |
| Published to | local `$self` / front-end server via `/IWFND/V4_ADMIN` |

Publishing steps (yours):
1. Create binding `ZHR360_UI_SRVB_O4`, type OData V4 UI, add service definition
   `ZHR360_UI_SRVD`, **Activate**.
2. Assign all objects to package **`ZHR_UTIL`** and one transport.
3. Front-end: expose the service (`/IWFND/V4_ADMIN` → Publish) if the FES is a
   separate client/system; embedded → automatic.
4. Create the Fiori app + tile (Doc 07 §6).

---

## 4. Entity-set behaviour in the binding

| Entity set | Capabilities | Notes |
|---|---|---|
| `Employee` | Read, Query, `$search`, `$filter`, `$orderby`, `$expand` | root; `$search` → `@Search` fuzzy (Doc 04 §7) |
| child sets (`Personal`…`DataQuality`) | Read, Query via `$expand` from `Employee` | independently queryable but UI reaches them by `$expand` |
| `OrgNode` | Read, hierarchy (`$apply` / hierarchy annotations) | consumed by UI5 `TreeTable` |
| `KpiOverview` | Aggregate (`$apply=groupby(...)`) | ALP / Overview Page |
| all | **no** Create/Update/Delete | enforced by BDEF (no operations) + `get_global_authorizations` |

---

## 5. Non-functional

- **`$batch`**: enabled (default V4) — Object Page issues one batched request for
  root + all `$expand`s.
- **Paging**: default server-side paging on `Employee` and every child set;
  `TimelineEvent` and `DataQualityIssue` can be large per employee — set
  `@OData.entitySet.page.size` guidance in the MDE (Doc 07) if needed.
- **ETag**: none (read-only) — clients must not send `If-Match`.
- **Caching**: rely on standard gateway/HANA; no custom buffering. `ZI_HR360_*`
  text joins are all against buffered T-tables.

---

## 6. Authorization (service layer)

- Gateway service authorization: standard — assign the OData V4 service to a
  PFCG role's *Service* authorizations (`S_SERVICE`), plus `S_RFC` for the
  metadata/OData RFCs as per your FES baseline.
- Data authorization: `P_ORGIN` (display) — enforced by DCL (Doc 05 §7) **and**
  the behavior pool global/instance authorization. A user with the tile but no
  `P_ORGIN` sees an empty list, not an error.
- No service-level "admin vs viewer" split in Phase 1 — single display persona
  (Doc 01 §9).

**Approve to proceed — Doc 07 (UI & Navigation) follows in this batch.**
