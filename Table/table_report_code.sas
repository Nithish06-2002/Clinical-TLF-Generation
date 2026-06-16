/*================================================================================
  CLINICAL SAS PROGRAM FINAL CORRECTED VERSION v3
================================================================================*/


/*--------------------------------------------------------------------------------
  STEP 0  Library and one-time import
--------------------------------------------------------------------------------*/

libname Table "/home/u64252598/SAS/New Folder";

proc import
  datafile = "/home/u64252598/SAS/New Folder/ADSL.xlsx"
  out      = Table.ADAM
  dbms     = xlsx
  replace;
  getnames = yes;
run;

data adam_raw;
  set Table.adam;
run;


/*--------------------------------------------------------------------------------
  STEP 1  Encode categorical variables into numeric (_N suffix)
--------------------------------------------------------------------------------*/

data adam_encoded;
  set adam_raw;

  if      upcase(strip(TRT01A))          = "BP3304"                                    then TRT01A_N = 1;
  else if upcase(strip(TRT01A))          = "PLACEBO"                                   then TRT01A_N = 0;

  if      upcase(strip(SEX))             = "MALE"                                      then SEX_N = 1;
  else if upcase(strip(SEX))             = "FEMALE"                                    then SEX_N = 2;

  if      upcase(strip(RACE))            = "WHITE"                                     then RACE_N = 1;
  else if upcase(strip(RACE))            = "BLACK OR AFRICAN AMERICAN"                 then RACE_N = 2;
  else if upcase(strip(RACE))            = "ASIAN"                                     then RACE_N = 3;
  else if upcase(strip(RACE))            = "AMERICAN INDIAN OR ALASKA NATIVE"          then RACE_N = 4;
  else if upcase(strip(RACE))            = "NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER" then RACE_N = 5;
  else if upcase(strip(RACE))            = "OTHER"                                     then RACE_N = 6;

  if      upcase(strip(ETHNICITY))       = "HISPANIC OR LATINO"                        then ETHNICITY_N = 1;
  else if upcase(strip(ETHNICITY))       = "NOT HISPANIC OR LATINO"                    then ETHNICITY_N = 2;

  if      upcase(strip(ALCOHOL_HISTORY)) = "CURRENTLY CONSUMES"                        then ALCOHOL_N = 1;
  else if upcase(strip(ALCOHOL_HISTORY)) = "PREVIOUSLY CONSUMED"                       then ALCOHOL_N = 2;
  else if upcase(strip(ALCOHOL_HISTORY)) = "NEVER CONSUMED"                            then ALCOHOL_N = 3;

  if      upcase(strip(TOBACCO_HISTORY)) = "CURRENTLY CONSUMES"                        then TOBACCO_N = 1;
  else if upcase(strip(TOBACCO_HISTORY)) = "PREVIOUSLY CONSUMED"                       then TOBACCO_N = 2;
  else if upcase(strip(TOBACCO_HISTORY)) = "NEVER CONSUMED"                            then TOBACCO_N = 3;

  if      HTN_DURATION_YRS <= 10         then HTN_CAT = 1;
  else if HTN_DURATION_YRS >  10         then HTN_CAT = 2;

run;


/*--------------------------------------------------------------------------------
  STEP 2  Add Overall duplicate rows (TRT01A_N = 2)
--------------------------------------------------------------------------------*/

data adam_all;
  set adam_encoded; output;
  TRT01A_N = 2;     output;
run;

proc sort data=adam_all out=adam_sorted;
  by TRT01A_N;
run;

