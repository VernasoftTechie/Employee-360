# Deploy Guide — no assumptions

How to turn the working service into clickable Fiori apps. Written for someone
who has **not** done Fiori configuration before. Where a step genuinely needs
Basis / Launchpad-admin rights, it says **[ask Basis]**.

---

## 0. What you already have (nothing to do)

- `ZHR360_UI_SRVD` — the OData V4 service (activated by the abapGit pull).
- `ZHR360_UI_SRVB_O4` — the service binding, **published**.
- All the CDS `@UI` annotations that describe the Employee 360 screen.

**Right now you can already use the app** without deploying anything:

> ADT → open `ZHR360_UI_SRVB_O4` → select entity **`Employee`** → click
> **Preview**. It opens a full working Fiori app in the browser. Bookmark that
> URL. This is a legitimate way to use / demo it. Everything below is only for
> putting a **tile on the Fiori Launchpad** for other users.

---

## Vocabulary (30 seconds)

| Term | Means |
|---|---|
| **Fiori Elements** | SAP generates the app UI automatically from the CDS `@UI` annotations. No UI coding. The Employee 360 app is this kind. |
| **Freestyle app** | Hand-written SAPUI5 (HTML/JS). The Data Health dashboard is this kind. |
| **BSP application** | How a UI5 app is stored on the ABAP server (transaction `SE80` → "BSP Application"). Deploying = uploading the app as a BSP. |
| **Launchpad / FLP** | The tile home screen users see. Tiles are configured in **catalogs**, catalogs are attached to **PFCG roles**, roles are assigned to users. |
| **Semantic object + action** | The address of an app, e.g. `Employee` + `display`. Tiles and navigation use this instead of a URL. |

---

## Part A — the Employee 360 app (Fiori Elements, no coding)

You need **one** of these tools on your PC:

- **VS Code + "SAP Fiori tools - Extension Pack"** (free, recommended), or
- **SAP Business Application Studio** (BAS) if your company has it.

Both do the same thing. Steps below are VS Code; BAS is nearly identical.

### A1. One-time setup

1. Install **Node.js LTS** (nodejs.org).
2. VS Code → Extensions → install **"SAP Fiori tools - Extension Pack"**.
3. You need to reach the S/4 system from your PC — a browser URL like
   `https://<host>:<port>` that opens SAP GUI for HTML / Fiori. If you don't
   have that, **[ask Basis]** for the "Fiori front-end server URL".

### A2. Generate the app

1. VS Code → `Ctrl+Shift+P` → **"Fiori: Open Application Generator"**.
2. **Template** → *List Report Page* → Next.
3. **Data source** → *Connect to a System*.
   - System type: *ABAP Environment* (on-prem) → enter the system URL + your
     SAP user / password (or pick a saved destination).
4. **Service** → in the list, pick **`ZHR360_UI_SRVD`** (OData V4).
5. **Main entity** → `Employee`.
   **Navigation entity** → leave empty (or `_DataQuality`).
6. **Project attributes**:
   - Module name: `zhr360employee`
   - Application title: `Employee 360`
   - Namespace: leave blank
   - Description: `HR Employee 360 profile & data quality`
   - Add deployment configuration: **Yes**
   - Add FLP configuration: **Yes**
7. **Deployment target** → *ABAP*:
   - Target system: same system as step 3
   - **SAPUI5 ABAP Repository (BSP name)**: `ZHR360_EMPLOYEE`
   - Package: `ZHR_UTIL`
   - Transport request: pick an open one, or *[ask Basis]* to create one
     (workbench request).
8. **FLP configuration**:
   - Semantic Object: `ZHR360Employee`
   - Action: `display`
   - Title: `Employee 360`
9. **Finish**. It generates a project folder.

### A3. Deploy

In the project folder terminal:
```bash
npm install
npm run deploy
```
Confirm the prompts. This uploads BSP `ZHR360_EMPLOYEE` to the system.

### A4. Make the tile appear  **[ask Basis if you lack the roles]**

The deploy step created a **target mapping** and a **tile** in a catalog it
generated (usually named after the BSP). To show it to users:

1. S/4 Fiori Launchpad → app **"Manage Launchpad Spaces / Content"**
   (or transaction `/UI2/FLPD_CONF` — the classic Launchpad Designer).
