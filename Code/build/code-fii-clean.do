* ******************************************************************************
* PROGRAM: FII DATA PREPARATION
* AUTHORS: Lolita Moorena and Natalie Theys
* PURPOSE: Create a clean FII dataset
* DATE CREATED: 17 December 2019
* LAST MODIFIED: 25 August 2020 by Nadia Setiabudi
* ******************************************************************************

********************************************************************************
*************************** COMBINE THE FII DATA *******************************
********************************************************************************
forval stage = 1/4  {
	if `stage' == 1 {
		local yeardata "$fii/2014 Wave 1/FII Indonesia 2014 (public+ANONGPS)"
		local year = 2014
		local suffix _year14
		}
	if `stage' == 2 {
		local yeardata "$fii/2015 Wave 2/FII Indonesia 2015 (public+ANONGPS)"
		local year = 2015
		local suffix _year15		
		}
	if `stage' == 3 {
		local yeardata "$fii/2016 Wave 3/FII Indonesia 2016 (public+ANONGPS)"
		local year = 2016
		local suffix _year16		
		}
	if `stage' == 4 {
		local yeardata "$fii/2018-2019 Wave 4/FII Indonesia 2018 (public+ANONGPS)"
		local year = 2018
		local suffix _year18
		}
	
import delimited "`yeardata'.csv", clear

//Rename some variables so that they are not too long when the year suffixes are added
	cap rename nonregistered* noreg*
	cap rename registered* reg*	

rename * *`suffix'
gen year = `year'

	save "$temp/fii`year'.dta", replace

			}

*Renamed all variables with their corresponding years, so there should be no need to force appending
use "$temp/fii2014.dta", clear
append using "$temp/fii2015.dta"
append using "$temp/fii2016.dta"
append using "$temp/fii2018.dta"
	save "$temp/fii-merge.dta", replace
	
	

********************************************************************************
********************** CREATE HARMONIZED DEMO VARS *****************************
********************************************************************************

use "$temp/fii-merge.dta", clear


*LOCATION VARAIABLES

	*1. Province	
		gen province = aa1_year18
			replace province = aa2_year14 if province==.
			replace province = aa2_year15 if province==.
			replace province = aa2_year16 if province==.
					
					label var province "Province"
			
	*2. District
		gen district = aa2_year18
			replace district = aa3_year14 if district==.
			replace district = aa3_year15 if district==.
			replace district = aa3_year16 if district==.
			
					label var district "District"
			
	*3. Urban
		foreach yr in 14 15 16 18{
			recode aa7_year`yr' (2=0)
				}
				
		gen urban = aa7_year18
			replace urban = aa7_year14 if urban==.
			replace urban = aa7_year15 if urban==.
			replace urban = aa7_year16 if urban==.
			
					label var urban "Urban"
			
*HOUSEHOLD ROSTER VARAIABLES

	*1. Household Size
		gen hh_size = dl11_year14
			replace hh_size = dl18_year15 if hh_size==.
			replace hh_size = dl18_year16 if hh_size==.
			replace hh_size = dl18_year18 if hh_size==.
			
		recode hh_size (6=1) (5=2) (4=3) (3=4) (2=5) (1=6)	
			
					label var hh_size "Number of HH Members (Categorical)"
					label define hh_size 1 "One" 2 "Two" 3 "Three" 4 "Four" 5 "Five" 6 "Six or more" 
					label values hh_size hh_size

	*2. All School-Aged Children Attending School
		gen all_children_school = dl12_year14
			replace all_children_school = dl15_year15 if all_children_school==.
			replace all_children_school = dl15_year16 if all_children_school==.
			replace all_children_school = dl15_year18 if all_children_school==.	
			
			recode all_children_school (1=-99) (2=0) (3=1)
			
					lab var all_children_school "Do all household members aged 6-18 currently attend school"
					label define all_children_school 0 "No" 1 "Yes" -99 "N/A: No members age 6 to 18"
					label values all_children_school all_children_school
					
	*3. Highest Education Level Female Head/Spouse
		gen highestedu_female = dl13_year14
			replace highestedu_female = dl16_year15 if highestedu_female==.
			replace highestedu_female = dl16_year16 if highestedu_female==.
			replace highestedu_female = dl16_year18 if highestedu_female==.	
			
		recode highestedu_female (1=0) (4=-99) (2=1) (3=2) (5=3) (6=4) (7=5)
			
					lab var highestedu_female "Highest Level of Education of Female HH Head/Female Spouse"
					label define highestedu_female 0 "No Education" 1 "Primary" 2 "Jr High" 3 "Vocational (HS level)" 4"High School" 5"Diploma" -99 "N/A: No female head/spouse"
					label values highestedu_female highestedu_female	
	
	*4. * Household decision making
	
		foreach var of varlist gn1_year18 gn2_year18 gn3_year18 gn4_year18 gn5_year18 gn6_year18 gn7_year18 {
			replace `var' = .r if `var' == -3
			replace `var' = .d if `var' == -3
			}
			
		rename gn1_year18 hhdecision_general
		rename gn2_year18 hhdecision_basic
		rename gn3_year18 hhdecision_beyondbasic
		rename gn4_year18 hhdecision_influence
		rename gn5_year18 hhdecision_voicedisagree
		rename gn6_year18 hhdecision_finaldecision
		rename gn7_year18 hhdecision_ownmoney
	