%macro rpt(indata=, outfile=, pgnum=1);

  title1 j=l "PHARMACEUTICAL COMPANY"  j=r "DATE: &sysdate9.";
  title2 j=l "BP3304-002"                   j=r "PROGRAM: DM.SAS";
  title3 j=r "&pgnum";

  ods escapechar = "^";

  ods rtf file    = "&outfile"
          style   = journal
          bodytitle;

  proc report data=&indata nowd headline headskip split="*"
    style(report) = [rules=groups frame=hsides cellspacing=0 cellpadding=2 width=100%]
    style(header) = [font_weight=bold just=center
                     borderbottomwidth=2pt borderbottomcolor=black background=white]
    style(column) = [just=center borderwidth=0];

    column (order suborder newvar tret1 tret0 tret2);

    define order    / order  noprint;
    define suborder / order  noprint;

    define newvar / display ""
      style(column) = [just=left cellwidth=3.2in];

    define tret1 / "BP3304*(N =xx)"
      style(column) = [cellwidth=1.5in];
    define tret0 / "Placebo*(N =xx)"
      style(column) = [cellwidth=1.5in];
    define tret2 / "Overall*(N=xx)"
      style(column) = [cellwidth=1.5in];

    rbreak after / skip;

    compute before _page_;
      line " ";
      line @20 "14.1.2.1  Subject Demographics and Baseline Characteristics";
      line @28 "Safety Population";
      line " ";
    endcomp;

    compute after;
      line " ";
      line @1 "Reference: Listing 16.2.4.1";
      line @1 "^{super a}  Percentages are based on the number of subjects in the population.";
      line @1 "Note:  SD = standard deviation, Min = Minimum, Max = Maximum.";
    endcomp;

    compute newvar;
     if suborder = 0 then
     call define(_col_, "style", "style=[font_weight=bold just=left]");
     else call define(_col_, "style", "style=[leftmargin=0.2in just=left]");
    endcomp;

  run;

  ods rtf close;
  title;

%mend rpt;

%macro fixlen(ds=);
  data &ds;
    length tret0 tret1 tret2 $ 50;
    set &ds;
  run;
%mend fixlen;


/*================================================================================
  TABLE 1 Demographics: Age | Gender | Ethnicity | Race
================================================================================*/

/*------ AGE ------*/

proc summary data=adam_sorted;
  by TRT01A_N;
  var age;
  output out    = age_sum
         n      = _n_
         mean   = _mean_
         std    = _std_
         median = _median_
         min    = _min_
         max    = _max_;
run;

data age_fmt;
  set age_sum;
  n      = put(_n_,       4.0);
  meansd = put(_mean_,    5.1) || " (" || put(_std_,    6.2) || ")";
  median = put(_median_,  5.1);
  minmax = put(_min_,     4.0) || ", " || put(_max_,    4.0);
  drop _: ;
run;

proc transpose data=age_fmt out=age_t prefix=tret;
  var n meansd median minmax;
  id TRT01A_N;
run;

data age_rows;
  length newvar $ 100 tret0 tret1 tret2 $ 50;
  set age_t;
  if      _NAME_ = "n"      then do; newvar = "    N";          suborder = 1; end;
  else if _NAME_ = "meansd" then do; newvar = "    Mean (SD)";  suborder = 2; end;
  else if _NAME_ = "median" then do; newvar = "    Median";     suborder = 3; end;
  else if _NAME_ = "minmax" then do; newvar = "    Min, Max";   suborder = 4; end;
  drop _NAME_;
run;

data age_hdr;
  length newvar $ 100 tret0 tret1 tret2 $ 50;
  newvar = "Age (years)";  suborder = 0;
  tret0 = ""; tret1 = ""; tret2 = "";
run;

data age_final;
  set age_hdr age_rows;
  order = 1;
run;


/*------ GENDER ------*/

proc freq data=adam_sorted noprint;
  by TRT01A_N;
  table SEX_N / out = gen_freq;
run;

data gen_fmt;
  set gen_freq;
  np = put(count, 4.0) || " (" || put(percent, 4.1) || ")";
run;

proc sort data=gen_fmt; by SEX_N; run;

proc transpose data=gen_fmt out=gen_t (drop=_NAME_) prefix=tret;
  var np;
  id TRT01A_N;
  by SEX_N;
run;

data gen_rows;
  length newvar $ 100 tret0 tret1 tret2 $ 50;
  set gen_t;
  if      SEX_N = 1 then newvar = "    Male";
  else if SEX_N = 2 then newvar = "    Female";
  suborder = 1;
run;

data gen_hdr;
  length newvar $ 100 tret0 tret1 tret2 $ 50;
  newvar = "Gender [n (%)]^{super a}";  suborder = 0;
  tret0 = ""; tret1 = ""; tret2 = "";
