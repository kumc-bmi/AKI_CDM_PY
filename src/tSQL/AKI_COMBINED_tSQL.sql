/*******************************************************************************
 AKI_extract_cohort.sql is used to extract the AKI cohort that satisfies the
 inclusion and exclusion criteria specified at: 
 https://github.com/kumc-bmi/AKI_CDM/blob/master/report/AKI_CDM_EXT_VALID_p1_QA.Rmd
 
 - &&cdm_db_name will be substituted by corresponding database name where CDM data is
 - &&cdm_db_schema will be substituted by corresponding CDM schema
 - Replace it using text editor if the user input prompt does not work in your SQL environment 
 - The intermediate table removal code can be found at the end of the this file (commented out) 
 
********************************************************************************/

/******************************************************************************
 Collect initial cohort:
 - EI, IP, or IS
 - LOS >= 2
 - between &&start_date and Date '2021-12-31'
    - first set &&start_date = '2010-01-01'
	- Replace it using text editor if the user input prompt does not work in your SQL environment
    - if taking too much memory, delay &&start_date
******************************************************************************/
with age_at_admit as (
select e.ENCOUNTERID
      ,e.PATID
      ,convert(datetime,convert(CHAR(8), e.ADMIT_DATE, 112)+ ' ' + CONVERT(CHAR(8), e.ADMIT_TIME, 108)) ADMIT_DATE_TIME
      ,(CONVERT(int,CONVERT(char(8),e.ADMIT_DATE,112))-CONVERT(int,CONVERT(char(8),d.BIRTH_DATE,112)))/10000 AS age_at_admit
      ,convert(datetime,convert(CHAR(8), e.DISCHARGE_DATE, 112)+ ' ' + CONVERT(CHAR(8), e.DISCHARGE_TIME, 108)) DISCHARGE_DATE_TIME
      ,round(datediff(dd,e.ADMIT_DATE,e.DISCHARGE_DATE),0) LOS
      ,e.ENC_TYPE
      ,e.DISCHARGE_DISPOSITION
      ,e.DISCHARGE_STATUS
      ,e.DRG
      ,e.DRG_TYPE
      ,e.ADMITTING_SOURCE
from [&&cdm_db_name].[&&cdm_db_schema].ENCOUNTER e
join [&&cdm_db_name].[&&cdm_db_schema].DEMOGRAPHIC d
on e.PATID = d.PATID
where datediff(dd,e.ADMIT_DATE,e.DISCHARGE_DATE) >= 2 and
      e.ENC_TYPE in ('EI','IP','IS') and
      e.ADMIT_DATE between &&start_date and '2021-12-31'
)

select ENCOUNTERID
      ,PATID
      ,age_at_admit
      ,ADMIT_DATE_TIME
      ,DISCHARGE_DATE_TIME
      ,los
      ,ENC_TYPE
      ,DISCHARGE_DISPOSITION
      ,DISCHARGE_STATUS
      ,DRG
      ,DRG_TYPE
      ,ADMITTING_SOURCE
into #AKI_Initial
from age_at_admit
where age_at_admit >= 18;


/******************************************************************************
 Collect SCr and calculate eGFR for all eligible encounters
******************************************************************************/
with Scr_all as (
select l.PATID
      ,l.ENCOUNTERID
      ,avg(l.RESULT_NUM) RESULT_NUM 
      ,l.LAB_ORDER_DATE
      ,l.SPECIMEN_DATE
      ,l.SPECIMEN_TIME
      ,l.RESULT_DATE
      ,l.RESULT_TIME
from [&&cdm_db_name].[&&cdm_db_schema].LAB_RESULT_CM l
where l.LAB_LOINC in ('2160-0','38483-4','14682-9','21232-4','35203-9','44784-7','59826-8') and 
      UPPER(l.RESULT_UNIT) = 'MG/DL' and
      l.SPECIMEN_SOURCE <> 'URINE' and  /*only serum creatinine*/
      l.RESULT_NUM > 0 and /*value 0 could exist*/
      exists (select 1 from #AKI_Initial init
              where init.PATID = l.PATID)
group by l.PATID,l.ENCOUNTERID,l.LAB_ORDER_DATE,
         l.SPECIMEN_DATE,l.SPECIMEN_TIME,l.RESULT_DATE,l.RESULT_TIME
)
    ,Scr_w_age as (
select distinct
       sa.PATID
      ,sa.ENCOUNTERID
      ,(CONVERT(int,CONVERT(char(8),sa.LAB_ORDER_DATE,112))-CONVERT(int,CONVERT(char(8),d.BIRTH_DATE,112)))/10000 AS age_at_Scr
      ,case when d.SEX = 'F' then 1 else 0 end as female_ind 
      ,case when d.RACE = '03' then 1 else 0 end as race_aa_ind /*03=Black or African American*/
      ,sa.RESULT_NUM
      ,sa.LAB_ORDER_DATE
      ,sa.SPECIMEN_DATE
      ,sa.SPECIMEN_TIME
      ,sa.RESULT_DATE
      ,sa.RESULT_TIME
from Scr_all sa
join [&&cdm_db_name].[&&cdm_db_schema].DEMOGRAPHIC d
on sa.PATID = d.PATID
)
select PATID
      ,ENCOUNTERID
      ,RESULT_NUM SERUM_CREAT
      ,cast(175*round(power(RESULT_NUM,-1.154),2)*round(power(convert(decimal(8,3),age_at_Scr),-0.203),2)*(0.742*female_ind+(1-female_ind))*(1.212*race_aa_ind+(1-race_aa_ind)) as FLOAT) eGFR
      ,LAB_ORDER_DATE
      ,convert(datetime, 
               convert(CHAR(8), SPECIMEN_DATE, 112)+ ' ' + CONVERT(CHAR(8), SPECIMEN_TIME, 108)
               ) SPECIMEN_DATE_TIME
      ,convert(datetime, 
               convert(CHAR(8), RESULT_DATE, 112)+ ' ' + CONVERT(CHAR(8), RESULT_TIME, 108)
               ) RESULT_DATE_TIME
into #All_Scr_eGFR
from Scr_w_age
where age_at_Scr >= 18
;

/******************************************************************************
 Merge labs within the same encounter
******************************************************************************/
with multi_match as (
select scr.*,aki.ADMIT_DATE_TIME
from #All_Scr_eGFR scr
join #AKI_Initial aki 
on scr.ENCOUNTERID = aki.ENCOUNTERID
where scr.LAB_ORDER_DATE between aki.ADMIT_DATE_TIME and aki.DISCHARGE_DATE_TIME
union all
select aki.PATID
      ,aki.ENCOUNTERID
      ,scr.SERUM_CREAT
      ,scr.eGFR
      ,scr.LAB_ORDER_DATE
      ,scr.SPECIMEN_DATE_TIME
      ,scr.RESULT_DATE_TIME
      ,aki.ADMIT_DATE_TIME
from #All_Scr_eGFR scr
join #AKI_Initial aki
on scr.PATID = aki.PATID and scr.ENCOUNTERID <> aki.ENCOUNTERID and
   scr.LAB_ORDER_DATE between aki.ADMIT_DATE_TIME and aki.DISCHARGE_DATE_TIME
)
select distinct
       mm.PATID
      ,mm.ENCOUNTERID
      ,mm.SERUM_CREAT
      ,mm.eGFR
      ,mm.LAB_ORDER_DATE
      ,mm.SPECIMEN_DATE_TIME
      ,mm.RESULT_DATE_TIME
      ,mm.ADMIT_DATE_TIME
      ,dense_rank() over (partition by mm.ENCOUNTERID order by mm.LAB_ORDER_DATE,mm.SPECIMEN_DATE_TIME) rn      
