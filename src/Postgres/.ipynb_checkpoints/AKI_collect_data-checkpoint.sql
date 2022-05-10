/*******************************************************************************
 AKI_collect_data.sql (Postgres) is used to collect all relavent clinical observations for
 the AKI cohort collected in AKI_onsets. More details can be found 
 at: https://github.com/kumc-bmi/AKI_CDM
 
 - &&cdm_db_schema will be substituted by corresponding CDM schema
 - Replace it using text editor if the user input prompt does not work in your SQL environment 
********************************************************************************/

/*Demographic Table*/
-- calculate age in years: https://stackoverflow.com/questions/17833176/postgresql-days-months-years-between-two-dates

create table AKI_DEMO_DEATH as
select distinct
     to_char(pat.ENCOUNTERID) onsets_ENCOUNTERID
 	,dth.*            	  	
    ,DATE_PART('day',dth.DEATH_DATE::date - pat.DISCHARGE_DATE::date) DDAYS_SINCE_ENC
from AKI_onsets pat
left join &&cdm_db_schema.DEATH dth
on pat.PATID = dth.PATID
;
 
create table AKI_DEMO as
select distinct
       to_char(pat.ENCOUNTERID) ONSETS_ENCOUNTERID
      ,case when DATE_PART('year', age(pat.ADMIT_DATE::date,demo.BIRTH_DATE::date)) > 89 then 90
	       else DATE_PART('year', age(pat.ADMIT_DATE::date,demo.BIRTH_DATE::date)) end as AGE
      ,demo.*              	  		  
      ,dth.DEATH_DATE
      ,DATE_PART('day',dth.DEATH_DATE::date - pat.DISCHARGE_DATE::date) DDAYS_SINCE_ENC
      ,dth.DEATH_DATE_IMPUTE
      ,dth.DEATH_SOURCE
from AKI_onsets pat
left join &&cdm_db_schema.DEMOGRAPHIC demo
on pat.PATID = demo.PATID
left join &&cdm_db_schema.DEATH dth
on pat.PATID = dth.PATID
;

/*Vital Table*/
-- add/substract days to a date: https://stackoverflow.com/questions/46079791/subtracting-1-day-from-a-timestamp-date
-- Depend on CDM version, only one of the AKI_VITAL or AKI_VITAL_OLD table will populate
create table AKI_VITAL as
select 
       to_char(pat.ENCOUNTERID) ONSETS_ENCOUNTERID
      ,v.*              	  	 
      ,DATE_PART('day',v.obsclin_start_date::date - pat.ADMIT_DATE::date) DAYS_SINCE_ADMIT
from AKI_onsets pat
left join &&cdm_db_schema.obs_clin v
on pat.PATID = v.PATID
where v.obsclin_start_date between (pat.ADMIT_DATE - INTERVAL '30 DAYS') and coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR,pat.DISCHARGE_DATE)
--      coalesce(v.HT, v.WT, v.SYSTOLIC, v.DIASTOLIC, v.ORIGINAL_BMI) is not null
;

-- add/substract days to a date: https://stackoverflow.com/questions/46079791/subtracting-1-day-from-a-timestamp-date
create table AKI_VITAL_OLD as
select 
       to_char(pat.ENCOUNTERID) ONSETS_ENCOUNTERID
      ,v.*              	  	 
      ,DATE_PART('day',v.MEASURE_DATE::date - pat.ADMIT_DATE::date) DAYS_SINCE_ADMIT
from AKI_onsets pat
left join &&cdm_db_schema.VITAL  v
on pat.PATID = v.PATID
where v.MEASURE_DATE between (pat.ADMIT_DATE - INTERVAL '30 DAYS') and coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR,pat.DISCHARGE_DATE)
--      coalesce(v.HT, v.WT, v.SYSTOLIC, v.DIASTOLIC, v.ORIGINAL_BMI) is not null
;

/*Procedure Table*/
create table AKI_PX as
select distinct
       to_char(pat.ENCOUNTERID) ONSETS_ENCOUNTERID            	  
      ,px.*              	  	  
      ,DATE_PART('day',px.PX_DATE::date - pat.ADMIT_DATE::date) DAYS_SINCE_ADMIT
from AKI_onsets pat
left join &&cdm_db_schema.PROCEDURES px
on pat.PATID = px.PATID
where px.PX_DATE between pat.ADMIT_DATE and coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR,pat.DISCHARGE_DATE)
;

/*Diagnoses Table (historic)*/
create table AKI_DX as
select 
       to_char(pat.ENCOUNTERID) ONSETS_ENCOUNTERID            	  
      ,dx.*              	  	
      ,DATE_PART('day',dx.ADMIT_DATE::date - pat.ADMIT_DATE::date) DAYS_SINCE_ADMIT
from AKI_onsets pat
join &&cdm_db_schema.DIAGNOSIS dx
on pat.PATID = dx.PATID
where dx.ADMIT_DATE between (pat.ADMIT_DATE - INTERVAL '365 DAYS') and (pat.ADMIT_DATE - INTERVAL '1 DAY')
;

