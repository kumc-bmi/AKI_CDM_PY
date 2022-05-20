/*Change the range of date shifting according to the requirement of your organization

  export the following tables after data shifting :
 - DEID_AKI_onsets
 - consort_diagram_AD
 - consort_diagram_BC
 - DEID_AKI_DEMO
 - DEID_AKI_VITAL
 - DEID_AKI_VITAL_OLD 
 - DEID_AKI_PX
 - DEID_AKI_DX
 - DEID_AKI_LAB
 - DEID_AKI_PMED 
 - DEID_AKI_AMED
 - DEID_AKI_DMED
 - DEID_AKI_DEMO_DEATH
 - DEID_AKI_DX_CURRENT
 - DEID_AKI_LAB_SCR 
*/


-- Create a unique date shift for each paitient
create table dateshift_table as
with unique_id as(
select
unique("PATID")
from AKI_onsets
)
select 
"PATID"
,round(dbms_random.value(-364.99999999999,-0.5),0) date_shift -- Change your range here
from unique_id;

create table DEID_AKI_ONSETS as
select
    aki."PATID" , 
	aki."ENCOUNTERID" , 
	aki."ADMIT_DATE" +pd.date_shift "ADMIT_DATE",
	aki."ADMIT_YEAR" , 
	aki."DISCHARGE_DATE" +pd.date_shift "DISCHARGE_DATE",
	aki."SERUM_CREAT_BASE" , 
	aki."NONAKI_ANCHOR" +pd.date_shift "NONAKI_ANCHOR",
	aki."NONAKI_SINCE_ADMIT" , 
	aki."NON_AKI_SCR" , 
	aki."NON_AKI_INC" , 
	aki."AKI1_ONSET" +pd.date_shift "AKI1_ONSET",
	aki."AKI1_SINCE_ADMIT" , 
	aki."AKI1_SCR" , 
	aki."AKI1_INC" , 
	aki."AKI2_ONSET" +pd.date_shift "AKI2_ONSET",
	aki."AKI2_SINCE_ADMIT" , 
	aki."AKI2_SCR" , 
	aki."AKI2_INC" , 
	aki."BCCOVID" , 
	aki."AKI3_ONSET" +pd.date_shift "AKI3_ONSET",
	aki."AKI3_SINCE_ADMIT" , 
	aki."AKI3_SCR" , 
	aki."AKI3_INC" 
from AKI_onsets aki
join dateshift_table pd on pd.patid = aki.patid;

create table DEID_AKI_DEMO_DEATH as
select "ONSETS_ENCOUNTERID", 
	aki."PATID" , 
	aki."DEATH_DATE" +pd.date_shift "DEATH_DATE", 
	aki."DEATH_DATE_IMPUTE" , 
	aki."DEATH_SOURCE" , 
	aki."DEATH_MATCH_CONFIDENCE" , 
	aki."DDAYS_SINCE_ENC" 
from AKI_DEMO_DEATH aki
join dateshift_table pd on pd.patid = aki.patid;

create table DEID_AKI_DEMO as
select 
    aki."ONSETS_ENCOUNTERID" , 
	aki."AGE" , 
	aki."PATID", 
	aki."BIRTH_DATE" +pd.date_shift "BIRTH_DATE",
	aki."BIRTH_TIME" , 
	aki."SEX", 
	aki."SEXUAL_ORIENTATION" , 
	aki."GENDER_IDENTITY" , 
	aki."HISPANIC" , 
	aki."BIOBANK_FLAG" , 
	aki."RACE" , 
	aki."PAT_PREF_LANGUAGE_SPOKEN" , 
	aki."RAW_SEX" , 
	aki."RAW_SEXUAL_ORIENTATION" , 
	aki."RAW_GENDER_IDENTITY" , 
	aki."RAW_HISPANIC" , 
	aki."RAW_RACE" , 
	aki."RAW_PAT_PREF_LANGUAGE_SPOKEN" , 
	aki."DEATH_DATE" +pd.date_shift "DEATH_DATE", 
	aki."DDAYS_SINCE_ENC" , 
	aki."DEATH_DATE_IMPUTE" , 
	aki."DEATH_SOURCE" 
from AKI_DEMO aki
join dateshift_table pd on pd.patid = aki.patid;

create table DEID_AKI_PX as
select 
    aki."ONSETS_ENCOUNTERID" ,
	aki."PROCEDURESID",
	aki."PATID" , 
	aki."ENCOUNTERID", 
	aki."ENC_TYPE", 
	aki."ADMIT_DATE" +pd.date_shift "ADMIT_DATE", 
	aki."PROVIDERID" , 
	aki."PX_DATE" +pd.date_shift "PX_DATE", 
	aki."PX" , 
	aki."PX_TYPE" , 
	aki."PX_SOURCE" , 
	aki."PPX" , 
	aki."RAW_PX" , 
	aki."RAW_PX_TYPE" , 
	aki."RAW_PPX" , 
	aki."DAYS_SINCE_ADMIT" 