into #AKI_Scr_eGFR
from multi_match mm
;

/******************************************************************************
 Calculate Baseline SCr: first SCr at encounter
******************************************************************************/
--get first record within the encounter
with scr_enc1 as (
select scr.* from #AKI_Scr_eGFR scr
where scr.rn = 1
)
--get all historical Scr records within 2 days prior to encounter
    ,scr_prior as (
select scre1.PATID
      ,scre1.ENCOUNTERID
      ,scr.SERUM_CREAT
      ,scr.eGFR
      ,scr.LAB_ORDER_DATE
      ,scr.SPECIMEN_DATE_TIME
      ,scr.RESULT_DATE_TIME
      ,datediff(dd,scr.LAB_ORDER_DATE,scre1.LAB_ORDER_DATE) days_prior
      ,dense_rank() over (partition by scr.PATID order by abs(datediff(dd,scr.LAB_ORDER_DATE,scre1.LAB_ORDER_DATE))) rn_prior
from scr_enc1 scre1
join #All_Scr_eGFR scr
on scre1.PATID = scr.PATID
where scr.LAB_ORDER_DATE < scre1.LAB_ORDER_DATE and
      datediff(dd,scr.LAB_ORDER_DATE,scre1.LAB_ORDER_DATE)< 2 and -- within 2 days prior
      scre1.LAB_ORDER_DATE > scr.LAB_ORDER_DATE
)
--get the most recent historical Scr if there exists one
    ,scr_prior1 as (
select scrp1.* from scr_prior scrp1
where scrp1.rn_prior = 1
)
--put results together: 
---- if there exist some historical Scr before encounter X, use the most recent value (scr_prior1)
---- otherwise, use the very first record at the encoutner (scr_enc1)
   ,scr_base_dup as (
select distinct 
       s1.PATID
      ,s1.ENCOUNTERID
      ,coalesce(sp.SERUM_CREAT,s1.SERUM_CREAT) SERUM_CREAT
      ,coalesce(sp.eGFR, s1.eGFR) eGFR
      ,coalesce(sp.LAB_ORDER_DATE, s1.LAB_ORDER_DATE) LAB_ORDER_DATE
      ,coalesce(sp.SPECIMEN_DATE_TIME, s1.SPECIMEN_DATE_TIME) SPECIMEN_DATE_TIME
      ,coalesce(sp.RESULT_DATE_TIME, s1.RESULT_DATE_TIME) RESULT_DATE_TIME
      ,sp.days_prior
from scr_enc1 s1 
left join scr_prior1 sp
on s1.ENCOUNTERID = sp.ENCOUNTERID
)
--looks like there exists multiple historical values on the same day 
select scrb.PATID
      ,scrb.ENCOUNTERID
      ,init.ADMIT_DATE_TIME
      ,max(scrb.SERUM_CREAT) SERUM_CREAT
      ,min(scrb.eGFR) eGFR
      ,scrb.LAB_ORDER_DATE
      ,scrb.SPECIMEN_DATE_TIME
      ,scrb.RESULT_DATE_TIME
      ,scrb.days_prior
into #AKI_Scr_base
from scr_base_dup scrb
join #AKI_Initial init
on scrb.ENCOUNTERID = init.ENCOUNTERID
group by scrb.PATID,scrb.ENCOUNTERID,init.ADMIT_DATE_TIME,scrb.LAB_ORDER_DATE,scrb.SPECIMEN_DATE_TIME,scrb.RESULT_DATE_TIME,scrb.days_prior
order by scrb.PATID, scrb.ENCOUNTERID
;

/***************************************************
 Exclusion Criteria 
 ****************************************************/
