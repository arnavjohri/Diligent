# WRICEF 141.B — Exceptional Approval format, Paints (FS text extract)

Astral Limited · project UDAY · module SD · V.01 · 24.08.2026 · prepared by Sanjay Modhvadiya

Extracted 05/09/26 from `141B_Exceptional_approval_format_Paints.docx` so the text is
greppable beside `141A_extract.md`. The three images in the document are the Astral,
KPMG and Al-Sayer logos only — no screenshots, no technical names.

## 1.1 Requirement
Paints: Data will be uploaded to the TMG table and report will be fetched from it in
report format.

## 2. Developments
- TMG table for Paints
- Table Upload/change Report
- Report for Paints

## TMG table for Paints — `ZSD_Exp_Paints` as drawn in the FS

| Label | Nature | Field | Key | Length |
|---|---|---|---|---|
| SR. No. | Numeric | ZSRN | Yes | 10 |
| Customer | Numeric | ZCUSTOMER | Yes | 10 |
| Exceptional Approval Month | Numeric | ZEXC_APPR_MONTH | Yes | MM-YYYY |
| Exceptional Approval Type | Fix value | ZEXC_APPR_TYPE | No | Credit Limit / Overdue / Credit Limit & Overdue |
| Exceptional Approval Date From | DATE | ZEXC_DATE_FROM | No | DD-MM-YYYY |
| Exceptional Approval Date To | DATE | ZEXC_DATE_TO | No | DD-MM-YYYY |
| Exceptional Amount | AMNT | ZEXC_AMOUNT | No | 23 |
| Commitment Date | DATE | ZCOMMIT_DATE | No | DD-MM-YYYY |
| Exceptional Approval Amount | AMNT | ZEX_AMNT | No | 23 |
| Collection Commitment Amount | AMNT | ZCM_AMNT | No | 23 |
| Remarks | — | ZREMARKS | No | 250 Cher. |

## Table Upload Report
Data Upload and change report is required for mass data entry.

## Report format (as drawn in the FS — three stacked blocks)

Block 1: Cust. Code | Name | L4_Name | L5_Name | L6_Name
  1009024 | BABA TRADING CO-MNT | Keerti Oberoi | Bharat Kapoor | Shailendra Mohan Pandey
  1025584 | AGRAWAL INDUSTRIES-MNT | Keerti Oberoi | Bharat Kapoor | Shailendra Mohan Pandey

Block 2: Exceptional Approval Month | Exceptional unique number | Exceptional Approval Type |
         Exceptional Approval Date | Exceptional Amount | Collection Commitment Amount
  Jul'26 | SR. No. | 1.Credit Limit 2.Overdue 3. Credit Limit & Overdue | 7/25/2026 | 50,000 | 100,000
  Jul'26 |         |                                                    | 7/26/2026 | 25,000 |

Block 3: Commitment Date | Actual Credit limit | Actual Collection | Non-Fulfilment Amount |
         Default % of Non-Fulfilment Amount | Status – 1 | Status – 2 | Remarks
  8/5/2026 | 100,000 | 125,000 | 25,000 | 25% | Commitment Not due / Commitment Overdue / Collection Received | Fulfilled / Not Fulfilled | 250 Cher.
  8/6/2026 | 100,000 |  98,000 | -2,000 | -2% | | |

## Input (selection screen)

| DESCRIPTION | USE | TABLE | FIELD | Obligation |
|---|---|---|---|---|
| Customer No. | Range | KNVV | KUNNR | Not required |
| Info Category | F4 | UKM_INFOCAT | INFOCATEGORY | Required |
| Info Type | F4 | UKM_INFOTYP (pass INFOCATEGORY selected above) | INFOTYPE | Required |
| Date | Range | — | — | Required |
| Co. Code | F4 | KNB1 | BUKRS | Required |
| Sales Org. | F4 | KNVV | VKORG | Required |
| Division | F4 | KNVV | SPART | Required |
| Cust GR 1 | F4 | KNVV | KVGR1 | Not required |
| Cust GR 2 | F4 | KNVV | KVGR2 | Not required |

## Output mapping

| Label | Table | Field | Instructions |
|---|---|---|---|
| Customer | BP3100 | PARTNER | Fetch |
| Name | KNA1 | NAME1 | Pass PARTNER IN KUNNR fetch NAME1 |
| L4_Name / L5_Name / L6_Name | SAPLSLVC_FULLSCREEN | L4/L5/L6 Name | Submit program SAPLSLVC_FULLSCREEN pass VKORG = 1000, 1100, 1200, 1300 fetch the name |
| Exceptional Approval Month | ZSD_Exp_Paints | ZEXC_APPR_MONTH | Pick Month MM-YYYY |
| Exception No. | ZSD_Exp_Paints | ZSRN | Fetch |
| Exceptional Approval Date From | ZSD_Exp_Paints | ZEXC_DATE_FROM | Fetch |
| Exceptional Approval Date To | ZSD_Exp_Paints | ZEXC_DATE_TO | Fetch |
| Exceptional Amount | ZSD_Exp_Paints | ZEXC_AMNT | Fetch |
| Collection Commitment Amount | ZSD_Exp_Paints | ZCM_AMNT | Fetch |
| Commitment Date | ZSD_Exp_Paints | ZCOMMIT_DATE | Fetch |
| Actual Credit limit | UKMBP_CMS_SGM | CREDIT_LIMIT | Fetch |
| Actual Collection | ACDOCA | HSL | Pass Default '0L' in RLDNR, RBUKRS, GJAHR (year as selection screen), BLART, BUDAT (Posting date as selection screen) "DZ" into the table ACDOCA and fetch HSL (customer not equal to blank and remove the negative sign) |
| Non-Fulfilment Amount | Calculation | — | Collection commitment Amount minus actual collection |
| Default % of Non-Fulfilment Amount | Calculation | — | Non-Fulfilment Amount * 100 / Actual Credit limit |
| Status - 1 | Calculation | Fix value: Commitment Not due / Commitment Overdue / Collection Received | IF Collection Commitment Amount minus Actual Collection ≤ 0 "Collection Received"; IF Commitment Date is future date and Collection Commitment Amount minus Actual Collection > 0 "Commitment Not due"; IF Commitment Date is today's date or past date and Collection Commitment Amount minus Actual Collection > 0 "Commitment Overdue" |
| Status - 2 | Calculation | Fix value: Fulfilled / Not fulfilled | IF Commitment Date arrived and Actual collection > Collection Commitment Amount is Fulfilled; IF commitment date arrived and Actual collection < Collection commitment Amount is Not fulfilled; IF Commitment date Not arrived it should be blank |
| Remarks | ZSD_Exp_Paints | ZREMARKS | Fetch |

## 2.4 Security and authorization
Authorization TBD.

## Reviewer comments embedded in the document
All four by Parth Shah, 26/08/26 and 27/08/26:
- "MM-YYYY – format required"
- "1. Collection Commitment — column missing"
- "2. Actual collection Formula — Collection received during the approval date & Commitment date."
- "3. Non-Fulfilment Amount — Collection commitment minus actual collection"
- "4. Status -1 Remarks — Commitment Not due / Overdue / Collection Received"