from AKI_PX aki
join dateshift_table pd on pd.patid = aki.patid;

create table DEID_AKI_VITAL as
select 
    aki."ONSETS_ENCOUNTERID" , 
	aki."OBSCLINID" , 
	aki."PATID", 
	aki."ENCOUNTERID" , 
	aki."OBSCLIN_PROVIDERID" , 
	aki."OBSCLIN_START_DATE" +pd.date_shift "OBSCLIN_START_DATE", 
	aki."OBSCLIN_START_TIME" , 
	aki."OBSCLIN_STOP_DATE" +pd.date_shift "OBSCLIN_STOP_DATE", 
	aki."OBSCLIN_STOP_TIME" , 
	aki."OBSCLIN_TYPE" , 
	aki."OBSCLIN_CODE" , 
	aki."OBSCLIN_RESULT_QUAL" , 
	aki."OBSCLIN_RESULT_TEXT" , 
	aki."OBSCLIN_RESULT_SNOMED" , 
	aki."OBSCLIN_RESULT_NUM" , 
	aki."OBSCLIN_RESULT_MODIFIER" , 
	aki."OBSCLIN_RESULT_UNIT" , 
	aki."OBSCLIN_ABN_IND" , 
	aki."RAW_OBSCLIN_NAME", 
	aki."RAW_OBSCLIN_CODE" , 
	aki."RAW_OBSCLIN_TYPE" , 
	aki."RAW_OBSCLIN_RESULT" , 
	aki."RAW_OBSCLIN_MODIFIER" , 
	aki."RAW_OBSCLIN_UNIT" , 
	aki."OBSCLIN_SOURCE" , 
	aki."DAYS_SINCE_ADMIT" 
from AKI_VITAL aki
join dateshift_table pd on pd.patid = aki.patid;

create table DEID_AKI_DX as
select 
    aki."ONSETS_ENCOUNTERID" , 
	aki."DIAGNOSISID" , 
	aki."PATID", 
	aki."ENCOUNTERID" , 
	aki."ENC_TYPE" , 
	aki."ADMIT_DATE" +pd.date_shift "ADMIT_DATE", 
	aki."DX_DATE" +pd.date_shift "DX_DATE", 
	aki."PROVIDERID" , 
	aki."DX" , 
	aki."DX_TYPE" , 
	aki."DX_SOURCE" , 
	aki."DX_ORIGIN" , 
	aki."PDX" , 
	aki."DX_POA" , 
	aki."RAW_DX" , 
	aki."RAW_DX_TYPE" , 
	aki."RAW_DX_SOURCE" , 
	aki."RAW_ORIGDX" , 
	aki."RAW_PDX" , 
	aki."RAW_DX_POA" , 
	aki."DAYS_SINCE_ADMIT" 
from AKI_DX aki
join dateshift_table pd on pd.patid = aki.patid;

create table DEID_AKI_LAB as
select 
    aki."ONSETS_ENCOUNTERID" , 
	aki."LAB_RESULT_CM_ID" , 
	aki."PATID" , 
	aki."ENCOUNTERID" , 
	aki."SPECIMEN_SOURCE" , 
	aki."LAB_LOINC" , 
	aki."PRIORITY" , 
	aki."RESULT_LOC", 
	aki."LAB_PX" , 
	aki."LAB_PX_TYPE" , 
	aki."LAB_ORDER_DATE" +pd.date_shift "LAB_ORDER_DATE", 
	aki."SPECIMEN_DATE" +pd.date_shift "SPECIMEN_DATE", 
	aki."SPECIMEN_TIME" , 
	aki."RESULT_DATE" +pd.date_shift "RESULT_DATE", 
	aki."RESULT_TIME" , 
	aki."RESULT_QUAL" , 
	aki."RESULT_SNOMED" , 
	aki."RESULT_NUM" , 
	aki."RESULT_MODIFIER" , 
	aki."RESULT_UNIT" , 
	aki."NORM_RANGE_LOW" , 
	aki."NORM_MODIFIER_LOW" , 
	aki."NORM_RANGE_HIGH", 
	aki."NORM_MODIFIER_HIGH" , 
	aki."ABN_IND" , 
	aki."RAW_LAB_NAME" , 
	aki."RAW_LAB_CODE" , 
	aki."RAW_PANEL" , 
	aki."RAW_RESULT" , 
	aki."RAW_UNIT" , 
	aki."RAW_ORDER_DEPT" , 
	aki."RAW_FACILITY_CODE" , 
	aki."LAB_LOINC_SOURCE" , 
	aki."LAB_RESULT_SOURCE" , 
	aki."DAYS_SINCE_ADMIT" 
