***********************************************************************
* Program    : SAPFZFIPL                                              *
*                                                                     *
* Title      : Profitability statement, Per Barrel analysis and       *
*              Other reports.                                         *
*                                                                     *
* Functional :                                                        *
* Specification                                                       *
*                                                                     *
* Author     : Hrishikesh Nikam        Go-Live Date : 17-March-2023   *
*                                                                     *
* Functional : Pawan Kushwaha & Ricky Joseph                          *
* Consultants                                                         *
*                                                                     *
* Login Id   : ABAPUSER01                                             *
*                                                                     *
* Desciption : 1)Profitability Statement Input-                       *
*                    Producing Projects & Non-Producing Projects      *
*                                                                     *
*              2)Qunatitative Information Input,                      *
*              3)Per Barrel Analysis,                                 *
*                                                                     *
*              4)Profitability Statement Reports -                    *
*                     Producing Projects & Non-Producing Projects     *
*                                                                     *
*              5)Variance Analysis  -                                 *
*                    Producing Projects & Non Producing Projects.     *                          *
*                                                                     *
*              6)Other Reports                                        *
*                                                                     *
* Transaction : ZFI_PL                                                *
* Code                                                                *
*                                                                     *
* Transport   : OCDK906048                                            *
* Request                                                             *
*                                                                     *
*Phase I Go-Live : - 17-March-2023                                    *                               *
***********************************************************************
* CHANGE HISTORY                                                      *
* ADDED FOUR TAB BY APARNA ANAND 25.04.2024
* ADDED REMARK IN VARIANCE TAB FOR BOTH PRODUCING AND NON PRODUCING OBJECT                                                              *
***********************************************************************
***********************************************************************
*                                                                     *
* Mod Date   Changed by    Description                Transport Req.  *
*                                                                     *
***********************************************************************

PROGRAM SAPFZFIPL.

*--- MODULE for Data Declaration---------------------------------------*
INCLUDE MZFIPLTOP.

*--- PBO-MODULE for User-screens --------------------------------------*
INCLUDE MZFIPLO01.

*--- PBO-MODULE for User-screens --------------------------------------*
INCLUDE MZFIPLI01.

*--- PBO-MODULE for User-screens --------------------------------------*
INCLUDE MZFIPLF01.
