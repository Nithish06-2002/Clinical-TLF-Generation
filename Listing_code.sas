/*Program 1:
Data sets : adsl , advs
Variables: Subject identifier
           sex
           country
           age
           planned treatment
           parameter description
           analysis visit
           analysis value
*/

*
Subject identifier - advs, adsl

sex - adsl
country - adsl
age - adsl

Planned Treatment - advs
Planned Treatment Number - advs
Parameter Description - advs
Analysis Visit - advs
Analysis Visit Number - advs
Analysis value - advs
;

**********************************************************************
* PROGRAM NAME : _VISIT.SAS
* OUTPUT NAME : _VISIT.TXT
* PROGRAMMER :NITHISH M S
* DATE : 18/03/2026
* REVIEWER :
* REVIEW DATE :
* TITLE : SUBJECT VISITS SINGS INFORMATION - LISTING
***********************************************************************;
*/;



/* IMPOERT ADSL AND ADVS DATASET */

PROC IMPORT DATAFILE="/home/u64252598/SAS/New Folder/adsl_tlf_practice.csv"
OUT=adsl
DBMS=CSV REPLACE;
GETNAMES=YES;
QUIT;

PROC IMPORT DATAFILE="/home/u64252598/SAS/New Folder/advs_tlf_practice.csv"
OUT=advs
DBMS=CSV REPLACE;
GETNAMES=YES;
QUIT;

PROC SQL;
CREATE TABLE ADSL_ADVS AS SELECT 

ADVS.USUBJID,ADVS.TRTP,ADVS.TRTPN,ADVS.PARAM,ADVS.AVISIT,ADVS.AVAL,
ADSL.USUBJID,ADSL.SEX,ADSL.COUNTRY,ADSL.AGE
FROM ADVS LEFT JOIN ADSL
ON ADVS.USUBJID=ADSL.USUBJID;
QUIT;


PROC FORMAT;
VALUE $ GENDER "M"="Male" "F"="Female";
run;

ods rtf file="/home/u64252598/Table_poj/listing.rtf";

proc report data=adsl_advs headline headskip SPLIT=".";
column (USUBJID SEX COUNTRY AGE TRTP TRTPN PARAM AVISIT AVAL);
DEFINE USUBJID/ORDER "SUBJECT.IDENTIFIER";
DEFINE SEX/ORDER FORMAT=$GENDER.;
DEFINE COUNTRY/ORDER;
DEFINE AGE/ORDER;
DEFINE TRTP/ORDER;
DEFINE TRTPN/ORDER NOPRINT;
DEFINE PARAM/ORDER;
DEFINE AVSIT/ORDER;
DEFINE AVAL/ORDER;
BREAK AFTER PARAM/SKIP;

COMPUTE BEFORE _PAGE_;
LINE @7 "BP3304-002" @180"1_VITALS.SAS";
LINE "";
LINE "";
LINE "SUBJECT VITALS SIGNS INFORMATION - LISTING";
LINE "";
ENDCOMP;
RUN;

ods rtf close;
