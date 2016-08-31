data work1;
 var1 = 'value1';
 var2 = 'value2';
 call symput('mvar1','newvalue'); /*Example 1*/
 call symput('mvar2',var1); /*Example 2*/
 call symput(var1,var2); /*Example 3*/
 call symput(var1,'newvalue'); /*Example 4*/
run; 

/* ------------------------------------------------
 Call SYMPUT Example 1.
 Create a data dependent title.
-------------------------------------------------*/
proc means data=SASUSERS.DEMOG noprint mean;
 var age;
 output out=average mean=avage;
run;
data _null_;
 set average;
 call symput('meanage',left(put(avage,2.)));
run;
proc print data =SASUSERS.DEMOG;
 title "Average age of trial sample is &meanage"; 
 RUN;

/* ------------------------------------------------------
 Call SYMPUT Example 2.
 Triggering a PROC based on a data step value
------------------------------------------------------*/
options mprint;
%macro archive;
 %if &append ^=0 %then %do;
 proc append base=arch data=oldrecs;
 run;
 %end;
 %else %put No archiving to be done;
%mend archive;
data new;
 input @1 date date7. reading1 reading2;
 cards;
01sep91 102 150
19aug91 98 143
05MAY90 98 142
07MAY90 90 140
21aug91 88 135
11MAY90 84 134
run;
data oldrecs;
 set new;
 if today() -date > 30 then output oldrecs;
run;
data _null_;
 if 0 then set oldrecs nobs=numobs;
 call symput('append',left(numobs));
 stop;
run;
%archive 

/* ----------------------------------------------------
 Call SYMPUT Example 3.
 Splitting a data set.
------------------------------------------------------*/
%macro split(inputds,byvar,prefix);
 proc freq data=&inputds;
 tables &byvar / noprint out=numbys(keep=&byvar);
 run;
 data _null_;
 set numbys end=eof;
 call symput('mvar'||left(put(_n_,2.)),
 left(put(&byvar,3.)));
 if eof then call symput('numobs',put(_n_,2.));
 run;
 data
 %do i = 1 %to &numobs;
 &prefix&&mvar&i
 %end;
 ;
 set &inputds;
 %let else=;
 %do i= 1 %to &numobs;
 &else if &byvar=&&mvar&i then
 output &prefix&&mvar&i;
 %let else=else;
 %end;
run;
%mend split;
%split(chap1.glow_11m,age,ds) 

proc sql;
 select avg(expenses)
 into :mvar1
 from sasuser.expenses;
quit;
title "Average expenses of the sample is &mvar1"; 

*Example 5: Selecting all the variables;
proc sql noprint;
select name into : vars separated by " "
from dictionary.columns
where LIBNAME = upcase("work")
and MEMNAME = upcase("ds89");
quit;
%put variables = &vars.;

*COUNTING OBSERVATIONS;
%macro obscnt(dsn); 
%local nobs;
%let nobs=.;
%* Open the data set of interest;
%let dsnid = %sysfunc(open(&dsn));
%* If the open was successful get the; A and then calls %OBSCNT to write the
%* number of observations and CLOSE;
%* &dsn;
%if &dsnid %then %do; 
 %let nobs =
 %sysfunc(attrn(&dsnid,nobs)); 
 %let rc =%sysfunc(close(&dsnid)); 
%end;
%else %do; 
 %put Unable to open &dsn - ;
 %put %sysfunc(sysmsg());
%end;
%* Return the number of observations;
&nobs 
%mend obscnt;

data a;
do i = 1 to 10;
 x=i**i;
 output;
end;
run;
%put number of obs is %obscnt(a);
*SAS Macro for Normality;

%macro normal(input=, vars=, output=);

ods output TestsForNormality = Normal;
proc univariate data = &input normal;
var &vars;
run;
ods output close;

data &output;
set Normal ( where = (Test = 'Shapiro-Wilk'));
if pValue > 0.05 then Status ="Normal";
else Status = "Non-normal";
drop TestLab Stat pType pSign; 
run;
%mend;

%normal(input=ds80, vars=HEIGHT WEIGHT, output=Normality);

%macro exist(dsn);
%global exist;
%if %sysfunc(exist(&dsn))  %then
 %let exist=YES;
%else %let exist=NO; 
%mend exist; 

%exist(ds63);


%macro rename1(oldvarlist, newvarlist);
  %let k=1;
  %let old = %scan(&oldvarlist, &k);
  %let new = %scan(&newvarlist, &k);
     %do %while(("&old" NE "") & ("&new" NE ""));
      rename &old = &new;
	  %let k = %eval(&k + 1);
      %let old = %scan(&oldvarlist, &k);
      %let new = %scan(&newvarlist, &k);
  %end;
%mend;

data faminc;
  input famid faminc1-faminc12 ;
cards;
1 3281 3413 3114 2500 2700 3500 3114 -999 3514 1282 2434 2818
2 4042 3084 3108 3150 -999 3100 1531 2914 3819 4124 4274 4471
3 6015 6123 6113 -999 6100 6200 6186 6132 -999 4231 6039 6215
;
run;

data a ;
  set faminc;
  %rename1(faminc1 faminc2, a b);
run;
proc print data = a heading= h noobs;
run;
