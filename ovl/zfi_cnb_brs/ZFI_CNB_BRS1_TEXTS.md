# ZFI_CNB_BRS1 — text elements and selection texts

As listed in the ONGC/OCD print of ZFI_CNB_BRS (10.10.2026). Only needed if the program is created
by paste instead of an SE38 copy. Text 017 is cut off in the print; take its full text from ZFI_CNB_BRS (SE38 → Goto → Text elements).

```
Title:
   Bank Reconciliation Report
Text elements:
001   Controls
002   Others
003   Control No  not  proper
004   Value date is greater than Statement date
005   Transaction code not valid for Bank Account No
006   Debit/Credit Indicator not Correct
007   The Amount is not same as the  amount in Check
008   Check no not valid
009   Check has been encashed
010   The payment document has been cleared
011   G/L Ac  for check is not same as bank clearing Ac.
013   More than one matching doc. found for RT#
014   The Document no for RT# is not a open item
015   The Doc. Amt for RT# <> transaction amt
016   G/L Account for RT# is not same as bank clearing Account
017   The Sum of all Transaction Amounts Rs. does not add up to the Difference b
018   G/L Ac. for check is blank
019   RT# can not be blank for transaction code RCT*
020   Payment Document for the check is blank
021   Not a valid Narration
022   No matching doc. found for RT#
023   Output Control ( Perform Activities in the Specified Order)
024   BDC Session Name
025   Upload BDC Session
026   Amount not valid hence not included for sum of transactions
027   Duplicate Narration
028   Transaction Date () not valid
029   Transaction date        From :
030   To :
031   Document no not valid(Valid format is R999999/D999999)
032   Value Date () not valid
033   The Document no for pre-go live  Check is not a open item
034   For Chk no match in bankbook or in alloc.field(Pre-go Live Chk)
035   D/C indicator incompatible with narration
036   Cum bal not proper:It should be
037   No previous month records Available
038   Narration Can not be blank
039   Transaction amt can not be blank
040   Cumulative amt can not be blank
041   Validation/Matching Program
042   BRS Rep(Unmatched/Trans/Rev)
043
044   Inconsistent File header in Previous month Error file
045   Save the Reports in Local file and generate final BRS.Pl. Get it approved.
Selection texts:
AZDAT
        Statement Date
AZNUM
        Statement Number
BDCSESS
        Upload to BDC Session
BRS
        BRS Rep(Unmatched/Trans/Rev)
BUKRS
        Company Code
CLBL
        Bank Stmt Closing Balance
DT_FM
        Transaction Dates From :
DT_TO
        To :
GJAHR
        Fiscal Year
GSBER
        Business Area
HBKID
        House Bank
HKTID
        Account ID
KOSTL
        Cost Center
OPBL
        Bank Stmt Opening Balance
POSTDT
        Posting date
SESSION
        BDS Session Name
VALD
        Validation/Matching Program
```
