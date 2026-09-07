sap.ui.define([
  "sap/ui/core/mvc/Controller",
  "sap/ui/model/json/JSONModel",
  "sap/ui/model/Sorter",
  "sap/ui/core/Fragment",
  "sap/m/MessageToast"
], function (Controller, JSONModel, Sorter, Fragment, MessageToast) {
  "use strict";

  var PAGE = 5000;                       // OData page size for the full-roster read
  var STORE_KEY = "hr360.dh.severity";

  // Status colours - the same red / orange / green everywhere.
  var COL = {
    CRITICAL: "var(--sapNegativeColor, #bb0000)",
    WARNING:  "var(--sapCriticalColor, #e9730c)",
    OK:       "var(--sapPositiveColor, #107e3e)"
  };
  var ACCENT = "var(--sapAccentColor6, #0a6ed1)";

  function pct(n, d) { return d ? Math.round(n * 1000 / d) / 10 : 0; }
  function round1(x) { return Math.round(x * 10) / 10; }
  function nf(n) { return (n || 0).toLocaleString(); }

  return Controller.extend("hr360.datahealth.controller.Dashboard", {

    /* ================================================================ init */

    onInit: function () {
      this._roster = [];                 // one row per employee  (EmployeeDq)
      this._byEmp  = {};                 // EmployeeID -> { checkId: true }
      this._orgPath = [];                // [{ key, text }]  length = drill level (0/1/2)

      this._vm = new JSONModel({
        busy: true,
        error: "",
        catalogue: [],                   // [{ id, cat, catLabel, name, rule, infotype, sev }]
        checksMode: "check",             // "check" | "category"
        orgSort: "worst",                // "worst" | "largest"
        kpi: { total: 0, critical: 0, warning: 0, clean: 0, completeness: 0 },
        org: { level: 0, crumbText: "", scopeText: "" },
        detail: [],
        html: { overview: "", fail: "", org: "" }
      });
      this.getView().setModel(this._vm);
      this._i18n = this.getView().getModel("i18n").getResourceBundle();

      this._loadCatalogue()
        .then(this._loadData.bind(this))
        .then(this._recompute.bind(this))
        .catch(function (e) { this._vm.setProperty("/error", (e && e.message) || String(e)); }.bind(this))
        .finally(function () { this._vm.setProperty("/busy", false); }.bind(this));
    },

    // One delegated click listener on the view root - the chart HTML blocks are
    // regenerated wholesale on every recompute, so per-element handlers can't be
    // used.
    onAfterRendering: function () {
      if (this._clickBound) { return; }
      var oRoot = this.getView().getDomRef();
      if (!oRoot) { return; }
      oRoot.addEventListener("click", this._onChartClick.bind(this));
      this._clickBound = true;
    },

    onExit: function () {
      if (this._helpDialog) { this._helpDialog.destroy(); this._helpDialog = null; }
    },

    /* ------------------------------------------------------------ catalogue */

    _loadCatalogue: function () {
      var sUrl = sap.ui.require.toUrl("hr360/datahealth/model/checkCatalogue.json");
      return fetch(sUrl).then(function (r) { return r.json(); }).then(function (cat) {
        var catLabel = {};
        (cat.categories || []).forEach(function (c) { catLabel[c.code] = c.label; });
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
          if (aCtx.length > 0 && typeof total === "number" && out.length < total) { return page(); }
          oList.destroy();
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
        var byEmp = {};
        (res[1] || []).forEach(function (i) {
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

    /* ------------------------------------------------------------- helpers */

    _esc: function (v) {
      return String(v == null ? "" : v).replace(/[&<>"']/g, function (c) {
        return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
      });
    },

    _sevOf: function (checkId) {
      var c = this._catById[checkId];
      return c ? c.sev : null;
    },

    _inScope: function (r) {
      var p = this._orgPath;
      if (p[0] && r.CompanyCode   !== p[0].key) { return false; }
      if (p[1] && r.PersonnelArea !== p[1].key) { return false; }
      return true;
    },

    _orgUnitLabel: function (v) {
      return (v && v !== "00000000") ? v : this._i18n.getText("unassigned");
    },

    /* ======================================================== aggregation */

    _recompute: function () {
      var self  = this;
      var level = this._orgPath.length;
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

        var nk, nl;
        if (level === 0)      { nk = r.CompanyCode;   nl = r.CompanyCode || "(none)"; }
        else if (level === 1) { nk = r.PersonnelArea; nl = r.PersonnelArea || "(none)"; }
        else                  { nk = r.OrgUnit;       nl = self._orgUnitLabel(r.OrgUnit); }
        var o = org[nk] || (org[nk] = { key: nk, label: nl, emp: 0, crit: 0, warn: 0, ok: 0 });
        o.emp++; o[status === "CRITICAL" ? "crit" : status === "WARNING" ? "warn" : "ok"]++;

        var dk = [r.CompanyCode, r.PersonnelArea, r.OrgUnit].join("|");
        var d = detail[dk] || (detail[dk] = {
          company: r.CompanyCode, area: r.PersonnelArea, orgUnit: self._orgUnitLabel(r.OrgUnit),
          emp: 0, crit: 0, warn: 0, pass: 0
        });
        d.emp++; d.pass += (N - failCount);
        d[status === "CRITICAL" ? "crit" : status === "WARNING" ? "warn" : "x"]++;
      });

      this._vm.setProperty("/kpi", {
        total: total, critical: crit, warning: warn, clean: ok,
        completeness: total ? round1(passSum * 100 / (total * N)) : 0
      });

      /* ---- section HTML ---- */
      this._vm.setProperty("/html/overview", this._overviewHtml(total, crit, warn, ok,
        total ? round1(passSum * 100 / (total * N)) : 0));
      this._vm.setProperty("/html/fail", this._failHtml(crit, warn, ok, total, byCheck, byCat));
      this._vm.setProperty("/html/org", this._orgHtml(org, total));

      /* ---- org meta ---- */
      this._vm.setProperty("/org/level", level);
      this._vm.setProperty("/org/crumbText",
        level === 0 ? "" : this._orgPath.map(function (p) { return p.key; }).join("  ›  "));
      this._vm.setProperty("/org/scopeText", level === 0
        ? this._i18n.getText("scopeAll")
        : this._i18n.getText("scopeFiltered", [this._orgPath.map(function (p) { return p.key; }).join(" › ")]));

      /* ---- detail table ---- */
      var detailRows = Object.keys(detail).map(function (k) {
        var d = detail[k];
        d.status = d.crit ? "CRITICAL" : d.warn ? "WARNING" : "OK";
        d.completeness = d.emp ? round1(d.pass * 100 / (d.emp * N)) : 0;
        return d;
      });
      detailRows.sort(function (a, b) { return b.crit - a.crit || b.emp - a.emp; });
      this._vm.setProperty("/detail", detailRows);
    },

    /* ====================================================== chart rendering */

    // Donut: fixed 3-status split. cx/cy 60, r 44, thickness 16.
    _donutSvg: function (parts, iTotal) {
      var C = 2 * Math.PI * 44, off = 0;
      var segs = parts.filter(function (p) { return p.value > 0; }).map(function (p) {
        var dash = (p.value / (iTotal || 1)) * C;
        var el = '<circle cx="60" cy="60" r="44" fill="none" stroke="' + p.color + '" stroke-width="16" ' +
          'stroke-dasharray="' + dash + " " + (C - dash) + '" stroke-dashoffset="' + (-off) +
          '" transform="rotate(-90 60 60)"/>';
        off += dash;
        return el;
      }).join("");
      return '<svg class="dh-donut" viewBox="0 0 120 120" role="img" aria-label="status split">' +
        '<circle cx="60" cy="60" r="44" fill="none" stroke="var(--sapList_Background,#eef2f6)" stroke-width="16"/>' +
        segs +
        '<text x="60" y="56" text-anchor="middle" class="dh-donut-num">' + nf(iTotal) + '</text>' +
        '<text x="60" y="72" text-anchor="middle" class="dh-donut-cap">' + this._esc(this._i18n.getText("kpiTotal")) + '</text></svg>';
    },

    // Horizontal bars. rows: [{label, value, pctOfTotal, color, key, drill, title}]
    _barsHtml: function (rows, mOpts) {
      mOpts = mOpts || {};
      var max = Math.max.apply(null, rows.map(function (r) { return r.value; }).concat([1]));
      var body = rows.map(function (r) {
        var w = Math.max(2, Math.round(r.value / max * 100));
        var attrs = r.drill ? ' data-drill="' + this._esc(r.drill) + '" data-key="' + this._esc(r.key) + '"' : "";
        var cls = "dh-bar" + (r.drill ? " dh-bar-click" : "");
        var right = mOpts.showPct
          ? '<span class="dh-bar-val">' + nf(r.value) + '</span><span class="dh-bar-pct">' + r.pctOfTotal + '%</span>'
          : '<span class="dh-bar-val">' + nf(r.value) + '</span>';
        return '<div class="' + cls + '"' + attrs + (r.title ? ' title="' + this._esc(r.title) + '"' : "") + '>' +
          '<span class="dh-bar-label">' + this._esc(r.label) + '</span>' +
          '<span class="dh-bar-track"><span class="dh-bar-fill" style="width:' + w + '%;background:' + (r.color || ACCENT) + '"></span></span>' +
          right + '</div>';
      }.bind(this)).join("");
      return '<div class="dh-bars">' + body + "</div>";
    },

    // Stacked crit/warn/ok bar (one org node).
    _stackHtml: function (o) {
      var t = o.emp || 1;
      var seg = function (n, col) {
        return n > 0 ? '<span style="width:' + (n / t * 100) + '%;background:' + col + '"></span>' : "";
      };
      return '<span class="dh-stack">' + seg(o.crit, COL.CRITICAL) + seg(o.warn, COL.WARNING) + seg(o.ok, COL.OK) + '</span>';
    },

    _card: function (sTitle, sSub, sBody, sInsight) {
      return '<div class="dh-card">' +
        '<div class="dh-card-h"><div class="dh-card-t">' + this._esc(sTitle) + '</div>' +
        (sSub ? '<div class="dh-card-s">' + this._esc(sSub) + '</div>' : "") + '</div>' +
        '<div class="dh-card-b">' + sBody + '</div>' +
        (sInsight ? '<div class="dh-card-i">' + sInsight + '</div>' : "") + '</div>';
    },

    _overviewHtml: function (total, crit, warn, ok, score) {
      var tile = function (label, num, sub, cls) {
        return '<div class="dh-kpi ' + (cls || "") + '"><div class="dh-kpi-l">' + label + '</div>' +
          '<div class="dh-kpi-n">' + nf(num) + '</div><div class="dh-kpi-s">' + sub + '</div></div>';
      };
      return '<div class="dh-kpis">' +
        tile(this._i18n.getText("kpiTotal"), total, this._i18n.getText("kpiTotalSub"), "") +
        tile(this._i18n.getText("kpiCritical"), crit, pct(crit, total) + "% " + this._i18n.getText("ofWorkforce"), "dh-crit") +
        tile(this._i18n.getText("kpiWarning"), warn, pct(warn, total) + "% " + this._i18n.getText("ofWorkforce"), "dh-warn") +
        tile(this._i18n.getText("kpiClean"), ok, pct(ok, total) + "% " + this._i18n.getText("ofWorkforce"), "dh-ok") +
        tile(this._i18n.getText("kpiCompleteness"), score + "%", this._i18n.getText("kpiCompletenessSub"), "dh-score") +
        '</div>';
    },

    _failHtml: function (crit, warn, ok, total, byCheck, byCat) {
      /* status donut card */
      var parts = [
        { name: "CRITICAL", value: crit, color: COL.CRITICAL },
        { name: "WARNING",  value: warn, color: COL.WARNING },
        { name: "OK",       value: ok,   color: COL.OK }
      ];
      var legend = "<ul class=\"dh-legend\">" + parts.map(function (p) {
        return '<li><span class="dh-sw" style="background:' + p.color + '"></span>' +
          this._esc(this._i18n.getText("st" + p.name)) +
          '<span class="dh-legv">' + nf(p.value) + " (" + pct(p.value, total) + "%)</span></li>";
      }.bind(this)).join("") + "</ul>";
      var donutBody = '<div class="dh-donut-row">' + this._donutSvg(parts, total) + legend + "</div>";
      var topStatus = crit >= warn && crit >= ok ? "CRITICAL" : warn >= ok ? "WARNING" : "OK";
      var donutInsight = "<b>" + this._esc(this._i18n.getText("st" + topStatus)) + "</b> — " +
        nf(parts.filter(function (p) { return p.name === topStatus; })[0].value) + " " +
        this._i18n.getText("employeesLc") + " (" + pct(parts.filter(function (p) { return p.name === topStatus; })[0].value, total) + "%).";

      /* by-check / by-category card */
      var mode = this._vm.getProperty("/checksMode");
      var rows;
      if (mode === "category") {
        var seen = {};
        this._catalogue.forEach(function (c) { seen[c.cat] = c.catLabel; });
        rows = Object.keys(seen).map(function (code) {
          return { label: seen[code], value: byCat[code] || 0, color: ACCENT };
        });
      } else {
        rows = this._catalogue.map(function (c) {
          return {
            label: c.name, value: byCheck[c.id] || 0,
            color: c.sev === "C" ? COL.CRITICAL : COL.WARNING,
            title: c.rule
          };
        });
      }
      rows = rows.filter(function (r) { return r.value > 0; })
                 .sort(function (a, b) { return b.value - a.value; });
      rows.forEach(function (r) { r.pctOfTotal = pct(r.value, total); });
      var checkBody = rows.length ? this._barsHtml(rows, { showPct: true }) :
        '<p class="dh-empty">' + this._esc(this._i18n.getText("noData")) + "</p>";
      var checkInsight = rows.length
        ? "<b>" + this._esc(rows[0].label) + "</b> — " + nf(rows[0].value) + " " +
          this._i18n.getText("employeesLc") + " (" + rows[0].pctOfTotal + "%)."
        : this._i18n.getText("allClean");

      return '<div class="dh-grid dh-grid-2">' +
        this._card(this._i18n.getText("cardStatus"), this._i18n.getText("cardStatusSub"), donutBody, donutInsight) +
        this._card(this._i18n.getText("cardCheck"),
          mode === "category" ? this._i18n.getText("byCategory") : this._i18n.getText("byCheck"),
          checkBody, checkInsight) +
        "</div>";
    },

    _orgHtml: function (org, total) {
      var sort = this._vm.getProperty("/orgSort");
      var level = this._orgPath.length;
      var rows = Object.keys(org).map(function (k) {
        var o = org[k];
        o.critPct = pct(o.crit, o.emp);
        return o;
      });
      rows.sort(sort === "largest"
        ? function (a, b) { return b.emp - a.emp; }
        : function (a, b) { return b.critPct - a.critPct || b.crit - a.crit; });

      var body = rows.map(function (o) {
        var drill = level < 2 ? "in" : "emp";
        return '<div class="dh-bar dh-bar-click" data-drill="' + drill + '" data-key="' + this._esc(o.key) + '" ' +
          'title="' + this._esc(o.label + ": " + o.crit + " critical / " + o.warn + " warning / " + o.ok + " ok of " + o.emp) + '">' +
          '<span class="dh-bar-label">' + this._esc(o.label) + '</span>' +
          this._stackHtml(o) +
          '<span class="dh-bar-val">' + nf(o.emp) + '</span>' +
          '<span class="dh-bar-pct dh-bar-crit">' + o.critPct + '%</span>' +
          '</div>';
      }.bind(this)).join("");

      var worst = rows.slice().sort(function (a, b) { return b.critPct - a.critPct; })[0];
      var insight = worst
        ? "<b>" + this._esc(worst.label) + "</b> — " + this._i18n.getText("highestCritical") + " " +
          worst.critPct + "% (" + nf(worst.crit) + " " + this._i18n.getText("ofN", [nf(worst.emp)]) + ")."
        : this._i18n.getText("noData");
      var hint = level < 2 ? this._i18n.getText("drillHint") : this._i18n.getText("drillHintLeaf");

      return '<div class="dh-bars dh-bars-org">' + body + '</div>' +
        '<div class="dh-orgfoot"><span class="dh-legend-inline">' +
        '<span class="dh-sw" style="background:' + COL.CRITICAL + '"></span>' + this._esc(this._i18n.getText("stCRITICAL")) +
        '<span class="dh-sw" style="background:' + COL.WARNING + '"></span>' + this._esc(this._i18n.getText("stWARNING")) +
        '<span class="dh-sw" style="background:' + COL.OK + '"></span>' + this._esc(this._i18n.getText("stOK")) +
        '</span><span class="dh-hint">' + this._esc(hint) + '</span></div>' +
        '<div class="dh-card-i">' + insight + '</div>';
    },

    /* ======================================================= interactions */

    _onChartClick: function (e) {
      var el = e.target.closest && e.target.closest("[data-drill]");
      if (!el) { return; }
      var drill = el.getAttribute("data-drill");
      var key   = el.getAttribute("data-key");
      if (drill === "in") {
        this._orgPath.push({ key: key, text: key });
        this._recompute();
      } else if (drill === "emp") {
        var p = { OrgUnit: (key && key !== this._i18n.getText("unassigned")) ? key : "" };
        if (this._orgPath[0]) { p.CompanyCode = this._orgPath[0].key; }
        if (this._orgPath[1]) { p.PersonnelArea = this._orgPath[1].key; }
        this._toEmployees(p);
      }
    },

    onChecksModeChange: function (oEvent) {
      this._vm.setProperty("/checksMode", oEvent.getParameter("selectedItem").getKey());
      this._recompute();
    },

    onOrgSortChange: function (oEvent) {
      this._vm.setProperty("/orgSort", oEvent.getParameter("selectedItem").getKey());
      this._recompute();
    },

    onOrgHome: function () { this._orgPath = []; this._recompute(); },
    onOrgUp:   function () { this._orgPath.pop(); this._recompute(); },

    // Always available - opens Employee 360 with whatever scope is active.
    onOpenEmployees: function () {
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
      if (ctx) { this._vm.setProperty(ctx.getPath() + "/sev", oEvent.getParameter("item").getKey()); }
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
      Fragment.load({ id: this.getView().getId(), name: "hr360.datahealth.view.Help", controller: this })
        .then(function (oDialog) {
          self.getView().addDependent(oDialog);
          self._helpDialog = oDialog;
          oDialog.open();
        });
    },

    onCloseHelp: function () { if (this._helpDialog) { this._helpDialog.close(); } }

  });
});