*INFORMATION ABOUT THE RESPONDENT VARIABLES
	
	*1. Birth Year
		destring dg1_year15, replace
		
		gen birth_year = dg1_year14
			replace birth_year = dg1_year15 if birth_year==.
			replace birth_year = dg1_year16 if birth_year==.
			replace birth_year = dg1_year18 if birth_year==.	
			
		replace birth_year = -98 if birth_year==. | birth_year==99
		
				label var birth_year "Birth Year of Respondent"
				label define birth_year -98 "Don't know/missing"
				label values birth_year birth_year
				
	*2. Age
		gen age = .
		foreach year in 14 15 16 18{
			replace age = age_year`year' if year==20`year'
			replace age = . if age_year`year'==999
					}
					
				label var age "Age (Years)"
					
	*3. Gender
		foreach yr in 14 15 16 18{
			recode dg2_year`yr' (1=0) (2=1)
				}	
				
		gen female = dg2_year14
			replace female = dg2_year15 if female==.
			replace female = dg2_year16 if female==.
			replace female = dg2_year18 if female==.		
			
				label var female "Female"
				
	*4. Marital Status
		recode dg3_year14 (1=0) (2=1) (3=1) (4=0) (5=0) (6=0) (7=0) (8=-99) (9=-99)
		recode dg3_year15 (1=0) (2=1) (3=1) (4=0) (5=0) (6=0) (7=0) (8=-99) (9=-99)
		recode dg3_year16 (1=0) (2=1) (3=1) (4=0) (5=0) (6=0) (96=-99)  (99=-99)
		recode dg3_year18 (2=0)
		
		gen married = dg3_year14
			replace married = dg3_year15 if married==.
			replace married = dg3_year16 if married==.
			replace married = dg3_year18 if married==.
			
			//replace Dk/Refuse as blank
				replace married = . if married==-99
		
				label var married "Married"
				label define married 0 "Not Married" 1 "Married" 
				label values married married
	
	*5. Highest Level of Education
			* Assuming in 2018 this is highest COMPLETED, although I can find no documentation either way)
			* Also combining senior high school and secondary vocational because i think they are substitues
		recode dg4_year14 (1=1) (2=1) (3=2) (4=2) (5=3) (6=3) (7=5) (8=3) (9=5) (10=5) (11=6) (12=6) (13=7) (14=8) (15=9) (16=-99) (17=-99) 
		recode dg4_year15 (1=1) (2=1) (3=2) (4=2) (5=3) (6=3) (7=5) (8=3) (9=5) (10=5) (11=6) (12=6) (13=7) (14=8) (15=9) (16=-99) (17=-99) 
		recode dg4_year16 (1=1) (2=1) (3=2) (4=2) (5=3) (6=3) (7=5) (8=3) (9=5) (10=5) (11=6) (12=6) (13=7) (14=8) (15=9) (96=-99) (99=-99) 
		recode dg4_year18 (4=5) (96=-99) (-2=-99) 
		
		gen highestedu_respondent = dg4_year14
			replace highestedu_respondent = dg4_year15 if highestedu_respondent==.
			replace highestedu_respondent = dg4_year16 if highestedu_respondent==.
			replace highestedu_respondent = dg4_year18 if highestedu_respondent==.			
		
				label var highestedu_respondent "Highest level of education of respondent"
				label define highestedu_respondent 1"No formal education" 2"Primary" 3"Jr. High" 5"HS/Vocational" 6"Diploma" 7"College/Uni" 8"Post-Graduate Uni" 9"Informal" -99"DK/Refuse/Other"
				label values highestedu_respondent highestedu_respondent
				
			* Create Dummbies of this Variable
				tab highestedu_respondent, gen(edu) lab
					rename edu2 noedu
						la var noedu "No Formal Education"
					rename edu3 primary
						lab var primary "Primary Education"
					rename edu4 jrhigh
						lab var jrhigh "Jr. High Education"
					rename edu5 hs
						lab var hs "High School Education"
					gen hs_orhigher = hs==1 | edu6==1 | edu7==1 | edu8==1
						lab var hs_orhigher "High School Education or Higher"
						
				foreach var in 	noedu primary jrhigh hs hs_orhigher{
					replace `var'=. if edu1==1
							}
	
	*6. Household role
		gen hhheadorspouse = 1 if dg6_year15 == 1 | dg6_year15 == 2
		replace hhheadorspouse = 1 if dg6_year16 == 1 | dg6_year16 == 2
		replace hhheadorspouse = 1 if dg6_year18 == 1 | dg6_year18 == 2
		
*JOB/INCOME VARIABLES
		
	*1. Worker Type
		g dl1_year18_raw = dl1_year18
		recode dl1_year14 (5=7) (6=5) (7=6) (8=7) (9=7) (10=-99) (11=-99) 
		recode dl1_year15 (4=3) (5=4) (6=7) (7=5) (8=6) (9=7) (10=7) (11=-99) (12=-99) 
		recode dl1_year16 (4=3) (5=4) (6=7) (7=5) (8=6) (9=7) (10=7) (96=-99) (99=-99) 
		recode dl1_year18 (4=3) (5=4) (6=7) (7=5) (8=6) (9=7) (10=7) (96=-99) (-2=-99) 

		gen workertype = dl1_year14
			replace workertype = dl1_year15 if workertype==.
			replace workertype = dl1_year16 if workertype==.
			replace workertype = dl1_year18 if workertype==.			
		
				label var workertype "Work Type"
				label define workertype 1 "Working full-time with reg. salary" 2 "Working part-time with reg. salary" 3 "Working occassionally, irregular pay/seasonal" 4 "Self-employed" 5 "Housewife/husband" 6 "Full-time student" 7 "Not working: looking/retire/disabled/sick" -99 "Other/Don't know/Refuse"		
				labe values workertype workertype
			
			* Create Dummies of this Variable
				gen salary = workertype==1 | workertype==2
					lab var salary "Salaried Worker"
				gen nonsalary = workertype==3
					lab var nonsalary "Non-Salaried Worker"
				gen selfemploy = workertype==4
					lab var selfemploy "Self-Employed"
				gen housewife = workertype==5
					lab var housewife "Housewive"
				gen student = workertype==6	
					la var student "Student"
				gen nowork = workertype==7	
					la var nowork "Not Working"
				
				foreach var in salary nonsalary selfemploy housewife student nowork {
					replace `var' =. if workertype==-99
							}
				
	*2. Job type [Just doing Agricultural, Gov't]
		foreach yr in 14 15 16 18{
			destring dl2_year`yr', replace
					}
		gen job_ag_worker = dl2_year14==1 
			replace job_ag_worker = 1 if dl2_year15==1 
			replace job_ag_worker = 1 if dl2_year16==1 
			replace job_ag_worker = 1 if dl2_year18==1			
		gen job_ag_owner = dl2_year14==2
			replace job_ag_owner = 1 if dl2_year15==2 
			replace job_ag_owner = 1 if dl2_year16==2 
			replace job_ag_owner = 1 if dl2_year18==2	
		gen job_prof = dl2_year14==3
			replace job_prof = 1 if dl2_year15==3
			replace job_prof = 1 if dl2_year16==3 
			replace job_prof = 1 if dl2_year18==3
		gen job_house = dl1_year14==5
			replace job_house = 1 if dl1_year15==5
			replace job_house = 1 if dl1_year16==5 
			replace job_house = 1 if dl1_year18==5

	*3. Employment status of male household head/spouse 
	
		gen employment_male = dl14_year14
			replace employment_male = dl17_year15 if employment_male==.
			replace employment_male = dl17_year16 if employment_male==.
			replace employment_male = dl17_year18 if employment_male==.			
				
				label var employment_male "Employment status of male household head/spouse"
				label define employment_male 1 "No male head/spouse" 2 "Not working, or unpaid worker" 3 "Self-employed" 4 "Business owner, or business owner with only temporary or unpaid workers" 5 "Wage or salary employee" 6 "Business owner with some permanent or paid workers"	
				labe values employment_male employment_male
				
	
	
	
*Weight
	gen weight  = weight_year14
			replace weight = weight_year15 if weight==. 
			replace weight = weight_year16 if weight==. 
			replace weight = weight_year18 if weight==.		
			

********************************************************************************
********************** CREATE OUTCOME VARS *****************************
********************************************************************************			
			
*MOBILE PHONE OUTCOME VARS

	*1. Any Cellphone Ownership
		foreach var in mt1_year14 mt2_year15 mt2_year16 mt2_year18{
			recode `var' (2=0)
				tab `var'
				}
		
		gen own_mobilephone = mt1_year14
			replace own_mobilephone = mt2_year15 if own_mobilephone==.
			replace own_mobilephone = mt2_year16 if own_mobilephone==.
			replace own_mobilephone = mt2_year18 if own_mobilephone==.	
			
				lab var own_mobilephone "Personally Owns Any Mobile"
		
	*2. Own Smartphone (excl. 2014)
		foreach var in mt3_3_year15 mt3_3_year16 mt2a_3_year18{
			destring `var', replace
				}
		gen mt3_3_year15_bin = 0 if year==2015 & (mt3_3_year15==0 | mt3_3_year15==.)
			replace mt3_3_year15_bin = 1 if year==2015 & (mt3_3_year15>=1 & mt3_3_year15!=.)
		gen mt3_3_year16_bin = 0 if year==2016 & (mt3_3_year16==0 | mt3_3_year16==.)
				replace mt3_3_year16_bin = 1 if year==2016 & (mt3_3_year16>=1 & mt3_3_year16!=.)
		recode mt2a_3_year18 (2=0)
			replace mt2a_3_year18=0 if mt2a_3_year18==. & year==2018
			
		gen own_smartphone = mt3_3_year15_bin==1 if mt3_3_year15_bin!=.
			replace own_smartphone = mt3_3_year16_bin if own_smartphone==.
			replace own_smartphone = mt2a_3_year18 if own_smartphone==.
				lab var own_smartphone "Personally Owns Smartphone"
	
*FINANCIAL OUTCOME VARS
	
	*1. Any Account Ownership [SNKI Replication - 2018 only]
		foreach var in bi_e5s bi_e26d bi_e27a bi_e14 ojk16_1 ojk16_2 ojk16_3 ojk16_4 ojk18_1 ojk18_2 ojk19_1 ojk19_2 ojk19_3 ojk24_1 ojk24_2 ojk20_1 ojk20_2 ojk21_1 ojk25_1 ojk25_2 ojk26_1 ojk26_2{
			destring `var'_year18, replace
				}
				
		gen Fnx_ATM_debit=0.
				replace Fnx_ATM_debit =1 if fnx_year18==1
				replace Fnx_ATM_debit = 1 if bi_e27a_year18>=1 & bi_e27a_year18<=100
				lab var Fnx_ATM_debit "Account ownership - Transction account"
				lab define Fnx_ATM_debit  1 "Yes" 0 "No"
				label values Fnx_ATM_debit Fnx_ATM_debit
		gen loan_save=0.
			foreach var in bi_e14 ojk16_1 ojk16_2 ojk16_3 ojk16_4 ojk18_1 ojk18_2 ojk19_1 ojk19_2 ojk19_3 ojk24_1 ojk24_2 ojk20_1 ojk20_2 ojk21_1 ojk25_1 ojk25_2 ojk26_1 ojk26_2{
			replace loan_save = 1 if `var'_year18==1
					}
				lab var loan_save "Account ownership - Savings or loan with a formal financial service provider"
				lab define loan_save 1"Yes" 0"No"
				lab values loan_save loan_save
		gen anyownership = 0	
			replace anyownership =1 if Fnx_ATM_debit==1 | loan_save==1 | bi_e5s_year18==1 | bi_e26d_year18==1
			lab var anyownership "Any Account Ownership"
			lab define anyownership 1"Yes" 0"No"		
			lab values anyownership anyownership
		
		foreach var in Fnx_ATM_debit loan_save anyownership{
			replace `var'=. if year!=2018
				}
		
	*2. HAS ANY BANK ACCOUNT [SNKI Replication - 2018 only]
		foreach var in bi_e1a bi_e1b bi_e1c bi_e1v bi_e25d{
			destring `var'_year18, replace
				}
		g hasbankacct = (bi_e1a_year18==1 | bi_e1b_year18==1 | bi_e1c_year18==1 | bi_e1v_year18==1) if year==2018
		sum hasbankacct [w=weight]
			lab var hasbankacct "Has Any Bank Account"
		
	*3. HAS EVER USED ANY BANK SERVICE [SNKI Replication - 2018 only]
		forvalues i=1/14{
			gen ojk1_`i'_ever=ojk1_`i'_year18==1 if year==2018
				}		
		egen snki_ever_use_bank = rowmax(ojk1_*_ever) if year==2018	
		sum snki_ever_use_bank [w=weight] 
				lab var snki_ever_use_bank "Has Ever Used Any Bank Service"
		
	*4. HAVE EVER USED ANY MULTIFINANCE SERVICE	 [SNKI Replication - 2018 only]	
		forvalues i=1/5{
			gen ojk3_`i'_ever=ojk3_`i'_year18==1 if year==2018
				}		
		egen snki_ever_use_multifinance = rowmax(ojk3_*_ever) if year==2018		
		sum snki_ever_use_multifinance [w=weight]	
				lab var snki_ever_use_multifinance "Has Ever Used Any Multifinance Service"
		
		
	*HAVE EVER USED INSURANCE (EXCL BPJS)  [SNKI Replication - 2018 only]
		forvalues i=1/11{
			gen ojk2_`i'_ever=ojk2_`i'_year18==1 if year==2018
				}
		egen snki_ever_use_insurance = rowmax(ojk2_*_ever) if year==2018	
		sum snki_ever_use_insurance [w=weight]	
				lab var snki_ever_use_insurance "Has Ever Used Any Insurance Service"
		
		
	*HAVE EVER USED CO-OP/LKM/S  [SNKI Replication - 2018 only]
		forvalues i=1/3{
			gen ojk11_`i'_ever=ojk11_`i'_year18==1 if year==2018
			gen ojk12_`i'_ever=ojk12_`i'_year18==1 if year==2018
			gen ojk13_`i'_ever=ojk13_`i'_year18==1 if year==2018
				}
		egen snki_ever_use_coop_lkms = rowmax(ojk11_*_ever ojk12_*_ever ojk13_*_ever) if year==2018	
		sum snki_ever_use_coop_lkms [w=weight]	
				lab var snki_ever_use_coop_lkms "Has Ever Used Any Co-Op or Microfinance Service"
		
		
	*HAVE EVER USED PAWNSHOP  [SNKI Replication - 2018 only]
		forvalues i=1/4{
			gen ojk6_`i'_ever=ojk6_`i'_year18==1 if year==2018
				}
		egen snki_ever_use_pawnshop = rowmax(ojk6_*_ever) if year==2018		
		sum snki_ever_use_pawnshop [w=weight]
				lab var snki_ever_use_pawnshop "Has Ever Used Any Pawnshop Service"
		
		
	*HAVE EVER USED PENSION (INCLU BPJS, DESPITE WHAT IS SAYS ON SLIDES)  [SNKI Replication - 2018 only]
		forvalues i=1/3{
			gen ojk5_`i'_ever=ojk5_`i'_year18==1  if year==2018
				}
		egen snki_ever_use_pension = rowmax(ojk5_*_ever) if year==2018 
			replace snki_ever_use_pension = 1 if ojk22_2=="1" //So this is having using BPJS employment in past 30 days
		sum snki_ever_use_pension [w=weight]	
				lab var snki_ever_use_pension "Has Ever Used Any Pension Service (Incl BPJS)"
		
		
	*HAVE EVER USED SERVER-BASED MOBILE MONEY  [SNKI Replication - 2018 only]
		gen snki_ever_use_server_emoney = bi_e25d_year18==1	if year==2018			
		sum snki_ever_use_server_emoney [w=weight]		
				lab var snki_ever_use_server_emoney "Has Ever Used Server-Based E-Money"
		
		
	*HAVE EVER USED INVESTMENT FUNDS  [SNKI Replication - 2018 only]
		forvalues i=1/4{
			gen ojk7_`i'_ever=ojk7_`i'_year18==1 if year==2018
				}
		forvalues i=1/2{
			gen ojk8_`i'_ever=ojk8_`i'_year18==1 if year==2018
				}				
		egen snki_ever_use_invest = rowmax(ojk7_*_ever ojk8_*_ever)	 if year==2018
		sum snki_ever_use_invest [w=weight]			
				lab var snki_ever_use_invest "Has Ever Used Any Investment Service"
		

	*EVER USED POST OFFICE [EXCLUDED FROM SLIDE 2, DOES NOT INCLUDE OTHER SERVICES]
		forvalues i=1/3{
			gen ojk10_`i'_ever=ojk10_`i'_year18==1 
				}		
		egen snki_ever_use_pos = rowmax(ojk10_*_ever) if year==2018	
		sum snki_ever_use_pos [w=weight]		
			lab var snki_ever_use_pos "Has Ever Used Any Post Office Service"
			
		
	*HAS EVER USED ANY FINANCIAL SERVICE  [SNKI Replication - 2018 only]
		egen snki_ever_use_any = rowmax(snki_ever_use_*) if year==2018	
		sum snki_ever_use_any [w=weight]	
			lab var snki_ever_use_any "Has Ever Used Any Formal Financial Service"
						
						
// ***	These are NOT included in SNKI defintion	
		
*EVER USED CARD-BASED MONEY [EXCLUDED FROM SLIDE 2]
		gen ever_use_atmcard = bi_e25a=="1"					
		gen ever_use_ccard = bi_e25b=="1"					
		gen ever_use_card_emoney = bi_e25c=="1"					

		egen ever_use_card_money = rowmax(ever_use_atmcard ever_use_ccard ever_use_card_emoney)		
		sum ever_use_card_money [w=weight]	
		
*EVER USED BPJS [EXCLUDED FROM SLIDE 2]
		forvalues i=1/2{
			gen ojk9_`i'_ever=ojk9_`i'==1
				}		
		egen ever_use_bpjs = rowmax(ojk9_*_ever)	
		sum ever_use_bpjs [w=weight]	
		

		
*Mobile Money: Heard of
		*destring some vars first
		drop mm2_others_year16
			ds mm2_*_year16 mm3_*_year16 mm2_*_year15 mm3_*_year15 mm2_*_year14 mm3_*_year14
			foreach var in `r(varlist)'{
				destring `var',replace
						}
		gen know_mobilemoney = bi_e24d_year18
			replace know_mobilemoney = mm1_year14 if know_mobilemoney==.
			replace know_mobilemoney = mm1_year15 if know_mobilemoney==.
			replace know_mobilemoney = mm1_year16 if know_mobilemoney==.
					*also include if they say they know a mobile money company
				ds mm2_*_year16 mm3_*_year16 mm2_*_year15 mm3_*_year15 mm2_*_year14 mm3_*_year14
						foreach var in `r(varlist)'{
							replace know_mobilemoney = 1 if `var'==1
									}					
					recode know_mobilemoney (2=0)
					label var know_mobilemoney "Heard of Mobile Money"

