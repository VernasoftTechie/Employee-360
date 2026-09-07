sap.ui.define([
  "sap/ui/core/mvc/Controller",
  "sap/ui/model/json/JSONModel",
  "sap/ui/model/Sorter",
  "sap/ui/core/Fragment",
  "sap/m/MessageToast"
], function (Controller, JSONModel, Sorter, Fragment, MessageToast) {
  "use strict";

  var PAGE = 5000;            // OData page size for the full-roster read
  var STORE_KEY = "hr360.dh.severity";

  function pct(n, d) { return d ? Math.round(n * 1000 / d) / 10 : 0; }
  function round1(x) { return Math.round(x * 10) / 10; }

  return Controller.extend("hr360.datahealth.controller.Dashboard", {

    /* ------------------------------------------------------------------ init */

    onInit: function () {
      this._roster = [];                 // one row per employee  (EmployeeDq)
      this._issues = [];                 // one row per employee+failed check (DataQualityIssue)
      this._byEmp  = {};                 // EmployeeID -> { checkId: true }
      this._orgPath = [];                // [{ key, text }]  length = drill level (0/1/2)

      this._vm = new JSONModel({
        busy: true,
        error: "",
        catalogue: [],                   // [{ id, cat, catLabel, name, rule, infotype, sev }]
        checksMode: "check",             // "check" | "category"
        orgMetric: "critPct",            // "critPct" | "critCount" | "completeness"
        kpi:    { total: 0, critical: 0, warning: 0, clean: 0, criticalPct: 0, warningPct: 0, cleanPct: 0, completeness: 0 },
        status: [],
        checks: [],
        detail: [],
        org: { level: 0, rows: [], subtitle: "", crumbText: "", canViewEmployees: false }
      });
      this.getView().setModel(this._vm);
      this._i18n = this.getView().getModel("i18n").getResourceBundle();

      this._loadCatalogue()
        .then(this._loadData.bind(this))
        .then(this._recompute.bind(this))
        .catch(function (e) {
          this._vm.setProperty("/error", (e && e.message) || String(e));
        }.bind(this))
        .finally(function () { this._vm.setProperty("/busy", false); }.bind(this));
    },

    _loadCatalogue: function () {
      var sUrl = sap.ui.require.toUrl("hr360/datahealth/model/checkCatalogue.json");
      return fetch(sUrl).then(function (r) { return r.json(); }).then(function (cat) {
        var catLabel = {};
        (cat.categories || []).forEach(function (c) { catLabel[c.code] = c.label; });
        this._catVersion = cat.version;
        var stored = this._readStoredSeverity();
        var list = (cat.checks || []).map(function (c) {
          return {
            id: c.id, cat: c.cat, catLabel: catLabel[c.cat] || c.cat,
            name: c.name, rule: c.rule, infotype: c.infotype,
            sev: stored[c.id] || c.sev
          };
        });
        this._catalogue = list;
        this._catById = {};
        list.forEach(function (c) { this._catById[c.id] = c; }.bind(this));
        this._vm.setProperty("/catalogue", list);
      }.bind(this));
    },

    _readStoredSeverity: function () {
      try {
        var raw = window.localStorage.getItem(STORE_KEY);
        return raw ? JSON.parse(raw) : {};
      } catch (e) { return {}; }
    },

    _writeStoredSeverity: function () {
      try {
        var map = {};
        this._catalogue.forEach(function (c) { map[c.id] = c.sev; });
        window.localStorage.setItem(STORE_KEY, JSON.stringify(map));
      } catch (e) { /* private mode - ignore */ }
    },

    /* ---------------------------------------------------------------- OData */

    // Read every row of an entity set, paged. An explicit key sort is essential:
    // without $orderby, $skip/$top paging on HANA is not guaranteed stable and
    // rows could be missed or duplicated across pages.
    _readAll: function (sPath, sSelect, aKeys) {
      var mParams = { $count: true };
      if (sSelect) { mParams.$select = sSelect; }
      var aSorters = (aKeys || []).map(function (k) { return new Sorter(k); });
      var oList = this.getView().getModel("odata").bindList(sPath, null, aSorters, [], mParams);
      var out = [];
      function page() {
        return oList.requestContexts(out.length, PAGE).then(function (aCtx) {
          aCtx.forEach(function (c) { out.push(c.getObject()); });
          var total = oList.getCount();
          if (aCtx.length > 0 && typeof total === "number" && out.length < total) {
            return page();
          }
          oList.destroy();                 // data already copied out - free the contexts
          return out;
        });
      }
      return page();
    },

    _loadData: function () {
      return Promise.all([
        this._readAll("/EmployeeDq", "EmployeeID,CompanyCode,PersonnelArea,OrgUnit", ["EmployeeID"]),
        this._readAll("/DataQualityIssue", "EmployeeID,CheckID", ["EmployeeID", "CheckID"])
      ]).then(function (res) {
        this._roster = res[0] || [];
        this._issues = res[1] || [];
        var byEmp = {};
        this._issues.forEach(function (i) {
          (byEmp[i.EmployeeID] || (byEmp[i.EmployeeID] = {}))[i.CheckID] = true;
        });
        this._byEmp = byEmp;
      }.bind(this));
    },

    onRefresh: function () {
      this._vm.setProperty("/busy", true);
      this.getView().getModel("odata").refresh();
      this._loadData()
        .then(this._recompute.bind(this))
        .catch(function (e) { this._vm.setProperty("/error", (e && e.message) || String(e)); }.bind(this))
        .finally(function () { this._vm.setProperty("/busy", false); }.bind(this));
    },

    /* --------------------------------------------------------- aggregation */

    _sevOf: function (checkId) {
      var c = this._catById[checkId];
      return c ? c.sev : null;              // unknown check ids are ignored
    },

    _inScope: function (r) {
      var p = this._orgPath;
      if (p[0] && r.CompanyCode   !== p[0].key) return false;
      if (p[1] && r.PersonnelArea !== p[1].key) return false;
      return true;
    },

    _orgUnitLabel: function (v) {
      return (v && v !== "00000000") ? v : this._i18n.getText("unassigned");
    },

    _recompute: function () {
      var self  = this;
      var level = this._orgPath.length;               // 0 company / 1 pers.area / 2 org unit
      var N     = this._catalogue.length || 1;

      var total = 0, crit = 0, warn = 0, ok = 0, passSum = 0;
      var byCheck = {}, byCat = {}, org = {}, detail = {};

      this._roster.forEach(function (r) {
        if (!self._inScope(r)) { return; }
        total++;

        var fails = self._byEmp[r.EmployeeID] || null;
        var hasC = false, hasW = false, failCount = 0;
        if (fails) {
          Object.keys(fails).forEach(function (cid) {
            var s = self._sevOf(cid);
            if (!s) { return; }
            failCount++;
            if (s === "C") { hasC = true; } else { hasW = true; }
            byCheck[cid] = (byCheck[cid] || 0) + 1;
            var cat = self._catById[cid].cat;
            byCat[cat] = (byCat[cat] || 0) + 1;
          });
        }
        var status = hasC ? "CRITICAL" : hasW ? "WARNING" : "OK";
        if (status === "CRITICAL") { crit++; } else if (status === "WARNING") { warn++; } else { ok++; }
        passSum += (N - failCount);

        // org-bar node at the current drill level
        var nk, nl;
        if (level === 0)      { nk = r.CompanyCode;   nl = r.CompanyCode || "(none)"; }
        else if (level === 1) { nk = r.PersonnelArea; nl = r.PersonnelArea || "(none)"; }
        else                  { nk = r.OrgUnit;       nl = self._orgUnitLabel(r.OrgUnit); }
        var o = org[nk] || (org[nk] = { key: nk, label: nl, emp: 0, crit: 0, warn: 0, pass: 0 });
        o.emp++; o.pass += (N - failCount);
        if (status === "CRITICAL") { o.crit++; } else if (status === "WARNING") { o.warn++; }

        // detail table row = full org tuple
        var dk = [r.CompanyCode, r.PersonnelArea, r.OrgUnit].join("|");
        var d = detail[dk] || (detail[dk] = {
          company: r.CompanyCode, area: r.PersonnelArea, orgUnit: self._orgUnitLabel(r.OrgUnit),
          emp: 0, crit: 0, warn: 0, pass: 0
        });
        d.emp++; d.pass += (N - failCount);
        if (status === "CRITICAL") { d.crit++; } else if (status === "WARNING") { d.warn++; }
      });

      /* KPI strip */
      this._vm.setProperty("/kpi", {
        total: total, critical: crit, warning: warn, clean: ok,
        criticalPct: pct(crit, total), warningPct: pct(warn, total), cleanPct: pct(ok, total),
        completeness: total ? round1(passSum * 100 / (total * N)) : 0
      });

      /* status donut */
      this._vm.setProperty("/status", [
        { name: "CRITICAL", value: crit },
        { name: "WARNING",  value: warn },
        { name: "OK",       value: ok }
      ].filter(function (x) { return x.value > 0; }));

      /* failures by check / category */
      this._buildChecks(byCheck, byCat);

      /* org bar */
      var metric = this._vm.getProperty("/orgMetric");
      var orgRows = Object.keys(org).map(function (k) {
        var o = org[k];
        return {
          key: o.key, label: o.label, employees: o.emp,
          critical: o.crit, warning: o.warn,
          critPct: pct(o.crit, o.emp),
          completeness: o.emp ? round1(o.pass * 100 / (o.emp * N)) : 0,
          value: metric === "critCount" ? o.crit
               : metric === "completeness" ? (o.emp ? round1(o.pass * 100 / (o.emp * N)) : 0)
               : pct(o.crit, o.emp)
        };
      });
      orgRows.sort(function (a, b) {
        return metric === "completeness" ? a.value - b.value : b.value - a.value;   // worst first
      });
      this._vm.setProperty("/org/rows", orgRows);
      this._vm.setProperty("/org/level", level);
      this._vm.setProperty("/org/subtitle", this._i18n.getText(
        ["cardOrgSubL0", "cardOrgSubL1", "cardOrgSubL2"][level],
        [this._orgPath[0] && this._orgPath[0].key, this._orgPath[1] && this._orgPath[1].key]));
      this._vm.setProperty("/org/crumbText",
        this._orgPath.map(function (p) { return p.key; }).join("  /  "));
      this._vm.setProperty("/org/canViewEmployees", this._orgPath.length > 0);

      /* detail table */
      var detailRows = Object.keys(detail).map(function (k) {
        var d = detail[k];
        d.status = d.crit ? "CRITICAL" : d.warn ? "WARNING" : "OK";
        d.completeness = d.emp ? round1(d.pass * 100 / (d.emp * N)) : 0;
        return d;
      });
      detailRows.sort(function (a, b) { return b.crit - a.crit; });
      this._vm.setProperty("/detail", detailRows);
    },

    _buildChecks: function (byCheck, byCat) {
      var self = this;
      var mode = this._vm.getProperty("/checksMode");
      var rows;
      if (mode === "category") {
        var seen = {};
        this._catalogue.forEach(function (c) { seen[c.cat] = c.catLabel; });
        rows = Object.keys(seen).map(function (code) {
          return { key: code, name: seen[code], value: byCat[code] || 0 };
        });
      } else {
        rows = this._catalogue.map(function (c) {
          return { key: c.id, name: c.name, value: byCheck[c.id] || 0 };
        });
      }
      rows = rows.filter(function (r) { return r.value > 0; });
      rows.sort(function (a, b) { return b.value - a.value; });
      this._vm.setProperty("/checks", rows);
    },

    /* -------------------------------------------------------- interactions */

    onChecksModeChange: function (oEvent) {
      this._vm.setProperty("/checksMode", oEvent.getParameter("item").getKey());
      this._recompute();
    },

    onOrgMetricChange: function (oEvent) {
      this._vm.setProperty("/orgMetric", oEvent.getParameter("item").getKey());
      this._recompute();
    },

    onOrgBarSelect: function (oEvent) {
      var data  = oEvent.getParameter("data");
      var label = data && data[0] && data[0].data && data[0].data.Node;
      if (!label) { return; }
      var row = (this._vm.getProperty("/org/rows") || []).filter(function (r) { return r.label === label; })[0];
      if (!row) { return; }

      if (this._orgPath.length >= 2) {
        // leaf level - a bar is an org unit -> open the filtered employee list
        this._toEmployees({
          CompanyCode: this._orgPath[0].key,
          PersonnelArea: this._orgPath[1].key,
          OrgUnit: row.key
        });
        return;
      }
      this._orgPath.push({ key: row.key, text: label });
      this._recompute();
    },

    onOrgHome: function () {
      this._orgPath = [];
      this._recompute();
    },

    onOrgUp: function () {
      this._orgPath.pop();
      this._recompute();
    },

    onViewEmployees: function () {
      var p = {};
      if (this._orgPath[0]) { p.CompanyCode = this._orgPath[0].key; }
      if (this._orgPath[1]) { p.PersonnelArea = this._orgPath[1].key; }
      this._toEmployees(p);
    },

    onDetailRowPress: function (oEvent) {
      var o = oEvent.getSource().getBindingContext().getObject();
      this._toEmployees({
        CompanyCode: o.company, PersonnelArea: o.area,
        OrgUnit: (o.orgUnit === this._i18n.getText("unassigned") ? "" : o.orgUnit),
        QualityStatus: o.status
      });
    },

    _toEmployees: function (mParams) {
      var clean = {};
      Object.keys(mParams).forEach(function (k) { if (mParams[k]) { clean[k] = mParams[k]; } });
      if (sap.ushell && sap.ushell.Container) {
        sap.ushell.Container.getServiceAsync("CrossApplicationNavigation").then(function (oCAN) {
          oCAN.toExternal({ target: { semanticObject: "Employee", action: "display" }, params: clean });
        });
      } else {
        MessageToast.show(this._i18n.getText("wouldOpen", [JSON.stringify(clean)]));
      }
    },

    /* --------------------------------------------------- severity checklist */

    onSeverityChange: function (oEvent) {
      var ctx = oEvent.getSource().getBindingContext();
      if (ctx) {
        this._vm.setProperty(ctx.getPath() + "/sev", oEvent.getParameter("item").getKey());
      }
    },

    onApplySeverity: function () {
      this._writeStoredSeverity();
      this._recompute();
      MessageToast.show(this._i18n.getText("severityApplied"));
    },

    onResetSeverity: function () {
      try { window.localStorage.removeItem(STORE_KEY); } catch (e) { /* ignore */ }
      this._loadCatalogue().then(this._recompute.bind(this));
      MessageToast.show(this._i18n.getText("severityReset"));
    },

    /* ------------------------------------------------------------ help */

    onOpenHelp: function () {
      var self = this;
      if (this._helpDialog) { this._helpDialog.open(); return; }
      Fragment.load({
        id: this.getView().getId(), name: "hr360.datahealth.view.Help", controller: this
      }).then(function (oDialog) {
        self.getView().addDependent(oDialog);
        self._helpDialog = oDialog;
        oDialog.open();
      });
    },

    onCloseHelp: function () { if (this._helpDialog) { this._helpDialog.close(); } },

    onExit: function () {
      if (this._helpDialog) { this._helpDialog.destroy(); this._helpDialog = null; }
    }

  });
});
