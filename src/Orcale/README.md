Standalone Orcale scripts for local data extraction out of PCORnet CDM
====================================================================

by Ho Yin Chan, with Mei Liu
[Medical Informatics Division, Univeristy of Kansas Medical Center][MI]

[MI]: http://informatics.kumc.edu/

Copyright (c) 2022 Univeristy of Kansas Medical Center  
Share and Enjoy according to the terms of the MIT Open Source License.

***

## Site Usage 

1. `AKI_extract_cohort.sql` is used to extract the AKI cohort that satisfies the [inclusion and exclusion criteria]. The following two output tables are expected to be delivered:      
      * AKI_onsets
      * consort_diagram_AD
      * consort_diagram_BC

[inclusion and exclusion criteria]: https://github.com/kumc-bmi/AKI_CDM/blob/master/report/AKI_CDM_EXT_VALID_p1_QA.Rmd


2. `AKI_collect_data.sql` is used to collect all relavent clinical observations for the AKI cohort against local PCORnet CDM schema.The following output tables are expected to be delivered:       
      * AKI_DEMO
      * AKI_VITAL (Extract data from obs_clin, populated for CDM v6.1)
      * AKI_VITAL_OLD (Extract data from vital, populated for CDM v6.0)      
      * AKI_PX
      * AKI_DX
      * AKI_LAB
      * AKI_DEMO_DEATH
      * AKI_DX_CURRENT
      * AKI_LAB_SCR 	  
      * AKI_PMED (skip it, if Prescribing table is not populated)
      * AKI_AMED (skip it, if Med_Admin table is not populated)
      * AKI_DMED (skip it, if Dispensing table is not populated)

3. (Optional) `date_shifting.sql` is used for date shifting, please use it if your organization does not have a date shifting pipeline provided. In this case, the table to be exported is renamed as:
      * DEID_AKI_onsets
      * consort_diagram_AD
      * consort_diagram_BC
      * DEID_AKI_DEMO
      * DEID_AKI_VITAL
      * DEID_AKI_VITAL_OLD 
      * DEID_AKI_PX
      * DEID_AKI_DX
      * DEID_AKI_LAB
      * DEID_AKI_PMED 
      * DEID_AKI_AMED
      * DEID_AKI_DMED
      * DEID_AKI_DEMO_DEATH
      * DEID_AKI_DX_CURRENT
      * DEID_AKI_LAB_SCR 

Please export the data in csv format with UTF-8 encoding

Remark: but make sure to extract and deliver at least one table with inpatient medication information and vital information