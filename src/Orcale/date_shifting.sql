/*export the following tables after data shifting :
 - AKI_onsets
 - consort_diagram_AD
 - consort_diagram_BC
 - AKI_DEMO
 - AKI_VITAL
 - AKI_VITAL_OLD 
 - AKI_PX
 - AKI_DX
 - AKI_LAB
 - AKI_PMED 
 - AKI_AMED
 - AKI_DMED
 - AKI_DEMO_DEATH
 - AKI_DX_CURRENT
 - AKI_LAB_SCR 
*/


select
"PATID" , 
	"ENCOUNTERID" , 
	"ADMIT_DATE" +pd.date_shift, 
	"ADMIT_YEAR" , 
	"DISCHARGE_DATE" +pd.date_shift, 
	"SERUM_CREAT_BASE" , 
	"NONAKI_ANCHOR" +pd.date_shift, 
	"NONAKI_SINCE_ADMIT" , 
	"NON_AKI_SCR" , 
	"NON_AKI_INC" , 
	"AKI1_ONSET" +pd.date_shift, 
	"AKI1_SINCE_ADMIT" , 
	"AKI1_SCR" , 
	"AKI1_INC" , 
	"AKI2_ONSET" +pd.date_shift, 
	"AKI2_SINCE_ADMIT" , 
	"AKI2_SCR" , 
	"AKI2_INC" , 
	"BCCOVID" , 
	"AKI3_ONSET" +pd.date_shift, 
	"AKI3_SINCE_ADMIT" , 
	"AKI3_SCR" , 
	"AKI3_INC" 
from AKI_onsets aki
join nightherondata.patient_dimension pd on pd.patient_num = aki.patid;

select *
from consort_diagram_AD;

select *
from consort_diagram_BC;

select "ONSETS_ENCOUNTERID", 
	"PATID" , 
	aki."DEATH_DATE" +pd.date_shift, 
	"DEATH_DATE_IMPUTE" , 
	"DEATH_SOURCE" , 
	"DEATH_MATCH_CONFIDENCE" , 
	"DDAYS_SINCE_ENC" 
from AKI_DEMO_DEATH aki
join nightherondata.patient_dimension pd on pd.patient_num = aki.patid;


select "ONSETS_ENCOUNTERID" , 
	"AGE" , 
	"PATID", 
	aki."BIRTH_DATE" +pd.date_shift, 
	"BIRTH_TIME" , 
	"SEX", 
	"SEXUAL_ORIENTATION" , 
	"GENDER_IDENTITY" , 
	"HISPANIC" , 
	"BIOBANK_FLAG" , 
	"RACE" , 
	"PAT_PREF_LANGUAGE_SPOKEN" , 
	"RAW_SEX" , 
	"RAW_SEXUAL_ORIENTATION" , 
	"RAW_GENDER_IDENTITY" , 
	"RAW_HISPANIC" , 
	"RAW_RACE" , 
	"RAW_PAT_PREF_LANGUAGE_SPOKEN" , 
	aki."DEATH_DATE" +pd.date_shift,
	"DDAYS_SINCE_ENC" , 
	"DEATH_DATE_IMPUTE" , 
	"DEATH_SOURCE" 
from AKI_DEMO aki
join nightherondata.patient_dimension pd on pd.patient_num = aki.patid;


select "ONSETS_ENCOUNTERID" ,
	"PROCEDURESID",
	"PATID" , 
	"ENCOUNTERID", 
	"ENC_TYPE", 
	"ADMIT_DATE" +pd.date_shift, 
	"PROVIDERID" , 
	"PX_DATE" +pd.date_shift, 
	"PX" , 
	"PX_TYPE" , 
	"PX_SOURCE" , 
	"PPX" , 
	"RAW_PX" , 
	"RAW_PX_TYPE" , 
	"RAW_PPX" , 
	"DAYS_SINCE_ADMIT" 
from AKI_PX aki
join nightherondata.patient_dimension pd on pd.patient_num = aki.patid;


select "ONSETS_ENCOUNTERID" , 
	"OBSCLINID" , 
	"PATID", 
	"ENCOUNTERID" , 
	"OBSCLIN_PROVIDERID" , 
	"OBSCLIN_START_DATE" +pd.date_shift, 
	"OBSCLIN_START_TIME" , 
	"OBSCLIN_STOP_DATE" +pd.date_shift, 
	"OBSCLIN_STOP_TIME" , 
	"OBSCLIN_TYPE" , 
	"OBSCLIN_CODE" , 
	"OBSCLIN_RESULT_QUAL" , 
	"OBSCLIN_RESULT_TEXT" , 
	"OBSCLIN_RESULT_SNOMED" , 
	"OBSCLIN_RESULT_NUM" , 
	"OBSCLIN_RESULT_MODIFIER" , 
	"OBSCLIN_RESULT_UNIT" , 
	"OBSCLIN_ABN_IND" , 
	"RAW_OBSCLIN_NAME", 
	"RAW_OBSCLIN_CODE" , 
	"RAW_OBSCLIN_TYPE" , 
	"RAW_OBSCLIN_RESULT" , 
	"RAW_OBSCLIN_MODIFIER" , 
	"RAW_OBSCLIN_UNIT" , 
	"OBSCLIN_SOURCE" , 
	"DAYS_SINCE_ADMIT" 
