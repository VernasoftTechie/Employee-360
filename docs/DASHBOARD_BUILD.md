# Building the "Employee Data Health" dashboard

The backend is done — these entity sets are live in `ZHR360_UI_SRVD`:

| Entity set | Grain | For |
|---|---|---|
| `StatusSplit` | per `QualityStatus` (3 rows) | **donut** — workforce by status |
| `CheckFailure` | per `CheckID` (≤12 rows) | **column** — where the data breaks |
| `AreaHealth` | per company / personnel area | **bar** — avg completeness by area |
| `KpiOverview` | company / area / EE group / org unit / status | detail table + drill |

Each chart view carries its `@UI.Chart` + `@UI.PresentationVariant` annotations,
so a chart control picks up type / dimension / measure automatically.

---

## Option A — Overview Page app (recommended, matches the mockup)

1. **SAP Business Application Studio** → *New Project from Template* →
   **SAP Fiori** → *Overview Page*.
2. Data source: **Connect to a System** → your S/4 system → OData V4 service
   `ZHR360_UI_SRVD` (binding `ZHR360_UI_SRVB_O4`).
3. Main entity: `KpiOverview`. Finish the wizard.
4. Replace the generated `webapp/manifest.json` `sap.ovp.cards` section with the
   one in **`ui/dashboard/webapp/manifest.json`** of this repo (4 cards:
   status donut, by-check column, by-area bar, KPI detail table), then add the
   KPI number cards via *Page Map → Add Card → Analytical/KPI* pointing at
   `Headline` with the `@UI.DataPoint#…` paths.
5. *Global filter*: entity `KpiOverviewType` — gives the dashboard a filter bar
   for Company Code / Personnel Area / Employee Group / Org Unit / Quality
   Status that drives every card.
6. **Card navigation** → each card's *Navigation* → intent
   `Employee-display` (or the List Report app's semantic object) so clicking a
   slice/bar opens the filtered employee list.
7. Deploy: *Deploy to ABAP* → package `ZHR_UTIL` → creates the BSP app +
   Fiori Launchpad content.

## Option B — Analytical List Page on `KpiOverview`

Simpler, one screen: chart + table + filter bar. New Project → *Analytical List
Page*, entity `KpiOverview`, chart annotation `#ByStatus`. Fewer cards but less
flexible than the OVP.

## The Employee 360 app (List Report + Object Page)

Separate app: *New Project* → **List Report Object Page**, entity `Employee`.
The `@UI` annotations already on `ZC_HR360_EMPLOYEE` give you the columns,
filter bar, completeness gauge, KPI header facets and all 8 detail sections
with no further annotation work. Deploy alongside the dashboard.

## Launchpad

Both apps → one Fiori catalog + group `ZHR360`, business role
`ZHR360_DISPLAY` = catalog + `P_ORGIN` (activity Display) + the OData V4 service
authorization (`S_SERVICE`). Two tiles: **Employee 360**, **Data Health**.
