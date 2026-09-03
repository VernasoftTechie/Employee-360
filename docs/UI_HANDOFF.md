# UI handoff — start here

For the Fiori/UI5 developer taking over the front end. The backend (CDS +
OData V4 service) is **done and stable** — you build only the UI.

---

## The service

| | |
|---|---|
| Service definition | `ZHR360_UI_SRVD` |
| Binding | `ZHR360_UI_SRVB_O4` — OData V4, UI, **published** |
| URL | `/sap/opu/odata4/sap/zhr360_ui_srvb_o4/srvd/sap/zhr360_ui_srvd/0001/` |
| Package | `ZHR_UTIL` |
| Auth | DCL on `P_ORGIN` (activity Display) — a user without HR auth gets 0 rows, not an error |

### Entity sets

| Set | Grain | Use |
|---|---|---|
| `Employee` | per employee | List Report + Object Page. `@UI` annotations (line items, filters, identification, 8 `LINEITEM_REFERENCE` facets, `QualityStatus` criticality) are **already in the CDS** `ZC_HR360_EMPLOYEE`. |
| `Education` `Qualification` `LeaveBalance` `Attendance` `PayrollItem` `Document` `TimelineEvent` `DataQualityIssue` | per record | The 8 Object Page facet tables. Navigation props on `Employee` are `_Education`, `_Qualification`, `_LeaveBalance`, `_Attendance`, `_Payroll`, `_Document`, `_Timeline`, `_DataQuality`. |
| `KpiOverview` | company / pers.area / EE group / org unit / status | Dashboard detail + drill source |
| `DQ_BY_STATUS` (`StatusSplit`) | per status | Dashboard donut |
| `DQ_BYCHECK` (`CheckFailure`) | per check | Dashboard column chart |
| `DQ_BY_AREA` (`AreaHealth`) | per company / pers.area | Dashboard bar chart |

The dashboard aggregate views carry `@UI.Chart` and `@Aggregation.default`
annotations but **no** `@UI.PresentationVariant` (it caused templating errors —
see `BUILD_ISSUES_LOG.md` A32).

---

## What's in the repo for you

| Path | What |
|---|---|
| `ui/employee360/` | **Ready-to-deploy Fiori Elements V4 app** (List Report + Object Page). Hand-written `manifest.json`. Deploys as BSP `ZHR360_EMPLOYEE`. |
| `ui/dashboard/` | **Ready-to-deploy freestyle SAPUI5 dashboard** — KPI strip, donut, column, and a Company→Pers.area→Org-unit **drill-down** bar, detail table. Deploys as BSP `ZHR360_DATAHEALTH`. |
| `ui/README.md` | deploy both apps: fill 3 values, `npm install && npm run deploy` |
| `docs/DEPLOY_GUIDE.md` | fuller deploy + Launchpad + PFCG role steps |
| `docs/14_dashboard_requirement_spec.md` | the dashboard design intent — cards, KPI formulas, navigation, phase 2 |
| `docs/PROJECT_OVERVIEW.md` | the whole solution as-built |
| `docs/BUILD_ISSUES_LOG.md` | every error the CDS build hit + fix — **read A1–A32 before editing any CDS** |

---

## Your scope

1. **Deploy** both apps (`ui/README.md`).
2. **Launchpad**: 2 tiles + `ZHR360_DISPLAY` PFCG role (`DEPLOY_GUIDE.md` Part C).
   - Employee 360 → semantic object `Employee`, action `display`
   - Data Health → semantic object `EmployeeDataHealth`, action `display`
   - Wire the dashboard's cross-nav to the `Employee` intent so a card click
     opens the filtered employee list.
3. **Object Page polish** (optional, in a **metadata extension**
   `ZC_HR360_EMPLOYEE` — do NOT edit the CDS view directly for this):
   - Completeness gauge in the header (`@UI.DataPoint` visualization `#Progress`
     + a `#DataPointReference` header facet).
   - Header KPI number facets (open issues, critical, status).
   - Timeline facet as `sap.suite.ui.commons.Timeline`.
   - Per-facet "populated / missing" badge.
4. **Dashboard** (`ui/dashboard/`): the drill + charts work; if you prefer an
   Overview Page or Analytical List Page instead of the freestyle app, the
   entity sets + `@UI.Chart` annotations support it — but note `@Analytics.query`
   fails the OData V4 UI binding (needs keys — A30), so keep them as keyed
   aggregate views.

## Constraints (learned the hard way)

- Keep CDS `@UI` to `lineItem` / `selectionField` / `identification` / `facet` +
  `criticality`. Anything fancier → metadata extension, tested one annotation at
  a time (A32).
- No `@Analytics.query` on anything exposed in this binding (A30).
- The Employee entity is **read-only** (no RAP BO — A19). List Report + Object
  Page work read-only; there is no draft, no edit, no actions.
- Text columns (`*Name` for org unit, cost center, etc.) were removed after
  "column unknown" errors (A10) — re-add per text table, verified in SE11.