*Mobile Money: Use	
		*destring some vars first
			ds mm4_*_year16 mm4_*_year15 mm5_*_year14
			foreach var in `r(varlist)'{
				destring `var',replace
						}
		gen use_mobilemoney = bi_e25d_year18
			ds mm4_*_year16 mm4_*_year15 mm5_*_year14
				foreach var in `r(varlist)'{
					replace use_mobilemoney = `var' if use_mobilemoney==.
							}							
			recode use_mobilemoney (2=0)	
			recode know_mobilemoney (2=0)
			
			replace use_mobilemoney = 0 if know_mobilemoney==0 
					
					label var use_mobilemoney "Ever Used Mobile Money"		
		

save "$final/fii-all-clean-inprogress.dta", replace

use "$final/fii-all-clean-inprogress.dta", clear

 keep if year==2018
 drop *year14 *year15 *year16
 
* Marital status
	destring i_*_d3_year18, replace
	egen hh_havechildren = min(i_1_d3_year18 < 18 | i_2_d3_year18 < 18 | i_3_d3_year18 < 18 | ///
		i_4_d3_year18 < 18 | i_5_d3_year18 < 18 | i_6_d3_year18 < 18 | i_7_d3_year18 < 18 | i_8_d3_year18 < 18 | ///
		i_9_d3_year18 < 18 | i_10_d3_year18 < 18), by(serial)
	
	gen single = dg3_year18 == 0 & inlist(dg6_year18, 2,4,5,6,8,9)
	gen divorced = dg3_year18 == 0 & inlist(dg6_year18, 3,7)
	replace divorced = 1 if hh_havechildren == 1 & dg3_year18 == 2 & dg6_year18 == 1
	
	gen marital_status = 1 if single == 1
	replace marital_status = 2 if married == 1
	replace marital_status = 3 if divorced == 1
	