-- Only one Scr record at encounter
--with AKI_EXCLD_1SCR_EN as (
select ENCOUNTERID, max(rn) lab_cnt 
Into #AKI_EXCLD_1SCR_EN
from #AKI_Scr_eGFR
group by ENCOUNTERID
having max(rn) <= 1
--)
-- update AKI_Initial 
    --,AKI_init as (
select * 
Into #AKI_init
from #AKI_Initial init
where exists (select 1 from #AKI_Scr_eGFR scr2
              where scr2.ENCOUNTERID = init.ENCOUNTERID)
--)
-- At CKD stage 4 or higher
    --,AKI_EXCLD_L1GFR_EN as (
select distinct ENCOUNTERID
Into #AKI_EXCLD_L1GFR_EN
from #AKI_Scr_eGFR
where rn = 1 and eGFR <= 15
--)
-- Pre-existing ESRD or RRT or dialysis (DX)
    --,AKI_EXCLD_PRF_EN as (
select aki.ENCOUNTERID
Into #AKI_EXCLD_PRF_EN_DX
from #AKI_init aki
where exists (select 1
			  from [&&cdm_db_name].[&&cdm_db_schema].DIAGNOSIS dx
              where dx.PATID = aki.PATID
			    and                    
                    (	-- ICD9 for ESRD
						(dx.DX_TYPE = '09' and (dx.DX like '%585.6%')) 
						or
						-- ICD10 for ESRD
						 (dx.DX_TYPE = '10' and (dx.DX like '%N18.6%')) 
						or
						-- ICD9 for RRT or dialysis
						 (dx.DX_TYPE = '09' and (dx.DX like 'V45.1%' or dx.DX like 'V56.%' or dx.DX like 'V42.0%' or dx.DX like '996.81%'))
						or
						-- ICD10 for RRT or dialysis
						 (dx.DX_TYPE = '10' and (dx.DX like 'Z49.31%' or dx.DX like 'Z99.2%' or dx.DX like 'Z94.0%' or dx.DX in ('T86.10', 'T86.11', 'T86.12')))
					)
				  and dx.ADMIT_DATE < CONVERT(date, aki.ADMIT_DATE_TIME))
;				
select aki.ENCOUNTERID
Into #AKI_EXCLD_PRF_EN_PX
from #AKI_init aki
where exists (select 1
			  from [&&cdm_db_name].[&&cdm_db_schema].[PROCEDURES] px
              where px.PATID = aki.PATID 
			    and (
					-- CPT codes for RRT or dialysis
                     (px.PX_TYPE = 'CH' and   
                      (   px.px in ('90935','90937') -- dialysis
                       or px.px like '9094%'
                       or px.px like '9095%'
                       or px.px like '9096%'
                       or px.px like '9097%'
                       or px.px like '9098%'
                       or px.px like '9099%'
                       or px.px in ('50300','50320','50323','50325','50327','50328','50329',
                                    '50340','50360','50365','50370','50380') --RRT
                       )
                      )
					 or
                    -- ICD9 codes for RRT or dialysis
                     (px.PX_TYPE = '09' and
                      (   px.px in ('39.93','39.95','54.98') -- dialysis
                       or px.px in ('55.51','55.52','55.53','55.54','55.61','55.69') --RRT
                       )
                      ) 
					 or
                     -- ICD10 codes for RRT or dialysis
                     (px.PX_TYPE = '10' and
                      (  px.px in ('5A1D00Z','5A1D60Z','5A1D70Z','5A1D80Z','5A1D90Z') -- dialysis
                      or px.px in ('0TY00Z0','0TY00Z1','0TY00Z2','0TY10Z0','0TY10Z1','0TY10Z2',
                                   '0TB00ZZ','0TB10ZZ','0TT00ZZ','0TT10ZZ','0TT20ZZ') -- RRT
                       )
                      )
                     )
				and px.PX_DATE < CONVERT(date, aki.ADMIT_DATE_TIME)
 )
 
select * 
into #AKI_EXCLD_PRF_EN
from #AKI_EXCLD_PRF_EN_PX
union all
select * 
from #AKI_EXCLD_PRF_EN_DX
 
--)
-- Receive renal transplant withing 48 hr since 1st Scr (PX, DX)
    --,scr48 as (
select PATID, ENCOUNTERID, CONVERT(date, ADMIT_DATE_TIME) admit_date,
       dateadd(day,2,SPECIMEN_DATE_TIME) time_bd
Into #scr48
from #AKI_Scr_eGFR
where rn = 1
--)
    --,AKI_EXCLD_RT48_EN as (
select distinct scr48.ENCOUNTERID
Into #AKI_EXCLD_RT48_EN
from #scr48 scr48
where exists (select 1 from [&&cdm_db_name].[&&cdm_db_schema].[PROCEDURES] px
              where px.PATID = scr48.PATID and
                    -- CPT codes for RRT or dialysis
                    (
                     (px.PX_TYPE = 'CH' and   
                      (   px.px in ('90935','90937') -- dialysis
                       or px.px like '9094%'
                       or px.px like '9095%'
                       or px.px like '9096%'
                       or px.px like '9097%'
                       or px.px like '9098%'
                       or px.px like '9099%'
                       or px.px in ('50300','50320','50323','50325','50327','50328','50329',
                                    '50340','50360','50365','50370','50380') --RRT
                       )
                      ) or
                    -- ICD9 codes for RRT or dialysis
                     (px.PX_TYPE = '09' and
                      (   px.px in ('39.93','39.95','54.98') -- dialysis
                       or px.px in ('55.51','55.52','55.53','55.54','55.61','55.69') --RRT
                       )
                      ) or
                     -- ICD10 codes for RRT or dialysis
                     (px.PX_TYPE = '10' and
                      (  px.px in ('5A1D00Z','5A1D60Z','5A1D70Z','5A1D80Z','5A1D90Z') -- dialysis
                      or px.px in ('0TY00Z0','0TY00Z1','0TY00Z2','0TY10Z0','0TY10Z1','0TY10Z2',
                                   '0TB00ZZ','0TB10ZZ','0TT00ZZ','0TT10ZZ','0TT20ZZ') -- RRT
                       )
                      )
                     ) and
                    px.PX_DATE < scr48.time_bd and px.PX_DATE >= scr48.admit_date
              )
--)
-- Burn Patients
   -- ,AKI_EXCLD_BURN_EN as (
select ENCOUNTERID
Into #AKI_EXCLD_BURN_EN
from #AKI_init aki
where exists (select 1 from [&&cdm_db_name].[&&cdm_db_schema].DIAGNOSIS dx
              where dx.PATID = aki.PATID and
                    -- ICD9 for burn patients
                    ((dx.DX_TYPE = '09' and
                      (   dx.DX like '906.5%' 
                       or dx.DX like '906.6%'
                       or dx.DX like '906.7%'
                       or dx.DX like '906.8%'
                       or dx.DX like '906.9%'
                       or dx.DX like '940%'
                       or dx.DX like '941%'
                       or dx.DX like '942%'
                       or dx.DX like '943%'
                       or dx.DX like '944%'
                       or dx.DX like '945%'
                       or dx.DX like '946%'
                       or dx.DX like '947%'
                       or dx.DX like '948%'
                       or dx.DX like '949%')
                      ) or
                    -- ICD10 for burn patients
                     (dx.DX_TYPE = '10' and
                      (   dx.DX like 'T20.%' 
                       or dx.DX like 'T21.%'
                       or dx.DX like 'T22.%'
                       or dx.DX like 'T23.%'
                       or dx.DX like 'T24.%'
                       or dx.DX like 'T25.%'
                       or dx.DX like 'T26.%'
                       or dx.DX like 'T27.%'
                       or dx.DX like 'T28.%'
                       or dx.DX like 'T30.%'
                       or dx.DX like 'T31.%'
                       or dx.DX like 'T32.%')
                       )
                      ) and 
                      dx.ADMIT_DATE = CONVERT(date, aki.ADMIT_DATE_TIME) and
                      dx.DX_SOURCE = 'AD'
                )
--)
-- collect all excluded encounters
SELECT * into #exclude_all FROM (
select ENCOUNTERID, 'Less_than_2_SCr' EXCLUD_TYPE from #AKI_EXCLD_1SCR_EN
union all
select ENCOUNTERID, 'Initial_GFR_below_15' EXCLUD_TYPE from #AKI_EXCLD_L1GFR_EN
union all 
select ENCOUNTERID, 'Pre_renal_failure' EXCLUD_TYPE from #AKI_EXCLD_PRF_EN
union all
select ENCOUNTERID, 'Renal_transplant_within_48hr' EXCLUD_TYPE from #AKI_EXCLD_RT48_EN
union all
select ENCOUNTERID, 'Burn_patients' EXCLUD_TYPE from #AKI_EXCLD_BURN_EN) as tmp
;

/*************************************************
 Finalize the Eligbile Encounters 
 *************************************************/
with exclud_unique as (
select distinct ENCOUNTERID
from #exclude_all
)
--perform exclusion
  ,scr_all as (
select a.PATID
      ,a.ENCOUNTERID
      ,a.SERUM_CREAT
      ,a.EGFR
      ,a.SPECIMEN_DATE_TIME
      ,a.RESULT_DATE_TIME
      ,a.rn
from #AKI_Scr_eGFR a
where not exists (select 1 from exclud_unique e
                  where e.ENCOUNTERID = a.ENCOUNTERID)
)
select scr.PATID
      ,scr.ENCOUNTERID
      ,scrb.ADMIT_DATE_TIME
      ,scrb.SERUM_CREAT SERUM_CREAT_BASE
      ,scrb.SPECIMEN_DATE_TIME SPECIMEN_DATE_TIME_BASE
      ,scrb.RESULT_DATE_TIME RESULT_DATE_TIME_BASE
      ,scr.SERUM_CREAT
      ,scr.EGFR
      ,scr.SPECIMEN_DATE_TIME
      ,scr.RESULT_DATE_TIME
      ,scr.rn
into #AKI_eligible
from scr_all scr
join #AKI_Scr_base scrb
on scr.ENCOUNTERID = scrb.ENCOUNTERID
order by scr.PATID, scr.ENCOUNTERID, scr.rn
;

