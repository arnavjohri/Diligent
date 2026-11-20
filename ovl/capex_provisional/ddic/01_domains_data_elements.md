# Object 1 — domains and data elements (`ZFI_PCX_*`)

Provisional Capex / Opex, OVL · prepared 20/11/26 · key in by hand in SE11 (or ADT), package and TR
of your choice. Create the 5 domains first, activate, then the 27 data elements.

Built on the assumptions of `../ASSUMPTIONS_AND_QUERIES.md` (Arnav, 20/11/26: assume and build):
amounts 2 decimals, rates 5 decimals, plain numbers without currency key (items 13, 15).

## Domains (5)

| Domain | Type | Length | Decimals | Short description | Notes |
|---|---|---|---|---|---|
| `ZFI_PCX_AMT` | DEC | 15 | 2 | Amount, USD million / INR crore | No sign (negatives are refused at entry). No fixed values. |
| `ZFI_PCX_RATE` | DEC | 9 | 5 | Exchange rate INR per USD | No sign. |
| `ZFI_PCX_STATUS` | CHAR | 1 |  | Fortnight entry status | Fixed values: blank = Not yet open · O = Open for entry · F = Frozen |
| `ZFI_PCX_ENTTYP` | CHAR | 1 |  | Entity type | Fixed values: S = Subsidiary · J = Incorporated JV · H = HQ / directly held |
| `ZFI_PCX_OPXCLS` | CHAR | 1 |  | Opex class of a project | Fixed values: C = Consolidated block · E = Equity investee |

Output length: accept what SE11 proposes.

## Data elements (27)

Short description = the Long label. Heading label = the Medium label.

| Data element | Type | Short (10) | Medium (20) | Long (40) |
|---|---|---|---|---|
| `ZFI_PCX_PROJID` | Built-in NUMC 4 | Project | Project Number | Project Number |
| `ZFI_PCX_PROJNM` | Built-in CHAR 60 | Proj. Name | Project Name | Project Name |
| `ZFI_PCX_SORTNO` | Built-in NUMC 4 | Sort No. | Sort Number | Sort Number in Reports |
| `ZFI_PCX_ACTIVE` | Domain XFELD (standard) | Active | Active | Project Active |
| `ZFI_PCX_BU` | Built-in CHAR 10 | Bus. Unit | Business Unit | Business Unit |
| `ZFI_PCX_JVTXT` | Built-in CHAR 60 | JV Code | JV Code(s) | JV Code(s), Information Only |
| `ZFI_PCX_ENTID` | Built-in NUMC 3 | Entity | Entity Number | Entity Number |
| `ZFI_PCX_ENTNM` | Built-in CHAR 60 | Ent. Name | Entity Name | Entity Name |
| `ZFI_PCX_ENTTYP` | Domain ZFI_PCX_ENTTYP | Ent. Type | Entity Type | Entity Type |
| `ZFI_PCX_OPXCLS` | Domain ZFI_PCX_OPXCLS | Opex Class | Opex Class | Opex Class (Consolidated / Equity) |
| `ZFI_PCX_PERNO` | Built-in NUMC 2 | Fortnight | Fortnight Number | Fortnight Number (01-24) |
| `ZFI_PCX_CUTOFF` | Built-in DATS | Cutoff | Cutoff Date | Fortnight Cutoff Date |
| `ZFI_PCX_STATUS` | Domain ZFI_PCX_STATUS | Status | Entry Status | Fortnight Entry Status |
| `ZFI_PCX_CHTIME` | Built-in TIMS | Changed At | Changed At | Time of Last Change |
| `ZFI_PCX_TTARATE` | Domain ZFI_PCX_RATE | TTA Rate | TTA Rate (INR/USD) | TTA Rate for the Fortnight (INR/USD) |
| `ZFI_PCX_BERATE` | Domain ZFI_PCX_RATE | BE Rate | BE Rate (INR/USD) | Budget Estimate Rate (INR/USD) |
| `ZFI_PCX_RERATE` | Domain ZFI_PCX_RATE | RE Rate | RE Rate (INR/USD) | Revised Estimate Rate (INR/USD) |
| `ZFI_PCX_EWIP` | Domain ZFI_PCX_AMT | Cum. EWIP | Cumulative EWIP | Cumulative EWIP (USD Million) |
| `ZFI_PCX_DWIP` | Domain ZFI_PCX_AMT | Cum. DWIP | Cumulative DWIP | Cumulative DWIP (USD Million) |
| `ZFI_PCX_CWIP` | Domain ZFI_PCX_AMT | Cum. CWIP | Cumulative CWIP | Cumulative CWIP (USD Million) |
| `ZFI_PCX_OTHCAP` | Domain ZFI_PCX_AMT | Cum. Other | Cum. Other Capex | Cumulative Other Capex (USD Million) |
| `ZFI_PCX_CAPBE` | Domain ZFI_PCX_AMT | Capex BE | Capex BE (USD Mn) | Capex Budget Estimate (USD Million) |
| `ZFI_PCX_CAPRE` | Domain ZFI_PCX_AMT | Capex RE | Capex RE (USD Mn) | Capex Revised Estimate (USD Million) |
| `ZFI_PCX_ITDUSD` | Domain ZFI_PCX_AMT | Op.ITD USD | Opening ITD (USD Mn) | Opening ITD Capex (USD Million) |
| `ZFI_PCX_PYUSD` | Domain ZFI_PCX_AMT | PY Cap USD | PY Capex (USD Mn) | Prior-Year Actual Capex (USD Million) |
| `ZFI_PCX_ITDINR` | Domain ZFI_PCX_AMT | Op.ITD INR | Opening ITD (INR Cr) | Opening ITD Capex (INR Crore) |
| `ZFI_PCX_PYINR` | Domain ZFI_PCX_AMT | PY Cap INR | PY Capex (INR Cr) | Prior-Year Actual Capex (INR Crore) |

## Standard data elements the tables will use — nothing to create

`MANDT`, `GJAHR` (financial year = its starting calendar year), `AENAM` (changed by), `AEDAT` (changed on).

## Not in this step

Tables (objects 2–7), lock object, message class. Opex amount data elements come with the Opex step.
