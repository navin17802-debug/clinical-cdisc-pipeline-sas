/*******************************************************************************
* Program Name : 03_tlf_outputs.sas
* Purpose      : Generate Regulatory Table 14.1.1 and Listing 16.2.7
*******************************************************************************/

/*=============================================================================
  1. TABLE 14.1.1: DEMOGRAPHICS AND BASELINE CHARACTERISTICS (SAFETY POP)
=============================================================================*/
/* Calculate continuous statistics for Age */
proc means data=adam_adsl(where=(SAFFL="Y")) noprint;
    class TRT01AN;
    var AGE;
    output out=age_stats n=n mean=mean std=std min=min max=max;
run;

data age_formatted;
    length stat_label $30 col1 col2 $25;
    set age_stats(where=(not missing(TRT01AN)));
    
    n_c      = strip(put(n, 4.));
    mean_sd  = catx(" ", put(mean, 5.1), cats("(", strip(put(std, 5.2)), ")"));
    min_max  = catx(", ", strip(put(min, 4.)), strip(put(max, 4.)));
run;

proc transpose data=age_formatted out=age_trans prefix=TRT_;
    id TRT01AN;
    var n_c mean_sd min_max;
run;

data final_table;
    length Category $35 TRT_1 TRT_2 $25;
    set age_trans;
    if _NAME_ = "n_c"     then Category = "Age (Years) - n";
    if _NAME_ = "mean_sd" then Category = "Age (Years) - Mean (SD)";
    if _NAME_ = "min_max" then Category = "Age (Years) - Min, Max";
    keep Category TRT_1 TRT_2;
run;

title1 "Protocol: NN-2026";
title2 "Table 14.1.1: Summary of Baseline Age Characteristics (Safety Population)";
footnote1 "Note: Values represent N, Mean (Standard Deviation), and Minimum, Maximum.";

proc report data=final_table nowd headline headskip split="|";
    column Category TRT_1 TRT_2;
    define Category / display "Parameter / Statistic" width=35;
    define TRT_1    / display "Active Drug A 50mg" width=20 center;
    define TRT_2    / display "Placebo" width=20 center;
run;
title; footnote;

/*=============================================================================
  2. LISTING 16.2.7: LISTING OF TREATMENT-EMERGENT ADVERSE EVENTS (TRTEMFL='Y')
=============================================================================*/
title1 "Protocol: NN-2026";
title2 "Listing 16.2.7: Treatment-Emergent Adverse Events (Safety Population)";
footnote1 "Note: Only events where TRTEMFL = 'Y' (onset on or after first dose date) are displayed.";

proc report data=adam_adae(where=(SAFFL="Y" and TRTEMFL="Y")) nowd headline headskip split="|";
    column USUBJID TRT01A AEDECOD AESOC AESEV AESER ASTDT ASTPTDY TRTEMFL;
    define USUBJID / order "Unique Subject ID" width=18;
    define TRT01A  / display "Treatment Arm" width=20;
    define AEDECOD / display "Preferred Term" width=18;
    define AESOC   / display "System Organ Class" width=26;
    define AESEV   / display "Severity" width=10 center;
    define AESER   / display "Serious" width=8 center;
    define ASTDT   / display "Start Date" width=12 center;
    define ASTPTDY / display "Study Day" width=10 center;
    define TRTEMFL / display "TEAE|Flag" width=6 center;
run;
title; footnote;