/******************************************************************************
 AKI Staging
******************************************************************************/
--with with aki3_rrt as (
-- identify 3-stage AKI based on existence of RRT
select akie.PATID
      ,akie.ENCOUNTERID
      ,akie.ADMIT_DATE_TIME
      ,akie.SERUM_CREAT_BASE
      ,akie.SPECIMEN_DATE_TIME_BASE
      ,min(px.PX_DATE) SPECIMEN_DATE_TIME
Into #aki3_rrt
from #AKI_eligible akie
join [&&cdm_db_name].&&cdm_db_schema.[PROCEDURES] px
on px.PATID = akie.PATID and
   (
    (px.PX_TYPE = 'CH' and 
    (   px.px in ('50300','50320','50323','50325','50327','50328','50329',
                  '50340','50360','50365','50370','50380') --RRT
     )
    ) or
   -- ICD9 codes for RRT
   (px.PX_TYPE = '09' and
   (   px.px in ('55.51','55.52','55.53','55.54','55.61','55.69') --RRT
     )
    ) or
   -- ICD10 codes for RRT
   (px.PX_TYPE = '10' and
   (  px.px in ('0TY00Z0','0TY00Z1','0TY00Z2','0TY10Z0','0TY10Z1','0TY10Z2',
                '0TB00ZZ','0TB10ZZ','0TT00ZZ','0TT10ZZ','0TT20ZZ') -- RRT
      )
    )
  )
group by akie.PATID,akie.ENCOUNTERID,akie.ADMIT_DATE_TIME,akie.SERUM_CREAT_BASE,akie.SPECIMEN_DATE_TIME_BASE
--)
     --,stage_aki as (
-- a semi-cartesian join to identify all eligible 1-, 3-stages w.r.t rolling basezline
-- REMOVED Criteria
select distinct
       s1.PATID
      ,s1.ENCOUNTERID
      ,s1.ADMIT_DATE_TIME
      ,s1.SERUM_CREAT_BASE
      ,s1.SERUM_CREAT SERUM_CREAT_RBASE
      ,s2.SERUM_CREAT
      ,s2.SERUM_CREAT - s1.SERUM_CREAT SERUM_CREAT_INC
--      ,case when s2.SERUM_CREAT - s1.SERUM_CREAT >= 0.3 then 1
--            when s2.SERUM_CREAT > 4.0 then 3
--            else 0
--       end as AKI_STAGE
      ,0 AKI_STAGE
      ,s2.SPECIMEN_DATE_TIME
      ,s2.RESULT_DATE_TIME
Into #stage_aki
from #AKI_eligible s1
join #AKI_eligible s2
on s1.ENCOUNTERID = s2.ENCOUNTERID
--restrict s2 to be strictly after s1 and before s1+2d
where datediff(dd,s1.SPECIMEN_DATE_TIME,s2.SPECIMEN_DATE_TIME)<= 2 and
      s2.SPECIMEN_DATE_TIME > s1.SPECIMEN_DATE_TIME
union all
-- only compare to baseline (baseline before admission)
select distinct 
       PATID
      ,ENCOUNTERID
      ,ADMIT_DATE_TIME
      ,SERUM_CREAT_BASE
      ,null SERUM_CREAT_RBASE
      ,SERUM_CREAT
      ,round(SERUM_CREAT/SERUM_CREAT_BASE,1) SERUM_CREAT_INC
      ,case when round(SERUM_CREAT/SERUM_CREAT_BASE,1) between 1.5 and 1.9 then 1
            when round(SERUM_CREAT/SERUM_CREAT_BASE,1) between 2.0 and 2.9 then 2
            when round(SERUM_CREAT/SERUM_CREAT_BASE,1) >= 3 then 3
            else 0
       end as AKI_STAGE
      ,SPECIMEN_DATE_TIME
      ,RESULT_DATE_TIME
from #AKI_eligible
where SPECIMEN_DATE_TIME_BASE < ADMIT_DATE_TIME and
      datediff(dd,ADMIT_DATE_TIME,SPECIMEN_DATE_TIME)<= 7 and
      SPECIMEN_DATE_TIME > ADMIT_DATE_TIME
union all
-- only compare to baseline (baseline after or on admission)
select distinct 
       PATID
      ,ENCOUNTERID
      ,ADMIT_DATE_TIME
      ,SERUM_CREAT_BASE
      ,null SERUM_CREAT_RBASE
      ,SERUM_CREAT
      ,round(SERUM_CREAT/SERUM_CREAT_BASE,1) SERUM_CREAT_INC
      ,case when round(SERUM_CREAT/SERUM_CREAT_BASE,1) between 1.5 and 1.9 then 1
            when round(SERUM_CREAT/SERUM_CREAT_BASE,1) between 2.0 and 2.9 then 2
            when round(SERUM_CREAT/SERUM_CREAT_BASE,1) >= 3 then 3
            else 0
       end as AKI_STAGE
      ,SPECIMEN_DATE_TIME
      ,RESULT_DATE_TIME
from #AKI_eligible  
where SPECIMEN_DATE_TIME_BASE < ADMIT_DATE_TIME and
      datediff(dd,ADMIT_DATE_TIME,SPECIMEN_DATE_TIME)<= 7 and
      SPECIMEN_DATE_TIME > ADMIT_DATE_TIME
--)
   --,AKI_stages as (
select PATID
      ,ENCOUNTERID
      ,ADMIT_DATE_TIME
      ,SERUM_CREAT_BASE
      ,SERUM_CREAT_RBASE
      ,SERUM_CREAT
      ,SERUM_CREAT_INC
      ,AKI_STAGE
      ,SPECIMEN_DATE_TIME
      ,datediff(hour,ADMIT_DATE_TIME,SPECIMEN_DATE_TIME) HOUR_SINCE_ADMIT
      ,datediff(dd,ADMIT_DATE_TIME,SPECIMEN_DATE_TIME) DAY_SINCE_ADMIT
      ,dense_rank() over (partition by PATID, ENCOUNTERID, datediff(dd,ADMIT_DATE_TIME,SPECIMEN_DATE_TIME)
                          order by datediff(dd,ADMIT_DATE_TIME,SPECIMEN_DATE_TIME) asc,
                                   AKI_STAGE desc, SERUM_CREAT desc, SERUM_CREAT_INC desc) rn_day
Into #AKI_stages
from #stage_aki
--)
  --,stage_uni as (
select distinct 
       PATID
      ,ENCOUNTERID
      ,ADMIT_DATE_TIME
      ,SERUM_CREAT_BASE
      ,SERUM_CREAT_RBASE
      ,SERUM_CREAT
      ,SERUM_CREAT_INC
      ,AKI_STAGE
      ,SPECIMEN_DATE_TIME
      ,DAY_SINCE_ADMIT
Into #stage_uni
from #AKI_stages
where rn_day = 1
--)
select PATID
      ,ENCOUNTERID
      ,ADMIT_DATE_TIME
      ,SERUM_CREAT_BASE
      ,SERUM_CREAT_RBASE
      ,SERUM_CREAT
      ,SERUM_CREAT_INC
      ,AKI_STAGE
      ,CONVERT(DATETIME, CONVERT(DATE, SPECIMEN_DATE_TIME)) SPECIMEN_DATE
      ,DAY_SINCE_ADMIT
      ,row_number() over (partition by ENCOUNTERID, AKI_STAGE order by DAY_SINCE_ADMIT) rn_asc
      ,row_number() over (partition by ENCOUNTERID, AKI_STAGE order by DAY_SINCE_ADMIT desc) rn_desc
      ,max(AKI_STAGE) over (partition by ENCOUNTERID) AKI_STAGE_max
