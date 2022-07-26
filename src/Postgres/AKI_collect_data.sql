/*******************************************************************************
 AKI_collect_data.sql (Postgres) is used to collect all relavent clinical observations for
 the AKI cohort collected in AKI_onsets. More details can be found 
 at: https://github.com/kumc-bmi/AKI_CDM
 
 - &&cdm_db_schema will be substituted by corresponding CDM schema
 - Replace it using text editor if the user input prompt does not work in your SQL environment 
********************************************************************************/

/*Demographic Table*/
-- calculate age in years: https://stackoverflow.com/questions/17833176/postgresql-days-months-years-between-two-dates

create table GPC_aki_project.AKI_DEMO_DEATH as
select distinct
     pat.ENCOUNTERID::char onsets_ENCOUNTERID
 	,dth.*            	  	
    ,(dth.DEATH_DATE::date - pat.DISCHARGE_DATE::date) DDAYS_SINCE_ENC
from GPC_aki_project.AKI_onsets pat
left join &&cdm_db_schema.DEATH dth
on pat.PATID = dth.PATID
;
 
create table GPC_aki_project.AKI_DEMO as
select distinct
       pat.ENCOUNTERID::char ONSETS_ENCOUNTERID
      ,case when DATE_PART('year', age(pat.ADMIT_DATE::date,demo.BIRTH_DATE::date)) > 89 then 90
	       else DATE_PART('year', age(pat.ADMIT_DATE::date,demo.BIRTH_DATE::date)) end as AGE
      ,demo.*              	  		  
      ,dth.DEATH_DATE
      ,(dth.DEATH_DATE::date - pat.DISCHARGE_DATE::date) DDAYS_SINCE_ENC
      ,dth.DEATH_DATE_IMPUTE
      ,dth.DEATH_SOURCE
from GPC_aki_project.AKI_onsets pat
left join &&cdm_db_schema.DEMOGRAPHIC demo
on pat.PATID = demo.PATID
left join &&cdm_db_schema.DEATH dth
on pat.PATID = dth.PATID
;

/*Vital Table*/
-- add/substract days to a date: https://stackoverflow.com/questions/46079791/subtracting-1-day-from-a-timestamp-date
-- Depend on CDM version, only one of the AKI_VITAL or AKI_VITAL_OLD table will populate
-- If your database is in v6.1 and AKI_VITAL is empty, please check modify the filter condition to corresponding code used in your site
-- We intend to collect 'SYSTOLIC','HT','SMOKING','TOBACCO_TYPE','TOBACCO','DIASTOLIC','ORIGINAL_BMI','WT' as in vital table in v6.0
create table GPC_aki_project.AKI_VITAL as
select 
       pat.ENCOUNTERID::char ONSETS_ENCOUNTERID
      ,v.*              	  	 
      ,(v.obsclin_start_date::date - pat.ADMIT_DATE::date) DAYS_SINCE_ADMIT
from GPC_aki_project.AKI_onsets pat
left join &&cdm_db_schema.obs_clin v
on pat.PATID = v.PATID
where v.obsclin_start_date between (pat.ADMIT_DATE - INTERVAL '30 DAYS') and greatest(coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR),pat.DISCHARGE_DATE) + INTERVAL '1 DAY'
and 
(v.OBSCLIN_CODE in ('8480-6','8459-0','8460-8','8461-6','75997-7','8462-4','8453-3','8454-1','8455-8','75995-1','3137-7','8302-2','8308-9','3138-5','3141-9','29463-7','8335-2','3142-7','8341-0','8340-2','39156-5','89270-3','722499006','11366-2','11367-0','39240-7','39243-1','63608-4','63638-1','64234-8','67741-9','72166-2','74010-0','74011-8','81229-7','82769-1','8663-7','8664-5','88029-4','88030-2','88031-0','95494-1','95529-4','96101-1','96103-7')
or
v.OBSCLIN_CODE in ('SYSTOLIC','HT','SMOKING','TOBACCO_TYPE','TOBACCO','DIASTOLIC','ORIGINAL_BMI','WT')
) 
;

