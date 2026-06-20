/**************************************************************************
Program Name : Table_14_2_1.sas

Project      : Clinical SAS Portfolio Project
Study        : Adverse Events Analysis

Purpose      : Generate Table 14.2.1 - Treatment Emergent Adverse Events
               by Treatment, System Organ Class, and Preferred Term
               for the Safety Population.

Input Data   : ADSL
               ADAE

Output       : Table_14_2_1.rtf

Programmer   : Nithish M S

Created Date : 20JUN2026

Software     : SAS 9.4

***************************************************************************
Modification History
***************************************************************************
Date         Programmer      Description
-----------  --------------  ---------------------------------------------
20JUN2026    Nithish M S     Initial version
**************************************************************************/

/* IMPORT ADSL */

PROC IMPORT DATAFILE="/home/u64252598/Project AE Table raw file Adverse_ADSL.xlsx"
    OUT=ADSL
    DBMS=XLSX
    REPLACE;
    GETNAMES=YES;
RUN;

/* SAFETY POPULATION */

DATA ADSL1;
SET ADSL;

IF SAFFL='Y';

IF INDEX(UPCASE(TRT01A),"100 MG TG3304")>0 THEN DO;
    TRT='A';
    ORD=1;
END;
ELSE IF INDEX(UPCASE(TRT01A),"PLACEBO")>0 THEN DO;
    TRT='B';
    ORD=2;
END;

KEEP USUBJID TRT ORD;
RUN;

/* BIG N */

PROC SQL NOPRINT;

SELECT COUNT(DISTINCT USUBJID)
INTO :N1-:N2
FROM ADSL1
GROUP BY ORD
ORDER BY ORD;

QUIT;

%PUT &=N1 &=N2;

/* IMPORT ADAE */

PROC IMPORT DATAFILE="/home/u64252598/Project AE Table raw file Adverse_ADAE.xlsx"
    OUT=ADAE
    DBMS=XLSX
    REPLACE;
    GETNAMES=YES;
RUN;

/* TEAE POPULATION */

DATA ADAE1;
SET ADAE;

IF SAFFL='Y' AND TEAEFL='Y';

IF INDEX(UPCASE(TRTA),"100 MG TG3304")>0 THEN DO;
    TRT='A';
    ORD=1;
END;
ELSE IF INDEX(UPCASE(TRTA),"PLACEBO")>0 THEN DO;
    TRT='B';
    ORD=2;
END;

RUN;

/* OVERALL SUBJECTS WITH TEAES */

PROC SQL;

CREATE TABLE OVERALL AS
SELECT TRT,
       "Number of Subjects with TEAEs" AS AEBODSYS LENGTH=200,
       "" AS AEDECOD LENGTH=200,
       COUNT(DISTINCT USUBJID) AS N,
       0 AS LVL
FROM ADAE1
GROUP BY TRT;

/* SOC LEVEL */

CREATE TABLE SOC AS
SELECT TRT,
       AEBODSYS,
       "" AS AEDECOD LENGTH=200,
       COUNT(DISTINCT USUBJID) AS N,
       1 AS LVL
FROM ADAE1
GROUP BY TRT,AEBODSYS;


/* PT LEVEL */

CREATE TABLE PT AS
SELECT TRT,
       AEBODSYS,
       AEDECOD,
       COUNT(DISTINCT USUBJID) AS N,
       2 AS LVL
FROM ADAE1
GROUP BY TRT,AEBODSYS,AEDECOD;

QUIT;


/* STACK DATA */

DATA ALL;
SET OVERALL SOC PT;
RUN;

/* SORT*/

PROC SORT DATA=ALL;
BY LVL AEBODSYS AEDECOD TRT;
RUN;

/* TRANSPOSE*/

PROC TRANSPOSE DATA=ALL OUT=TRANS;
BY LVL AEBODSYS AEDECOD;
ID TRT;
VAR N;
RUN;

/* CREATE DISPLAY VALUES*/

DATA FINAL;

SET TRANS;

LENGTH TERM $200
       DRUGA $30
       DRUGB $30;

/* Treatment A */

IF MISSING(A) THEN DRUGA='0';
ELSE IF A=&N1 THEN
DRUGA=CATS(PUT(A,3.),'(100%)');
ELSE
DRUGA=CATS(PUT(A,3.),'(',
            PUT((A/&N1)*100,5.1),'%)');

/* Treatment B */

IF MISSING(B) THEN DRUGB='0';
ELSE IF B=&N2 THEN
DRUGB=CATS(PUT(B,3.),'(100%)');
ELSE
DRUGB=CATS(PUT(B,3.),'(',
            PUT((B/&N2)*100,5.1),'%)');

/* Display hierarchy */

IF LVL=0 THEN
TERM='Number of Subjects with TEAEs';

ELSE IF LVL=1 THEN
TERM=AEBODSYS;

ELSE IF LVL=2 THEN
TERM='   '||STRIP(AEDECOD);

RUN;

/* REPORT */

ODS ESCAPECHAR='^';

ODS RTF FILE="/home/u64252598/Table_14_2_1.rtf"
STYLE=JOURNAL;

TITLE1 J=C H=6PT
"TABLE 14.2.1";

TITLE2 J=C H=6PT
"TREATMENT EMERGENT ADVERSE EVENTS BY TREATMENT, SYSTEM ORGAN CLASS AND PREFERRED TERM";

TITLE3 J=C H=6PT
"(SAFETY POPULATION)";

PROC REPORT DATA=FINAL NOWD HEADLINE HEADSKIP SPLIT='|';

COLUMN TERM
       ("Treatment"
         DRUGA
         DRUGB);

DEFINE TERM / DISPLAY
"MedDRA@ System Organ Class|MedDRA@ Preferred Term"
STYLE(COLUMN)=[JUST=L CELLWIDTH=50%];

DEFINE DRUGA / DISPLAY
"100 MG TG3304|(N=&N1)"
STYLE(COLUMN)=[JUST=C CELLWIDTH=20%];

DEFINE DRUGB / DISPLAY
"Placebo|(N=&N2)"
STYLE(COLUMN)=[JUST=C CELLWIDTH=20%];

RUN;

ODS RTF CLOSE;
TITLE;