into #AKI_stages_daily
from #stage_uni
order by PATID, ENCOUNTERID, AKI_STAGE, SPECIMEN_DATE
;

with pat_enc as (
select distinct 
       cast(PATID as integer) PATID
      ,cast(ENCOUNTERID as integer) ENCOUNTERID
      ,CONVERT(DATETIME, CONVERT(DATE, ADMIT_DATE_TIME)) ADMIT_DATE
      ,SERUM_CREAT_BASE
from #AKI_stages_daily
)
   ,onsets as (
select ENCOUNTERID, [0] as NONAKI_ANCHOR, [1] as AKI1_ONSET, [2] as AKI2_ONSET, [3] as AKI3_ONSET from
(select ENCOUNTERID
       ,AKI_STAGE
       ,SPECIMEN_DATE
 from #AKI_stages_daily
 where rn_asc = 1 and AKI_STAGE_max > 0 and AKI_STAGE > 0
 union all
 select ENCOUNTERID
       ,AKI_STAGE
       ,SPECIMEN_DATE
 from #AKI_stages_daily
 where rn_desc = 1 and AKI_STAGE_max = 0 and AKI_STAGE = 0
 )as s1
pivot 
(min(SPECIMEN_DATE)
 for AKI_STAGE in ([0] ,
                   [1] ,
                   [2] ,
                   [3] )
 ) as pvt1
)
   ,ONSETS_val as (
select ENCOUNTERID, [0] as NON_AKI_SCR, [1] as AKI1_SCR, [2] as AKI2_SCR, [3] as AKI3_SCR from
(select ENCOUNTERID
       ,AKI_STAGE
       ,SERUM_CREAT
 from #AKI_stages_daily
 where rn_asc = 1 and AKI_STAGE_max > 0 and AKI_STAGE > 0
 union all
 select ENCOUNTERID
       ,AKI_STAGE
       ,SERUM_CREAT
 from #AKI_stages_daily
 where rn_desc = 1 and AKI_STAGE_max = 0 and AKI_STAGE = 0) as s2
pivot 
(max(SERUM_CREAT)
 for AKI_STAGE in ([0] ,
                   [1] ,
                   [2] ,
                   [3] )
 ) as pvt2
)
   ,ONSETS_inc as (
select ENCOUNTERID, [0] as NON_AKI_INC, [1] as AKI1_INC, [2] as AKI2_INC, [3] as AKI3_INC from
(select ENCOUNTERID
       ,AKI_STAGE
       ,SERUM_CREAT_INC
 from #AKI_stages_daily
 where rn_asc = 1 and AKI_STAGE_max > 0 and AKI_STAGE > 0
 union all
 select ENCOUNTERID
       ,AKI_STAGE
       ,SERUM_CREAT_INC
 from #AKI_stages_daily
 where rn_desc = 1 and AKI_STAGE_max = 0 and AKI_STAGE = 0) as s3
pivot 
(max(SERUM_CREAT_INC)
 for AKI_STAGE in ([0],
                   [1],
                   [2],
                   [3])
 ) as pvt3
)
   ,raw_onset as (
select pe.PATID
      ,pe.ENCOUNTERID
      ,pe.ADMIT_DATE
      ,CONVERT(DATETIME, CONVERT(DATE,init.DISCHARGE_DATE_TIME)) DISCHARGE_DATE
      ,pe.SERUM_CREAT_BASE
      ,ons.NONAKI_ANCHOR
      ,datediff(dd,pe.ADMIT_DATE,ons.NONAKI_ANCHOR) NONAKI_SINCE_ADMIT
      ,NON_AKI_SCR
      ,NON_AKI_INC
      ,ons.AKI1_ONSET
      ,datediff(dd,pe.ADMIT_DATE,ons.AKI1_ONSET) AKI1_SINCE_ADMIT
      ,scr.AKI1_SCR
      ,inc.AKI1_INC
      ,ons.AKI2_ONSET
      ,datediff(dd,pe.ADMIT_DATE,ons.AKI2_ONSET) AKI2_SINCE_ADMIT
      ,scr.AKI2_SCR
      ,inc.AKI2_INC
      ,ons.AKI3_ONSET
      ,datediff(dd,pe.ADMIT_DATE,ons.AKI3_ONSET) AKI3_SINCE_ADMIT
      ,scr.AKI3_SCR
      ,inc.AKI3_INC
from pat_enc pe
join #AKI_Initial init
on pe.ENCOUNTERID = init.ENCOUNTERID
left join onsets ons
on pe.ENCOUNTERID = ons.ENCOUNTERID
left join ONSETS_val scr
on pe.ENCOUNTERID = scr.ENCOUNTERID
left join ONSETS_inc inc
on pe.ENCOUNTERID = inc.ENCOUNTERID
)
-- some pruning (recovering progress doesn't count)
select distinct
       PATID
      ,ENCOUNTERID
      ,ADMIT_DATE
      ,DISCHARGE_DATE
      ,SERUM_CREAT_BASE
      ,NONAKI_ANCHOR
      ,NONAKI_SINCE_ADMIT
      ,NON_AKI_SCR
      ,NON_AKI_INC
      ,case when AKI1_SINCE_ADMIT >= AKI2_SINCE_ADMIT or AKI1_SINCE_ADMIT >= AKI3_SINCE_ADMIT then null
            else AKI1_ONSET end as AKI1_ONSET
      ,case when AKI1_SINCE_ADMIT >= AKI2_SINCE_ADMIT or AKI1_SINCE_ADMIT >= AKI3_SINCE_ADMIT then null
            else AKI1_SINCE_ADMIT end as AKI1_SINCE_ADMIT
      ,case when AKI1_SINCE_ADMIT >= AKI2_SINCE_ADMIT or AKI1_SINCE_ADMIT >= AKI3_SINCE_ADMIT then null 
            else AKI1_SCR end as AKI1_SCR
      ,case when AKI1_SINCE_ADMIT >= AKI2_SINCE_ADMIT or AKI1_SINCE_ADMIT >= AKI3_SINCE_ADMIT then null
            else AKI1_INC end as AKI1_INC
      ,case when AKI2_SINCE_ADMIT >= AKI3_SINCE_ADMIT then null 
            else AKI2_ONSET end as AKI2_ONSET
      ,case when AKI2_SINCE_ADMIT >= AKI3_SINCE_ADMIT then null 
            else AKI2_SINCE_ADMIT end as AKI2_SINCE_ADMIT
      ,case when AKI2_SINCE_ADMIT >= AKI3_SINCE_ADMIT then null 
            else AKI2_SCR end as AKI2_SCR
      ,case when AKI2_SINCE_ADMIT >= AKI3_SINCE_ADMIT then null 
            else AKI2_INC end as AKI2_INC
	  ,case when ADMIT_DATE <= '2019-12-31' then 1
            else 0 end as BCCOVID			
      ,AKI3_ONSET
      ,AKI3_SINCE_ADMIT
      ,AKI3_SCR
      ,AKI3_INC
into #AKI_onsets
from raw_onset
order by PATID, ENCOUNTERID
;


/*************************
 Consort Diagram
***************************/
select x.*
into #consort_diagram_bc
from (
 select 'Initial' CNT_TYPE,
        count(distinct encounterid) ENC_CNT
 from #AKI_Initial
 where ADMIT_DATE_TIME <= '2019-12-31'
 union all
 select 'Has_at_least_1_SCr' CNT_TYPE,
        count(distinct a.encounterid) ENC_CNT
 from #AKI_Scr_eGFR a
 left join #AKI_Initial b
 on a.encounterid = b.encounterid
 where b.ADMIT_DATE_TIME <= '2019-12-31'
 union all
 select exclud_type CNT_TYPE,
        count(distinct a.encounterid) ENC_CNT
 from #exclude_all a
 left join #AKI_Initial b
 on a.encounterid = b.encounterid
 where b.ADMIT_DATE_TIME <= '2019-12-31' 
 group by a.exclud_type
 union all
 select 'Total' CNT_TYPE,
        count(distinct encounterid) ENC_CNT
 from #AKI_onsets
 where BCCOVID = 1 
 union all
 select 'nonAKI' CNT_TYPE,
        count(distinct encounterid) ENC_CNT
 from #AKI_onsets
 where AKI1_onset is null and
       AKI2_onset is null and
       AKI3_onset is null and
	   BCCOVID = 1
 union all
 select 'AKI1' CNT_TYPE,
        count(distinct encounterid) ENC_CNT
 from #AKI_onsets
 where AKI1_onset is not null and
       BCCOVID = 1
 union all
 select 'nonAKI_to_AKI2' CNT_TYPE,
        count(distinct encounterid) ENC_CNT
 from #AKI_onsets
 where AKI1_onset is null and
       AKI2_onset is not null and
       BCCOVID = 1
 union all
 select 'AKI1_to_AKI2' CNT_TYPE,
        count(distinct encounterid) ENC_CNT
 from #AKI_onsets
 where AKI1_onset is not null and
       AKI2_onset is not null and
       BCCOVID = 1	   
 union all
 select 'nonAKI_to_AKI3' CNT_TYPE,
        count(distinct encounterid) ENC_CNT
 from #AKI_onsets
 where AKI1_onset is null and
       AKI2_onset is null and
       AKI3_onset is not null and
       BCCOVID = 1	   
 union all
 select 'nonAKI_to_AKI2_to_AKI3' CNT_TYPE,
        count(distinct encounterid) ENC_CNT
 from #AKI_onsets
 where AKI1_onset is null and
       AKI2_onset is not null and
       AKI3_onset is not null and
       BCCOVID = 1   
 union all
 select 'AKI1_to_AKI2_to_AKI3' CNT_TYPE,
        count(distinct encounterid) ENC_CNT
 from #AKI_onsets
 where AKI1_onset is not null and
       AKI2_onset is not null and
       AKI3_onset is not null and
       BCCOVID = 1	   
) x;

select x.*
into #consort_diagram_ad
from (
 select 'Initial' CNT_TYPE,
        count(distinct encounterid) ENC_CNT
 from #AKI_Initial
 where ADMIT_DATE_TIME > '2019-12-31'
 union all
 select 'Has_at_least_1_SCr' CNT_TYPE,
        count(distinct a.encounterid) ENC_CNT
 from #AKI_Scr_eGFR a
 left join #AKI_Initial b
 on a.encounterid = b.encounterid
 where b.ADMIT_DATE_TIME > '2019-12-31'
 union all
 select exclud_type CNT_TYPE,
        count(distinct a.encounterid) ENC_CNT
 from #exclude_all a
 left join #AKI_Initial b
 on a.encounterid = b.encounterid
 where b.ADMIT_DATE_TIME > '2019-12-31' 
 group by a.exclud_type
 union all
 select 'Total' CNT_TYPE,
        count(distinct encounterid) ENC_CNT
 from #AKI_onsets
 where BCCOVID = 0
 union all
 select 'nonAKI' CNT_TYPE,
        count(distinct encounterid) ENC_CNT
 from #AKI_onsets
 where AKI1_onset is null and
       AKI2_onset is null and
       AKI3_onset is null and
       BCCOVID = 0 
 union all
 select 'AKI1' CNT_TYPE,
        count(distinct encounterid) ENC_CNT
 from #AKI_onsets
 where AKI1_onset is not null and
       BCCOVID = 0 
 union all
 select 'nonAKI_to_AKI2' CNT_TYPE,
        count(distinct encounterid) ENC_CNT
 from #AKI_onsets
 where AKI1_onset is null and
       AKI2_onset is not null and
       BCCOVID = 0 
 union all
 select 'AKI1_to_AKI2' CNT_TYPE,
        count(distinct encounterid) ENC_CNT
 from #AKI_onsets
 where AKI1_onset is not null and
       AKI2_onset is not null and
       BCCOVID = 0 
 union all
 select 'nonAKI_to_AKI3' CNT_TYPE,
        count(distinct encounterid) ENC_CNT
 from #AKI_onsets
 where AKI1_onset is null and
       AKI2_onset is null and
       AKI3_onset is not null and
       BCCOVID = 0 
 union all
 select 'nonAKI_to_AKI2_to_AKI3' CNT_TYPE,
        count(distinct encounterid) ENC_CNT
 from #AKI_onsets
 where AKI1_onset is null and
       AKI2_onset is not null and
       AKI3_onset is not null and
       BCCOVID = 0 
 union all
 select 'AKI1_to_AKI2_to_AKI3' CNT_TYPE,
        count(distinct encounterid) ENC_CNT
 from #AKI_onsets
 where AKI1_onset is not null and
       AKI2_onset is not null and
       AKI3_onset is not null and
       BCCOVID = 0 
) x;

-- Select * From #consort_diagram
--------------------------------------------------------------------------------------------
/*export the following tables:
 - AKI_onsets (Note: don't drop this table until the AKI_collect_data.sql is successfully run)
 - consort_diagram_ad
 - consort_diagram_bc
    - send consort_diagram to KUMC for an initial diagnostic
    - upon approval, drop the following intermediate tables and run AKI_collect_data.sql
*/
--------------------------------------------------------------------------------------------

/*drop the following intermediate tables when `AKI_onsets` table looks ok*/
--drop table if exsits AKI3_RRT;
--drop table if exsits AKI_ELIGIBLE;
--drop table if exsits AKI_EXCLD_BURN_EN;
--drop table if exsits AKI_EXCLD_L1GFR_EN;
--drop table if exsits AKI_EXCLD_PRF_EN;
--drop table if exsits AKI_EXCLD_PRRT_EN;
--drop table if exsits AKI_EXCLD_PRRT_EN_DX;
--drop table if exsits AKI_EXCLD_PRRT_EN_PX;
--drop table if exsits AKI_EXCLD_RT48_EN;
--drop table if exsits AKI_INIT;
--drop table if exsits AKI_Initial;
--drop table if exsits AKI_Scr_base;
--drop table if exsits AKI_Scr_eGFR;
--drop table if exsits AKI_STAGES;
--drop table if exsits AKI_STAGES_DAILY;
--drop table if exsits All_Scr_eGFR;
--drop table if exsits EXCLUDE_ALL;
--drop table if exsits SCR48;
--drop table if exsits STAGE_AKI;
--drop table if exsits STAGE_UNI;
/*******************************************************************************
 AKI_collect_data.sql is used to collect all relavent clinical observations for
 the AKI cohort collected in AKI_onsets. More details can be found 
 at: https://github.com/kumc-bmi/AKI_CDM
 
 - &&cdm_db_name will be substituted by corresponding database name where CDM data is
 - &&cdm_db_schema will be substituted by corresponding CDM schema
********************************************************************************/

/*Demographic Table*/

select distinct
       pat.ENCOUNTERID as ONSETS_ENCOUNTERID            	  	
      ,dth.*
      ,datediff(dd,pat.DISCHARGE_DATE,dth.DEATH_DATE) DDAYS_SINCE_ENC
into #AKI_DEMO_DEATH
from #AKI_onsets pat
left join [&&cdm_db_name].[&&cdm_db_schema].DEATH dth
on pat.PATID = dth.PATID
;

select distinct
       pat.ENCOUNTERID as ONSETS_ENCOUNTERID            	  	
      ,demo.*
      ,case when (CONVERT(int,CONVERT(char(8),pat.ADMIT_DATE,112))-CONVERT(int,CONVERT(char(8),demo.BIRTH_DATE,112)))/10000 > 89 then 90
	       else (CONVERT(int,CONVERT(char(8),pat.ADMIT_DATE,112))-CONVERT(int,CONVERT(char(8),demo.BIRTH_DATE,112)))/10000 end as AGE
      ,dth.DEATH_DATE
      ,datediff(dd,pat.DISCHARGE_DATE,dth.DEATH_DATE) DDAYS_SINCE_ENC
      ,dth.DEATH_DATE_IMPUTE
      ,dth.DEATH_SOURCE
into #AKI_DEMO
from #AKI_onsets pat
left join [&&cdm_db_name].[&&cdm_db_schema].DEMOGRAPHIC demo
on pat.PATID = demo.PATID
left join [&&cdm_db_name].[&&cdm_db_schema].DEATH dth
on pat.PATID = dth.PATID
--order by pat.PATID, pat.ENCOUNTERID
;

/*Vital Table*/
-- Depend on CDM version, only one of the AKI_VITAL or AKI_VITAL_OLD table will populate
-- If your database is in v6.1 and AKI_VITAL is empty, please check modify the filter condition to corresponding code used in your site
-- We intend to collect 'SYSTOLIC','HT','SMOKING','TOBACCO_TYPE','TOBACCO','DIASTOLIC','ORIGINAL_BMI','WT' as in vital table in v6.0
select
      --,v.VITALID
       pat.ENCOUNTERID as ONSETS_ENCOUNTERID            	  		  
      ,v.*
--      ,case when v.SMOKING = 'NI' then null else v.SMOKING end as SMOKING
--      ,case when v.TOBACCO = 'NI' then null else v.TOBACCO end as TOBACCO
--      ,case when v.TOBACCO_TYPE = 'NI' then null else v.TOBACCO_TYPE end as TOBACCO_TYPE
      ,datediff(dd,pat.ADMIT_DATE,v.obsclin_start_date) DAYS_SINCE_ADMIT
into #AKI_VITAL
from #AKI_onsets pat
left join [&&cdm_db_name].[&&cdm_db_schema].obs_clin v
on pat.PATID = v.PATID
where v.obsclin_start_date between dateadd(day,-30,pat.ADMIT_DATE) and dateadd(day,1,(case when coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR) > pat.DISCHARGE_DATE then coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR) else pat.DISCHARGE_DATE end))
and 
(v.OBSCLIN_CODE in ('8480-6','8459-0','8460-8','8461-6','75997-7','8462-4','8453-3','8454-1','8455-8','75995-1','3137-7','8302-2','8308-9','3138-5','3141-9','29463-7','8335-2','3142-7','8341-0','8340-2','39156-5','89270-3','722499006','11366-2','11367-0','39240-7','39243-1','63608-4','63638-1','64234-8','67741-9','72166-2','74010-0','74011-8','81229-7','82769-1','8663-7','8664-5','88029-4','88030-2','88031-0','95494-1','95529-4','96101-1','96103-7')
or
v.OBSCLIN_CODE in ('SYSTOLIC','HT','SMOKING','TOBACCO_TYPE','TOBACCO','DIASTOLIC','ORIGINAL_BMI','WT')
) 

