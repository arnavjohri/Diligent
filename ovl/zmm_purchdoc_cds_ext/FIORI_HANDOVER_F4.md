# Fiori handover — F4 on the custom PO header field `zzinsp_typ` (Manage Purchase Orders)

**From:** Arnav Johri (ABAP) · **To:** Fiori consultant (BAS app on `ZMM_PUR_PO_MAINT_V2_SRV`) · **Date:** 22/10/26

## Why the control is replaced instead of the annotation

The app's service is SAP's generated SEGW project. Its entity sets are fixed; the value-help view
`ZI_DOM_FIXVAL_VH` is not one of them and cannot be added without enhancing SAP's classes. Fiori
Elements resolves `Common.ValueList` only inside the app's own service, so the SmartField for
`zzinsp_typ` can never get an F4 there. A UI5 control, however, can bind to two OData models at
once: the **value** stays on the PO entity (default model, draft, two-way), the **list of choices**
comes from a second, tiny service. The PO service is not touched.

## Backend, done by ABAP

| Item | Value |
|---|---|
| Value-help service | `/sap/opu/odata/sap/ZMM_PO_VH_SRV/` (OData V2, SEGW referenced data source) |
| Entity set | `ZI_DOM_FIXVAL_VH` |
| Key / text / sort properties | `DomainValue` / `DomainValueText` / `ValuePosition` (`DomainName` = `ZINSP_TYP`) |
| Rows today | `1` Source Inspection · `2` Destination Inspection (fixed values of domain `ZINSP_TYP`) |
| PO property to write | `zzinsp_typ` on entity set `C_PurchaseOrderTP` (type `C_PurchaseOrderTPType`) |
| Generated SmartField | hidden by ABAP (`@UI.hidden: true` on `zzinsp_typ`) so the field is not shown twice |
| Check before building | PO `$metadata`: `zzinsp_typ` has `sap:updatable="true"` (or its field-control property allows update). If not, the ComboBox would render but the save would be refused |

Proof URLs (Gateway Client or browser, client 500):

    /sap/opu/odata/sap/ZMM_PO_VH_SRV/$metadata
    /sap/opu/odata/sap/ZMM_PO_VH_SRV/ZI_DOM_FIXVAL_VH?$format=json

## Front end, done by Fiori

**1. `manifest.json` — second data source and a named model**

```json
"sap.app": {
  "dataSources": {
    "ZMM_PO_VH_SRV": {
      "uri": "/sap/opu/odata/sap/ZMM_PO_VH_SRV/",
      "type": "OData",
      "settings": { "odataVersion": "2.0" }
    }
  }
},
"sap.ui5": {
  "models": {
    "vh": {
      "dataSource": "ZMM_PO_VH_SRV",
      "preload": true,
      "settings": { "defaultCountMode": "Inline" }
    }
  }
}
```

**2. Object-page extension — a group in the form that holds the custom fields**

```json
"sap.ui5": {
  "extends": {
    "extensions": {
      "sap.ui.viewExtensions": {
        "sap.suite.ui.generic.template.ObjectPage.view.Details": {
          "SmartFormExtension|C_PurchaseOrderTP|<FacetID>": {
            "className": "sap.ui.core.Fragment",
            "fragmentName": "<app.namespace>.ext.fragment.InspectionGroup",
            "type": "XML"
          }
        }
      }
    }
  }
}
```

`<FacetID>` is the ID of the `UI.Facets` entry (collection facet) whose form shows the custom
fields today — read it from the PO `$metadata` (`UI.Facets`, `ID`) or the app's annotation file.

**3. Fragment `ext/fragment/InspectionGroup.fragment.xml`**

```xml
<core:FragmentDefinition
    xmlns="sap.m"
    xmlns:core="sap.ui.core"
    xmlns:smartForm="sap.ui.comp.smartform">
  <smartForm:Group label="Inspection">
    <smartForm:GroupElement label="Inspection Type">
      <ComboBox id="cbInspectionType"
                selectedKey="{zzinsp_typ}"
                editable="{ui>/editable}"
                items="{ path: 'vh>/ZI_DOM_FIXVAL_VH', sorter: { path: 'ValuePosition' } }">
        <core:Item key="{vh>DomainValue}" text="{vh>DomainValueText}"/>
      </ComboBox>
    </smartForm:GroupElement>
  </smartForm:Group>
</core:FragmentDefinition>
```

- `selectedKey="{zzinsp_typ}"` is a relative path on the **default** model: the fragment sits
  inside the object page, which is bound to the PO (draft) entity, so a change is a normal
  draft `MERGE` like any SmartField's.
- `editable="{ui>/editable}"` follows the page's display / edit state.
- `items` come from the **`vh`** model; the ComboBox shows the text in display mode as well.

**First-go variant, no backend at all:** replace the `items` binding by two static items,
`<core:Item key="1" text="Source Inspection"/>` and `<core:Item key="2" text="Destination Inspection"/>`.
Proves the binding and the draft save in an hour. It hardcodes SE11 fixed values in the UI, so it
is a step, not the end state — switch to the `vh` binding once the service is there, and only
with the functional lead's agreement in between.

**4. Test**: edit a PO, pick a value, save, activate; `SE16` → `EKKO-ZZINSP_TYP` on that PO shows
the key. Display mode shows the text.

**Not covered:** F4 on the same field in the list-report filter bar (separate custom filter field),
and any other custom field — each further field is one more `GroupElement` and, if its values are
a different domain, one more entity in `ZMM_PO_VH_SRV`.

## Adaptation project instead of a copied app

Same fragment through *Add Fragment* on the section, plus the descriptor changes
`appdescr_app_addNewDataSource` (the service) and `appdescr_ui5_addNewModel` (the `vh` model).
