# Employee Data Health — dashboard (SAPUI5 freestyle)

HR-wide employee data-quality dashboard with org drill-down. Consumes the
existing OData V4 service `ZHR360_UI_SRVD` — no new backend.

## Cards
- **KPI strip** — Employees · Critical (+%) · Warning · Fully clean (+%)
- **Workforce by status** — donut (`StatusSplit`)
- **Where the data breaks** — column, failures per check (`CheckFailure`)
- **Data health by organization** — bar, drill **Company code → Personnel area →
  Org unit** (breadcrumb + "All companies" reset). Tap a bar to drill; at any
  level "View employees" opens the Employee 360 app filtered to that scope.
- **Detail** — table of every dimension combination in the current scope; tap a
  row to open the filtered employee list.

The org drill aggregates `AreaHealth` / `KpiOverview` **client-side** to the
current level — robust regardless of `$apply` support. Filtered levels are small.

## Run locally
1. Edit `ui5.yaml` → `fiori-tools-proxy` → your S/4 host / port / client.
2. `npm install && npm start`  (needs `@ui5/cli`, `@sap/ux-ui5-tooling`).

## Deploy to S/4 (BSP)
- **BAS:** import this folder → *Deploy → Deploy to ABAP* → package `ZHR_UTIL`,
  BSP name `ZHR360_DATAHEALTH`, transport.
- **or** `ui5 build` then upload `dist/` via report `/UI5/UI5_REPOSITORY_LOAD`.
- Then add a Launchpad tile (semantic object `EmployeeDataHealth`, action
  `display`) and the `Employee` semantic object target for the cross-navigation.

## Cross-navigation
Cards navigate to semantic object **`Employee`**, action **`display`** with
params `CompanyCode` / `PersonnelArea` / `OrgUnit` / `QualityStatus`. Configure
that target to the Employee 360 List Report app. Standalone (no launchpad) the
navigation shows a toast with the intended filter instead.