* HH decision making
	gen hh_general = inlist(hhdecision_general,4,5)
	gen hh_basic = inlist(hhdecision_basic,4,5)
	gen hh_beyondbasic = inlist(hhdecision_beyondbasic,4,5)
	gen hh_influence = inlist(hhdecision_influence,4,5)
	gen hh_voicedisagree = inlist(hhdecision_voicedisagree,4,5)
	gen hh_final = inlist(hhdecision_final,4,5)
	gen hh_ownmoney = inlist(hhdecision_ownmoney,4,5)
	
{ 

* NATALIE'S CONSTRUCTION CODE


*SNKI INDICATORS
* 1) Currently has between 1 and 100 ATM cards in their own name [bi_e27a]
gen hasatm = bi_e27a>0 & bi_e27a<100
lab var hasatm "Has ATM Card"

* 2) Loan from multi-finance [ojk16_1 ojk16_2 ojk16_3 ojk16_4]
gen loanmulti = inlist(ojk16_1, 1, 2, 3) | inlist(ojk16_2, 1, 2, 3) | inlist(ojk16_3, 1, 2, 3) | inlist(ojk16_4, 1, 2, 3)
lab var loanmulti "Has Loan from Multifinance"

* 3) Loan from Pawnshop [ojk19_1 ojk19_2 ojk19_3]
gen loanpawn = inlist(ojk19_1, 1, 2, 3) | inlist(ojk19_2, 1, 2, 3) | inlist(ojk19_3, 1, 2, 3)
lab var loanpawn "Has Loan from Pawnshop"