-- add/substract days to a date: https://stackoverflow.com/questions/46079791/subtracting-1-day-from-a-timestamp-date
create table GPC_aki_project.AKI_VITAL_OLD as
select 
       pat.ENCOUNTERID::char ONSETS_ENCOUNTERID
      ,v.*              	  	 
      ,(v.MEASURE_DATE::date - pat.ADMIT_DATE::date) DAYS_SINCE_ADMIT
from GPC_aki_project.AKI_onsets pat
left join &&cdm_db_schema.VITAL  v
on pat.PATID = v.PATID
where v.MEASURE_DATE between (pat.ADMIT_DATE - INTERVAL '30 DAYS') and greatest(coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR),pat.DISCHARGE_DATE) + INTERVAL '1 DAY'
--      coalesce(v.HT, v.WT, v.SYSTOLIC, v.DIASTOLIC, v.ORIGINAL_BMI) is not null
;

/*Procedure Table*/
create table GPC_aki_project.AKI_PX as
select distinct
       pat.ENCOUNTERID::char ONSETS_ENCOUNTERID            	  
      ,px.*              	  	  
      ,(px.PX_DATE::date - pat.ADMIT_DATE::date) DAYS_SINCE_ADMIT
from GPC_aki_project.AKI_onsets pat
left join &&cdm_db_schema.PROCEDURES px
on pat.PATID = px.PATID
where px.PX_DATE between pat.ADMIT_DATE and greatest(coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR),pat.DISCHARGE_DATE) + INTERVAL '1 DAY'
;

/*Diagnoses Table (historic)*/
create table GPC_aki_project.AKI_DX as
select 
       pat.ENCOUNTERID::char ONSETS_ENCOUNTERID            	  
      ,dx.*              	  	
      ,(dx.ADMIT_DATE::date - pat.ADMIT_DATE::date) DAYS_SINCE_ADMIT
from GPC_aki_project.AKI_onsets pat
join &&cdm_db_schema.DIAGNOSIS dx
on pat.PATID = dx.PATID
where dx.ADMIT_DATE between (pat.ADMIT_DATE - INTERVAL '365 DAYS') and (pat.ADMIT_DATE - INTERVAL '1 DAY')
;

create table GPC_aki_project.AKI_DX_CURRENT as
select 
       pat.ENCOUNTERID::char ONSETS_ENCOUNTERID            	  
      ,dx.*              	  	
      ,(dx.DX_DATE::date - pat.ADMIT_DATE::date) DAYS_SINCE_ADMIT
from GPC_aki_project.AKI_onsets pat
join &&cdm_db_schema.DIAGNOSIS dx
on pat.PATID = dx.PATID
where dx.DX_DATE between pat.ADMIT_DATE and greatest(coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR),pat.DISCHARGE_DATE) + INTERVAL '1 DAY'
;

create table GPC_aki_project.AKI_DX_CURRENT_ADMIT_DATE as
select 
       pat.ENCOUNTERID::char ONSETS_ENCOUNTERID            	  
      ,dx.*              	  	
      ,(dx.ADMIT_DATE::date - pat.ADMIT_DATE::date) DAYS_SINCE_ADMIT
from GPC_aki_project.AKI_onsets pat
join &&cdm_db_schema.DIAGNOSIS dx
on pat.PATID = dx.PATID
where dx.ADMIT_DATE between pat.ADMIT_DATE and greatest(coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR),pat.DISCHARGE_DATE) + INTERVAL '1 DAY'
;

/*Lab Table*/
create table GPC_aki_project.AKI_LAB as
select distinct
       pat.ENCOUNTERID::char ONSETS_ENCOUNTERID            	  
      ,l.*
      ,(l.SPECIMEN_DATE::date - pat.ADMIT_DATE::date) DAYS_SINCE_ADMIT
from GPC_aki_project.AKI_onsets pat
join &&cdm_db_schema.LAB_RESULT_CM l
on pat.PATID = l.PATID and l.LAB_ORDER_DATE between pat.ADMIT_DATE and greatest(coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR),pat.DISCHARGE_DATE) + INTERVAL '1 DAY'
;

