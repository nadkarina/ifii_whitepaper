* ******************************************************************************
* PROGRAM: FII DATA PREPARATION FOR ANALYSIS
* PROGRAMMER: Natalie Theys
* PURPOSE: Create a clean FII dataset
* DATE CREATED: 17 December 2019
* LAST MODIFIED: 14 September 2020
* ******************************************************************************


** IMPORT DATASET **
import delimited "${fii}/FII Indonesia 2018 (public+ANONGPS).csv", varnames(1) clear

*use excel codebook

*LOCATION VARAIABLES

	*1. Province	
		gen province = aa1
			label var province "Province"
			
	*2. District
		gen district = aa2
			label var district "District"
			
	*3. Urban
		gen urban = aa7==1
			label var urban "Urban"
			
*HOUSEHOLD ROSTER VARAIABLES

	*1. All School-Aged Children Attending School
		gen all_children_school = dl15	
			recode all_children_school (1=-99) (2=0) (3=1)
			lab var all_children_school "Do all household members aged 6-18 currently attend school"
					label define all_children_school 0 "No" 1 "Yes" -99 "N/A: No members age 6 to 18"
					label values all_children_school all_children_school
					
	*2. Highest Education Level Female Head/Spouse
		gen highestedu_female = dl16	
		recode highestedu_female (1=0) (4=-99) (2=1) (3=2) (5=3) (6=4) (7=5)
			lab var highestedu_female "Highest Level of Education of Female HH Head/Female Spouse"
					label define highestedu_female 0 "No Education" 1 "Primary" 2 "Jr High" 3 "Vocational (HS level)" 4"High School" 5"Diploma" -99 "N/A: No female head/spouse"
					label values highestedu_female highestedu_female	
	
	*3. * Household decision making
			foreach var of varlist gn1 gn2 gn3 gn4 gn5 gn6 gn7 {
			replace `var' = .r if `var' == -3
			replace `var' = .d if `var' == -3
			}
			
		g invovle_hhinc = gn1
			lab var invovle_hhinc "Deciding how to spend your household’s income?"
				lab define gn 1"Very uninvolved" 2"Somewhat uninvolved" 3"Neither uninvolved, nor involved" 4"Somewhat involved" 5"Very involved" -3"Refused" -2"Don't Know"
				lab values invovle_hhinc gn
		g invovle_basics = gn2 
			lab var invovle_basics "Deciding how your household’s income is spent on basic needs like food and clothing?"
				lab values invovle_basics gn
		g invovle_beybasics = gn3 
			lab var invovle_beybasics "Deciding how your household’s income is spent on other things beyond basic needs?"
			lab values invovle_beybasics gn
		g influence_spending = gn4 
			lab var influence_spending "If you were to speak your mind on a typical decision on how to spend your household’s income, how much influence would you have on the final decision?"
			lab define g4 1"None" 2"A little" 3"A fair amount" 4"Most" 5"Almost all" -3"Refused" -2"Don't Know"
			lab values influence_spending gn4
		g voice_disagreement = gn5
			lab var voice_disagreement "If you happened to disagree with a typical decision about how your household’s income is spent, how likely would you be to voice disagreement?"
			lab define g5 1"Very unlikely" 2"Somewhat unlikely" 3"Neither unlikely, nor likely" 4"Somewhat likely" 5"Very likely" -3"Refused" -2"Don't Know"
			lab values voice_disagreement g5
		g finaldec_hhinc = gn6
			lab var finaldec_hhinc "Hw much you agree or disagree with the following statements: You make the final decision on how household income is spent."
			lab define agree 1"Strongly disagree" 2"Somewhat disagree" 3"Neither disagree, nor agree" 4"Somewhat agree" 5"Strongly agree"  -3"Refused" -2"Don't Know"
			lab values finaldec_hhinc agree
		g finaldec_ownmoney = gn7
			lab var finaldec_ownmoney "How much you agree or disagree with the following statements: You make the final decision on how your money is spent or saved."
			lab values finaldec_ownmoney agree
		g trust_in_system = gn8  
			lab var trust_in_system "How much you agree or disagree with the following statements: You trust financial service providers to keep your personal information private unless you allow it to be shared."
			lab values trust_in_system agree
	