from AKI_VITAL aki
join nightherondata.patient_dimension pd on pd.patient_num = aki.patid;


select "ONSETS_ENCOUNTERID" , 
	"DIAGNOSISID" , 
	"PATID", 
	"ENCOUNTERID" , 
	"ENC_TYPE" , 
	"ADMIT_DATE" +pd.date_shift, 
	"DX_DATE" +pd.date_shift, 
	"PROVIDERID" , 
	"DX" , 
	"DX_TYPE" , 
	"DX_SOURCE" , 
	"DX_ORIGIN" , 
	"PDX" , 
	"DX_POA" , 
	"RAW_DX" , 
	"RAW_DX_TYPE" , 
	"RAW_DX_SOURCE" , 
	"RAW_ORIGDX" , 
	"RAW_PDX" , 
	"RAW_DX_POA" , 
	"DAYS_SINCE_ADMIT" 
from AKI_DX aki
join nightherondata.patient_dimension pd on pd.patient_num = aki.patid;


select "ONSETS_ENCOUNTERID" , 
	"LAB_RESULT_CM_ID" , 
	"PATID" , 
	"ENCOUNTERID" , 
	"SPECIMEN_SOURCE" , 
	"LAB_LOINC" , 
	"PRIORITY" , 
	"RESULT_LOC", 
	"LAB_PX" , 
	"LAB_PX_TYPE" , 
	"LAB_ORDER_DATE" +pd.date_shift, 
	"SPECIMEN_DATE" +pd.date_shift, 
	"SPECIMEN_TIME" , 
	"RESULT_DATE" +pd.date_shift, 
	"RESULT_TIME" , 
	"RESULT_QUAL" , 
	"RESULT_SNOMED" , 
	"RESULT_NUM" , 
	"RESULT_MODIFIER" , 
	"RESULT_UNIT" , 
	"NORM_RANGE_LOW" , 
	"NORM_MODIFIER_LOW" , 
	"NORM_RANGE_HIGH", 
	"NORM_MODIFIER_HIGH" , 
	"ABN_IND" , 
	"RAW_LAB_NAME" , 
	"RAW_LAB_CODE" , 
	"RAW_PANEL" , 
	"RAW_RESULT" , 
	"RAW_UNIT" , 
	"RAW_ORDER_DEPT" , 
	"RAW_FACILITY_CODE" , 
	"LAB_LOINC_SOURCE" , 
	"LAB_RESULT_SOURCE" , 
	"DAYS_SINCE_ADMIT" 
from AKI_LAB aki
join nightherondata.patient_dimension pd on pd.patient_num = aki.patid;



select "ONSETS_ENCOUNTERID" , 
	"PRESCRIBINGID" , 
	"PATID" , 
	"ENCOUNTERID" , 
	"RX_PROVIDERID" , 
	"RX_ORDER_DATE" +pd.date_shift, 
	"RX_ORDER_TIME" , 
	"RX_START_DATE" +pd.date_shift, 
	"RX_END_DATE" +pd.date_shift, 
	"RX_DOSE_ORDERED" , 
	"RX_DOSE_ORDERED_UNIT" , 
	"RX_QUANTITY" , 
	"RX_DOSE_FORM" , 
	"RX_REFILLS" , 
	"RX_DAYS_SUPPLY" , 
	"RX_FREQUENCY" , 
	"RX_PRN_FLAG" , 
	"RX_ROUTE" , 
	"RX_BASIS" , 
	"RXNORM_CUI" , 
	"RX_SOURCE", 
	"RX_DISPENSE_AS_WRITTEN" , 
	"RAW_RX_MED_NAME" , 
	"RAW_RX_FREQUENCY" , 
	"RAW_RXNORM_CUI" , 
	"RAW_RX_QUANTITY", 
	"RAW_RX_NDC" , 
	"RAW_RX_DOSE_ORDERED" , 
	"RAW_RX_DOSE_ORDERED_UNIT", 
	"RAW_RX_ROUTE" , 
	"RAW_RX_REFILLS" , 
	"RX_END_DATE_MOD" +pd.date_shift, 
	"RX_QUANTITY_DAILY" , 
	"DAYS_SINCE_ADMIT" 
from AKI_PMED aki
join nightherondata.patient_dimension pd on pd.patient_num = aki.patid;


select "ONSETS_ENCOUNTERID" , 
	"MEDADMINID", 
	"PATID" , 
	"ENCOUNTERID" , 
	"PRESCRIBINGID" , 
	"MEDADMIN_PROVIDERID", 
	"MEDADMIN_START_DATE" +pd.date_shift, 
	"MEDADMIN_START_TIME" , 
	"MEDADMIN_STOP_DATE" +pd.date_shift, 
	"MEDADMIN_STOP_TIME" , 
	"MEDADMIN_TYPE" , 
	"MEDADMIN_CODE" , 
	"MEDADMIN_DOSE_ADMIN", 
	"MEDADMIN_DOSE_ADMIN_UNIT" , 
	"MEDADMIN_ROUTE", 
	"MEDADMIN_SOURCE", 
	"RAW_MEDADMIN_MED_NAME" , 
	"RAW_MEDADMIN_CODE" , 
	"RAW_MEDADMIN_DOSE_ADMIN" , 
	"RAW_MEDADMIN_DOSE_ADMIN_UNIT" , 
	"RAW_MEDADMIN_ROUTE" , 
	"DAYS_SINCE_ADMIT" 