run;

data gender_final;
  set gen_hdr gen_rows;
  order = 2;
run;


/*------ ETHNICITY ------*/

proc freq data=adam_sorted noprint;
  by TRT01A_N;
  table ETHNICITY_N / out = eth_freq;
run;

data eth_fmt;
  set eth_freq;
  np = put(count, 4.0) || " (" || put(percent, 4.1) || ")";
run;

proc sort data=eth_fmt; by ETHNICITY_N; run;

proc transpose data=eth_fmt out=eth_t (drop=_NAME_) prefix=tret;
  var np;
  id TRT01A_N;
  by ETHNICITY_N;
run;

data eth_rows;
  length newvar $ 100 tret0 tret1 tret2 $ 50;
  set eth_t;
  if      ETHNICITY_N = 1 then newvar = "    Hispanic or Latino";
  else if ETHNICITY_N = 2 then newvar = "    Not Hispanic or Latino";
  suborder = 1;
run;

data eth_hdr;
  length newvar $ 100 tret0 tret1 tret2 $ 50;
  newvar = "Ethnicity [n (%)]^{super a}";  suborder = 0;
  tret0 = ""; tret1 = ""; tret2 = "";
run;

data ethnicity_final;
  set eth_hdr eth_rows;
  order = 3;
run;


/*------ RACE ------*/

proc freq data=adam_sorted noprint;
  by TRT01A_N;
  table RACE_N / out = race_freq;
run;

data race_fmt;
  set race_freq;
  np = put(count, 4.0) || " (" || put(percent, 4.1) || ")";
run;

proc sort data=race_fmt; by RACE_N; run;

proc transpose data=race_fmt out=race_t (drop=_NAME_) prefix=tret;
  var np;
  id TRT01A_N;
  by RACE_N;
run;

data race_rows;
  length newvar $ 100 tret0 tret1 tret2 $ 50;
  set race_t;
  if      RACE_N = 1 then newvar = "    White";
  else if RACE_N = 2 then newvar = "    Black or African American";
  else if RACE_N = 3 then newvar = "    Asian";
  else if RACE_N = 4 then newvar = "    American Indian or Alaskan Native";
  else if RACE_N = 5 then newvar = "    Native Hawaiian or Other Pacific Islander";
  else if RACE_N = 6 then newvar = "    Other";
  suborder = 1;
run;

data race_hdr;
  length newvar $ 100 tret0 tret1 tret2 $ 50;
  newvar = "Race [n (%)]^{super a}";  suborder = 0;
  tret0 = ""; tret1 = ""; tret2 = "";
run;

data race_final;
  set race_hdr race_rows;
  order = 4;
run;


/*------ STACK & REPORT TABLE 1 ------*/

data table111_data;
  length newvar $ 100 tret0 tret1 tret2 $ 50;
  set age_final gender_final ethnicity_final race_final;
  keep order suborder newvar tret0 tret1 tret2;
run;

%rpt(indata  = table111_data,
     outfile = /home/u64252598/Table_new_poj/table10_demographics.rtf,
     pgnum   = 1);


/*================================================================================
  TABLE 2 Anthropometrics: Height | Weight | BMI
================================================================================*/

%macro anthro(var=, label=, ord=, s1=, s2=, s3=, s4=, hdr=, fin=);

  proc summary data=adam_sorted;
    by TRT01A_N;
    var &var;
    output out    = &s1
           n      = _n_
           mean   = _mean_
           stddev = _std_
           median = _median_
           min    = _min_
           max    = _max_;
  run;

  data &s2;
    set &s1;
    n      = put(_n_,       4.0);
    meansd = put(_mean_,    4.1) || " (" || put(_std_,    5.2) || ")";
    median = put(_median_,  4.1);
    minmax = put(_min_,     4.0) || ", " || put(_max_,    4.0);
    drop _: ;
  run;

  proc transpose data=&s2 out=&s3 prefix=tret;
    var n meansd median minmax;
    id TRT01A_N;
  run;

  data &s4;
    length newvar $ 100 tret0 tret1 tret2 $ 50;
    set &s3;
    if      _NAME_ = "n"      then do; newvar = "    N";          suborder = 1; end;
    else if _NAME_ = "meansd" then do; newvar = "    Mean (SD)";  suborder = 2; end;
    else if _NAME_ = "median" then do; newvar = "    Median";     suborder = 3; end;
    else if _NAME_ = "minmax" then do; newvar = "    Min, Max";   suborder = 4; end;
    drop _NAME_;
  run;

  data &hdr;
    length newvar $ 100 tret0 tret1 tret2 $ 50;
    newvar = &label;  suborder = 0;
    tret0 = ""; tret1 = ""; tret2 = "";
  run;

  data &fin;
    length newvar $ 100 tret0 tret1 tret2 $ 50;
    set &hdr &s4;
    order = &ord;
  run;

