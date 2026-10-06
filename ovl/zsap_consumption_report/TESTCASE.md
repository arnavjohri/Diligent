# ZSAP_CONSUMPTION_REPORT — test case (data as of 06/10/26 SE16N extract)

Counted entries = HEAD_IT_APPROVE = 'X' only: docs 3,4,5,10,11,16,18,19,20,21,22,23,24,25,27,28,30.
Not counted: docs 1,2,6-9,12-15,17,26,29 (not Head-IT approved / rejected), docs 31-43 (March,
only SAP PM approved), doc 5 27.01.2026 (Scope MICROSOFT).

Rate = DAILY_RATE_GST (PM/FTLS/SDC FTLS 81,420; BAES 94,400; EXEC 56,640).

## T1 01.01.2026-31.01.2026 (period = till date, no earlier entries)
| Service Element | AS IS Cons | Cons till | Avail | Cons Amt | Cons Amt till | Avail Amt |
|---|---|---|---|---|---|---|
| SDC: PROJECT MANAGEMENT | 2 | 2 | 180 | 162,840 | 162,840 | 14,655,600 |
| BUSINESS ADVISORY... | 0 | 0 | 25 | 0 | 0 | 2,360,000 |
| FUNCTIONAL AND TECH LEAD SERVICES | 3 | 3 | 429 | 244,260 | 244,260 | 34,929,180 |
| SDC: FUNCTIONAL AND TECH LEAD SERVI | 2 | 2 | 1,513 | 162,840 | 162,840 | 123,188,460 |
| EXECUTION SERVICES | 0 | 0 | 144 | 0 | 0 | 8,156,160 |

## T2 01.02.2026-28.02.2026 (the real test: till date includes January)
| Service Element | AS IS Cons | Cons till | Avail | Cons Amt | Cons Amt till | Avail Amt |
|---|---|---|---|---|---|---|
| SDC: PROJECT MANAGEMENT | 8 | 10 | 172 | 651,360 | 814,200 | 14,004,240 |
| BUSINESS ADVISORY... | 0 | 0 | 25 | 0 | 0 | 2,360,000 |
| FUNCTIONAL AND TECH LEAD SERVICES | 32 | 35 | 397 | 2,605,440 | 2,849,700 | 32,323,740 |
| SDC: FUNCTIONAL AND TECH LEAD SERVI | 59 | 61 | 1,454 | 4,803,780 | 4,966,620 | 118,384,680 |
| EXECUTION SERVICES | 6 | 6 | 138 | 339,840 | 339,840 | 7,816,320 |
Old logic would show Avail 174 / 400 / 1,456 / 138.
Additional (all rows): 0 consumed; EXECUTION SERVICES Additional Avail 830 / 47,011,200.

## T3 01.01.2026-31.12.2026
Same Cons = Cons till = T2 "till" values (10 / 0 / 35 / 61 / 6); Avail as T2.
