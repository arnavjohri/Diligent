sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/m/MessageToast"
], function (Controller, MessageToast) {
    "use strict";

    // BOC By Arnav on 24/09/26
    // Fiscal year is not entered by the user: it is derived from "Date To".
    // Indian fiscal year, April to March: FY = year of Date To when its month
    // is April or later, otherwise the year before (rule agreed 24/09/26).
    // The global filter entity ZDPR_Q_DASH_FILTER keeps the P_FiscalYear
    // parameter because cards 2, 3 and 4 receive it by NAME from the filter
    // bar; this extension fills it whenever the dates change and takes the
    // field out of the filter bar, so the mandatory parameter is always set
    // before Go without the user seeing it.
    //
    // Facts taken from the sap.ovp 1.136.10 and sap.ui.comp 1.136 sources
    // (not assumptions):
    // 1. sap.ovp.app.Main is an async XML view; the filter bar does not exist
    //    at onInit. OVP itself waits for getView().loaded(). So do we.
    // 2. Filter bar id is "ovpGlobalFilter"; parameter keys in getFilterData
    //    and setFilterData are "$Parameter.<name>".
    // 3. A mandatory field can be removed from the bar with
    //    setVisibleInFilterBar(false) ONLY once it has a value; without a
    //    value the FilterBar reverts the change. Hence: fill first, hide after.
    // 4. Never call setVisible(false) on the item: an invisible item drops
    //    out of getFilterData, OVP's mandatory check then fails and no card
    //    loads. VisibleInFilterBar=false with a value keeps it in the data.

    // Set to false before deployment. While true, short messages appear at
    // the bottom of the page reporting what the extension does.
    var DEBUG = true;

    var KEY_TO = "$Parameter.P_DateTo";
    var KEY_FY = "$Parameter.P_FiscalYear";

    function toDate(vValue) {
        if (!vValue) {
            return null;
        }
        if (vValue instanceof Date) {
            return isNaN(vValue.getTime()) ? null : vValue;
        }
        // DateRangeType shape: { ranges: [ { value1: Date } ] }
        if (typeof vValue === "object" && vValue.ranges && vValue.ranges[0]) {
            return toDate(vValue.ranges[0].value1);
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

    function fiscalYearOf(oDate) {
        var iYear = oDate.getFullYear();
        var iMonth = oDate.getMonth() + 1;      // 1..12
        return String(iMonth >= 4 ? iYear : iYear - 1);
    }

    function say(sText) {
        if (DEBUG) {
            MessageToast.show("FY ext: " + sText, { duration: 6000, width: "40em" });
        }
    }

    return Controller.extend("zdprdashboard.ext.controller.FiscalYear", {

        onInit: function () {
            var oView = this.getView();
            if (!oView || !oView.loaded) {
                return;
            }
            oView.loaded().then(function () {
                var oFilterBar = oView.byId("ovpGlobalFilter");
                if (!oFilterBar) {
                    say("no filter bar in the view");
                    return;
                }
                say("loaded");
                var fnApply = function () {
                    this._apply(oFilterBar);
                }.bind(this);
                if (oFilterBar.isInitialised && oFilterBar.isInitialised()) {
                    fnApply();
                } else if (oFilterBar.attachInitialized) {
                    oFilterBar.attachInitialized(fnApply);
                } else {
                    oFilterBar.attachInitialise(fnApply);
                }
                // user typed a date, a variant was applied, or setFilterData ran
                oFilterBar.attachFilterChange(fnApply);
                if (oFilterBar.attachAfterVariantLoad) {
                    oFilterBar.attachAfterVariantLoad(fnApply);
                }
            }.bind(this));
        },

        _apply: function (oFilterBar) {
            var oData = oFilterBar.getFilterData() || {};
            var oDateTo = toDate(oData[KEY_TO]);
            // no Date To yet: seed from today so the field can be hidden at
            // once; it is corrected as soon as Date To is entered
            var sFy = fiscalYearOf(oDateTo || new Date());
            if (oData[KEY_FY] !== sFy) {
                var oPatch = {};
                oPatch[KEY_FY] = sFy;
                oFilterBar.setFilterData(oPatch);        // merge; fires filterChange
                say((oDateTo ? "Date To -> " : "no Date To yet, today -> ") + "fiscal year " + sFy);
                return;                                  // the filterChange re-entry hides it
            }
            this._hide(oFilterBar);
        },

        _hide: function (oFilterBar) {
            var aItems = oFilterBar.getAllFilterItems ? oFilterBar.getAllFilterItems(false) : [];
            aItems.forEach(function (oItem) {
                if (oItem.getName && oItem.getName() === KEY_FY && oItem.getVisibleInFilterBar()) {
                    oItem.setVisibleInFilterBar(false);  // allowed: the field has a value
                    say("fiscal year field hidden");
                }
            });
        }
    });
    // EOC By Arnav on 24/09/26
});
