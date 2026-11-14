/*******************************************************************************
* Program Name : 02_adam_adsl_adae.sas
* Purpose      : Derive ADaM Datasets (ADSL and ADAE) from SDTM Domains
* Standards    : CDISC ADaMIG v1.3
*******************************************************************************/

/*=============================================================================
  1. DERIVE SUBJECT-LEVEL ANALYSIS DATASET (ADaM.ADSL)
=============================================================================*/
data adam_adsl(label="Subject-Level Analysis Dataset");
    length STUDYID $10 USUBJID $20 SUBJID $5 SITEID $3 TRT01P TRT01A $20 
           TRT01PN TRT01AN 8 TRTSDT TRTEDT 8 AGEGR1 $10 SAFFL ITTFL $1;
    set sdtm_dm;

    /* Treatment Variables */
    TRT01P = ARM;
    TRT01A = ARM;
    if ARMCD = "DRUG_A" then do; TRT01PN = 1; TRT01AN = 1; end;
    else if ARMCD = "PLACEBO" then do; TRT01PN = 2; TRT01AN = 2; end;

    /* Numeric Treatment Dates from ISO 8601 */
    TRTSDT = input(RFSTDTC, yymmdd10.);
    TRTEDT = input(RFENDTC, yymmdd10.);
    format TRTSDT TRTEDT date9.;

    /* Age Group Categorization */
    if AGE < 65 then AGEGR1 = "<65";
    else if AGE >= 65 then AGEGR1 = ">=65";

    /* Population Flags */
    ITTFL = "Y";
    if not missing(TRTSDT) then SAFFL = "Y";
    else SAFFL = "N";
run;

proc sort data=adam_adsl; by USUBJID; run;

/*=============================================================================
  2. DERIVE ADVERSE EVENT ANALYSIS DATASET (ADaM.ADAE)
=============================================================================*/
data adam_adae(label="Adverse Events Analysis Dataset");
    merge sdtm_ae(in=a) 
          adam_adsl(in=b keep=USUBJID TRT01A TRT01AN TRTSDT TRTEDT SAFFL AGE SEX RACE);
    by USUBJID;
    if a;

    /* Convert ISO Dates to Numeric Analysis Dates */
    ASTDT = input(AESTDTC, yymmdd10.);
    AENDT = input(AEENDTC, yymmdd10.);
    format ASTDT AENDT date9.;

    /* Calculate Relative Study Day (ADY) */
    if ASTDT >= TRTSDT then ASTPTDY = ASTDT - TRTSDT + 1;
    else ASTPTDY = ASTDT - TRTSDT;

    /* Derive Treatment-Emergent Flag (TRTEMFL)
       Rule: AE is treatment-emergent if it starts on or after first dose date */
    length TRTEMFL $1;
    if not missing(ASTDT) and not missing(TRTSDT) then do;
        if ASTDT >= TRTSDT then TRTEMFL = "Y";
        else TRTEMFL = "N"; /* Pre-treatment AE */
    end;
run;

proc sort data=adam_adae; by USUBJID AESEQ; run;
