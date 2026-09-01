# Employee-360 — Demo Guide (Doc 13)

A 15-minute walkthrough for stakeholders. Assumes the apps are deployed and
2–3 prepared sandbox employees exist.

---

## 0. Prep (before the demo)

| Need | How |
|---|---|
| "Star" employee | a PA30 record with **everything** filled — personal, address, bank, education, 2–3 qualifications, a pay history, some absences, a manager and 2 direct reports |
| "Gaps" employee | same person cloned, then blank out DOB, cost center and email |
| Org context | both employees under the same org unit with a visible reporting line |
| User | your ID with `P_ORGIN` display for the demo org |
| Tiles | *Employee 360* and *HR Data Quality Audit* on the launchpad |

---

## 1. The problem (1 min)

> "Today, building a full picture of one employee means opening PA20, PA30,
> PPOME, transaction after transaction. And nobody has a workforce-wide view of
> where the data is incomplete."

---

## 2. Employee 360 — the star profile (5 min)

1. Open **Employee 360**. Show the **search box** — type part of a surname,
   show fuzzy match. Apply an **org unit filter**.
2. Open the star employee. Walk the **header**: name, org unit, position,
   manager, **completeness 100 %**, **0 issues** (green).
3. **Personal Details** — DOB, address, email, mobile, IBAN.
4. **Organization & Position** — company code, org unit, position, job, cost
   center, manager.
5. **Org Navigation** — expand the tree, show the reporting line, click a
   **direct report** → jumps straight to their profile. Navigate back.
6. **Education**, **Skills**, **Certifications** — show a certification with a
   validity date.
7. **Leave & Attendance** — quota entitlement / taken / remaining; a recorded
   absence.
8. **Pay History** — pay-scale progression over time.
9. **Documents** — open a personnel-file document (content server link).
10. **Timeline** — scroll the chronological feed: hire → org change → pay
    change → qualification earned.

---

## 3. Employee 360 — the data-gap profile (3 min)

1. Back to the list, open the **"gaps" employee**.
2. Header now shows **completeness < 100 %** and **Quality Status = Critical**
   (red).
3. Open the **Data Quality Issues** facet — one row per gap: *Date of birth
   missing (Critical)*, *Cost center missing (Critical)*, *Email missing
   (Warning)* — each colour-coded.
4. Point out: *"These checks are defined once in the data model. Adding a new
   one — say 'emergency contact missing' — is a one-line change, no new tables,
   no new screens."*

---

## 4. HR Data Quality Audit (4 min)

1. Open **HR Data Quality Audit**.
2. **KPI header** — average completeness %, total critical issues, employees
   with issues.
3. **Chart** — employees with vs without issues, by org unit. Point to the
   worst org unit.
4. **Drill down** on that bar → the employee list opens **filtered** to that
   org unit and quality status.
5. From there, open one employee → full circle back to the 360 profile.

---

## 5. Reports (2 min)

1. Run **Missing Data Validation** for an org unit → ALV grouped by severity,
   subtotals. *"This is the worklist HR works down."*
2. Mention **Employee Master Export** (ALV or scheduled file) and **HR Audit
   Report** (management summary), and that all three run as background jobs
   with an application log.

---

## 6. Close (1 min)

> "One app, read-only, built entirely on standard SAP HR data — no custom
> tables, upgrade-safe, RAP and Clean-Core compliant. The data-quality layer is
> reused from the earlier HR Data Quality proof of concept and extended.
> Performance Review, Training Matrix and Succession Planning are the natural
> next steps and slot into the same model."

---

## Talking points / FAQ

| Question | Answer |
|---|---|
| Can users change data here? | No — display only. Corrections stay in PA30 / standard tools. |
| Whose data can I see? | Only what your HR display authorization (`P_ORGIN`) allows — same as PA20. |
| What if we don't use ArchiveLink / qualifications? | Those sections just show nothing — no errors, no config forced. |
| How hard is a new data-quality check? | One CDS `UNION` branch. No table, service or UI change. |
| Custom tables added? | Zero. Everything reads SAP standard tables. |
| Package? | Everything goes into `Z001` on abapGit pull. |