from AKI_AMED aki
join nightherondata.patient_dimension pd on pd.patient_num = aki.patid;


select "ONSETS_ENCOUNTERID" ,
	"DISPENSINGID" , 
	"PATID" , 
	"PRESCRIBINGID" , 
	"DISPENSE_DATE" +pd.date_shift, 
	"NDC", 
	"DISPENSE_SUP" , 
	"DISPENSE_AMT" , 
	"DISPENSE_DOSE_DISP" , 
	"DISPENSE_DOSE_DISP_UNIT", 
	"DISPENSE_ROUTE" , 
	"RAW_NDC" , 
	"RAW_DISPENSE_DOSE_DISP" , 
	"RAW_DISPENSE_DOSE_DISP_UNIT" , 
	"RAW_DISPENSE_ROUTE" , 
	"DISPENSE_SOURCE" , 
	"DAYS_SINCE_ADMIT" 
from AKI_DMED aki
join nightherondata.patient_dimension pd on pd.patient_num = aki.patid;



select "ONSETS_ENCOUNTERID" , 
	"DIAGNOSISID" , 
	"PATID" , 
	"ENCOUNTERID" , 
	"ENC_TYPE" , 
	"ADMIT_DATE" +pd.date_shift, 
	"DX_DATE" +pd.date_shift, 
	"PROVIDERID" , 
	"DX" , 
	"DX_TYPE" , 
	"DX_SOURCE" , 
	"DX_ORIGIN" , 
	"PDX" , 
	"DX_POA" , 
	"RAW_DX" , 
	"RAW_DX_TYPE" , 
	"RAW_DX_SOURCE" , 
	"RAW_ORIGDX", 
	"RAW_PDX" , 
	"RAW_DX_POA" , 
	"DAYS_SINCE_ADMIT" 
from AKI_DX_CURRENT aki
join nightherondata.patient_dimension pd on pd.patient_num = aki.patid;


select "ONSETS_ENCOUNTERID" , 
	"LAB_RESULT_CM_ID" , 
	"PATID" , 
	"ENCOUNTERID", 
	"SPECIMEN_SOURCE" , 
	"LAB_LOINC" , 
	"PRIORITY" , 
	"RESULT_LOC" , 
	"LAB_PX" , 
	"LAB_PX_TYPE" , 
	"LAB_ORDER_DATE" +pd.date_shift, 
	"SPECIMEN_DATE" +pd.date_shift, 
	"SPECIMEN_TIME" , 
	"RESULT_DATE" +pd.date_shift, 
	"RESULT_TIME" , 
	"RESULT_QUAL" , 
	"RESULT_SNOMED" , 
	"RESULT_NUM" , 
	"RESULT_MODIFIER" , 
	"RESULT_UNIT" , 
	"NORM_RANGE_LOW" , 
	"NORM_MODIFIER_LOW" , 
	"NORM_RANGE_HIGH" , 
	"NORM_MODIFIER_HIGH" , 
	"ABN_IND" , 
	"RAW_LAB_NAME", 
	"RAW_LAB_CODE" , 
	"RAW_PANEL" , 
	"RAW_RESULT" , 
	"RAW_UNIT" , 
	"RAW_ORDER_DEPT" , 
	"RAW_FACILITY_CODE" , 
	"LAB_LOINC_SOURCE" , 
	"LAB_RESULT_SOURCE" , 
	"DAYS_SINCE_ADMIT" 
from AKI_LAB_SCR aki
join nightherondata.patient_dimension pd on pd.patient_num = aki.patid;


select "ONSETS_ENCOUNTERID", 
	"VITALID" , 
	"PATID" , 
	"ENCOUNTERID" , 
	"MEASURE_DATE" +pd.date_shift, 
	"MEASURE_TIME", 
	"VITAL_SOURCE" ,
	"HT" ,
	"WT" ,
	"DIASTOLIC" ,
	"SYSTOLIC",
	"ORIGINAL_BMI" ,
	"BP_POSITION" ,
	"SMOKING" ,
	"TOBACCO" ,
	"TOBACCO_TYPE" ,
	"RAW_VITAL_SOURCE" ,
	"RAW_HT" ,
	"RAW_WT" ,
	"RAW_DIASTOLIC" , 
	"RAW_SYSTOLIC" ,
	"RAW_BP_POSITION" ,
	"RAW_SMOKING" ,
	"RAW_TOBACCO" ,
	"RAW_TOBACCO_TYPE" ,
	"DAYS_SINCE_ADMIT" 
from AKI_VITAL_OLD aki
join nightherondata.patient_dimension pd on pd.patient_num = aki.patid;

