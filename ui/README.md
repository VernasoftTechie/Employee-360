# Fiori apps — deploy without knowing Fiori

Two apps, both **fully coded**. You do **not** write or design anything.

| Folder | App | Kind |
|---|---|---|
| `employee360/` | **Employee 360** — searchable employee list + a full profile page with 8 sections and the data-quality panel | Fiori Elements (SAP builds the screen from the CDS annotations at runtime) |
| `dashboard/` | **Employee Data Health** — KPI tiles + charts + Company→Area→Org-unit drill-down | Freestyle SAPUI5 (hand-written) |

Both talk to the **existing** service `ZHR360_UI_SRVD` — no backend change.

---

## The whole process: edit 3 values, run 1 command, per app

### 0. One-time on your PC
- Install **Node.js LTS** (nodejs.org).
- That's it. No VS Code extension, no BAS needed for deploy.

### 1. Fill in your system — 3 values, twice

In **`employee360/ui5-deploy.yaml`** and **`dashboard/ui5-deploy.yaml`** replace:

| Placeholder | With |
|---|---|
| `REPLACE-WITH-YOUR-S4-HOST:PORT` | your S/4 host+port, e.g. `http://ikjdcdevcha01:8000` (the URL you use for SAP GUI for HTML / Web ADT) |
| `REPLACE-CLIENT` | your logon client, e.g. `100` |
| `REPLACE-WITH-TRANSPORT` | an **open workbench transport request** — create one in `SE10` (New → Workbench Request), or ask Basis; paste its ID e.g. `DCDK900123` |

*(Do the same in `ui5.yaml` if you also want to run it locally first.)*

### 2. Set your SAP credentials (so the deploy can log in)

In the terminal, before deploying:
```bash
# Windows PowerShell
$env:ABAP_USER="YOURSAPUSER"
$env:ABAP_PASSWORD="yourpassword"
```
```bash
# macOS / Linux / Git Bash
export ABAP_USER=YOURSAPUSER
export ABAP_PASSWORD=yourpassword
```

### 3. Deploy each app

```bash
cd ui/employee360
npm install
npm run deploy
```
```bash
cd ../dashboard
npm install
npm run deploy
```

Each `npm run deploy` builds the app and uploads it as a **BSP application**
(`ZHR360_EMPLOYEE` / `ZHR360_DATAHEALTH`) into package `ZHR_UTIL` on your
transport. Confirm the prompts.

### 4. Open them — no tile needed for a demo

Straight browser URLs (you must be logged into SAP in that browser):
```
https://<your-host>:<port>/sap/bc/ui5_ui5/sap/zhr360_employee/index.html
https://<your-host>:<port>/sap/bc/ui5_ui5/sap/zhr360_datahealth/index.html
```
These are real, shareable, presentable apps. **This is enough to present.**

---

## 5. (Later) put them on the Fiori Launchpad — needs Basis

A Launchpad **tile** needs PFCG + Launchpad-admin rights. Hand `docs/DEPLOY_GUIDE.md`
Part A4 / B4 / C to whoever administers your Fiori Launchpad. The exact values:

| App | Semantic object | Action | UI5 component id | BSP path |
|---|---|---|---|---|
| Employee 360 | `Employee` | `display` | `hr360.employee` | `/sap/bc/ui5_ui5/sap/zhr360_employee` |
| Data Health | `EmployeeDataHealth` | `display` | `hr360.datahealth` | `/sap/bc/ui5_ui5/sap/zhr360_datahealth` |

Role `ZHR360_DISPLAY` = the Fiori catalog + `S_SERVICE` (OData service group of
`ZHR360_UI_SRVB_O4`) + `P_ORGIN` (`AUTHC = R`, PERSA/PERSG/PERSK = `*`).

---

## Run locally first (optional sanity check)

```bash
cd ui/employee360    # or ui/dashboard
# edit ui5.yaml -> fiori-tools-proxy -> your host/port/client
npm install
npm start
```
Opens the app in your browser, proxied to the live service.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `deploy` fails "401 / auth" | wrong `ABAP_USER` / `ABAP_PASSWORD`, or user lacks `S_DEVELOP` for BSP + the transport |
| `deploy` "transport not found / not modifiable" | the transport ID is wrong or already released — use an open one |
| app opens but list is empty | your user has no `P_ORGIN` display authorization — the DCL returns 0 rows (not an error) |
| charts blank in the dashboard | `sap.viz` lib not loaded on your FES — add it to the SAPUI5 dist, or bump `minUI5Version` |
| "service not found" | `/IWFND/V4_ADMIN` → confirm `ZHR360_UI_SRVB_O4` is published in this client |
