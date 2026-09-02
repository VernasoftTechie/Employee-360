sap.ui.define([
  "sap/ui/core/mvc/Controller",
  "sap/ui/model/json/JSONModel",
  "sap/ui/model/Filter",
  "sap/ui/model/FilterOperator",
  "sap/m/MessageToast"
], function (Controller, JSONModel, Filter, FilterOperator, MessageToast) {
  "use strict";

  // org drill levels
  var L_COMPANY = 0, L_AREA = 1, L_ORGUNIT = 2;

  return Controller.extend("hr360.datahealth.controller.Dashboard", {

    onInit: function () {
      this._vm = new JSONModel({
        kpi: { total: 0, critical: 0, warning: 0, clean: 0, criticalPct: 0, cleanPct: 0 },
        status: [], checks: [], detail: [],
        org: {
          level: L_COMPANY,
          path: [],                 // [{key, text}] chosen nodes
          rows: [],
          subtitle: "",
          currentText: "",
          canViewEmployees: false
        }
      });
      this.getView().setModel(this._vm);
      this._i18n = this.getView().getModel("i18n").getResourceBundle();
      this._loadAll();
    },

    /* ---------------------------------------------------------------- loading */

    _loadAll: function () {
      this._setError("");
      Promise.all([ this._loadStatusAndKpis(), this._loadChecks(), this._loadOrg() ])
        .catch(function (e) { this._setError((e && e.message) || String(e)); }.bind(this));
    },

    onRefresh: function () {
      this.getView().getModel().refresh();
      this._loadAll();
    },

    _read: function (sPath, aFilters, iTop) {
      var oList = this.getView().getModel().bindList(sPath, null, null, aFilters || [], {
        $count: false
      });
      return oList.requestContexts(0, iTop || 2000).then(function (aCtx) {
        return aCtx.map(function (c) { return c.getObject(); });
      });
    },

    _num: function (v) { var n = parseFloat(v); return isNaN(n) ? 0 : n; },

    _loadStatusAndKpis: function () {
      return this._read("/StatusSplit").then(function (rows) {
        var total = 0, crit = 0, warn = 0, ok = 0;
        var chart = rows.map(function (r) {
          var c = this._num(r.EmployeeCount);
          total += c;
          if (r.QualityStatus === "CRITICAL") crit = c;
          else if (r.QualityStatus === "WARNING") warn = c;
          else if (r.QualityStatus === "OK") ok = c;
          return { name: r.QualityStatus, value: c };
        }.bind(this));
        this._vm.setProperty("/status", chart);
        this._vm.setProperty("/kpi", {
          total: total, critical: crit, warning: warn, clean: ok,
          criticalPct: total ? Math.round(crit * 1000 / total) / 10 : 0,
          cleanPct: total ? Math.round(ok * 1000 / total) / 10 : 0
        });
      }.bind(this));
    },

    _loadChecks: function () {
      return this._read("/CheckFailure").then(function (rows) {
        rows.sort(function (a, b) { return this._num(b.FailureCount) - this._num(a.FailureCount); }.bind(this));
        this._vm.setProperty("/checks", rows.map(function (r) {
          return { name: r.CheckID, value: this._num(r.FailureCount) };
        }.bind(this)));
      }.bind(this));
    },

    /* --------------------------------------------------------------- org drill */

    _orgFilters: function () {
      var path = this._vm.getProperty("/org/path");
      var f = [];
      if (path[0]) f.push(new Filter("CompanyCode", FilterOperator.EQ, path[0].key));
      if (path[1]) f.push(new Filter("PersonnelArea", FilterOperator.EQ, path[1].key));
      return f;
    },

    _loadOrg: function () {
      var level = this._vm.getProperty("/org/level");
      var path = this._vm.getProperty("/org/path");
      var src, groupBy, labelOf;

      if (level === L_COMPANY) {
        src = "/AreaHealth"; groupBy = "CompanyCode"; labelOf = function (r) { return r.CompanyCode; };
      } else if (level === L_AREA) {
        src = "/AreaHealth"; groupBy = "PersonnelArea"; labelOf = function (r) { return r.PersonnelArea; };
      } else {
        src = "/KpiOverview"; groupBy = "OrgUnit"; labelOf = function (r) { return r.OrgUnit || "(none)"; };
      }

      // detail table follows the same scope
      this._loadDetail();

      return this._read(src, this._orgFilters()).then(function (rows) {
        var agg = {};
        rows.forEach(function (r) {
          var k = r[groupBy] || "(none)";
          var a = agg[k] || (agg[k] = { key: k, label: labelOf(r), employees: 0, critical: 0, passed: 0 });
          var emp = this._num(r.EmployeeCount);
          a.employees += emp;
          a.critical  += this._num(r.CriticalCount);
          // completeness back-computed: AvgCompleteness is a % -> passed-check-equivalent
          a.passed += emp * this._num(r.AvgCompleteness) / 100;
        }.bind(this));

        var out = Object.keys(agg).map(function (k) {
          var a = agg[k];
          return {
            key: a.key, label: a.label,
            employees: a.employees, critical: a.critical,
            completeness: a.employees ? Math.round(a.passed * 1000 / a.employees) / 10 : 0
          };
        });
        out.sort(function (x, y) { return x.completeness - y.completeness; });   // worst first
        this._vm.setProperty("/org/rows", out);

        var subKey = ["cardOrgSubL0", "cardOrgSubL1", "cardOrgSubL2"][level];
        this._vm.setProperty("/org/subtitle",
          this._i18n.getText(subKey, [ path[0] && path[0].key, path[1] && path[1].key ]));
        this._vm.setProperty("/org/currentText",
          level === L_COMPANY ? "" : path.map(function (p) { return p.key; }).join(" / "));
        this._vm.setProperty("/org/canViewEmployees", path.length > 0);
      }.bind(this));
    },

    onOrgBarSelect: function (oEvent) {
      var level = this._vm.getProperty("/org/level");
      if (level >= L_ORGUNIT) {
        // leaf: bars are org units -> open the employee list for that org unit
        var d = oEvent.getParameter("data");
        var node = d && d[0] && d[0].data && d[0].data.Node;
        if (node) this._toEmployees({ OrgUnit: this._keyForLabel(node) });
        return;
      }
      var data = oEvent.getParameter("data");
      var label = data && data[0] && data[0].data && data[0].data.Node;
      if (!label) return;
      var key = this._keyForLabel(label);
      var path = this._vm.getProperty("/org/path").slice();
      path.push({ key: key, text: label });
      this._vm.setProperty("/org/path", path);
      this._vm.setProperty("/org/level", level + 1);
      this._loadOrg();
    },

    _keyForLabel: function (label) {
      var row = (this._vm.getProperty("/org/rows") || []).filter(function (r) { return r.label === label; })[0];
      return row ? row.key : label;
    },

    onOrgHome: function () {
      this._vm.setProperty("/org/path", []);
      this._vm.setProperty("/org/level", L_COMPANY);
      this._loadOrg();
    },

    onViewEmployees: function () {
      var path = this._vm.getProperty("/org/path");
      var p = {};
      if (path[0]) p.CompanyCode = path[0].key;
      if (path[1]) p.PersonnelArea = path[1].key;
      this._toEmployees(p);
    },

    /* -------------------------------------------------------------- detail tbl */

    _loadDetail: function () {
      this._read("/KpiOverview", this._orgFilters(), 200).then(function (rows) {
        rows.sort(function (a, b) { return this._num(b.CriticalCount) - this._num(a.CriticalCount); }.bind(this));
        this._vm.setProperty("/detail", rows);
      }.bind(this));
    },

    onDetailRowPress: function (oEvent) {
      var o = oEvent.getSource().getBindingContext().getObject();
      this._toEmployees({
        CompanyCode: o.CompanyCode, PersonnelArea: o.PersonnelArea,
        OrgUnit: o.OrgUnit, QualityStatus: o.QualityStatus
      });
    },

    /* ------------------------------------------------------------------ nav */

    _toEmployees: function (mParams) {
      var oClean = {};
      Object.keys(mParams).forEach(function (k) { if (mParams[k]) oClean[k] = mParams[k]; });

      if (sap.ushell && sap.ushell.Container) {
        sap.ushell.Container.getServiceAsync("CrossApplicationNavigation").then(function (oCAN) {
          oCAN.toExternal({
            target: { semanticObject: "Employee", action: "display" },
            params: oClean
          });
        });
      } else {
        MessageToast.show("Would open Employee 360 filtered by: " + JSON.stringify(oClean));
      }
    },

    _setError: function (sText) {
      var s = this.byId("errStrip");
      s.setText(sText || "");
      s.setVisible(!!sText);
    }
  });
});