*INFORMATION ABOUT THE RESPONDENT VARIABLES
	
	*1. Birth Year
		gen birth_year = dg1	
		replace birth_year = -98 if birth_year==. | birth_year==99
				label var birth_year "Birth Year of Respondent"
				label define birth_year -98 "Don't know/missing"
				label values birth_year birth_year
				
	*2. Age
		label var age "Age (Years)"
					
	*3. Gender
		gen female = dg2==2	
			label var female "Female"
				
	*4. Marital Status
		gen married = dg3==1
			label var married "Married"
			label define married 0 "Not Married" 1 "Married" 
			label values married married
	
	*5. Highest Level of Education
		gen highestedu_respondent = dg4
		recode highestedu_respondent (4=5) (96=-99) (-2=-99) 
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
		
*JOB/INCOME VARIABLES
		
	*1. Worker Type
		g dl1_raw = dl1
		g workertype = dl1
		recode workertype (4=3) (5=4) (6=7) (7=5) (8=6) (9=7) (10=7) (96=-99) (-2=-99)		
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
				
	*3. Employment status of male household head/spouse 
	
		gen employment_male = dl17		
			label var employment_male "Employment status of male household head/spouse"
			label define employment_male 1 "No male head/spouse" 2 "Not working, or unpaid worker" 3 "Self-employed" 4 "Business owner, or business owner with only temporary or unpaid workers" 5 "Wage or salary employee" 6 "Business owner with some permanent or paid workers"	
			labe values employment_male employment_male


********************************************************************************
********************** CREATE OUTCOME VARS *****************************
********************************************************************************			
			
*MOBILE PHONE OUTCOME VARS

	*1. Any Cellphone Ownership
		gen own_mobilephone = mt2
		recode own_mobilephone (2=0)			
			lab var own_mobilephone "Personally Owns Any Mobile"
		
	*2. Own Smartphone (excl. 2014)
		destring mt2a_3, replace
		gen own_smartphone = mt2a_3
		recode own_smartphone (2=0)
			replace own_smartphone=0 if mt2a_3==.
			lab var own_smartphone "Personally Owns Smartphone"
	