create table AKI_DX_CURRENT as
select 
       to_char(pat.ENCOUNTERID) ONSETS_ENCOUNTERID            	  
      ,dx.*              	  	
      ,DATE_PART('day',dx.DX_DATE::date - pat.ADMIT_DATE::date) DAYS_SINCE_ADMIT
from AKI_onsets pat
join &&cdm_db_schema.DIAGNOSIS dx
on pat.PATID = dx.PATID
where dx.DX_DATE between pat.ADMIT_DATE and coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR,pat.DISCHARGE_DATE)
;

/*Lab Table*/
create table AKI_LAB as
select distinct
       to_char(pat.ENCOUNTERID) ONSETS_ENCOUNTERID            	  
      ,l.*
      ,DATE_PART('day',l.SPECIMEN_DATE::date - pat.ADMIT_DATE::date) DAYS_SINCE_ADMIT
from AKI_onsets pat
join &&cdm_db_schema.LAB_RESULT_CM l
on pat.PATID = l.PATID and l.LAB_ORDER_DATE between pat.ADMIT_DATE and least(coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR,pat.DISCHARGE_DATE),pat.DISCHARGE_DATE)
;

create table AKI_LAB_SCR as
select distinct
       to_char(pat.ENCOUNTERID) ONSETS_ENCOUNTERID            	  
      ,l.*
      ,DATE_PART('day',l.SPECIMEN_DATE::date - pat.ADMIT_DATE::date) DAYS_SINCE_ADMIT
from AKI_onsets pat
join &&cdm_db_schema.LAB_RESULT_CM l
on pat.PATID = l.PATID and l.LAB_ORDER_DATE between (pat.ADMIT_DATE - INTERVAL '365 DAYS') and 
													(coalesce(pat.DISCHARGE_DATE,pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR) + INTERVAL '1 DAYS')
where l.LAB_LOINC in ('2160-0','38483-4','14682-9','21232-4','35203-9','44784-7','59826-8') and 
      (UPPER(l.RESULT_UNIT) = 'MG/DL' or UPPER(l.RESULT_UNIT) = 'MG') and /*there are variations of common units*/
      l.SPECIMEN_SOURCE <> 'URINE' and  /*only serum creatinine*/
      l.RESULT_NUM > 0 and /*value 0 could exist*/
;

/*Prescribing Table*/
create table AKI_PMED as
select distinct
       to_char(pat.ENCOUNTERID) ONSETS_ENCOUNTERID            	  
      ,p.*
      ,least(pat.DISCHARGE_DATE,p.RX_END_DATE),'YYYY:MM:DD') RX_END_DATE_MOD
      ,case when p.RX_DAYS_SUPPLY > 0 and p.RX_QUANTITY is not null then round(p.RX_QUANTITY/p.RX_DAYS_SUPPLY) 
            else null end as RX_QUANTITY_DAILY
      ,DATE_PART('day',p.RX_START_DATE::date - pat.ADMIT_DATE::date) DAYS_SINCE_ADMIT
from AKI_onsets pat
join &&cdm_db_schema.PRESCRIBING p
on pat.PATID = p.PATID
where p.RXNORM_CUI is not null and
      p.RX_START_DATE is not null and
      p.RX_ORDER_DATE is not null and 
      p.RX_ORDER_TIME is not null and
      p.RX_ORDER_DATE between (pat.ADMIT_DATE - INTERVAL '30 DAYS') and coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR,pat.DISCHARGE_DATE)
;

/*Dispensing Table*/
-- Note: for sites don't populate this table, please skip
create table AKI_DMED as
select distinct
       to_char(pat.ENCOUNTERID) ONSETS_ENCOUNTERID            	  
      ,d.*
      ,DATE_PART('day',d.DISPENSING_DATE::date - pat.ADMIT_DATE::date) DAYS_SINCE_ADMIT
from AKI_onsets pat
join &&cdm_db_schema.DISPENSING d
on pat.PATID = d.PATID
where d.NDC is not null and
      d.DISPENSING_DATE between (pat.ADMIT_DATE - INTERVAL '30 DAYS') and coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR,pat.DISCHARGE_DATE)
;


/*Med Admin Table*/
-- Note: for sites don't populate this table, please skip
create table AKI_AMED as
select distinct
       to_char(pat.ENCOUNTERID) ONSETS_ENCOUNTERID            	  
      ,m.*
      ,DATE_PART('day',m.MEDADMIN_START_DATE::date - pat.ADMIT_DATE::date) DAYS_SINCE_ADMIT
from AKI_onsets pat
join &&cdm_db_schema.MED_ADMIN m
on pat.PATID = m.PATID
where m.MEDADMIN_CODE is not null and
      m.MEDADMIN_START_DATE is not null and
      --m.MEDADMIN_START_TIME is not null and 
      m.MEDADMIN_STOP_DATE is not null and
      --m.MEDADMIN_STOP_TIME is null and
      m.MEDADMIN_START_DATE between (pat.ADMIT_DATE - INTERVAL '30 DAYS') and coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR,pat.DISCHARGE_DATE)
;

-------------------------------------------------------------------------------
/* eyeball several lines and export the following tables as .csv files. Please 
   skip the tables that are not populated. 
 
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
------------------------------------------------------------------------------------
