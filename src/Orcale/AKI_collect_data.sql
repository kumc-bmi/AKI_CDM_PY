/*******************************************************************************
 AKI_collect_data.sql is used to collect all relavent clinical observations for
 the AKI cohort collected in AKI_onsets. More details can be found 
 at: https://github.com/kumc-bmi/AKI_CDM
 
 - &&cdm_db_schema will be substituted by corresponding CDM schema
********************************************************************************/

/*Demographic Table*/
create table AKI_DEMO_DEATH as
select distinct
       to_char(pat.ENCOUNTERID) ONSETS_ENCOUNTERID            
      ,dth.*
      ,(dth.DEATH_DATE - pat.DISCHARGE_DATE) DDAYS_SINCE_ENC
from AKI_onsets pat
left join "&&cdm_db_schema".DEATH dth
on pat.PATID = dth.PATID
;

create table AKI_DEMO as
select distinct
       to_char(pat.ENCOUNTERID) ONSETS_ENCOUNTERID            
      ,case when round((pat.ADMIT_DATE - demo.BIRTH_DATE)/365.25) > 89 then 90
	       else round((pat.ADMIT_DATE - demo.BIRTH_DATE)/365.25) end as AGE
      ,demo.*
      ,dth.DEATH_DATE
      ,(dth.DEATH_DATE - pat.DISCHARGE_DATE) DDAYS_SINCE_ENC
      ,dth.DEATH_DATE_IMPUTE
      ,dth.DEATH_SOURCE      
from AKI_onsets pat
left join "&&cdm_db_schema".DEMOGRAPHIC demo
on pat.PATID = demo.PATID
left join "&&cdm_db_schema".DEATH dth
on pat.PATID = dth.PATID
;

/*Vital Table*/
create table AKI_VITAL as
select 
       to_char(pat.ENCOUNTERID) ONSETS_ENCOUNTERID            	  
      ,v.*
      ,round(v.obsclin_start_date-pat.ADMIT_DATE) DAYS_SINCE_ADMIT
from AKI_onsets pat
left join "&&cdm_db_schema".obs_clin v
on pat.PATID = v.PATID
where v.obsclin_start_date between pat.ADMIT_DATE-30 and coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR,pat.DISCHARGE_DATE)
--where v.MEASURE_DATE between pat.ADMIT_DATE-7 and coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR,pat.DISCHARGE_DATE) and
--      coalesce(v.HT, v.WT, v.SYSTOLIC, v.DIASTOLIC, v.ORIGINAL_BMI) is not null
;

/*Procedure Table*/
create table AKI_PX as
select distinct
       to_char(pat.ENCOUNTERID) ONSETS_ENCOUNTERID            	  
      ,px.*
      ,round(px.PX_DATE-pat.ADMIT_DATE) DAYS_SINCE_ADMIT
from AKI_onsets pat
left join "&&cdm_db_schema".PROCEDURES px
on pat.PATID = px.PATID
where px.PX_DATE between pat.ADMIT_DATE and coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR,pat.DISCHARGE_DATE)
--where (px.PX_DATE    is not null and px.PX_DATE    between pat.ADMIT_DATE and coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR,pat.DISCHARGE_DATE))
--      (px.ADMIT_DATE is not null and px.ADMIT_DATE between pat.ADMIT_DATE and coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR,pat.DISCHARGE_DATE))
;

/*Diagnoses Table (historic)*/
create table AKI_DX as
select
       to_char(pat.ENCOUNTERID) ONSETS_ENCOUNTERID            	  
      ,dx.*
      ,round(dx.ADMIT_DATE-pat.ADMIT_DATE) DAYS_SINCE_ADMIT
from AKI_onsets pat
join "&&cdm_db_schema".DIAGNOSIS dx
on pat.PATID = dx.PATID
where dx.ADMIT_DATE between pat.ADMIT_DATE-365 and pat.ADMIT_DATE-1
--where (dx.ADMIT_DATE     is not null and dx.ADMIT_DATE     between pat.ADMIT_DATE-365 and pat.ADMIT_DATE-1)     
--      (dx.DX_DATE        is not null and dx.DX_DATE        between pat.ADMIT_DATE-365 and pat.ADMIT_DATE-1)
;