*FINANCIAL OUTCOME VARS
	
	*1. Any Account Ownership [SNKI Replication - 2018 only]
		foreach var in bi_e5s bi_e26d bi_e27a bi_e14 ojk16_1 ojk16_2 ojk16_3 ojk16_4 ojk18_1 ojk18_2 ojk19_1 ojk19_2 ojk19_3 ojk24_1 ojk24_2 ojk20_1 ojk20_2 ojk21_1 ojk25_1 ojk25_2 ojk26_1 ojk26_2{
			destring `var', replace
				}
				
		gen Fnx_ATM_debit=0.
				replace Fnx_ATM_debit =1 if fnx==1
				replace Fnx_ATM_debit = 1 if bi_e27a>=1 & bi_e27a<=100
				lab var Fnx_ATM_debit "Account ownership - Transction account"
				lab define Fnx_ATM_debit  1 "Yes" 0 "No"
				label values Fnx_ATM_debit Fnx_ATM_debit
		gen loan_save=0.
			foreach var in bi_e14 ojk16_1 ojk16_2 ojk16_3 ojk16_4 ojk18_1 ojk18_2 ojk19_1 ojk19_2 ojk19_3 ojk24_1 ojk24_2 ojk20_1 ojk20_2 ojk21_1 ojk25_1 ojk25_2 ojk26_1 ojk26_2{
			replace loan_save = 1 if `var'==1
					}
				lab var loan_save "Account ownership - Savings or loan with a formal financial service provider"
				lab define loan_save 1"Yes" 0"No"
				lab values loan_save loan_save
		gen anyownership = 0	
			replace anyownership =1 if Fnx_ATM_debit==1 | loan_save==1 | bi_e5s==1 | bi_e26d==1
			lab var anyownership "Any Account Ownership"
			lab define anyownership 1"Yes" 0"No"		
			lab values anyownership anyownership
		
	*2. HAS ANY BANK ACCOUNT [SNKI Replication - 2018 only]
		foreach var in bi_e1a bi_e1b bi_e1c bi_e1v bi_e25d{
			destring `var', replace
				}
		g hasbankacct = (bi_e1a==1 | bi_e1b==1 | bi_e1c==1 | bi_e1v==1) 
		sum hasbankacct [w=weight]
			lab var hasbankacct "Has Any Bank Account"
		
	*3. HAS EVER USED ANY BANK SERVICE [SNKI Replication - 2018 only]
		forvalues i=1/14{
			gen ojk1_`i'_ever=ojk1_`i'==1 
				}		
		egen snki_ever_use_bank = rowmax(ojk1_*_ever) 	
		sum snki_ever_use_bank [w=weight] 
				lab var snki_ever_use_bank "Has Ever Used Any Bank Service"
		
	*4. HAVE EVER USED ANY MULTIFINANCE SERVICE	 [SNKI Replication - 2018 only]	
		forvalues i=1/5{
			gen ojk3_`i'_ever=ojk3_`i'==1 
				}		
		egen snki_ever_use_multifinance = rowmax(ojk3_*_ever) 		
		sum snki_ever_use_multifinance [w=weight]	
				lab var snki_ever_use_multifinance "Has Ever Used Any Multifinance Service"
		
		
	*HAVE EVER USED INSURANCE (EXCL BPJS)  [SNKI Replication - 2018 only]
		forvalues i=1/11{
			gen ojk2_`i'_ever=ojk2_`i'==1 
				}
		egen snki_ever_use_insurance = rowmax(ojk2_*_ever) 	
		sum snki_ever_use_insurance [w=weight]	
				lab var snki_ever_use_insurance "Has Ever Used Any Insurance Service"
		
		
	*HAVE EVER USED CO-OP/LKM/S  [SNKI Replication - 2018 only]
		forvalues i=1/3{
			gen ojk11_`i'_ever=ojk11_`i'==1 
			gen ojk12_`i'_ever=ojk12_`i'==1 
			gen ojk13_`i'_ever=ojk13_`i'==1 
				}
		egen snki_ever_use_coop_lkms = rowmax(ojk11_*_ever ojk12_*_ever ojk13_*_ever) 	
		sum snki_ever_use_coop_lkms [w=weight]	
				lab var snki_ever_use_coop_lkms "Has Ever Used Any Co-Op or Microfinance Service"
		
		
	*HAVE EVER USED PAWNSHOP  [SNKI Replication - 2018 only]
		forvalues i=1/4{
			gen ojk6_`i'_ever=ojk6_`i'==1 
				}
		egen snki_ever_use_pawnshop = rowmax(ojk6_*_ever) 		
		sum snki_ever_use_pawnshop [w=weight]
				lab var snki_ever_use_pawnshop "Has Ever Used Any Pawnshop Service"
		
		
	*HAVE EVER USED PENSION (INCLU BPJS, DESPITE WHAT IS SAYS ON SLIDES)  [SNKI Replication - 2018 only]
		forvalues i=1/3{
			gen ojk5_`i'_ever=ojk5_`i'==1  
				}
		egen snki_ever_use_pension = rowmax(ojk5_*_ever)  
			replace snki_ever_use_pension = 1 if ojk22_2=="1" //So this is having using BPJS employment in past 30 days
		sum snki_ever_use_pension [w=weight]	
				lab var snki_ever_use_pension "Has Ever Used Any Pension Service (Incl BPJS)"
		
		
	*HAVE EVER USED SERVER-BASED MOBILE MONEY  [SNKI Replication - 2018 only]
		gen snki_ever_use_server_emoney = bi_e25d==1				
		sum snki_ever_use_server_emoney [w=weight]		
				lab var snki_ever_use_server_emoney "Has Ever Used Server-Based E-Money"
		
		
	*HAVE EVER USED INVESTMENT FUNDS  [SNKI Replication - 2018 only]
		forvalues i=1/4{
			gen ojk7_`i'_ever=ojk7_`i'==1 
				}
		forvalues i=1/2{
			gen ojk8_`i'_ever=ojk8_`i'==1 
				}				
		egen snki_ever_use_invest = rowmax(ojk7_*_ever ojk8_*_ever)	 
		sum snki_ever_use_invest [w=weight]			
				lab var snki_ever_use_invest "Has Ever Used Any Investment Service"
		

	*EVER USED POST OFFICE [EXCLUDED FROM SLIDE 2, DOES NOT INCLUDE OTHER SERVICES]
		forvalues i=1/3{
			gen ojk10_`i'_ever=ojk10_`i'==1 
				}		
		egen snki_ever_use_pos = rowmax(ojk10_*_ever) 	
		sum snki_ever_use_pos [w=weight]		
			lab var snki_ever_use_pos "Has Ever Used Any Post Office Service"
			
		
	*HAS EVER USED ANY FINANCIAL SERVICE  [SNKI Replication - 2018 only]
		egen snki_ever_use_any = rowmax(snki_ever_use_*) 	
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
		
*Mobile Money: Heard of
		gen know_mobilemoney = bi_e24d
			recode know_mobilemoney (2=0)
			label var know_mobilemoney "Heard of Mobile Money"