--      coalesce(v.HT, v.WT, v.SYSTOLIC, v.DIASTOLIC, v.ORIGINAL_BMI) is not null
--order by PATID, ENCOUNTERID, MEASURE_DATE_TIME
;

select
      --,v.VITALID
       pat.ENCOUNTERID as ONSETS_ENCOUNTERID
      ,v.*
--      ,case when v.SMOKING = 'NI' then null else v.SMOKING end as SMOKING
--      ,case when v.TOBACCO = 'NI' then null else v.TOBACCO end as TOBACCO
--      ,case when v.TOBACCO_TYPE = 'NI' then null else v.TOBACCO_TYPE end as TOBACCO_TYPE
      ,datediff(dd,pat.ADMIT_DATE,v.MEASURE_DATE) DAYS_SINCE_ADMIT
into #AKI_VITAL_OLD
from #AKI_onsets pat
left join [&&cdm_db_name].[&&cdm_db_schema].vital v
on pat.PATID = v.PATID
where v.MEASURE_DATE between dateadd(day,-30,pat.ADMIT_DATE) and dateadd(day,1,(case when coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR) > pat.DISCHARGE_DATE then coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR) else pat.DISCHARGE_DATE end))
--      coalesce(v.HT, v.WT, v.SYSTOLIC, v.DIASTOLIC, v.ORIGINAL_BMI) is not null
--order by PATID, ENCOUNTERID, MEASURE_DATE_TIME
;