from AKI_LAB aki
join dateshift_table pd on pd.patid = aki.patid;


create table DEID_AKI_PMED as
select 
    aki."ONSETS_ENCOUNTERID" , 
	aki."PRESCRIBINGID" , 
	aki."PATID" , 
	aki."ENCOUNTERID" , 
	aki."RX_PROVIDERID" , 
	aki."RX_ORDER_DATE" +pd.date_shift "RX_ORDER_DATE", 
	aki."RX_ORDER_TIME" , 
	aki."RX_START_DATE" +pd.date_shift "RX_START_DATE", 
	aki."RX_END_DATE" +pd.date_shift "RX_END_DATE", 
	aki."RX_DOSE_ORDERED" , 
	aki."RX_DOSE_ORDERED_UNIT" , 
	aki."RX_QUANTITY" , 
	aki."RX_DOSE_FORM" , 
	aki."RX_REFILLS" , 
	aki."RX_DAYS_SUPPLY" , 
	aki."RX_FREQUENCY" , 
	aki."RX_PRN_FLAG" , 
	aki."RX_ROUTE" , 
	aki."RX_BASIS" , 
	aki."RXNORM_CUI" , 
	aki."RX_SOURCE", 
	aki."RX_DISPENSE_AS_WRITTEN" , 
	aki."RAW_RX_MED_NAME" , 
	aki."RAW_RX_FREQUENCY" , 
	aki."RAW_RXNORM_CUI" , 
	aki."RAW_RX_QUANTITY", 
	aki."RAW_RX_NDC" , 
	aki."RAW_RX_DOSE_ORDERED" , 
	aki."RAW_RX_DOSE_ORDERED_UNIT", 
	aki."RAW_RX_ROUTE" , 
	aki."RAW_RX_REFILLS" , 
	aki."RX_END_DATE_MOD" +pd.date_shift "RX_END_DATE_MOD", 
	aki."RX_QUANTITY_DAILY" , 
	aki."DAYS_SINCE_ADMIT" 
from AKI_PMED aki
join dateshift_table pd on pd.patid = aki.patid;



create table DEID_AKI_AMED as
select 
    aki."ONSETS_ENCOUNTERID" , 
	aki."MEDADMINID", 
	aki."PATID" , 
	aki."ENCOUNTERID" , 
	aki."PRESCRIBINGID" , 
	aki."MEDADMIN_PROVIDERID", 
	aki."MEDADMIN_START_DATE" +pd.date_shift "MEDADMIN_START_DATE", 
	aki."MEDADMIN_START_TIME" , 
	aki."MEDADMIN_STOP_DATE" +pd.date_shift "MEDADMIN_STOP_DATE", 
	aki."MEDADMIN_STOP_TIME" , 
	aki."MEDADMIN_TYPE" , 
	aki."MEDADMIN_CODE" , 
	aki."MEDADMIN_DOSE_ADMIN", 
	aki."MEDADMIN_DOSE_ADMIN_UNIT" , 
	aki."MEDADMIN_ROUTE", 
	aki."MEDADMIN_SOURCE", 
	aki."RAW_MEDADMIN_MED_NAME" , 
	aki."RAW_MEDADMIN_CODE" , 
	aki."RAW_MEDADMIN_DOSE_ADMIN" , 
	aki."RAW_MEDADMIN_DOSE_ADMIN_UNIT" , 
	aki."RAW_MEDADMIN_ROUTE" , 
	aki."DAYS_SINCE_ADMIT" 
from AKI_AMED aki
join dateshift_table pd on pd.patid = aki.patid;

create table DEID_AKI_DMED as
select 
    aki."ONSETS_ENCOUNTERID" ,
	aki."DISPENSINGID" , 
	aki."PATID" , 
	aki."PRESCRIBINGID" , 
	aki."DISPENSE_DATE" +pd.date_shift "DISPENSE_DATE", 
	aki."NDC", 
	aki."DISPENSE_SUP" , 
	aki."DISPENSE_AMT" , 
	aki."DISPENSE_DOSE_DISP" , 
	aki."DISPENSE_DOSE_DISP_UNIT", 
	aki."DISPENSE_ROUTE" , 
	aki."RAW_NDC" , 
	aki."RAW_DISPENSE_DOSE_DISP" , 
	aki."RAW_DISPENSE_DOSE_DISP_UNIT" , 
	aki."RAW_DISPENSE_ROUTE" , 
	aki."DISPENSE_SOURCE" , 
	aki."DAYS_SINCE_ADMIT" 