* 4) Loan from Microfinance (incl Sharia) [ojk24_1, ojk26_1]
gen loanmicro = inlist(ojk24_1, 1, 2, 3) | inlist(ojk26_1, 1, 2, 3)
lab var loanmicro "Has Loan from Microfinance"

* 5) Savings at Microfinance (incl Sharia) [ojk24_2, ojk26_2]
gen savmicro = inlist(ojk24_2, 1, 2, 3) | inlist(ojk26_2, 1, 2, 3)
lab var savmicro "Has Savings Account from Microfinance"

* 6) Loan from Cooperative [ojk25_1]
gen loancoop = inlist(ojk25_1, 1, 2, 3)  
lab var loancoop "Has Loan from Cooperative"

* 7) Savings at Cooperative [ojk25_2]
gen savecoop = inlist(ojk25_2, 1, 2, 3)  
lab var savecoop "Has Savings Account from Cooperative"

* 8) BSA [bi_e5s]
gen bsa = inlist(bi_e5s, 1)  
lab var bsa "Has Basic Savings Account"

* 9) e-money [bi_e26d]
gen emoney = inlist(bi_e26d, 1)  
lab var emoney "Has Electronic Money"


* 10) investments ojk18_1 ojk18_2 ojk20_1 ojk20_2 ojk21_1
gen invest = inlist(ojk18_1, 1, 2, 3) | inlist(ojk18_2, 1, 2, 3) | inlist(ojk20_1, 1, 2, 3) | inlist(ojk20_2, 1, 2, 3) | inlist(ojk21_1, 1, 2, 3)
lab var invest "Has Investments"