%mend anthro;

%anthro(var=height_cm,
        label="Height (cm)",
        ord=1,
        s1=hgt1, s2=hgt2, s3=hgt3, s4=hgt4, hdr=hgt_hdr, fin=height_fin);

%anthro(var=weight_kg,
        label="Weight (kg)",
        ord=2,
        s1=wgt1, s2=wgt2, s3=wgt3, s4=wgt4, hdr=wgt_hdr, fin=weight_fin);

%anthro(var=BMI,
        label="Body Mass Index (kg/m^{super 2})",
        ord=3,
        s1=bmi1, s2=bmi2, s3=bmi3, s4=bmi4, hdr=bmi_hdr, fin=bmi_fin);


/*------ STACK & REPORT TABLE 2 ------*/

data table222_data;
  length newvar $ 100 tret0 tret1 tret2 $ 50;
  set height_fin weight_fin bmi_fin;
  keep order suborder newvar tret0 tret1 tret2;
run;

%rpt(indata  = table222_data,
     outfile = /home/u64252598/Table_new_poj/table20_anthropometrics.rtf,
     pgnum   = 2);


/*================================================================================
  TABLE 3 Medical History: Alcohol | Tobacco | HTN Duration
================================================================================*/

/*------ ALCOHOL HISTORY ------*/

proc freq data=adam_sorted noprint;
  by TRT01A_N;
  table ALCOHOL_N / out = ah_freq;
run;

data ah_fmt;
  set ah_freq;
  np = put(count, 4.0) || " (" || put(percent, 4.1) || ")";
run;

proc sort data=ah_fmt; by ALCOHOL_N; run;

proc transpose data=ah_fmt out=ah_t (drop=_NAME_) prefix=tret;
  var np;
  id TRT01A_N;
  by ALCOHOL_N;
run;

data ah_rows;
  length newvar $ 100 tret0 tret1 tret2 $ 50;
  set ah_t;
  if      ALCOHOL_N = 3 then do; newvar = "    Never Consumed";      suborder = 1; end;
  else if ALCOHOL_N = 2 then do; newvar = "    Previously Consumed"; suborder = 2; end;
  else if ALCOHOL_N = 1 then do; newvar = "    Currently Consumes";  suborder = 3; end;
run;

proc sort data=ah_rows; by suborder; run;

data ah_hdr;
  length newvar $ 100 tret0 tret1 tret2 $ 50;
  newvar = "Alcohol History [n (%)]^{super a}";  suborder = 0;
  tret0 = ""; tret1 = ""; tret2 = "";
run;

data ah_final;
  length newvar $ 100 tret0 tret1 tret2 $ 50;
  set ah_hdr ah_rows;
  order = 1;
run;


/*------ TOBACCO HISTORY ------*/

proc freq data=adam_sorted noprint;
  by TRT01A_N;
  table TOBACCO_N / out = th_freq;
run;

data th_fmt;
  set th_freq;
  np = put(count, 4.0) || " (" || put(percent, 4.1) || ")";
run;

proc sort data=th_fmt; by TOBACCO_N; run;

proc transpose data=th_fmt out=th_t (drop=_NAME_) prefix=tret;
  var np;
  id TRT01A_N;
  by TOBACCO_N;
run;