create table AKI_DX_CURRENT as
select
       to_char(pat.ENCOUNTERID) ONSETS_ENCOUNTERID            	  
      ,dx.*
      ,round(dx.ADMIT_DATE-pat.ADMIT_DATE) DAYS_SINCE_ADMIT
from AKI_onsets pat 
join "&&cdm_db_schema".DIAGNOSIS dx
on pat.PATID = dx.PATID
where dx.ADMIT_DATE     between pat.ADMIT_DATE and coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR,pat.DISCHARGE_DATE)
--where (dx.ADMIT_DATE     is not null and dx.ADMIT_DATE     between pat.ADMIT_DATE-1 and coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR,pat.DISCHARGE_DATE))     
--      (dx.DX_DATE        is not null and dx.DX_DATE        between pat.ADMIT_DATE-1 and coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR,pat.DISCHARGE_DATE))
;

/*Lab Table*/
create table AKI_LAB as
select distinct
       to_char(pat.ENCOUNTERID) ONSETS_ENCOUNTERID            	  
      ,l.*
      ,round(l.SPECIMEN_DATE-pat.ADMIT_DATE) DAYS_SINCE_ADMIT
from AKI_onsets pat
join "&&cdm_db_schema".LAB_RESULT_CM l
on pat.PATID = l.PATID and l.LAB_ORDER_DATE between pat.ADMIT_DATE and least(coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR,pat.DISCHARGE_DATE),pat.DISCHARGE_DATE)
--on pat.PATID = l.PATID and 
--  ((l.LAB_ORDER_DATE is not null and  l.LAB_ORDER_DATE between pat.ADMIT_DATE and least(coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR,pat.DISCHARGE_DATE),pat.DISCHARGE_DATE)) or
--   (l.SPECIMEN_DATE  is not null and  l.SPECIMEN_DATE  between pat.ADMIT_DATE and least(coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR,pat.DISCHARGE_DATE),pat.DISCHARGE_DATE)) or
--   (l.RESULT_DATE    is not null and  l.RESULT_DATE    between pat.ADMIT_DATE and least(coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR,pat.DISCHARGE_DATE),pat.DISCHARGE_DATE)))   
;

create table AKI_LAB_SCR as
select distinct
       to_char(pat.ENCOUNTERID) ONSETS_ENCOUNTERID            	  
      ,l.*
      ,round(l.SPECIMEN_DATE-pat.ADMIT_DATE) DAYS_SINCE_ADMIT
from AKI_onsets pat
join "&&cdm_db_schema".LAB_RESULT_CM l
on pat.PATID = l.PATID and l.LAB_ORDER_DATE between pat.ADMIT_DATE-365 and least(coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR,pat.DISCHARGE_DATE),pat.DISCHARGE_DATE)
--on pat.PATID = l.PATID and
--  ((l.LAB_ORDER_DATE is not null and  l.LAB_ORDER_DATE between pat.ADMIT_DATE-365 and least(coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR,pat.DISCHARGE_DATE),pat.DISCHARGE_DATE)) or
--   (l.SPECIMEN_DATE  is not null and  l.SPECIMEN_DATE  between pat.ADMIT_DATE-365 and least(coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR,pat.DISCHARGE_DATE),pat.DISCHARGE_DATE)) or
--   (l.RESULT_DATE    is not null and  l.RESULT_DATE    between pat.ADMIT_DATE-365 and least(coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR,pat.DISCHARGE_DATE),pat.DISCHARGE_DATE)))   
where l.LAB_LOINC in ('2160-0','38483-4','14682-9','21232-4','35203-9','44784-7','59826-8') and 
      (UPPER(l.RESULT_UNIT) = 'MG/DL' or UPPER(l.RESULT_UNIT) = 'MG') and /*there are variations of common units*/
      l.SPECIMEN_SOURCE <> 'URINE' and  /*only serum creatinine*/
      l.RESULT_NUM > 0 /*value 0 could exist*/