2. Find the catalog the deploy created (or create catalog `ZHR360`).
3. Confirm it has:
   - a **Target Mapping**: semantic object `ZHR360Employee`, action `display`,
     Launchpad role/app = `SAPUI5`, UI5 component = `zhr360employee`,
     URL `/sap/bc/ui5_ui5/sap/zhr360_employee`.
   - a **Static App Launcher (tile)**: title "Employee 360", target the same
     intent `#ZHR360Employee-display`.
4. Add the catalog + a group to a **PFCG role** (see Part C).

---

## Part B — the Data Health dashboard (freestyle, deploy the folder)

The code is in `ui/dashboard/` of this repo.

### B1. Set the backend host

Open `ui/dashboard/ui5.yaml`, in `fiori-tools-proxy` → `backend` → set
`url:` to your S/4 host and `client:` to your logon client. Save.

### B2. (optional) run it locally first

```bash
cd ui/dashboard
npm install
npm start
```
Browser opens the dashboard against the live service. Good for a quick look.

### B3. Deploy to the server

Easiest — from VS Code with Fiori tools:
1. Open the `ui/dashboard` folder in VS Code.
2. `Ctrl+Shift+P` → **"Fiori: Add Deployment Configuration"** →
   target *ABAP*, BSP name `ZHR360_DATAHEALTH`, package `ZHR_UTIL`, a transport.
3. Terminal: `npm install && npm run build && npm run deploy`.

Alternative — **[ask Basis]** to run report **`/UI5/UI5_REPOSITORY_LOAD`**:
give them the built `ui/dashboard/dist/` folder (`npm run build` produces it),
BSP name `ZHR360_DATAHEALTH`, package `ZHR_UTIL`.

### B4. Tile  **[ask Basis if needed]**

Same as A4, but:
- Semantic Object: `EmployeeDataHealth`, Action: `display`
- UI5 component: `hr360.datahealth`
- URL: `/sap/bc/ui5_ui5/sap/zhr360_datahealth`
- Tile title: "Data Health"

### B5. Wire the cross-navigation

The dashboard's "View employees" / row taps navigate to semantic object
**`Employee`** action **`display`**. Add a **Target Mapping** for
`Employee` + `display` pointing at the Employee 360 app (from Part A) in the
**same catalog**. Then a click in the dashboard opens the filtered employee
list. (Without this it just shows a toast with the intended filter.)

---

## Part C — the role  **[ask Basis — this needs PFCG]**

PFCG role **`ZHR360_DISPLAY`**:

1. **Menu tab** → add the Fiori catalog(s) from A4 / B4 (and a group).
2. **Authorizations tab** → generate the profile, then maintain:
   - `S_SERVICE` — the OData V4 service. Find its name in
     `/IWFND/V4_ADMIN` → *Publish Service Groups* → group for
     `ZHR360_UI_SRVB_O4`. Add that to `S_SERVICE` (type `HT`, the service
     group's technical name).
   - `P_ORGIN` — HR org authorization:
     `INFTY = *`, `SUBTY = *`, `AUTHC = R`, `PERSA = *`, `PERSG = *`,
     `PERSK = *`, `VDSK1 = *` (scope down later per HR security policy).
   - `S_RFC` — per your front-end server baseline (usually inherited).
3. **User tab** → assign the pilot users.
4. Generate + save.

Without `P_ORGIN` a user opens the app and sees **zero employees** (not an
error) — that's the DCL doing its job.

---

## Part D — before go-live: post-pull manual steps

| Step | Transaction | Why |
|---|---|---|
| Create Application Log object `ZHR360`, subobject `REPORT` | `SLG0` | the 3 executable reports log their runs here (they run without it, just no log) |
| Run ATC on package `ZHR_UTIL`, fix findings | `ATC` / ADT | Clean-Core compliance before transporting to QA |
| Release the transport(s) | `SE10` | move to QA / PRD |

---

## Quick decision table

| I want to… | Do this |
|---|---|
| Try the employee app now, no setup | ADT → binding `ZHR360_UI_SRVB_O4` → `Employee` → **Preview** |
| See the dashboard now | `cd ui/dashboard && npm start` (after editing `ui5.yaml`) |
| Real tiles for my team | Part A + B + C (get Basis to help with C and the tile steps) |
| Hand it all to a Fiori consultant | give them this file + `docs/PROJECT_OVERVIEW.md` + `docs/14_dashboard_requirement_spec.md` |