data th_rows;
  length newvar $ 100 tret0 tret1 tret2 $ 50;
  set th_t;
  if      TOBACCO_N = 3 then do; newvar = "    Never Consumed";      suborder = 1; end;
  else if TOBACCO_N = 2 then do; newvar = "    Previously Consumed"; suborder = 2; end;
  else if TOBACCO_N = 1 then do; newvar = "    Currently Consumes";  suborder = 3; end;
run;

proc sort data=th_rows; by suborder; run;

data th_hdr;
  length newvar $ 100 tret0 tret1 tret2 $ 50;
  newvar = "Tobacco History [n (%)]^{super a}";  suborder = 0;
  tret0 = ""; tret1 = ""; tret2 = "";
run;

data th_final;
  length newvar $ 100 tret0 tret1 tret2 $ 50;
  set th_hdr th_rows;
  order = 2;
run;


/*------ DURATION OF HYPERTENSION continuous stats ------*/

proc sort data=adam_sorted out=du_sort;
  by TRT01A_N;
run;

proc summary data=du_sort;
  var HTN_DURATION_YRS;
  by TRT01A_N;
  output out    = du_sum
         n      = _n_
         mean   = _mean_
         stddev = _std_
         median = _med_
         min    = _min_
         max    = _max_;
run;

data du_fmt;
  set du_sum;
  n      = strip(put(_n_,    5.));
  meansd = strip(put(_mean_, 5.1)) || " (" || strip(put(_std_, 5.2)) || ")";
  median = strip(put(_med_,  5.1));
  minmax = compress(put(_min_, 5.0)) || ", " || compress(put(_max_, 5.0));
  drop _: ;
run;

proc transpose data=du_fmt out=du_t prefix=tret name=rowname;
  var n meansd median minmax;
  id TRT01A_N;
run;

data du_stat_rows;
  length newvar $ 100 tret0 tret1 tret2 $ 50;
  set du_t;
  if      rowname = "n"      then do; newvar = "    N";          suborder = 1; end;
  else if rowname = "meansd" then do; newvar = "    Mean (SD)";  suborder = 2; end;
  else if rowname = "median" then do; newvar = "    Median";     suborder = 3; end;
  else if rowname = "minmax" then do; newvar = "    Min, Max";   suborder = 4; end;
  drop rowname;
run;


/*------ HTN DURATION categorical <=10 / >10 ------*/

proc freq data=adam_sorted noprint;
  by TRT01A_N;
  table HTN_CAT / out = htn_cat_freq;
run;

data htn_cat_fmt;
  set htn_cat_freq;
  np = put(count, 4.0) || " (" || put(percent, 4.1) || ")";
run;

proc sort data=htn_cat_fmt; by HTN_CAT; run;

proc transpose data=htn_cat_fmt out=htn_cat_t (drop=_NAME_) prefix=tret;
  var np;
  id TRT01A_N;
  by HTN_CAT;
run;

data htn_cat_rows;
  length newvar $ 100 tret0 tret1 tret2 $ 50;
  set htn_cat_t;
  if      HTN_CAT = 1 then do; newvar = "    ^{unicode 2264}10 years"; suborder = 5; end;
  else if HTN_CAT = 2 then do; newvar = "    >10 years";               suborder = 6; end;
  drop HTN_CAT;
run;


/*------ HTN DURATION section header and final stack ------*/

data du_hdr;
  length newvar $ 100 tret0 tret1 tret2 $ 50;
  newvar = "Duration of Hypertension (years)";  suborder = 0;
  tret0 = ""; tret1 = ""; tret2 = "";
run;

data du_final;
  length newvar $ 100 tret0 tret1 tret2 $ 50;
  set du_hdr du_stat_rows htn_cat_rows;
  order = 3;
run;


/*------ STACK & REPORT TABLE 3 ------*/

data table333_data;
  length newvar $ 100 tret0 tret1 tret2 $ 50;
  set ah_final th_final du_final;
  keep order suborder newvar tret0 tret1 tret2;
run;

%rpt(indata  = table333_data,
     outfile = /home/u64252598/Table_new_poj/table30_medhistory.rtf,
     pgnum   = 3);


/*================================================================================
  END OF PROGRAM
================================================================================*/
