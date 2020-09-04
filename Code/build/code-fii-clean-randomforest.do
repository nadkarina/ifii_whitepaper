* ******************************************************************************
* PROGRAM: FII DATA PREPARATION FOR RANDOM FORESTS
* PROGRAMMER: Natalie Theys
* PURPOSE: Data Cleaning and Prep for Random Forests
*			This means all categorical variables have to be labeled, all observations
*			must have complete data
* DATE CREATED: 26 Feb 2020
* ******************************************************************************


// ********************************************************************************
*************************** CLEAN AND PREP DATA ********************************
********************************************************************************


*Read in Data 
	use "$final/fii-clean-inprogress.dta", clear

*Subset to 2018 (because the above is a dataset of all years)
	keep if year==2018
	drop *_year14 *_year15 *_year16 age_year18 weight_year18
	rename *_year18 *
	rename dl1_year18_raw dl1_raw
	
*Create vars for use and depth of use in past 6 months
	
foreach var in ojk16_1 ojk16_2 ojk16_3 ojk16_4 ojk18_1 ojk18_2 ojk19_1 ojk19_2 ojk19_3 ojk24_1 ojk24_2 ojk20_1 ojk20_2 ojk21_1 ojk25_1 ojk25_2 ojk26_1 ojk26_2 ojk14_1 ojk14_2 ojk14_3 ojk14_4 ojk14_5 ojk14_6 ojk14_7 ojk14_8 ojk14_9 ojk14_10 ojk14_12 ojk14_13  ojk15_1 ojk15_2 ojk15_3 ojk15_4 ojk15_5 ojk15_6 ojk15_7 ojk15_8 ojk15_9 ojk15_10  ojk22_2 gf3b ojk23_1 ojk23_2 ojk23_3	{
	destring `var', replace
	gen `var'_30days = `var'==1
	gen `var'_90days = `var'==1 | `var'==2
	gen `var'_6mon = `var'==1 | `var'==2  | `var'==3
	gen `var'_1yr = `var'==1 | `var'==2  | `var'==3 | `var'==4
	gen `var'_2plusyr = `var'==6
			}
			
foreach time in 30days 90days 6mon 1yr 2plusyr{
	g p`time'_bankservices = ojk14_1_`time'==1 | ojk14_2_`time'==1 | ojk14_3_`time'==1 | ojk14_4_`time'==1 | ojk14_5_`time'==1 | ojk14_6_`time'==1 | ojk14_7_`time'==1 | ojk14_8_`time'==1 | ojk14_9_`time'==1 | ojk14_10_`time'==1 | ojk14_12_`time'==1 | ojk14_13_`time'==1 
		lab var p`time'_bankservices "Used bank services in past `time'"	
	g p`time'_multifinance = 		ojk16_1_`time'==1 | ojk16_2_`time'==1 | ojk16_3_`time'==1 | ojk16_4_`time'==1
		lab var p`time'_multifinance "Used multifinance in past `time'"
	g p`time'_pension =				ojk18_1_`time'==1 | ojk18_2_`time'==1
		lab var p`time'_pension "Used pension in past `time'"	
	g p`time'_pawnshop =			ojk19_1_`time'==1 | ojk19_2_`time'==1 | ojk19_3_`time'==1
		lab var p`time'_pawnshop "Used pawnshop in past `time'"		
	g p`time'_microfinance = 		ojk24_1_`time'==1 | ojk24_2_`time'==1
		lab var p`time'_microfinance "Used microfinance in past `time'"		
	g p`time'_investments = 		ojk20_1_`time'==1 | ojk20_2_`time'==1 | ojk21_1_`time'==1
		lab var p`time'_investments "Used investments in past `time'"			
	g p`time'_cooperative = 		ojk25_1_`time'==1 | ojk25_2_`time'==1
		lab var p`time'_cooperative "Used cooperatives in past `time'"				
	g p`time'_sharia_microfinance = ojk26_1_`time'==1 | ojk26_2_`time'==1
		lab var p`time'_sharia_microfinance "Used sharia microfinance in past `time'"				
				}
								
*Number of financial tasks in past 30, 90, etc 

foreach time in 30days 90days 6mon 1yr{
		
		egen use_depth_`time' = rowtotal(p`time'_bankservices  p`time'_multifinance p`time'_pension p`time'_pawnshop p`time'_microfinance p`time'_investments p`time'_cooperative p`time'_sharia_microfinance)
			lab var use_depth_`time' "Depth of Engagement in Past `time'"
		gen use_`time'_bin = use_depth_`time'>0
			lab var use_`time'_bin "Used any serivce in past `time'"			
			}
	