*NON SNKI
*11) savings account
gen savings =  inlist(ojk14_1_year18, "1", "2", "3") | inlist(ojk14_2_year18, "1", "2", "3") | inlist(ojk14_3_year18, "1", "2", "3")
  lab var savings "Has Savings Account at Bank"
 

*12) loans from bank
gen loanbank =  inlist(ojk14_5_year18, "1", "2", "3") | inlist(ojk14_6_year18, "1", "2", "3") | inlist(ojk14_7_year18, "1", "2", "3") | inlist(ojk14_8_year18, "1", "2", "3") | inlist(ojk14_9_year18, "1", "2", "3") | inlist(ojk14_10_year18, "1", "2", "3") | inlist(ojk14_12_year18, "1", "2", "3") | inlist(ojk14_13_year18, "1", "2", "3")
  lab var loanbank "Has Loan at Bank"



egen included = rowtotal(hasatm loanmulti loanpawn loanmicro savmicro loancoop savecoop bsa emoney invest loanbank savings)
gen included_bin = included>0
tab2 included_bin anyownership

*gen have some bank account but we don't know what type

gen haveother = included_bin==0 & Fnx_ATM_debit==1 & loan_save==0
lab var haveother "Has an Account - Unknown"
* gen have some loan but don't know what type

gen haveloanother = included_bin==0 & loan_save==1
lab var haveloanother "Has a Loan - Unknown"

egen included2 = rowtotal(included haveother haveloanother)
gen included_bin2 = included2>0
tab2 included_bin2 anyownership

}

gen formal = loanbank == 1 | savings == 1
gen informal = loanmulti == 1 | loanpawn == 1 | loanmicro == 1 | savmicro == 1 | loancoop == 1 | savecoop == 1 

keep if age > 17

save "$final/fii2018", replace
