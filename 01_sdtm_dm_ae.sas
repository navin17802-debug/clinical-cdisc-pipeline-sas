/*******************************************************************************
* Program Name : 01_sdtm_dm_ae.sas
* Purpose      : Generate Mock Raw Clinical Data and Map to SDTM (DM & AE)
* Standards    : CDISC SDTMIG v3.4
*******************************************************************************/

/*=============================================================================
  1. CREATE MOCK RAW CLINICAL DATA (eCRF Extracts)
=============================================================================*/
data raw_demog;
    input center subjid $ age sex_raw $ race_raw $ arm_cd $ rfstdt :date9. rfendt :date9.;
    format rfstdt rfendt date9.;
    datalines;
101 001 45 Male Asian DRUG_A 01JAN2026 30MAR2026
101 002 62 Female White PLACEBO 05JAN2026 04APR2026
102 003 54 Male Asian DRUG_A 10JAN2026 15FEB2026
102 004 38 Female Black PLACEBO 12JAN2026 12APR2026
103 005 70 Male Asian DRUG_A 15JAN2026 15APR2026
103 006 29 Female White DRUG_A 20JAN2026 20APR2026
;
run;

data raw_ae;
    input center subjid $ aeseq aeterm $15. aedecod $15. aesoc $25. aestdt :date9. aeenddt :date9. aeser $ aesev $;
    format aestdt aeenddt date9.;
    datalines;
101 001 1 Headache        Headache        Nervous system disorders  10JAN2026 12JAN2026 N MILD
101 001 2 Nausea          Nausea          Gastrointestinal disorder 02JAN2026 05JAN2026 N MODERATE
101 002 1 Dizziness       Dizziness       Nervous system disorders  01JAN2026 03JAN2026 N MILD
102 003 1 Elevated ALT    ALT increased   Investigations            25JAN2026 10FEB2026 Y SEVERE
103 005 1 Fatigue         Fatigue         General disorders         01FEB2026 05FEB2026 N MILD
103 006 1 Skin Rash       Rash            Skin disorders            18JAN2026 19JAN2026 N MILD
;
run;

/*=============================================================================
  2. DERIVE SDTM DEMOGRAPHICS DOMAIN (SDTM.DM)
=============================================================================*/
data sdtm_dm(label="Demographics");
    length STUDYID $10 DOMAIN $2 USUBJID $20 SUBJID $5 SITEID $3 
           RFSTDTC RFENDTC $10 AGE 8 AGEU $5 SEX $2 RACE $30 ARMCD $8 ARM $20 COUNTRY $3;
    set raw_demog;

    STUDYID = "NN-2026";
    DOMAIN  = "DM";
    SITEID  = put(center, z3.);
    USUBJID = catx("-", STUDYID, SITEID, SUBJID);
    
    /* ISO 8601 Date Conversion */
    RFSTDTC = put(rfstdt, is8601da.);
    RFENDTC = put(rfendt, is8601da.);
    
    AGE  = age;
    AGEU = "YEARS";

    /* Controlled Terminology Mapping */
    if upcase(sex_raw) = "MALE" then SEX = "M";
    else if upcase(sex_raw) = "FEMALE" then SEX = "F";

    RACE = upcase(race_raw);
    ARMCD = arm_cd;

    if ARMCD = "DRUG_A" then ARM = "Active Drug A 50mg";
    else if ARMCD = "PLACEBO" then ARM = "Placebo";

    COUNTRY = "IND";

    keep STUDYID DOMAIN USUBJID SUBJID SITEID RFSTDTC RFENDTC AGE AGEU SEX RACE ARMCD ARM COUNTRY;
run;

proc sort data=sdtm_dm; by USUBJID; run;

/*=============================================================================
  3. DERIVE SDTM ADVERSE EVENTS DOMAIN (SDTM.AE)
=============================================================================*/
data sdtm_ae(label="Adverse Events");
    length STUDYID $10 DOMAIN $2 USUBJID $20 AESEQ 8 AETERM AEDECOD $50 AESOC $50
           AESEV $10 AESER $2 AESTDTC AEENDTC $10;
    set raw_ae;

    STUDYID = "NN-2026";
    DOMAIN  = "AE";
    USUBJID = catx("-", STUDYID, put(center, z3.), subjid);

    AETERM  = upcase(aeterm);
    AEDECOD = upcase(aedecod);
    AESOC   = upcase(aesoc);
    AESEV   = upcase(aesev);
    AESER   = upcase(aeser);

    AESTDTC = put(aestdt, is8601da.);
    AEENDTC = put(aeenddt, is8601da.);

    keep STUDYID DOMAIN USUBJID AESEQ AETERM AEDECOD AESOC AESEV AESER AESTDTC AEENDTC;
run;

proc sort data=sdtm_ae; by USUBJID AESEQ; run;