*Mobile Money: Use	

		gen use_mobilemoney = bi_e25d		
			recode use_mobilemoney (2=0)				
			replace use_mobilemoney = 0 if know_mobilemoney==0 
					label var use_mobilemoney "Ever Used Mobile Money"

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
gen savings =  inlist(ojk14_1, "1", "2", "3") | inlist(ojk14_2, "1", "2", "3") | inlist(ojk14_3, "1", "2", "3")
  lab var savings "Has Savings Account at Bank"
 

*12) loans from bank
gen loanbank =  inlist(ojk14_5, "1", "2", "3") | inlist(ojk14_6, "1", "2", "3") | inlist(ojk14_7, "1", "2", "3") | inlist(ojk14_8, "1", "2", "3") | inlist(ojk14_9, "1", "2", "3") | inlist(ojk14_10, "1", "2", "3") | inlist(ojk14_12, "1", "2", "3") | inlist(ojk14_13, "1", "2", "3")
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

gen formal = loanbank == 1 | savings == 1
gen informal = loanmulti == 1 | loanpawn == 1 | loanmicro == 1 | savmicro == 1 | loancoop == 1 | savecoop == 1 

*keep if age > 17



		save "${final}/fii2018", replace					


** PREPARE DATA FOR RANDOM FOREST
********************************************************************************
*************************** CLEAN AND PREP DATA ********************************
********************************************************************************

	
*Create vars for use and depth of use in past 6 months
	destring dl2, replace
	replace dl2 = 0 if missing(dl2)
	
	
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
	replace jobtype = 0 if (dl1==6 | dl1==7 | dl1==8 | dl1==9 | dl1==10)
	
	
*Create Var on Number of Income Sources
	foreach var in dl4_1 dl4_2 dl4_3 dl4_4 dl4_5 dl4_6 dl4_7 dl4_8 dl4_9 dl4_10 dl4_11{
		recode `var' (2=0)
		assert `var'!=.
			}
	egen num_income_sources = rowtotal(dl4_1 dl4_2 dl4_3 dl4_4 dl4_5 dl4_6 dl4_7 dl4_8 dl4_9 dl4_10 dl4_11)		
			

	
