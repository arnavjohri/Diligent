sap.ui.define([
    "sap/ui/core/mvc/Controller"
], function (Controller) {
    "use strict";

    // BOC By Arnav on 24/09/26
    // Fiscal year is not entered by the user: it is derived from "Date To".
    // Indian fiscal year, April to March: FY = year of Date To when its month
    // is April or later, otherwise the year before (rule agreed 24/09/26).
    // The global filter entity ZDPR_Q_DASH_FILTER keeps the P_FiscalYear
    // parameter because cards 2, 3 and 4 receive it by NAME from the filter
    // bar; this extension hides the field and fills it whenever the dates
    // change, so the mandatory parameter is always set before Go.
    // ASSUMPTION: the Overview Page's SmartFilterBar has the view id
    // "ovpGlobalFilter" and keys analytical parameters as "$Parameter.<name>"
    // in getFilterData / setFilterData. Both verified on the first preview run.

    var PARAM_TO = "$Parameter.P_DateTo";
    var PARAM_FY = "$Parameter.P_FiscalYear";

    function toDate(vValue) {
        if (!vValue) {
            return null;
        }
        if (vValue instanceof Date) {
            return isNaN(vValue.getTime()) ? null : vValue;
        }
        var s = String(vValue);
        // yyyymmdd (Edm.String dates of the analytical services)
        if (/^\d{8}$/.test(s)) {
            return new Date(Number(s.substr(0, 4)), Number(s.substr(4, 2)) - 1, Number(s.substr(6, 2)));
        }
        // yyyy-mm-dd or yyyy-mm-ddThh:mm:ss (Edm.DateTime as text)
        var m = /^(\d{4})-(\d{2})-(\d{2})/.exec(s);
        if (m) {
            return new Date(Number(m[1]), Number(m[2]) - 1, Number(m[3]));
        }
        var d = new Date(s);
        return isNaN(d.getTime()) ? null : d;
    }

    function fiscalYearOf(vDateTo) {
        var d = toDate(vDateTo);
        if (!d) {
            return null;
        }
        var iYear = d.getFullYear();
        var iMonth = d.getMonth() + 1;          // 1..12
        return String(iMonth >= 4 ? iYear : iYear - 1);
    }

    return Controller.extend("zdprdashboard.ext.controller.FiscalYear", {

        onInit: function () {
            var oView = this.getView();
            var oFilterBar = oView && oView.byId("ovpGlobalFilter");
            if (!oFilterBar) {
                return;
            }
            var fnHide = function () {
                this._hideFiscalYear(oFilterBar);
            }.bind(this);
            if (oFilterBar.isInitialised && oFilterBar.isInitialised()) {
                fnHide();
            } else {
                oFilterBar.attachInitialise(fnHide);
            }
            oFilterBar.attachFilterChange(function () {
                this._deriveFiscalYear(oFilterBar);
                this._hideFiscalYear(oFilterBar);   // idempotent; survives late init
            }, this);
        },

        _hideFiscalYear: function (oFilterBar) {
            // The SmartFilterBar keeps MANDATORY fields in the bar whatever the
            // "visible in filter bar" flag says, so the item is hidden fully.
            // Item names may or may not carry the "$Parameter." prefix.
            var aItems = [].concat(
                oFilterBar.getFilterGroupItems ? (oFilterBar.getFilterGroupItems() || []) : [],
                oFilterBar.getFilterItems ? (oFilterBar.getFilterItems() || []) : []
            );
            aItems.forEach(function (oItem) {
                var sName = oItem.getName ? String(oItem.getName()) : "";
                if (sName === PARAM_FY || sName === "P_FiscalYear" || /P_FiscalYear$/.test(sName)) {
                    if (oItem.setVisibleInFilterBar) {
                        oItem.setVisibleInFilterBar(false);
                    }
                    if (oItem.setVisible) {
                        oItem.setVisible(false);
                    }
                }
            });
            // last resort: hide the field control itself (label goes with it)
            var oCtrl = oFilterBar.determineControlByName && (
                oFilterBar.determineControlByName(PARAM_FY) || oFilterBar.determineControlByName("P_FiscalYear"));
            if (oCtrl && oCtrl.getParent && oCtrl.getParent() && oCtrl.getParent().setVisible) {
                oCtrl.getParent().setVisible(false);
            }
        },

        _deriveFiscalYear: function (oFilterBar) {
            var oData = oFilterBar.getFilterData() || {};
            var sFy = fiscalYearOf(oData[PARAM_TO]);
            if (!sFy || oData[PARAM_FY] === sFy) {
                return;                          // nothing to do, avoids re-entry
            }
            var oPatch = {};
            oPatch[PARAM_FY] = sFy;
            oFilterBar.setFilterData(oPatch);    // merge, keeps the other fields
        }
    });
    // EOC By Arnav on 24/09/26
});