*Make extra category to include ATM

	gen use_depth_6mon_atm = use_depth_6mon
		replace use_depth_6mon_atm = use_depth_6mon_atm + 1 if bi_e9a=="1"
		replace use_depth_6mon_atm = use_depth_6mon_atm + 1 if bi_e11a=="1"
		lab var use_depth_6mon_atm "Depth of engagement in past 6 months, incl ATM"
	gen use_6mon_atm_bin = use_depth_6mon_atm>0
		lab var use_6mon_atm_bin "Any services in past 6mo, incl ATM"
		
*Household Structure Variables (we only have age and gender, no relationship)
	*for household head, we can do age and gender
		forvalues i = 1/10{
			gen hhm_`i'_age = i_`i'_d3
				destring hhm_`i'_age , replace
			gen hhm_`i'_fem = i_`i'_d4
				destring hhm_`i'_fem , replace
					recode hhm_`i'_fem  (1=0 ) (2=1)
				}
		g hh_head_age = hhm_1_age
		g hh_head_fem = hhm_1_fem
		
	*household size and composition
		cap drop hh_size
		egen hh_size =  rownonmiss(hhm_*_fem )
		
		egen hh_num_males = anycount(hhm_*_fem), values(0)
		egen hh_num_females = anycount(hhm_*_fem), values(1)
		
		foreach var in hhm_u4 hhm_5t8 hhm_9t12 hhm_13t15 hhm_16t18{
			gen `var'_f=0
			gen `var'_m=0
					}

			forvalues i=1/10{
				replace hhm_u4_f = hhm_u4_f+1 if (hhm_`i'_age>=0 & hhm_`i'_age<=4  ) & hhm_`i'_fem==1
				replace hhm_u4_m = hhm_u4_m+1 if (hhm_`i'_age>=0 & hhm_`i'_age<=4  ) & hhm_`i'_fem==0
				
				replace hhm_5t8_f = hhm_5t8_f+1 if (hhm_`i'_age>=5 & hhm_`i'_age<=8  ) & hhm_`i'_fem==1
				replace hhm_5t8_m = hhm_5t8_m+1 if (hhm_`i'_age>=5 & hhm_`i'_age<=8  ) & hhm_`i'_fem==0
				
				replace hhm_9t12_f = hhm_9t12_f+1 if (hhm_`i'_age>=9 & hhm_`i'_age<=12  ) & hhm_`i'_fem==1
				replace hhm_9t12_m = hhm_9t12_m+1 if (hhm_`i'_age>=9 & hhm_`i'_age<=12  ) & hhm_`i'_fem==0
				
				replace hhm_13t15_f = hhm_13t15_f+1 if (hhm_`i'_age>=13 & hhm_`i'_age<=15  ) & hhm_`i'_fem==1
				replace hhm_13t15_m = hhm_13t15_m+1 if (hhm_`i'_age>=13 & hhm_`i'_age<=15  ) & hhm_`i'_fem==0
				
				replace hhm_16t18_f = hhm_16t18_f+1 if (hhm_`i'_age>=16 & hhm_`i'_age<=18  ) & hhm_`i'_fem==1
				replace hhm_16t18_m = hhm_16t18_m+1 if (hhm_`i'_age>=16 & hhm_`i'_age<=18  ) & hhm_`i'_fem==0				
					}
					
			g any_teenage_boys =  (hhm_13t15_m>=1 | hhm_16t18_m>=1)	
			g any_teenage_girls = (hhm_13t15_f>=1 | hhm_16t18_f>=1)	

*Create poverty variable
	gen poverty_bin = poverty==0 | poverty==1
		lab var poverty_bin "Below Poverty Line"

*Create phone use and ability vars	
	gen phone_user =  mt2==1 | mt7==1
		lab var phone_user "Uses Any Phone"
		destring mt8, replace
	gen phone_user_data = mt8==1 if (phone_user==1 & mt8!=-2)
		lab var phone_user_data "Phone User and Uses Data"
	
	*Basic and Advanced Phone Ability
		forvalues i=1/6{
			assert mt18a_`i'!=.
			}
		gen basic_ability = ( mt18a_1>=3 | mt18a_2>=3 | mt18a_3>=3 )
			replace basic_ability = . if basic_ability==0 & ( mt18a_1==-2 | mt18a_2==-2 | mt18a_3==-2 )
		gen smart_ability = ( mt18a_4>=3 | mt18a_5>=3 | mt18a_6>=3 )
			replace smart_ability = . if smart_ability==0 & ( mt18a_4==-2 | mt18a_5==-2 | mt18a_6==-2 )
			
		forvalues i=1/6{
			gen mt18a_`i'_ability = (mt18a_`i' == 3 |  mt18a_`i' ==4) if  mt18a_`i'!=-2
				}
		egen phoneusage_full = rowtotal( mt18a_*_ability), missing
			replace phoneusage_full = . if mt18a_1_ability==.  | mt18a_2_ability==.  | mt18a_3_ability==.  | mt18a_4_ability==.  | mt18a_5_ability==.  | mt18a_6_ability==.  
		egen phoneusage_basic = rowtotal(mt18a_1_ability mt18a_2_ability mt18a_3_ability), missing
			replace phoneusage_basic = . if mt18a_1_ability==. | mt18a_2_ability==. | mt18a_3_ability==. 
		egen phoneusage_adv = rowtotal(mt18a_4_ability mt18a_5_ability mt18a_6_ability), missing
			replace phoneusage_adv= . if mt18a_4_ability==. | mt18a_5_ability==. | mt18a_6_ability==. 
		
	*Phone Use Recent
		foreach var in mt17_1 mt17_2 mt17_3 mt17_4 mt17_5	{
			gen `var'_today = `var'==1
			gen `var'_week = `var'==1 | `var'==2
			gen `var'_month = `var'==1 | `var'==2 | `var'==4
			gen `var'_ever = `var'!=7
					}
					
		egen phonetasks_today = rowtotal(mt17*_today)	, missing		
			egen phonetasks_bas_today = rowtotal(mt17_1_today mt17_2_today)	, missing		
				g phonetasks_bas_today_bin = phonetasks_bas_today>0		
			egen phonetasks_adv_today = rowtotal(mt17_3_today mt17_4_today mt17_5_today), missing		
				g phonetasks_adv_today_bin = phonetasks_adv_today>0
		egen phonetasks_week = rowtotal(mt17*_week)	, missing
			egen phonetasks_bas_week = rowtotal(mt17_1_week mt17_2_week)	, missing
				g phonetasks_bas_week_bin = phonetasks_bas_week>0		
			egen phonetasks_adv_week = rowtotal(mt17_3_week mt17_4_week mt17_5_week), missing	
				g phonetasks_adv_week_bin = phonetasks_adv_week>0		
		egen phonetasks_month = rowtotal(mt17*_month)	, missing		
			egen phonetasks_bas_month = rowtotal(mt17_1_month mt17_2_month)	, missing		
				g phonetasks_bas_month_bin = phonetasks_bas_month>0				
			egen phonetasks_adv_month = rowtotal(mt17_3_month mt17_4_month mt17_5_month), missing
				g phonetasks_adv_month_bin = phonetasks_adv_month>0				
		egen phonetasks_ever = rowtotal(mt17*_ever)	, missing		
			egen phonetasks_bas_ever = rowtotal(mt17_1_ever mt17_2_ever)	, missing	
				g phonetasks_bas_ever_bin = phonetasks_bas_ever>0				
			egen phonetasks_adv_ever = rowtotal(mt17_3_ever mt17_4_ever mt17_5_ever), missing	
				g phonetasks_adv_ever_bin = phonetasks_adv_ever>0				
		
		foreach time in today week month ever{
			g phoneuse_`time' = phonetasks_`time'>0
					}
	
	*Create a new ability var keeping missings as zero
	forvalues i=1/6{
		gen mt18a_`i'_mi = mt18a_`i'
			replace mt18a_`i'_mi = 0 if mt18a_`i'==-2
				}	
	*Now, reacreate totals by task complexity
		egen phoneusage_basic_n = rowtotal(mt18a_1_mi mt18a_2_mi mt18a_3_mi), missing
		egen phoneusage_adv_n = rowtotal(mt18a_4_mi mt18a_5_mi mt18a_6_mi), missing	
	
	
	*Now, a new var with missings are zero for phone type
		foreach var in mt2a_1 mt2a_2 mt2a_3{
			destring `var' , replace
			recode `var' (2=0)
			replace `var' = 0 if `var'==.
				}	
	
*Create categorical age variable 
	rename age resp_age
	
	foreach var in resp hh_head {
	gen `var'_age_bin = .
	local l = 1
		forvalues j=15(5)70{
			local k=`j'+5
			replace `var'_age_bin = `l' if (`var'_age>=`j' & `var'_age<`k')
			label define `var'_age_bin `l' "age `j' to `k'", modify
			local ++l
					}
		sum `var'_age_bin
		replace `var'_age_bin = `r(max)' if `var'_age>=70 & `var'_age!=.
			label define `var'_age_bin `r(max)' "age 70 plus", modify
			label values `var'_age_bin `var'_age_bin
						}

*Create variable for number of IDs
	foreach var in dg5_1 dg5_2 dg5_3 dg5_4 dg5_5 dg5_6{
		recode `var' (2=0)
			}
	egen num_ids = rowtotal(dg5_1 dg5_2 dg5_3 dg5_4 dg5_5 dg5_6)		
			
*Clean Var for Relation to HH Head
	gen rel_hh_head = dg6 if dg6!=-2
	
*Clean for on Contribution to HH Income
	gen income_pct = dl0 if dl0>0
	
*Clean Job Type Var
	gen jobtype = dl2 if dl2!=-3
	replace jobtype = 0 if (dl1==-99 | dl1==5 | dl1==6 | dl1==7)
	
*Create Var on Number of Income Sources
	foreach var in dl4_1 dl4_2 dl4_3 dl4_4 dl4_5 dl4_6 dl4_7 dl4_8 dl4_9 dl4_10 dl4_11{
		recode `var' (2=0)
		assert `var'!=.
			}
	egen num_income_sources = rowtotal(dl4_1 dl4_2 dl4_3 dl4_4 dl4_5 dl4_6 dl4_7 dl4_8 dl4_9 dl4_10 dl4_11)		
			

*Clean vars on decisionmaking
	foreach var in hhdecision_general hhdecision_basic hhdecision_beyondbasic hhdecision_influence hhdecision_voicedisagree hhdecision_finaldecision hhdecision_ownmoney gn8{
		recode `var;' (-2=0) (-3=0)
		}
		
* Clean vars on distance to various banking services
	foreach var in bi_e43_1 bi_e43_2 bi_e43_3 bi_e43_4 bi_e43_5 bi_e43_6 bi_e43_7 bi_e43_8 bi_e43_9 bi_e43_10 bi_e43_11 bi_e43_12 bi_e43_13 bi_e43_14{
		recode `var' (-2=0)
		tab `var'
		}
		
*Recode HH infastructur vars to be 0/1
	foreach var in dl21 dl22 dl23 {
		recode `var' (1=0) (2=1)
			}
			
*Recode some various variables with negatives
	replace dl1_raw= 97 if dl1_raw==-2
	replace highestedu_female = 6 if highestedu_female==-99
	
*Clean up respondnet education variable		
	g highestedu_respondent_sub=highestedu_respondent
		replace highestedu_respondent_sub = 1 if highestedu_respondent==9
		replace highestedu_respondent_sub = 5 if highestedu_respondent==6  | highestedu_respondent==7 | highestedu_respondent==8
		replace highestedu_respondent = 10 if highestedu_respondent==-99





********************************************************************************
***************************** CREATE PROFILES  *********************************
********************************************************************************



*Profile 1: Urban/Rural and by Worker Type
*Hypothesis: Rural housewives have low use, non-salaried workers (particularly in rural areas) low use


	cap drop profile1
	lab define profile1, replace

	gen profile1=.

	local j = 1
	foreach var in salary nonsalary selfemploy housewife student nowork {
		replace profile1 = `j' if `var'==1  & urban==0 
			label define profile1 `j' "Rural, `: variable label `var''", modify
		local j = `j'+1
		
		replace profile1 = `j' if `var'==1  & urban==1
			label define profile1 `j' "Urban, `: variable label `var''", modify	
		local j = `j'+1
				}
				
	lab values profile1 profile1
	fre profile1
		
	tab profile1 [w=weight], sum(everuse)
	tab profile1 [w=weight], sum(ownership)
		


*Profile 2: Urban/Rural, Worker Type, SES
*Hypothesis: BPL, rural, non-salaried workers have low use

	cap drop profile2
	gen profile2=.
	lab define profile2, replace	

	replace profile2 = 1 if poverty_bin==1 & urban==0 & salary!=1 & (nonsalary==1 | selfemploy==1  )
		label define profile2 1 "BPL, RURAL, NOSALARY WORKERS", modify
	replace profile2 = 2 if salary==1
		label define profile2 2 "SALARIED, REGARDLESS OF POVERTY STATUS OR URBAN OR RURAL", modify
	replace profile2 = 3 if poverty_bin==1 & urban==1 & salary!=1 & (nonsalary==1 | selfemploy==1 )
		label define profile2 3 "BPL, URBAN WORKERS", modify
	replace profile2 = 4 if poverty_bin==0 & salary!=1 & (nonsalary==1 | selfemploy==1 )
		label define profile2 4 "APL WORKERS", modify	
	replace profile2 = 5 if (student==1 | nowork==1) 
		label define profile2 5 "STUDENTS/NOWORKERS", modify
	replace profile2 = 6 if (housewife==1 ) 
		label define profile2 6 "HOUSEWIVES", modify

			
	lab values profile2 profile2
	fre profile2
	
	tab profile2 [w=weight], sum(everuse)
	tab profile2 [w=weight], sum(ownership)
			
		
*Profile 3: Urban/Rural, Worker Type, EUDCATION
*Hypothesis: NONWORKERS have low access, Workers with little education have less access, particularly rural areas
	
	g anytypeofwork = (salary==1 | nonsalary==1 | selfemploy==1 ) if workertype!=-99

	cap drop profile3
	gen profile3=.
	lab define profile3, replace	

	replace profile3 = 1 if urban==0 & anytypeofwork==0
		label define profile3 1 "RURAL NONWORKERS", modify
	replace profile3 = 2 if urban==1 & anytypeofwork==0
		label define profile3 2 "URBAN NONWORKERS", modify	
	replace profile3 = 3 if ((urban==0 & anytypeofwork==1)) & (noedu==1 | primary==1 | edu9==1)
		label define profile3 3 "RURAL WORKERS, LITTLE EDU", modify
	replace profile3 = 4 if ((urban==0 & anytypeofwork==1)) & (hs_orhigher==1 | jrhigh==1)
		label define profile3 4 "RURAL WORKERS, MORE EDU", modify
	replace profile3 = 5 if ((urban==1 & anytypeofwork==1)) & (noedu==1 | primary==1 | edu9==1)
		label define profile3 5 "URBAN WORKERS, LITTLE EDU", modify
	replace profile3 = 6 if ((urban==1 & anytypeofwork==1)) & (hs_orhigher==1 | jrhigh==1)
		label define profile3 6 "URBAN WORKERS, MORE EDU", modify
				
		lab values profile3 profile3
		fre profile3
		
		
*Profile 4: EDUCATION AND PHONE USER
*Hypothesis: People who have never used phones and with little education will have less access
		
	gen profile4=.
	lab define profile4, replace	

		replace profile4 = 1 if phoneuse_ever==0 
			label define profile4 1 "NEVER USED", modify
		replace profile4 = 2 if phoneuse_ever==1 & (highestedu_respondent_sub==1 | highestedu_respondent_sub==2)
			label define profile4 2 "User and No/Primary Education", modify
		replace profile4 = 3 if phoneuse_ever==1 & highestedu_respondent_sub==3
			label define profile4 3 "User and Jr High Education", modify
		replace profile4 = 4 if phoneuse_ever==1 & highestedu_respondent_sub==5
			label define profile4 4 "User and HS or Greater Education", modify
			
	lab values profile4 profile4
	fre profile4

*NEW CATEGORIES

	*Poor, Distrustful
		g profile5 = (gn8==1 |  gn8==2 |  gn8==3) & poverty_bin==1
		
	*Remote and disconected (far away from bank and no phone)
		g profile6 =  bi_e43_1==4 & own_mobilephone ==0
		
	*Remote and low education
		g profile7 =  bi_e43_1==4 & (highestedu_respondent==1 | highestedu_respondent==2 | highestedu_respondent==3) & resp_age>2		 
	
	*Tech Illiterate, married, housewife
		g profile8  = dl1_raw==7 & married==1 & (mt18a_4_mi==0 | mt18a_4_mi ==1)
	
	*Female household head
		g profile9  = hh_head_fem==1 & rel_hh_head==1 
	
	*Ag Workers
		g profile10  = jobtype==1 | jobtype==2 	
		
	*housewives
		gen profile11 = jobtype==7 & female==1
		
	*non-advanced users
		gen profile12 = phonetasks_adv_ever
		
*share phone
	gen used_shared = mt7==1
	
********************************************************************************
***************************** DROP MISSING VARS  *******************************
********************************************************************************


*NOTE: we are not going to drop those with missing values for the profiles, we can subset these in R

*Drop observations missing the following:
	drop if highestedu_respondent_sub==. | rel_hh_head==. | income_pct==. | jobtype==. | hh_head_age_bin==.


*SPLIT OUT BPJS
	rename ojk9_1_ever bpjs_health
	rename ojk9_2_ever bpjs_labor
	
*We do not want to use a series of binary variables in random forest
	keep  everuse  use_6mon_atm_bin ownership  province urban highestedu_female resp_age_bin used_shared ///
		 highestedu_respondent  workertype employment_male poverty_bin female married jobtype income_pct dl14 ln1 ln2_1 ln2_2 ///
		 own_mobilephone phonetasks_today phonetasks_bas_today phonetasks_adv_today phonetasks_week phonetasks_bas_week phonetasks_adv_week phonetasks_month phonetasks_bas_month phonetasks_adv_month phonetasks_ever phonetasks_bas_ever phonetasks_adv_ever ///
		 mt18a_1_mi mt18a_2_mi mt18a_3_mi mt18a_4_mi mt18a_5_mi mt18a_6_mi phoneusage_basic_n phoneusage_adv_n ///
		 bpjs_health  bpjs_labor  dl1_raw ///
		 dg5_1 dg5_2 dg5_3 dg5_4 dg5_5 dg5_6 num_ids    ///
		 rel_hh_head  income_pct num_income_sources dl4_1 dl4_2 dl4_3 dl4_4 dl4_5 dl4_6 dl4_7 dl4_8 dl4_9 dl4_10 dl4_11 ///
		   dl21 dl22 dl23 dl18 dl19  dl20  ///
		 hhdecision_general hhdecision_basic hhdecision_beyondbasic hhdecision_influence hhdecision_voicedisagree hhdecision_finaldecision hhdecision_ownmoney gn8 ///
		  bi_e43_1 bi_e43_2 bi_e43_3 bi_e43_4 bi_e43_5 bi_e43_6 bi_e43_7 bi_e43_8 bi_e43_9 bi_e43_10 bi_e43_11 bi_e43_12 bi_e43_13 bi_e43_14 ///
		  profile* weight ///
		   hh_head_age_bin hh_head_fem hh_size hh_num_males hh_num_females hhm_u4_f hhm_u4_m hhm_5t8_f hhm_5t8_m hhm_9t12_f hhm_9t12_m hhm_13t15_f hhm_13t15_m hhm_16t18_f hhm_16t18_m any_teenage_boys any_teenage_girls *mobilemoney own_smartphone ///
			Fnx_ATM_debit
	  

* This should just be profile variables 
	ds _all
	foreach var in `r(varlist)'  {
	quietly count if `var'==. 
	if `r(N)'!=0{
		di "`var'"
		}		
		}


********************************************************************************
**************************** LABEL ALL CAT. DATA  ******************************
********************************************************************************



*HAVE TO LABEL ALL DATA FOR IT TO WORK AS FACTORS IN R
	label define yesno 1"Yes" 0"No"

	foreach var in profile5 profile6 profile7 profile8 profile9 profile10 everuse  use_6mon_atm_bin ownership hh_head_fem bpjs_health  bpjs_labor female  married poverty_bin own_mobilephone dg5_1 dg5_2 dg5_3 dg5_4 dg5_5 dg5_6 dl4_1 dl4_2 dl4_3 dl4_4 dl4_5 dl4_6 dl4_7 dl4_8 dl4_9 dl4_10 dl4_11  dl21 dl22 dl23 any_teenage_boys any_teenage_girls know_mobilemoney use_mobilemoney own_smartphone used_shared{
		label values `var' yesno
			}

	forvalues i=1/33{
	label define province `i' "Province `i'", modify
			}
			
	foreach var in hh_size hh_num_males hh_num_females hhm_u4_f hhm_u4_m hhm_5t8_f hhm_5t8_m hhm_9t12_f hhm_9t12_m hhm_13t15_f hhm_13t15_m hhm_16t18_f hhm_16t18_m{
		sum `var', detail
		forvalues i = `r(min)'/`r(max)'{
			label define `var' `i' "`i'", modify
				}
		lab values `var' `var'
				}

	lab define dl1_raw 1"FT Salary" 2"PT Salary" 3"Irreg" 4"Season" 5"SelfEmply" 6"Looking" 7"Housewife" 8"Student" 9"Retire" 10"Disabl" 96"Other" 97"DK"
	lab def urban 0"Rural" 1"Urban"
	lab define highestedu_female 0 "No Education" 1 "Primary" 2 "Jr High" 3 "Vocational HS level" 4 "High School" 5 "Diploma"  6 "No female head or spouse", replace
	lab define highestedu_respondent 1 "No formal education" 2 "Primary" 3 "Jr. High" 5 "HS Vocational" 6 "Diploma" 7 "College Uni" 8 "Post-Graduate Uni" 9 "Informal" 10"Refuse etc", replace
	lab define income_pct 1 "none" 2"a little" 3"about half" 4"most" 5"almost all"
	lab define jobtype 0"Non worker" 1"Ag owner" 2"Ag worker" 3"govt" 4"professional" 5"clerk" 6"technician" 7"service" 8"manufacturing" 9 "operator" 10"laborer" 11"driver" 12"military" 96"other"
	lab define num_ids 0"0" 1"1" 2"2" 3"3" 4"4" 5"5" 6"6"
	lab define num_income_sources 0"0" 1"1" 2"2" 3"3" 4"4" 5"5" 6"6" 7"7"
	lab define phonetasks_today 0"0" 1"1" 2"2" 3"3" 4"4" 5"5"
	lab define phonetasks_bas_today  0"0" 1"1" 2"2"
	lab define phonetasks_adv_today  0"0" 1"1" 2"2" 3"3"
	lab define phonetasks_week 0"0" 1"1" 2"2" 3"3" 4"4" 5"5"
	lab define phonetasks_bas_week 0"0" 1"1" 2"2"
	lab define phonetasks_adv_week 0"0" 1"1" 2"2" 3"3"
	lab define phonetasks_month 0"0" 1"1" 2"2" 3"3" 4"4" 5"5"
	lab define phonetasks_bas_month 0"0" 1"1" 2"2"
	lab define phonetasks_adv_month 0"0" 1"1" 2"2" 3"3"
	lab define phonetasks_ever 0"0" 1"1" 2"2" 3"3" 4"4" 5"5"
	lab define phonetasks_bas_ever 0"0" 1"1" 2"2"
	lab define phonetasks_adv_ever 0"0" 1"1" 2"2" 3"3"
	lab define phoneusage_basic_n 0"0" 1"1" 2"2" 3"3" 4"4" 5"5" 6"6" 7"7" 8"8" 9"9" 10"10" 11"11" 12"12"
	lab define phoneusage_adv_n 0"0" 1"1" 2"2" 3"3" 4"4" 5"5" 6"6" 7"7" 8"8" 9"9" 10"10" 11"11" 12"12"
	lab define rel_hh_head  1"self" 2"spouse" 3"child" 4"parent" 5"sibling" 6"grand parent" 7"grandchild" 8"other" 9"non relative" 

	lab define dl14  1"1" 2"2" 3"3" 4"4" 5"5" 6"6 plus"
	lab define  dl18 1"Earth bamboo" 2"other"
	lab define dl19 1"none or latrine" 2"non flush to septic" 3"flush"
	lab define dl20 1"firewood" 2"fas"

	lab define distance 1"less than .5km" 2"btwn .5 and 1km" 3"btwn 1 and 5km" 4"more than 5km" 0"dont know"

	lab define	hhdecision_influence  0"dk ref" 1"none" 2"a little" 3"fair amount" 4"most" 5"almost all"
	lab define  hhdecision_voicedisagree  0"dk ref" 1"v unlikely" 2"some unlikely" 3"neither" 4"some likely" 5"v likely" 
	lab define  hhdecision_finaldecision  0"dk ref" 1"strong disagree" 2"somewhat disagree" 3"neither" 4"some agree" 5"strong agree" 
	lab define  hhdecision_ownmoney 0"dk ref" 1"strong disagree" 2"somewhat disagree" 3"neither" 4"some agree" 5"strong agree" 
	lab define  gn8  0"dk ref" 1"strong disagree" 2"somewhat disagree" 3"neither" 4"some agree" 5"strong agree" 

	lab define ln1 1"fluent" 2"some help" 3"struggle" 4"unable"
	lab define ln2_1 1"cannot" 2"badly" 3"somewhat badly" 4"good" 5"excellent"
	lab define ln2_2 1"cannot" 2"badly" 3"somewhat badly" 4"good" 5"excellent"

	 lab define ability 0"dk" 1"none" 2"little" 3"some" 4"complete"
	 
	lab define gn1 0"dk ref" 1"v uninvolved" 2"some uninvolved" 3"neither" 4"some involved" 5"v involved"
	 

	foreach var in  bi_e43_1 bi_e43_2 bi_e43_3 bi_e43_4 bi_e43_5 bi_e43_6 bi_e43_7 bi_e43_8 bi_e43_9 bi_e43_10 bi_e43_11 bi_e43_12 bi_e43_13 bi_e43_14{
		lab values `var' distance
		}
		
	 foreach var in hhdecision_general hhdecision_basic hhdecision_beyondbasic{
		lab values `var' gn1
		}
	 
	 foreach var in  mt18a_1_mi mt18a_2_mi mt18a_3_mi mt18a_4_mi mt18a_5_mi mt18a_6_mi {
		label values `var' ability
		}
		
	foreach var in dl1_raw phoneusage_basic_n phoneusage_adv_n rel_hh_head resp_age_bin hh_head_age_bin province urban highestedu_female highestedu_respondent income_pct jobtype num_ids num_income_sources phonetasks_today phonetasks_bas_today phonetasks_adv_today phonetasks_week phonetasks_bas_week phonetasks_adv_week phonetasks_month phonetasks_bas_month phonetasks_adv_month phonetasks_ever phonetasks_bas_ever phonetasks_adv_ever dl14 dl18 dl19 dl20 hhdecision_influence hhdecision_voicedisagree hhdecision_finaldecision hhdecision_ownmoney gn8 ln1 ln2_1 ln2_2 {
		lab values `var' `var'
			}	
	  
	  
  
*Misc prepartion		
	order  Fnx_ATM_debit everuse use_6mon_atm_bin ownership  know_mobilemoney use_mobilemoney
	
/*	NOT FOUND
replace ability_fintrans = 5 if ability_fintrans==0	
 lab define ability2 1"none" 2"little" 3"some" 4"complete"  5"dk", modify
	lab values ability_fintrans ability2
*/	
	
*ADDED renameiables so they are intuitive in R output
	rename dg5_1 has_KTP
	rename dg5_2 has_FamReg
	rename dg5_3 has_Passport
	rename dg5_4 has_SchID
	rename dg5_5 has_TaxCard
	rename dg5_6 has_DrivLic
	
	rename dl4_1 money_fish
	rename dl4_2 money_ag
	rename dl4_3 money_govt_asst
	rename dl4_4 money_dom_remit
	rename dl4_5 money_for_remit
	rename dl4_6 money_own
	rename dl4_7 money_govtempl
	rename dl4_8 money_bus_less10
	rename dl4_9 money_bus_more10
	rename dl4_10 money_scholarship
	rename dl4_11 money_pension
	
	
	rename dl14 hh_members
	rename dl18 floortype
	rename dl19 toilets
	rename dl20 cookfuel
	rename dl21 gascylinder
	rename dl22 fridge
	rename dl23 scooter
	
	rename bi_e43_1 bank_dist
	rename bi_e43_2 atm_dist
	rename bi_e43_3 pos_dist
	rename bi_e43_4 laku_dist
	rename bi_e43_5 bpr_dist
	rename bi_e43_6 coop_dist
	rename bi_e43_7 pawnshop_dist
	rename bi_e43_8 multi_dist
	rename bi_e43_9 micro_dist
	rename bi_e43_10 sh_micro_dist
	rename bi_e43_11 insur_dist
	rename bi_e43_12 broker_dist
	rename bi_e43_13 moneych_dist
	rename bi_e43_14 mta_dist
	
	rename ln1 can_read
	rename ln2_1 read_bahasa
	rename ln2_2 write_bahasa
	
	rename jobtype jobsector
	rename dl1_raw jobtype
	
	rename hhm_u4_f fems_u4
	rename hhm_u4_m males_u4
	rename hhm_5t8_f fems_5t8
	rename hhm_5t8_m males_5t8
	rename hhm_9t12_f fems_9t12
	rename hhm_9t12_m males_9t12
	rename hhm_13t15_f fems_13t15
	rename hhm_13t15_m males_13t15
	rename hhm_16t18_f fems_16t18
	rename hhm_16t18_m males_16t18
	
	rename mt18a_1_mi ability_call
	rename mt18a_2_mi ability_navmenu
	rename mt18a_3_mi ability_text
	rename mt18a_4_mi ability_internet
	rename mt18a_5_mi ability_fintrans
	rename mt18a_6_mi ability_dwldapp
	
	
	rename hhdecision_general invovle_hhinc
	rename hhdecision_basic invovle_basics
	rename hhdecision_beyondbasic invovle_beybasics
	rename hhdecision_influence influence_spending
	rename hhdecision_voicedisagree voice_disagreement
	rename hhdecision_finaldecision finaldec_hhinc
	rename hhdecision_ownmoney finaldec_ownmoney
	rename gn8 trust_in_system
	
	
	drop if missing(invovle_hhinc) | missing(invovle_basics) | missing(invovle_beybasics) | missing(influence_spending) | missing(voice_disagreement) | missing(finaldec_hhinc) | missing(finaldec_ownmoney)
	
	*drop province
	drop ownership
	drop num_income_sources
	drop num_ids
	rename Fnx_ATM_debit ownership
	
*SAVE DATASET
	save "$final/fii-clean-randomforestprofiles.dta", replace
	
/*	
	asfasdf
	*Create summary table for findings
	gen N = 1

	gen cut1 = profile2==1 
	gen cut2 = profile2==6
	gen cut3 = profile3==1 
	gen cut4 = profile3==3
	gen cut5 = profile4==1
	gen cut6 = profile5==1 
	gen cut7 = profile6==1
	gen cut8 = profile7==1 
	gen cut9 = profile8==1
	gen cut10 = profile9==1	
	gen cut11 = profile10==1	
	gen cut12 = N==1
	
	
	forvalues i=1/12{
	preserve
	collapse (mean) UsedRecently=use_6mon_atm_bin Ownership=ownership (count) N [w=weight], by(cut`i')
	keep if cut`i'==1
		tempfile cut`i'
		save `"`cut`i''"'  
	restore
			}
			
			
	use "`cut1'", clear
	forvalues i=2/12{
	append using `"`cut`i''"' 
				}

	
		gen Segment = "BPL, Rural, Non-Salaried Workers" if  cut1==1
		replace Segment="Housewives" if  cut2==1
		replace Segment="Rural, Non-Workers" if cut3==1 
		replace Segment="Rural, Uneducated Workers" if  cut4==1
		replace Segment="Never Phone Users" if  cut5==1
		
		replace Segment="BPL, Distrustful" if  cut6==1
		replace Segment="Remote, Disconnected" if  cut7==1
		replace Segment="Remote, Uneducated" if  cut8==1
		replace Segment="Tech Illit, Married, Housewife" if  cut9==1
		replace Segment="Female HH Heads" if  cut10==1
		replace Segment="Ag Workers" if  cut11==1
		
		replace Segment="Full Sample" if  cut12==1
		
		order Segment
		drop cut*
		foreach var in  UsedRecently Ownership{
		replace `var' = `var'*100
		format `var' %9.3g
						}
	 dataout, save("${fiifig}/profilesummary") tex replace  	

	