*Clean vars on decisionmaking
	foreach var in invovle_hhinc invovle_basics invovle_beybasics influence_spending voice_disagreement finaldec_hhinc finaldec_ownmoney trust_in_system{
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
		
*share phone
	gen used_shared = mt7==1
	
********************************************************************************
***************************** DROP MISSING VARS  *******************************
********************************************************************************

*Drop observations missing the following:
	drop if highestedu_respondent_sub==. | rel_hh_head==. | income_pct==. | jobtype==. | hh_head_age_bin==.


*SPLIT OUT BPJS
	g bpjs_health = ojk9_1==1
	g bpjs_labor = ojk9_2==1
	
*We do not want to use a series of binary variables in random forest
	keep  everuse  use_6mon_atm_bin ownership  province urban highestedu_female resp_age_bin used_shared ///
		 highestedu_respondent  workertype employment_male poverty_bin female married jobtype income_pct dl14 ln1 ln2_1 ln2_2 ///
		 own_mobilephone phonetasks_today phonetasks_bas_today phonetasks_adv_today phonetasks_week phonetasks_bas_week phonetasks_adv_week phonetasks_month phonetasks_bas_month phonetasks_adv_month phonetasks_ever phonetasks_bas_ever phonetasks_adv_ever ///
		 mt18a_1_mi mt18a_2_mi mt18a_3_mi mt18a_4_mi mt18a_5_mi mt18a_6_mi phoneusage_basic_n phoneusage_adv_n ///
		 bpjs_health  bpjs_labor  dl1_raw ///
		 dg5_1 dg5_2 dg5_3 dg5_4 dg5_5 dg5_6 num_ids    ///
		 rel_hh_head  income_pct num_income_sources dl4_1 dl4_2 dl4_3 dl4_4 dl4_5 dl4_6 dl4_7 dl4_8 dl4_9 dl4_10 dl4_11 ///
		   dl21 dl22 dl23 dl18 dl19  dl20  ///
		 invovle_hhinc invovle_basics invovle_beybasics influence_spending voice_disagreement finaldec_hhinc finaldec_ownmoney trust_in_system ///
		  bi_e43_1 bi_e43_2 bi_e43_3 bi_e43_4 bi_e43_5 bi_e43_6 bi_e43_7 bi_e43_8 bi_e43_9 bi_e43_10 bi_e43_11 bi_e43_12 bi_e43_13 bi_e43_14 ///
		  weight ///
		   hh_head_age_bin hh_head_fem hh_size hh_num_males hh_num_females hhm_u4_f hhm_u4_m hhm_5t8_f hhm_5t8_m hhm_9t12_f hhm_9t12_m hhm_13t15_f hhm_13t15_m hhm_16t18_f hhm_16t18_m any_teenage_boys any_teenage_girls  own_smartphone *mobilemoney ///
			Fnx_ATM_debit
	  

********************************************************************************
**************************** LABEL ALL CAT. DATA  ******************************
********************************************************************************



*HAVE TO LABEL ALL DATA FOR IT TO WORK AS FACTORS IN R
	label define yesno 1"Yes" 0"No"

	foreach var in  everuse  use_6mon_atm_bin ownership hh_head_fem bpjs_health  bpjs_labor female  married poverty_bin own_mobilephone dg5_1 dg5_2 dg5_3 dg5_4 dg5_5 dg5_6 dl4_1 dl4_2 dl4_3 dl4_4 dl4_5 dl4_6 dl4_7 dl4_8 dl4_9 dl4_10 dl4_11  dl21 dl22 dl23 any_teenage_boys any_teenage_girls  own_smartphone used_shared know_mobilemoney use_mobilemoney{
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

	lab define	influence_spending  0"dk ref" 1"none" 2"a little" 3"fair amount" 4"most" 5"almost all"
	lab define  voice_disagreement  0"dk ref" 1"v unlikely" 2"some unlikely" 3"neither" 4"some likely" 5"v likely" 
	lab define  finaldec_hhinc  0"dk ref" 1"strong disagree" 2"somewhat disagree" 3"neither" 4"some agree" 5"strong agree" 
	lab define  finaldec_ownmoney 0"dk ref" 1"strong disagree" 2"somewhat disagree" 3"neither" 4"some agree" 5"strong agree" 
	lab define  trust_in_system  0"dk ref" 1"strong disagree" 2"somewhat disagree" 3"neither" 4"some agree" 5"strong agree" 

	lab define ln1 1"fluent" 2"some help" 3"struggle" 4"unable"
	lab define ln2_1 1"cannot" 2"badly" 3"somewhat badly" 4"good" 5"excellent"
	lab define ln2_2 1"cannot" 2"badly" 3"somewhat badly" 4"good" 5"excellent"

	 lab define ability 0"dk" 1"none" 2"little" 3"some" 4"complete"
	 
	lab define gn1 0"dk ref" 1"v uninvolved" 2"some uninvolved" 3"neither" 4"some involved" 5"v involved"
	 

	foreach var in  bi_e43_1 bi_e43_2 bi_e43_3 bi_e43_4 bi_e43_5 bi_e43_6 bi_e43_7 bi_e43_8 bi_e43_9 bi_e43_10 bi_e43_11 bi_e43_12 bi_e43_13 bi_e43_14{
		lab values `var' distance
		}
		
	 foreach var in invovle_hhinc invovle_basics invovle_beybasics{
		lab values `var' gn1
		}
	 
	 foreach var in  mt18a_1_mi mt18a_2_mi mt18a_3_mi mt18a_4_mi mt18a_5_mi mt18a_6_mi {
		label values `var' ability
		}
		
	foreach var in dl1_raw phoneusage_basic_n phoneusage_adv_n rel_hh_head resp_age_bin hh_head_age_bin province urban highestedu_female highestedu_respondent income_pct jobtype num_ids num_income_sources phonetasks_today phonetasks_bas_today phonetasks_adv_today phonetasks_week phonetasks_bas_week phonetasks_adv_week phonetasks_month phonetasks_bas_month phonetasks_adv_month phonetasks_ever phonetasks_bas_ever phonetasks_adv_ever dl14 dl18 dl19 dl20 influence_spending voice_disagreement finaldec_hhinc finaldec_ownmoney trust_in_system ln1 ln2_1 ln2_2 {
		lab values `var' `var'
			}	
	  
	  
  
*Misc prepartion		
	order  Fnx_ATM_debit everuse use_6mon_atm_bin ownership  
	
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
	

	
		
replace ability_fintrans = 5 if ability_fintrans==0	
 lab define ability2 1"none" 2"little" 3"some" 4"complete"  5"dk", modify
	lab values ability_fintrans ability2
	
	drop if missing(invovle_hhinc) | missing(invovle_basics) | missing(invovle_beybasics) | missing(influence_spending) | missing(voice_disagreement) | missing(finaldec_hhinc) | missing(finaldec_ownmoney)
	
	*drop province
	drop ownership
	drop num_income_sources
	drop num_ids
	rename Fnx_ATM_debit ownership
	
*SAVE DATASET
	save "${final}/fii-clean-randomforestprofiles.dta", replace
	
