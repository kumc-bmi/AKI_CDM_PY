/* Date Shift script for postgres

  Change the range of date shifting according to the requirement of your organization

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
create table GPC_aki_project.dateshift_table as
with unique_id as(
select
distinct("patid")
from GPC_aki_project.AKI_onsets
)
select 
"patid"
,floor(random()*(-365-(-1)+1))+(-1) as date_shift -- Change your range here
from unique_id;

create table gpc_aki_project.deid_aki_onsets as
select
    aki."patid" , 
	aki."encounterid" , 
	aki."admit_date" + pd.date_shift * interval '1 day' "admit_date",
	aki."discharge_date" + pd.date_shift * interval '1 day' "discharge_date",
	aki."serum_creat_base" , 
	aki."nonaki_anchor" + pd.date_shift * interval '1 day' "nonaki_anchor",
	aki."nonaki_since_admit" , 
	aki."non_aki_scr" , 
	aki."non_aki_inc" , 
	aki."aki1_onset" + pd.date_shift * interval '1 day' "aki1_onset",
	aki."aki1_since_admit" , 
	aki."aki1_scr" , 
	aki."aki1_inc" , 
	aki."aki2_onset" + pd.date_shift * interval '1 day' "aki2_onset",
	aki."aki2_since_admit" , 
	aki."aki2_scr" , 
	aki."aki2_inc" , 
	aki."bccovid" , 
	aki."aki3_onset" + pd.date_shift * interval '1 day' "aki3_onset",
	aki."aki3_since_admit" , 
	aki."aki3_scr" , 
	aki."aki3_inc" 
from gpc_aki_project.aki_onsets aki
join gpc_aki_project.dateshift_table pd on pd.patid = aki.patid;

create table gpc_aki_project.deid_aki_demo_death as
select "onsets_encounterid", 
	aki."patid" , 
	aki."death_date" + pd.date_shift * interval '1 day' "death_date", 
	aki."death_date_impute" , 
	aki."death_source" , 
	aki."death_match_confidence" , 
	aki."ddays_since_enc" 
from gpc_aki_project.aki_demo_death aki
join gpc_aki_project.dateshift_table pd on pd.patid = aki.patid;

create table gpc_aki_project.deid_aki_demo as
select 
    aki."onsets_encounterid" , 
	aki."age" , 
	aki."patid", 
	aki."birth_date" + pd.date_shift * interval '1 day' "birth_date",
	aki."birth_time" , 
	aki."sex", 
	aki."sexual_orientation" , 
	aki."gender_identity" , 
	aki."hispanic" , 
	aki."biobank_flag" , 
	aki."race" , 
	aki."pat_pref_language_spoken" , 
	aki."raw_sex" , 
	aki."raw_sexual_orientation" , 
	aki."raw_gender_identity" , 
	aki."raw_hispanic" , 
	aki."raw_race" , 
	aki."raw_pat_pref_language_spoken" , 
	aki."death_date" + pd.date_shift * interval '1 day' "death_date", 
	aki."ddays_since_enc" , 
	aki."death_date_impute" , 
	aki."death_source" 
from gpc_aki_project.aki_demo aki
join gpc_aki_project.dateshift_table pd on pd.patid = aki.patid;

create table gpc_aki_project.deid_aki_px as
select 
    aki."onsets_encounterid" ,
	aki."proceduresid",
	aki."patid" , 
	aki."encounterid", 
	aki."enc_type", 
	aki."admit_date" + pd.date_shift * interval '1 day' "admit_date", 
	aki."providerid" , 
	aki."px_date" + pd.date_shift * interval '1 day' "px_date", 
	aki."px" , 
	aki."px_type" , 
	aki."px_source" , 
	aki."ppx" , 
	aki."raw_px" , 
	aki."raw_px_type" , 
	aki."raw_ppx" , 
	aki."days_since_admit" 
from gpc_aki_project.aki_px aki
join gpc_aki_project.dateshift_table pd on pd.patid = aki.patid;

create table gpc_aki_project.deid_aki_vital as
select 
    aki."onsets_encounterid" , 
	aki."obsclinid" , 
	aki."patid", 
	aki."encounterid" , 
	aki."obsclin_providerid" , 
	aki."obsclin_start_date" + pd.date_shift * interval '1 day' "obsclin_start_date", 
	aki."obsclin_start_time" , 
	aki."obsclin_stop_date" + pd.date_shift * interval '1 day' "obsclin_stop_date", 
	aki."obsclin_stop_time" , 
	aki."obsclin_type" , 
	aki."obsclin_code" , 
	aki."obsclin_result_qual" , 
	aki."obsclin_result_text" , 
	aki."obsclin_result_snomed" , 
	aki."obsclin_result_num" , 
	aki."obsclin_result_modifier" , 
	aki."obsclin_result_unit" , 
	aki."obsclin_abn_ind" , 
	aki."raw_obsclin_name", 
	aki."raw_obsclin_code" , 
	aki."raw_obsclin_type" , 
	aki."raw_obsclin_result" , 
	aki."raw_obsclin_modifier" , 
	aki."raw_obsclin_unit" , 
	aki."obsclin_source" , 
	aki."days_since_admit" 
from gpc_aki_project.aki_vital aki
join gpc_aki_project.dateshift_table pd on pd.patid = aki.patid;

create table gpc_aki_project.deid_aki_dx as
select 
    aki."onsets_encounterid" , 
	aki."diagnosisid" , 
	aki."patid", 
	aki."encounterid" , 
	aki."enc_type" , 
	aki."admit_date" + pd.date_shift * interval '1 day' "admit_date", 
	aki."dx_date" + pd.date_shift * interval '1 day' "dx_date", 
	aki."providerid" , 
	aki."dx" , 
	aki."dx_type" , 
	aki."dx_source" , 
	aki."dx_origin" , 
	aki."pdx" , 
	aki."dx_poa" , 
	aki."raw_dx" , 
	aki."raw_dx_type" , 
	aki."raw_dx_source" , 
	aki."raw_origdx" , 
	aki."raw_pdx" , 
	aki."raw_dx_poa" , 
	aki."days_since_admit" 
from gpc_aki_project.aki_dx aki
join gpc_aki_project.dateshift_table pd on pd.patid = aki.patid;

create table gpc_aki_project.deid_aki_lab as
select 
    aki."onsets_encounterid" , 
	aki."lab_result_cm_id" , 
	aki."patid" , 
	aki."encounterid" , 
	aki."specimen_source" , 
	aki."lab_loinc" , 
	aki."priority" , 
	aki."result_loc", 
	aki."lab_px" , 
	aki."lab_px_type" , 
	aki."lab_order_date" + pd.date_shift * interval '1 day' "lab_order_date", 
	aki."specimen_date" + pd.date_shift * interval '1 day' "specimen_date", 
	aki."specimen_time" , 
	aki."result_date" + pd.date_shift * interval '1 day' "result_date", 
	aki."result_time" , 
	aki."result_qual" , 
	aki."result_snomed" , 
	aki."result_num" , 
	aki."result_modifier" , 
	aki."result_unit" , 
	aki."norm_range_low" , 
	aki."norm_modifier_low" , 
	aki."norm_range_high", 
	aki."norm_modifier_high" , 
	aki."abn_ind" , 
	aki."raw_lab_name" , 
	aki."raw_lab_code" , 
	aki."raw_panel" , 
	aki."raw_result" , 
	aki."raw_unit" , 
	aki."raw_order_dept" , 
	aki."raw_facility_code" , 
	aki."lab_loinc_source" , 
	aki."lab_result_source" , 
	aki."days_since_admit" 
from gpc_aki_project.aki_lab aki
join gpc_aki_project.dateshift_table pd on pd.patid = aki.patid;


create table gpc_aki_project.deid_aki_pmed as
select 
    aki."onsets_encounterid" , 
	aki."prescribingid" , 
	aki."patid" , 
	aki."encounterid" , 
	aki."rx_providerid" , 
	aki."rx_order_date" + pd.date_shift * interval '1 day' "rx_order_date", 
	aki."rx_order_time" , 
	aki."rx_start_date" + pd.date_shift * interval '1 day' "rx_start_date", 
	aki."rx_end_date" + pd.date_shift * interval '1 day' "rx_end_date", 
	aki."rx_dose_ordered" , 
	aki."rx_dose_ordered_unit" , 
	aki."rx_quantity" , 
	aki."rx_dose_form" , 
	aki."rx_refills" , 
	aki."rx_days_supply" , 
	aki."rx_frequency" , 
	aki."rx_prn_flag" , 
	aki."rx_route" , 
	aki."rx_basis" , 
	aki."rxnorm_cui" , 
	aki."rx_source", 
	aki."rx_dispense_as_written" , 
	aki."raw_rx_med_name" , 
	aki."raw_rx_frequency" , 
	aki."raw_rxnorm_cui" , 
	aki."raw_rx_quantity", 
	aki."raw_rx_ndc" , 
	aki."raw_rx_dose_ordered" , 
	aki."raw_rx_dose_ordered_unit", 
	aki."raw_rx_route" , 
	aki."raw_rx_refills" , 
	aki."rx_end_date_mod" + pd.date_shift * interval '1 day' "rx_end_date_mod", 
	aki."rx_quantity_daily" , 
	aki."days_since_admit" 
from gpc_aki_project.aki_pmed aki
join gpc_aki_project.dateshift_table pd on pd.patid = aki.patid;

create table gpc_aki_project.deid_aki_amed as
select 
    aki."onsets_encounterid" , 
	aki."medadminid", 
	aki."patid" , 
	aki."encounterid" , 
	aki."prescribingid" , 
	aki."medadmin_providerid", 
	aki."medadmin_start_date" + pd.date_shift * interval '1 day' "medadmin_start_date", 
	aki."medadmin_start_time" , 
	aki."medadmin_stop_date" + pd.date_shift * interval '1 day' "medadmin_stop_date", 
	aki."medadmin_stop_time" , 
	aki."medadmin_type" , 
	aki."medadmin_code" , 
	aki."medadmin_dose_admin", 
	aki."medadmin_dose_admin_unit" , 
	aki."medadmin_route", 
	aki."medadmin_source", 
	aki."raw_medadmin_med_name" , 
	aki."raw_medadmin_code" , 
	aki."raw_medadmin_dose_admin" , 
	aki."raw_medadmin_dose_admin_unit" , 
	aki."raw_medadmin_route" , 
	aki."days_since_admit" 
from gpc_aki_project.aki_amed aki
join gpc_aki_project.dateshift_table pd on pd.patid = aki.patid;

create table gpc_aki_project.deid_aki_dmed as
select 
    aki."onsets_encounterid" ,
	aki."dispensingid" , 
	aki."patid" , 
	aki."prescribingid" , 
	aki."dispense_date" + pd.date_shift * interval '1 day' "dispense_date", 
	aki."ndc", 
	aki."dispense_sup" , 
	aki."dispense_amt" , 
	aki."dispense_dose_disp" , 
	aki."dispense_dose_disp_unit", 
	aki."dispense_route" , 
	aki."raw_ndc" , 
	aki."raw_dispense_dose_disp" , 
	aki."raw_dispense_dose_disp_unit" , 
	aki."raw_dispense_route" , 
	aki."dispense_source" , 
	aki."days_since_admit" 
from gpc_aki_project.aki_dmed aki
join gpc_aki_project.dateshift_table pd on pd.patid = aki.patid;


create table gpc_aki_project.deid_aki_dx_current as
select 
    aki."onsets_encounterid" , 
	aki."diagnosisid" , 
	aki."patid" , 
	aki."encounterid" , 
	aki."enc_type" , 
	aki."admit_date" + pd.date_shift * interval '1 day' "admit_date", 
	aki."dx_date" + pd.date_shift * interval '1 day' "dx_date", 
	aki."providerid" , 
	aki."dx" , 
	aki."dx_type" , 
	aki."dx_source" , 
	aki."dx_origin" , 
	aki."pdx" , 
	aki."dx_poa" , 
	aki."raw_dx" , 
	aki."raw_dx_type" , 
	aki."raw_dx_source" , 
	aki."raw_origdx", 
	aki."raw_pdx" , 
	aki."raw_dx_poa" , 
	aki."days_since_admit" 
from gpc_aki_project.aki_dx_current aki
join gpc_aki_project.dateshift_table pd on pd.patid = aki.patid;

create table gpc_aki_project.deid_aki_lab_scr as
select 
    aki."onsets_encounterid" , 
	aki."lab_result_cm_id" , 
	aki."patid" , 
	aki."encounterid", 
	aki."specimen_source" , 
	aki."lab_loinc" , 
	aki."priority" , 
	aki."result_loc" , 
	aki."lab_px" , 
	aki."lab_px_type" , 
	aki."lab_order_date" + pd.date_shift * interval '1 day' "lab_order_date", 
	aki."specimen_date" + pd.date_shift * interval '1 day' "specimen_date", 
	aki."specimen_time" , 
	aki."result_date" + pd.date_shift * interval '1 day' "result_date", 
	aki."result_time" , 
	aki."result_qual" , 
	aki."result_snomed" , 
	aki."result_num" , 
	aki."result_modifier" , 
	aki."result_unit" , 
	aki."norm_range_low" , 
	aki."norm_modifier_low" , 
	aki."norm_range_high" , 
	aki."norm_modifier_high" , 
	aki."abn_ind" , 
	aki."raw_lab_name", 
	aki."raw_lab_code" , 
	aki."raw_panel" , 
	aki."raw_result" , 
	aki."raw_unit" , 
	aki."raw_order_dept" , 
	aki."raw_facility_code" , 
	aki."lab_loinc_source" , 
	aki."lab_result_source" , 
	aki."days_since_admit" 
from gpc_aki_project.aki_lab_scr aki
join gpc_aki_project.dateshift_table pd on pd.patid = aki.patid;

create table gpc_aki_project.deid_aki_vital_old as
select 
    aki."onsets_encounterid", 
	aki."vitalid" , 
	aki."patid" , 
	aki."encounterid" , 
	aki."measure_date" + pd.date_shift * interval '1 day' "measure_date", 
	aki."measure_time", 
	aki."vital_source" ,
	aki."ht" ,
	aki."wt" ,
	aki."diastolic" ,
	aki."systolic",
	aki."original_bmi" ,
	aki."bp_position" ,
	aki."smoking" ,
	aki."tobacco" ,
	aki."tobacco_type" ,
	aki."raw_vital_source" ,
	aki."raw_ht" ,
	aki."raw_wt" ,
	aki."raw_diastolic" , 
	aki."raw_systolic" ,
	aki."raw_bp_position" ,
	aki."raw_smoking" ,
	aki."raw_tobacco" ,
	aki."raw_tobacco_type" ,
	aki."days_since_admit" 
from gpc_aki_project.aki_vital_old aki
join gpc_aki_project.dateshift_table pd on pd.patid = aki.patid;