create table GPC_aki_project.AKI_LAB_SCR as
select distinct
       pat.ENCOUNTERID::char ONSETS_ENCOUNTERID            	  
      ,l.*
      ,(l.SPECIMEN_DATE::date - pat.ADMIT_DATE::date) DAYS_SINCE_ADMIT
from GPC_aki_project.AKI_onsets pat
join &&cdm_db_schema.LAB_RESULT_CM l
on pat.PATID = l.PATID and l.LAB_ORDER_DATE between (pat.ADMIT_DATE - INTERVAL '365 DAYS') and 
(greatest(coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR),pat.DISCHARGE_DATE) + INTERVAL '1 DAY'
)
where l.LAB_LOINC in ('2160-0','38483-4','14682-9','21232-4','35203-9','44784-7','59826-8') and 
      (UPPER(l.RESULT_UNIT) = 'MG/DL' or UPPER(l.RESULT_UNIT) = 'MG') and /*there are variations of common units*/
      l.SPECIMEN_SOURCE <> 'URINE' and  /*only serum creatinine*/
      l.RESULT_NUM > 0 /*value 0 could exist*/
;

/*Prescribing Table*/
create table GPC_aki_project.AKI_PMED as
select distinct
       pat.ENCOUNTERID::char ONSETS_ENCOUNTERID            	  
      ,p.*
      ,least(pat.DISCHARGE_DATE,p.RX_END_DATE) RX_END_DATE_MOD
      ,case when p.RX_DAYS_SUPPLY > 0 and p.RX_QUANTITY is not null then round(p.RX_QUANTITY/p.RX_DAYS_SUPPLY) 
            else null end as RX_QUANTITY_DAILY
      ,(p.RX_START_DATE::date - pat.ADMIT_DATE::date) DAYS_SINCE_ADMIT
from GPC_aki_project.AKI_onsets pat
join &&cdm_db_schema.PRESCRIBING p
on pat.PATID = p.PATID
where p.RXNORM_CUI is not null and
      p.RX_START_DATE is not null and
      p.RX_ORDER_DATE is not null and 
      p.RX_ORDER_TIME is not null and
      p.RX_ORDER_DATE between (pat.ADMIT_DATE - INTERVAL '30 DAYS') and greatest(coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR),pat.DISCHARGE_DATE) + INTERVAL '1 DAY'
;

/*Dispensing Table*/
-- Note: for sites don't populate this table, please skip
create table GPC_aki_project.AKI_DMED as
select distinct
       pat.ENCOUNTERID::char ONSETS_ENCOUNTERID            	  
      ,d.*
      ,(d.DISPENSE_DATE::date - pat.ADMIT_DATE::date) DAYS_SINCE_ADMIT
from GPC_aki_project.AKI_onsets pat
join &&cdm_db_schema.DISPENSING d
on pat.PATID = d.PATID
where d.NDC is not null and
      d.DISPENSE_DATE between (pat.ADMIT_DATE - INTERVAL '30 DAYS') and greatest(coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR),pat.DISCHARGE_DATE) + INTERVAL '1 DAY'
;


/*Med Admin Table*/
-- Note: for sites don't populate this table, please skip
create table GPC_aki_project.AKI_AMED as
select distinct
       pat.ENCOUNTERID::char ONSETS_ENCOUNTERID            	  
      ,m.*
      ,(m.MEDADMIN_START_DATE::date - pat.ADMIT_DATE::date) DAYS_SINCE_ADMIT
from GPC_aki_project.AKI_onsets pat
join &&cdm_db_schema.MED_ADMIN m
on pat.PATID = m.PATID
where m.MEDADMIN_CODE is not null and
      m.MEDADMIN_START_DATE is not null and
      --m.MEDADMIN_START_TIME is not null and 
      m.MEDADMIN_STOP_DATE is not null and
      --m.MEDADMIN_STOP_TIME is null and
      m.MEDADMIN_START_DATE between (pat.ADMIT_DATE - INTERVAL '30 DAYS') and greatest(coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR),pat.DISCHARGE_DATE) + INTERVAL '1 DAY'
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
 - AKI_LAB_SCR  */
------------------------------------------------------------------------------------
