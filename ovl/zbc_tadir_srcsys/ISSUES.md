# ZBC_TADIR_SRCSYS_CHANGE — issue log

| Date | Issue | Cause | Fix | TR |
|---|---|---|---|---|
| 05/10/26 | Need custom objects editable as originals in new DEV; development was done in OCQ (now QA) | TADIR-SRCSYSTEM = OCQ on all Z/Y objects | New utility report, test mode + confirm, Z/Y name **and** package only | — |
| 05/10/26 | Arnav: simplify — fixed OCQ -> OCD, no selection screen, all custom objects | — | Constants OCQ/OCD; only test flag; criterion widened to SRCSYSTEM=OCQ + name OR package customer namespace; WRITE list | — |
| 05/10/26 | Arnav: change whatever possible | Name/package guard left SICF/SMIM etc. to manual | Guard dropped; every R3TR entry with SRCSYSTEM = OCQ changed | — |