from AKI_DMED aki
join dateshift_table pd on pd.patid = aki.patid;


create table DEID_AKI_DX_CURRENT as
select 
    aki."ONSETS_ENCOUNTERID" , 
	aki."DIAGNOSISID" , 
	aki."PATID" , 
	aki."ENCOUNTERID" , 
	aki."ENC_TYPE" , 
	aki."ADMIT_DATE" +pd.date_shift "ADMIT_DATE", 
	aki."DX_DATE" +pd.date_shift "DX_DATE", 
	aki."PROVIDERID" , 
	aki."DX" , 
	aki."DX_TYPE" , 
	aki."DX_SOURCE" , 
	aki."DX_ORIGIN" , 
	aki."PDX" , 
	aki."DX_POA" , 
	aki."RAW_DX" , 
	aki."RAW_DX_TYPE" , 
	aki."RAW_DX_SOURCE" , 
	aki."RAW_ORIGDX", 
	aki."RAW_PDX" , 
	aki."RAW_DX_POA" , 
	aki."DAYS_SINCE_ADMIT" 
from AKI_DX_CURRENT aki
join dateshift_table pd on pd.patid = aki.patid;

create table DEID_AKI_LAB_SCR as
select 
    aki."ONSETS_ENCOUNTERID" , 
	aki."LAB_RESULT_CM_ID" , 
	aki."PATID" , 
	aki."ENCOUNTERID", 
	aki."SPECIMEN_SOURCE" , 
	aki."LAB_LOINC" , 
	aki."PRIORITY" , 
	aki."RESULT_LOC" , 
	aki."LAB_PX" , 
	aki."LAB_PX_TYPE" , 
	aki."LAB_ORDER_DATE" +pd.date_shift "LAB_ORDER_DATE", 
	aki."SPECIMEN_DATE" +pd.date_shift "SPECIMEN_DATE", 
	aki."SPECIMEN_TIME" , 
	aki."RESULT_DATE" +pd.date_shift "RESULT_DATE", 
	aki."RESULT_TIME" , 
	aki."RESULT_QUAL" , 
	aki."RESULT_SNOMED" , 
	aki."RESULT_NUM" , 
	aki."RESULT_MODIFIER" , 
	aki."RESULT_UNIT" , 
	aki."NORM_RANGE_LOW" , 
	aki."NORM_MODIFIER_LOW" , 
	aki."NORM_RANGE_HIGH" , 
	aki."NORM_MODIFIER_HIGH" , 
	aki."ABN_IND" , 
	aki."RAW_LAB_NAME", 
	aki."RAW_LAB_CODE" , 
	aki."RAW_PANEL" , 
	aki."RAW_RESULT" , 
	aki."RAW_UNIT" , 
	aki."RAW_ORDER_DEPT" , 
	aki."RAW_FACILITY_CODE" , 
	aki."LAB_LOINC_SOURCE" , 
	aki."LAB_RESULT_SOURCE" , 
	aki."DAYS_SINCE_ADMIT" 
from AKI_LAB_SCR aki
join dateshift_table pd on pd.patid = aki.patid;

create table DEID_AKI_VITAL_OLD as
select 
    aki."ONSETS_ENCOUNTERID", 
	aki."VITALID" , 
	aki."PATID" , 
	aki."ENCOUNTERID" , 
	aki."MEASURE_DATE" +pd.date_shift "MEASURE_DATE", 
	aki."MEASURE_TIME", 
	aki."VITAL_SOURCE" ,
	aki."HT" ,
	aki."WT" ,
	aki."DIASTOLIC" ,
	aki."SYSTOLIC",
	aki."ORIGINAL_BMI" ,
	aki."BP_POSITION" ,
	aki."SMOKING" ,
	aki."TOBACCO" ,
	aki."TOBACCO_TYPE" ,
	aki."RAW_VITAL_SOURCE" ,
	aki."RAW_HT" ,
	aki."RAW_WT" ,
	aki."RAW_DIASTOLIC" , 
	aki."RAW_SYSTOLIC" ,
	aki."RAW_BP_POSITION" ,
	aki."RAW_SMOKING" ,
	aki."RAW_TOBACCO" ,
	aki."RAW_TOBACCO_TYPE" ,
	aki."DAYS_SINCE_ADMIT" 
from AKI_VITAL_OLD aki
join dateshift_table pd on pd.patid = aki.patid;
