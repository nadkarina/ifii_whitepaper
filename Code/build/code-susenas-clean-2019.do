* ******************************************************************************
* PROGRAM: SUSENAS DATA PREPARATION
* AUTHORS: Nick Wisely
* PURPOSE: Create a clean 2019 Susenas dataset
* DATE CREATED: 09 June 2020
* LAST MODIFIED: 25 August 2020 by Nadia Setiabudi
* ******************************************************************************


********************************************************************************
*************************** PREPARE THE SUSENAS DATA ***************************
********************************************************************************

* Household data
	{
	use "$susenas19\kor19rt_revisi1_diseminasi.dta", clear
	
	rename RENUM URUT
	
	isid URUT // Check unique identifier
	
	* Generate social protection variables
		gen byte raskin = R2101 == 1
		label var raskin "Raskin"
		
		gen byte bpnt = R2109 == 1 
		label var bpnt "BPNT"
		
		replace R2108IK2 = 0 if R2108IK2 == .
		replace R2108IIK2 = 0 if R2108IIK2 == .
		replace R2108IIIK2 = 0 if R2108IIIK2 == .
		
		gen byte pip = R2108IK2 + R2108IIK2 + R2108IIIK2 > 0 
		label var pip "PIP"
		
		gen byte kis = R2105 != 5 
		label var kis "KIS"
		
		gen byte pkh = R2106 == 1 
		label var pkh "PKH"
		
		gen byte pkh_card = R2107A == 1
		label var pkh_card "PKH card"
		
		gen byte lpg = R1817== 4
		label var lpg "LPG 3kg"
		
		//Not available in SUSENAS 2019
		//gen byte electric = R1518B1 < 3 & R1518B2 < 3 & R1518B3 < 3   
		//label var electric "Electricity 450 W & 900 W"
	
	* KUR variable
		gen byte kur = R1901A == 1 
		label var kur "Government credit program" 
		
		gen loan = inlist(1, R1901A, R1901B, R1901C, R1901D, R1901E, R1901F, R1901G, R1901H, R1901I, R1901J)
		label var loan "Have ever received any loan"
		
		rename FWT wt_hh
		label var wt_hh "Weight of household"
		
	* Beneficiaries dummy variable
		gen benefc = inlist(1, raskin, bpnt, pip, kis, pkh)
		label var benefc "Government program beneficiaries"
		
	* Label original variables
		rename R101 province_code
		label var province_code "Province"
		
		rename R102 district_code
		label var district_code "District"
		
		gen byte urban = R105 == 1
		label var urban "Urban"
		
		gen consumption_pc = EXP_CAP
		label var consumption_pc "Consumption per capita (in IDR)"
		
		keep URUT raskin bpnt pip kis pkh lpg /*electric*/ loan kur benefc ///
			province_code district_code urban consumption_pc wt_hh 
			
		save "$temp\susenas-household19.dta", replace
	}
	