/*Procedure Table*/
select distinct
       pat.ENCOUNTERID as ONSETS_ENCOUNTERID            	  	
      ,px.*
      ,datediff(dd,pat.ADMIT_DATE,px.PX_DATE) DAYS_SINCE_ADMIT
into #AKI_PX
from #AKI_onsets pat
left join [&&cdm_db_name].[&&cdm_db_schema].[PROCEDURES] px
on pat.PATID = px.PATID
where px.PX_DATE between pat.ADMIT_DATE and dateadd(day,1,(case when coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR) > pat.DISCHARGE_DATE then coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR) else pat.DISCHARGE_DATE end))
--order by pat.PATID, pat.ENCOUNTERID, px.PX_DATE desc


/*Diagnoses Table (historic)*/
select
       pat.ENCOUNTERID as ONSETS_ENCOUNTERID            	  	
      ,dx.*
      ,datediff(dd,pat.ADMIT_DATE,dx.ADMIT_DATE) as DAYS_SINCE_ADMIT
into #AKI_DX
from #AKI_onsets pat
join [&&cdm_db_name].[&&cdm_db_schema].DIAGNOSIS dx
on pat.PATID = dx.PATID
where datediff(dd,dx.ADMIT_DATE,pat.ADMIT_DATE) between 1 and 365
--order by pat.PATID, pat.ENCOUNTERID, dx.ADMIT_DATE desc

select
       pat.ENCOUNTERID as ONSETS_ENCOUNTERID            	  	
      ,dx.*
      ,datediff(dd,pat.ADMIT_DATE,dx.DX_DATE) as DAYS_SINCE_ADMIT