;


/*Prescribing Table*/
create table AKI_PMED as
select distinct
       to_char(pat.ENCOUNTERID) ONSETS_ENCOUNTERID            	  
      ,p.*
      ,least(pat.DISCHARGE_DATE,p.RX_END_DATE) RX_END_DATE_MOD
      ,case when p.RX_DAYS_SUPPLY > 0 and p.RX_QUANTITY is not null then round(p.RX_QUANTITY/p.RX_DAYS_SUPPLY) 
            else null end as RX_QUANTITY_DAILY
      ,round(p.RX_START_DATE-pat.ADMIT_DATE,2) DAYS_SINCE_ADMIT
from AKI_onsets pat
join "&&cdm_db_schema".PRESCRIBING p
on pat.PATID = p.PATID
where p.RXNORM_CUI is not null and
      p.RX_START_DATE is not null and
      p.RX_ORDER_DATE is not null and 
      p.RX_ORDER_DATE between pat.ADMIT_DATE-30 and coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR,pat.DISCHARGE_DATE)
--where p.RXNORM_CUI is not null and
--     ((p.RX_ORDER_DATE is not null and p.RX_ORDER_DATE between pat.ADMIT_DATE-30 and coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR,pat.DISCHARGE_DATE)) or     
--      (p.RX_START_DATE is not null and p.RX_START_DATE between pat.ADMIT_DATE-30 and coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR,pat.DISCHARGE_DATE)) or
--      (p.RX_END_DATE   is not null and p.RX_END_DATE   between pat.ADMIT_DATE-30 and coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR,pat.DISCHARGE_DATE)))      
;

/*Dispensing Table*/
-- Note: for sites don't populate this table, please skip
create table AKI_DMED as
select distinct
       to_char(pat.ENCOUNTERID) ONSETS_ENCOUNTERID            	  
      ,d.*
      ,round(d.DISPENSE_DATE-pat.ADMIT_DATE,2) DAYS_SINCE_ADMIT
from AKI_onsets pat
join "&&cdm_db_schema".DISPENSING d
on pat.PATID = d.PATID
where d.NDC is not null and
      d.DISPENSE_DATE between pat.ADMIT_DATE-30 and coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR,pat.DISCHARGE_DATE)
;

/*Med Admin Table*/
-- Note: for sites don't populate this table, please skip
create table AKI_AMED as
select distinct
       to_char(pat.ENCOUNTERID) ONSETS_ENCOUNTERID            	  
      ,m.*
      ,round(m.MEDADMIN_START_DATE-pat.ADMIT_DATE,2) DAYS_SINCE_ADMIT
from AKI_onsets pat
join "&&cdm_db_schema".MED_ADMIN m
on pat.PATID = m.PATID
where m.MEDADMIN_CODE is not null and
      m.MEDADMIN_START_DATE is not null and
      m.MEDADMIN_STOP_DATE is not null and      
      m.MEDADMIN_START_DATE between pat.ADMIT_DATE-30 and coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR,pat.DISCHARGE_DATE)
;
--where m.MEDADMIN_CODE is not null and
--     ((m.MEDADMIN_START_DATE is not null and m.MEDADMIN_START_DATE between pat.ADMIT_DATE-30 and coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR,pat.DISCHARGE_DATE)) or
--      (m.MEDADMIN_STOP_DATE  is not null and m.MEDADMIN_STOP_DATE  between pat.ADMIT_DATE-30 and coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR,pat.DISCHARGE_DATE)))

-------------------------------------------------------------------------------
/* eyeball several lines and export the following tables as .csv files. Please 
   skip the tables that are not populated. 

 - AKI_onsets
 - consort_diagram_AD
 - consort_diagram_BC
   
 - AKI_DEMO
 - AKI_VITAL
 - AKI_PX
 - AKI_DX
 - AKI_LAB
 - AKI_PMED 
 - AKI_AMED
 - AKI_DMED
 - AKI_DEMO_DEATH
 - AKI_DX_CURRENT
 - AKI_LAB_SCR */
------------------------------------------------------------------------------------