* Individual data
	{
	use "$susenas19\kor19ind_diseminasi_merge.dta", clear
	
	rename RENUM URUT
	
	isid URUT R401 // Check unique identifiers 
	
	* Generate demographic
		gen byte rural= R105==2 if R105!=.
		label var rural "Rural"
		
		rename R401 ind_num
		label var ind_num "Individual ID"
		
		rename R403 rel_head
		label var rel_head "Relationship with Household head"	
		
		gen byte female_head = (R405 == 2 & rel_head == 1) //Female household head
		bys URUT: egen HH_femalehead = max(female_head)
		gen byte female_head_spouse = (HH_femalehead == 1 & rel_head == 2) //Female household head's spouse 
		label var female_head "Female household head"
		
		gen byte male_head = (R405 == 1 & rel_head == 1) //Male household head
		bys URUT: egen HH_malehead = max(male_head)
		gen byte male_head_spouse = (HH_malehead == 1 & rel_head == 2) //Male household head's spouse 
		label var male_head "Male household head"
		
		gen byte female_headorspouse = (female_head == 1 | male_head_spouse == 1)
		gen byte male_headorspouse = (male_head == 1 | female_head_spouse == 1)
		
		gen byte female = R405 == 2 
		label var female "Female"
		
		gen byte kids = inlist(rel_head, 3, 4, 5, 6)
		label var kids "Children in household"
		
		gen byte rest_HHmember = inlist(rel_head, 7, 8, 9)
		label var rest_HHmember "The rest of HH members"
		
		gen byte age = R407
		label var age "The age of the individuals"
		
		gen byte gender = R405 == 2
		label var gender "Female"
		
		gen byte household_head = rel_head == 1
		label var household_head "Household head"
		
		rename R404 marst
			label var marst "Marriage status"
			g byte married= marst==2 if marst!=.
			g byte unmarr= marst==1 if marst!=.
			g byte div= marst==3 if marst!=.
			g byte widow= marst==4 if marst!=.
		
		ren FWT wt_ind
		label var wt_ind "Weight of individual"
		
		* IDENTITY
		gen byte id = R501 == 1
		label var id "Have national id"
		
		gen byte birth_certificate = inlist(R606, 1, 2)
		label var birth_certificate "Have birth certificate"
		
		* EMPLOYMENT
		gen byte work = R702 == 1 
		la var work "1 if work"
		
		gen byte school = R702 == 2 
		la var school "1 if school"
		
		gen byte housekeeping = R702 == 3 
		la var housekeeping "1 if house work"
		
		gen byte otheract = R702 == 4 
		la var otheract "1 if other activity"
		
		gen byte tempoutofwork = R703 == 1
		la var tempoutofwork "1 if temporary out of work"
		
		gen empstatus = R705 
		la var empstatus "employment status"
		la define vemp 1 "own account" 2 "with unpaid workers" 3 "with paid workers"/*
		*/	4 "employee" 5 "casual worker" 6 "family or unpaid worker"
		la values empstatus vemp
		
		gen informal = 1 if empstatus!=.
		replace informal = 0 if empstatus!=. & (empstatus==3 | empstatus==4)
		la var informal "1 if in informal sector"
	
			* works
			gen laborf = 1 if work==1 & age>=15
			* temporary out of work
			replace laborf = 1 if work==0 & tempoutofwork==1 & age>=15
			* unemployed: doesn't go to school, doesn't do housekeeping, doesn't do other private acts
			replace laborf = 2 if work==0 & tempoutofwork==0 & /*
			*/		school==0 & housekeeping==0 & otheract==0 & age>=15
			
			* not in labor force
			replace laborf = 0 if age<15
			* go to school
			replace laborf = 0 if work==0 & tempoutofwork==0 & school==1 & age>=15
			* housekeeping
			replace laborf = 0 if work==0 & tempoutofwork==0 & housekeeping==1 & age>=15
			* other (private) activies
			replace laborf = 0 if work==0 & tempoutofwork==0 & otheract==1 & age>=15

		gen byte empformal = 0
		replace empformal = 1 if laborf==2
		replace empformal = 2 if work==1 & informal==0
		replace empformal = 2 if work==0 & tempoutofwork==1 & informal==0
		replace empformal = 3 if work==1 & informal==1
		replace empformal = 3 if work==0 & tempoutofwork==1 & informal==1
		
		la var empformal "employment in the formal and informal sector"
		la define vempformal 0 "not in LF" 1 "unemployed" 2 "employed, formal" 3 "employed, informal"
		la values empformal vempformal

		
	* Employment type
		gen byte worktype = .
		replace worktype = 1 if inlist(R705, 4, 5)
		replace worktype = 2 if R705 == 6
		replace worktype = 3 if inlist(R705, 1, 2, 3) 
		replace worktype = 4 if R702 == 3 
		replace worktype = 5 if R702 == 2
		replace worktype = 6 if R702 != 1 & worktype == .
		
		label var worktype "What were you mainly doing for work?"
		label define WORKTYPE 1	"Salary" 2 "No salary" 3 "Self-employed" ///
			4 "Housewife" 5 "Student" 6 "No work" 
		label val worktype WORKTYPE
		
	* Generate digital usage & financial inclusion
		bys URUT: gen byte hh_size = _N
		label var hh_size "Size of household"
		
		gen byte phone_usage = R801 == 1
		label var phone_usage "HH member who use mobile phone in the last 3 months"
		
		gen byte phone_own = R802 == 1
		label var phone_own "HH member who own mobile phone in the last 3 months"
		
		gen byte computer_use = (R803_A == "A" | R803_B == "B" | R803_C == "C ")
		label var computer_use "HH member who use computer in the last 3 months"
		
		gen byte internet_use = R804 == 1
		label var internet_use "HH member who have ever use internet, incl. social media"
		
		gen byte saving_account = R808 == 1
		label var saving_account "HH member who have any saving account"
	
	* Education Level
		gen education = .
		replace education = 1 if R612 == 1
		replace education = 2 if inlist(R613, 1,2,3,4) 
		replace education = 3 if inlist(R613, 5,6,7,8)
		replace education = 4 if inlist(R613, 9,10,11,12,13,14)
		replace education = 5 if inlist(R613, 15,16,17,18,19,20) 
		
		label define EDU 1 "No Formal Education " 2 "Primary" 3 "Junior high" 4 "Senior high" 5 "University" 
		label values education EDU
		label var education "Education level"
		
	 * Digital technology in the household
	 gen byte phone_notuse = phone_usage == 0
		*bys URUT (rel_head): replace phone_notuse = phone_notuse[_n-1] if _n > 1
	 gen byte phone_notown = phone_own == 0
		*bys URUT (rel_head): replace phone_notown = phone_notown[_n-1] if _n > 1
	 gen byte internet_notuse = internet_use == 0
		*bys URUT (rel_head): replace internet_notuse = internet_notuse[_n-1] if _n > 1
	 
	 foreach var of varlist phone_notuse phone_notown internet_notuse {
		 * Head not use
		 gen byte ind`var'_head = .
		 replace ind`var'_head = 1 if `var' == 1 & female_head == 1 
		 replace ind`var'_head = 1 if `var' == 1 & male_head == 1
		 replace ind`var'_head = 0 if `var' == 0 & female_head == 1   
		 replace ind`var'_head = 0 if `var' == 0 & male_head == 1 
		 bys URUT: egen `var'_head = max(ind`var'_head) 
	 
		 * Not use but spouse used
		 gen byte ind`var'_spouseuse = .
		 replace ind`var'_spouseuse = 1 if `var'_head == 1 & rel_head == 2 & phone_notuse == 0
		 replace ind`var'_spouseuse = 0 if `var'_head == 1 & ind`var'_spouseuse == .
		 bys URUT: egen `var'_spouseuse = max(ind`var'_spouseuse) 
		 
		 * Not use but kids used
		 gen byte ind`var'_kidsuse = .
		 replace ind`var'_kidsuse = 1 if `var'_head == 1 & kids == 1 & phone_notuse == 0
		 replace ind`var'_kidsuse = 0 if `var'_head == 1 & ind`var'_kidsuse == .
		 bys URUT: egen `var'_kidsuse = max(ind`var'_kidsuse) 
		 
		 * Not use but others beside spouse and kids used
		 gen byte ind`var'_othersuse = .
		 replace ind`var'_othersuse = 1 if `var'_head == 1 & `var' == 1 & rel_head > 3
		 replace ind`var'_othersuse = 0 if `var'_head == 1 & ind`var'_othersuse == .
		 bys URUT: egen `var'_othersuse = max(ind`var'_othersuse)
		 
		 * No one use in the HH
		 bys URUT: egen byte `var'_noneuse = min(`var') if `var'_head == 1		
		}
	
	* Own a saving account by relationship in HH
	gen byte indsaving_fheadown = saving_account == 1 & female_head == 1
	bys URUT: egen saving_fheadown = max(indsaving_fheadown)
	gen byte indsaving_mheadown = saving_account == 1 & male_head == 1
	bys URUT: egen saving_mheadown = max(indsaving_mheadown)
	
	gen byte indsaving_spouseown = .
	replace indsaving_spouseown = 1 if saving_account == 1 & female_head_spouse == 1 
	replace indsaving_spouseown = 1 if saving_account == 1 & male_head_spouse == 1
	replace indsaving_spouseown = 0 if saving_account == 0 & female_head_spouse == 1   
	replace indsaving_spouseown = 0 if saving_account == 0 & male_head_spouse == 1 
	bys URUT: egen saving_spouseown = max(indsaving_spouseown) 
		 
	* Not own but kids own
	gen byte indsaving_kidsown = .
	replace indsaving_kidsown = 1 if saving_account == 1 & kids == 1
	replace indsaving_kidsown = 0 if saving_account == 0 & kids == 1 
	bys URUT: egen saving_kidsown = max(indsaving_kidsown) 
		 		 
	* No one own in the HH
	bys URUT: egen byte saving_noneown = min(saving_account)
	
	* Health insurance
	gen byte jkn_pbi = R1101_A == "A" 
	gen byte health_insurance = R1101_X == ""
	egen any_jkn_pbi = max(jkn_pbi), by(URUT)
	egen any_health_insurance = max(health_insurance), by(URUT)
		
	save "$temp\susenas-individual19.dta", replace
	}
	
	merge m:1 URUT using "$temp\susenas-household19.dta"
	
	*Loan
	gen byte loan_fheadhave = loan == 1 & female_head == 1
	gen byte loan_mheadhave = loan == 1 & male_head == 1
	
	drop _m		
	save "$temp\susenas-merge19.dta", replace

	* Province/District name 
	{
	use "$susenas19\kor19region.dta", clear //region names and code from Susenas
	
	* prepare the data for matching
		rename value_prov province_code
		rename nama_prov province_name
		replace province_name = proper(province_name)
		tostring value_kab, replace
		gen district_code = substr(value_kab,3,2)
		drop value_kab
		destring district_code, replace
	
		* Clean the region_name for matching
		gen region_name = lower(nama_kab)
		replace region_name = "kota " + region_name if district_code > 70 // Tag urban area 
		replace region_name = "siak" if region_name == "s i a k"
		replace region_name = "kota batam" if region_name == "kota b a t a m"
		replace region_name = "kota dumai" if region_name == "kota d u m a i"
		replace region_name = "kotabaru" if region_name == "kota baru"
		replace region_name = "karang asem" if region_name == "karangasem"
		replace region_name = "kota pangkal pinang" if region_name == "kota pangkalpinang"
		
		gen byte urban = district_code > 70
		
		keep province_name province_code district_code region_name
		duplicates drop
		
	save "$temp\susenas-region.dta", replace
	}