into #AKI_DX_CURRENT
from #AKI_onsets pat
join [&&cdm_db_name].[&&cdm_db_schema].DIAGNOSIS dx
on pat.PATID = dx.PATID
where dx.DX_DATE between pat.ADMIT_DATE and dateadd(day,1,(case when coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR) > pat.DISCHARGE_DATE then coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR) else pat.DISCHARGE_DATE end))

--order by pat.PATID, pat.ENCOUNTERID, dx.ADMIT_DATE desc

select
       pat.ENCOUNTERID as ONSETS_ENCOUNTERID            	  	
      ,dx.*
      ,datediff(dd,pat.ADMIT_DATE,dx.ADMIT_DATE) as DAYS_SINCE_ADMIT
into #AKI_DX_CURRENT_ADMIT_DATE
from #AKI_onsets pat
join [&&cdm_db_name].[&&cdm_db_schema].DIAGNOSIS dx
on pat.PATID = dx.PATID
where dx.ADMIT_DATE between pat.ADMIT_DATE and dateadd(day,1,(case when coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR) > pat.DISCHARGE_DATE then coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR) else pat.DISCHARGE_DATE end))

/*Lab Table*/
select distinct
       pat.ENCOUNTERID as ONSETS_ENCOUNTERID            	  	
      ,l.*
      ,datediff(dd,pat.ADMIT_DATE,l.SPECIMEN_DATE) DAYS_SINCE_ADMIT
into #AKI_LAB
from #AKI_onsets pat
join [&&cdm_db_name].[&&cdm_db_schema].LAB_RESULT_CM l
on pat.PATID = l.PATID and l.LAB_ORDER_DATE between pat.ADMIT_DATE and dateadd(day,1,(case when coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR) > pat.DISCHARGE_DATE then coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR) else pat.DISCHARGE_DATE end))
--order by pat.PATID, pat.ENCOUNTERID, SPECIMEN_DATE_TIME
;

select distinct
       pat.ENCOUNTERID as ONSETS_ENCOUNTERID            	  	
      ,l.*
      ,datediff(dd,pat.ADMIT_DATE,l.SPECIMEN_DATE) DAYS_SINCE_ADMIT
into #AKI_LAB_SCR
from #AKI_onsets pat
join [&&cdm_db_name].[&&cdm_db_schema].LAB_RESULT_CM l
on pat.PATID = l.PATID and l.LAB_ORDER_DATE between dateadd(day,-365,pat.ADMIT_DATE)
and dateadd(day,1,(case when coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR) > pat.DISCHARGE_DATE then coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR) else pat.DISCHARGE_DATE end))
where l.LAB_LOINC in ('2160-0','38483-4','14682-9','21232-4','35203-9','44784-7','59826-8') and 
      UPPER(l.RESULT_UNIT) = 'MG/DL' and
      l.SPECIMEN_SOURCE <> 'URINE' and  /*only serum creatinine*/
      l.RESULT_NUM > 0 /*value 0 could exist*/ 
--order by pat.PATID, pat.ENCOUNTERID, SPECIMEN_DATE_TIME
;
-- and coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR,pat.DISCHARGE_DATE)


/*Prescribing Table*/
select distinct
       pat.ENCOUNTERID as ONSETS_ENCOUNTERID            	  	
      ,p.*
      ,case when pat.DISCHARGE_DATE < p.RX_END_DATE THEN convert(CHAR(8), pat.DISCHARGE_DATE, 112)
            else convert(CHAR(8), p.RX_END_DATE , 112)
       end as RX_END_DATE_MOD	   
      ,case when p.RX_DAYS_SUPPLY is not null and p.RX_DAYS_SUPPLY is not null then round(p.RX_QUANTITY/p.RX_DAYS_SUPPLY,0) 
            else null 
	     end as RX_QUANTITY_DAILY
      ,datediff(dd,pat.ADMIT_DATE,p.RX_START_DATE) DAYS_SINCE_ADMIT
into #AKI_PMED
from #AKI_onsets pat
join [&&cdm_db_name].[&&cdm_db_schema].PRESCRIBING p
on pat.PATID = p.PATID
where p.RXNORM_CUI is not null and 
      p.RX_START_DATE is not null and 
      p.RX_ORDER_DATE is not null and 
      p.RX_ORDER_TIME is not null and
      p.RX_ORDER_DATE between dateadd(day,-30,pat.ADMIT_DATE) and dateadd(day,1,(case when coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR) > pat.DISCHARGE_DATE then coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR) else pat.DISCHARGE_DATE end))
--order by PATID, ENCOUNTERID, RXNORM_CUI, RX_START_DATE
;

/*Dispensing Table*/
-- Note: for sites don't populate this table, please skip
select distinct
       pat.ENCOUNTERID as ONSETS_ENCOUNTERID            	  	
      ,d.*
      ,datediff(dd,pat.ADMIT_DATE,d.DISPENSE_DATE) DAYS_SINCE_ADMIT
into #AKI_DMED
from #AKI_onsets pat
join [&&cdm_db_name].[&&cdm_db_schema].DISPENSING d
on pat.PATID = d.PATID
where d.NDC is not null and
      d.DISPENSE_DATE between dateadd(day,-30,pat.ADMIT_DATE) and dateadd(day,1,(case when coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR) > pat.DISCHARGE_DATE then coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR) else pat.DISCHARGE_DATE end))
;


/*Med Admin Table*/
-- Note: for sites don't populate this table, please skip
select distinct
       pat.ENCOUNTERID as ONSETS_ENCOUNTERID            	  	
      ,m.*
      ,datediff(dd,pat.ADMIT_DATE,m.MEDADMIN_START_DATE) DAYS_SINCE_ADMIT
into #AKI_AMED
from #AKI_onsets pat
join [&&cdm_db_name].[&&cdm_db_schema].MED_ADMIN m
on pat.PATID = m.PATID
where m.MEDADMIN_CODE is not null and
      m.MEDADMIN_START_DATE is not null and
      --m.MEDADMIN_START_TIME is not null and 
      m.MEDADMIN_STOP_DATE is not null and
      --m.MEDADMIN_STOP_TIME is null and
      m.MEDADMIN_START_DATE between dateadd(day,-30,pat.ADMIT_DATE) and dateadd(day,1,(case when coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR) > pat.DISCHARGE_DATE then coalesce(pat.AKI3_ONSET,pat.AKI2_ONSET,pat.AKI1_ONSET,pat.NONAKI_ANCHOR) else pat.DISCHARGE_DATE end))
;

-------------------------------------------------------------------------------
/* Eyeball several lines and export the following tables as .csv files. Please 
   skip the tables that are not populated. 

Select * From #AKI_ONSETS
Select * From #consort_diagram_AD
Select * From #consort_diagram_BC

   
Select * From #AKI_DEMO
Select * From #AKI_VITAL
Select * From #AKI_VITAL_OLD
Select * From #AKI_PX
Select * From #AKI_DX
Select * From #AKI_LAB
Select * From #AKI_PMED 
Select * From #AKI_AMED
Select * From #AKI_DMED
Select * From #AKI_DEMO_DEATH
Select * From #AKI_DX_CURRENT
Select * From #AKI_LAB_SCR
------------------------------------------------------------------------------------*/