* Import the poverty line
	{
	import excel "$raw\Poverty line per municipal 2015-2019.xlsx", sheet("table") ///
		cellrange(A4:F551) clear
	
	rename A region_name
	rename B povertyline_15
	rename C povertyline_16
	rename D povertyline_17
	rename E povertyline_18
	rename F povertyline_19

	* Identify the rural and urban districts
		* Clean the region_name for matching
		replace region_name = "kotabaru" if region_name == "Kota Baru"
		replace region_name = "nduga" if region_name == "Nduga *"
		replace region_name = "mempawah" if region_name == "Pontianak"
					
		gen byte region_type = regexm(region_name, "^([A-Z][A-Z])") // Province
		replace region_type = 1 if region_name == "D I YOGYAKARTA"
		replace region_name = lower(region_name)
		
		
	save "$temp\poverty_line.dta", replace

	drop if region_type == 1  //drop if province level
	merge 1:1 region_name using "$temp\susenas-region.dta"
	
	drop _m povertyline_15 povertyline_16 region_type
	drop if province_code == . & district_code ==.
	
	save "$temp\susenas-poverty_line.dta", replace
}

merge 1:m province_code district_code using "$temp\susenas-merge19.dta"
	drop _m
	
* Poor people
	gen byte poor = consumption_pc < povertyline_19
	label var poor "Poor people"
		
* Consumption Percentile
	xtile pct = consumption [w=wt_hh], n(10)
	tab pct, gen(p)

*Age group 
	recode age 0/1=1 2/4=2 5/9=3 10/14=4 15/19=5 20/24=6 25/29=7 30/34=8 35/39=9 40/44=10 45/49=11 50/54=12 55/59=13 60/max=14 , gen(agegrp)
	forval i=1/14 {
		gen agegrp`i' = agegrp == `i'
		}

		
save "$temp\susenas-merge19_allage.dta", replace

* Keep if age > = 15
	keep if age > = 15 // based on financial inclusion definition
	
save "$final\susenas-merge19.dta", replace
	
