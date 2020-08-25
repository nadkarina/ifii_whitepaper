* ******************************************************************************
* PROGRAM: SOFIA DATA PREPARATION
* AUTHOR: Nick Wisely
* PURPOSE: Create a clean SOFIA dataset
* DATE CREATED: 29 January 2020
* LAST MODIFIED: 25 August 2020 by Nadia Setiabudi
* ******************************************************************************

********************************************************************************
*************************** PREPARE THE SOFIA DATA *****************************
********************************************************************************

* Household data
	{
	use "$sofia\HHD_ROSTER.dta", clear
	*****************************************************************************
	* IDENTITY SECTION 
	*****************************************************************************
	{
	* create subset variable for household only
		rename RESP_AGE age_hhd
		label var age_hhd "Age of Respondents, HHD only."
		
	* create female variable for household
		gen female_hhd = .
		replace female_hhd = 1 if RESP_GENDER == 2
		replace female_hhd = 0 if RESP_GENDER == 1
		label var female_hhd "Female Respondent, for HHD"
	
	
	* Generate education variable
		label define edu_level ///
			1 "No Education" ///
			2 "Primary" ///
			3 "Junior High School" ///
			4 "High School" ///
			5 "University" ///
		
		gen education = .
		replace education = 1 if age_hhd >= 5 & inlist(RESP_EDU, 9) //noedu
		replace education = 2 if age_hhd >= 5 & inlist(RESP_EDU, 1) //primary
		replace education = 3 if age_hhd >= 5 & inlist(RESP_EDU, 2)	//junior high
		replace education = 4 if age_hhd >= 5 & inlist(RESP_EDU, 3, 4)	//high school
		replace education = 5 if age_hhd >= 5 & inlist(RESP_EDU, 5, 6, 7)	//diploma, Bachelor, Master, Doctor
		label values education edu_level
		label var education "Education Level"
	}
	*****************************************************************************
	* MARRIED SECTION 
	*****************************************************************************
	{
		gen byte married = 0
		label var married "marital status"
		
		bysort HHD_ID: egen total_spouse = total(RELATIONSHIP) if RELATIONSHIP == 2
		bysort HHD_ID: egen total_head = total(RELATIONSHIP) if RELATIONSHIP == 1 | RELATIONSHIP == 2 
		bysort HHD_ID: egen total_parents = total(RELATIONSHIP) if RELATIONSHIP == 5
		bysort HHD_ID: egen total_gparents = total(RELATIONSHIP) if RELATIONSHIP == 7
		bysort HHD_ID: egen total_inlaw = total(RELATIONSHIP) if RELATIONSHIP == 11
		
		replace married = 1 if total_head == 3 | total_head == 5
		replace married = 1 if total_spouse == 2 | total_spouse == 4
		replace married = 1 if total_parents/2 == 5
		replace married = 1 if total_gparents/2 == 7
		replace married = 1 if total_inlaw/2 == 11
		
		//for monitoring the data
		save "$temp/sofia-dummy.dta", replace
		
	}
	*****************************************************************************
	* EXPORT SECTION 
	*****************************************************************************
	{
		keep n_pid PROV DIST PSU HHD_ID age_hhd female_hhd ///
		married RELATIONSHIP education ENROLLED //
			
		save "$temp\sofia-household.dta", replace
	}
	}
* Individual data
	{
	use "$sofia\Individual_revised26Sept2017.dta", clear	
	*****************************************************************************
	* IDENTITY SECTION 
	*****************************************************************************
	{
	* create subset variable for individuals only
		rename RESP_AGE age_ind
		label var age_ind "Age of Respondents, Individuals only."
	
	* create female variable for household
		gen female_ind = .
		replace female_ind = 1 if RESP_GENDER == 2
		replace female_ind = 0 if RESP_GENDER == 1
		label var female_ind "Female Respondent for Individuals"
		
	}
	*****************************************************************************
	* INCOME SECTION 
	*****************************************************************************
	{
	* Create variable income	
		//The source of income for every individuals
		gen byte income_source1 = 1 if Q501A == 1
		gen byte income_source2 = 1 if Q501B == 1
		gen byte income_source3 = 1 if Q501C == 1
		gen byte income_source4 = 1 if Q501D == 1
		gen byte income_source5 = 1 if Q501E == 1
		gen byte income_source6 = 1 if Q501F == 1
		gen byte income_source7 = 1 if Q501G == 1
		gen byte income_source8 = 1 if Q501H == 1
		gen byte income_source9 = 1 if Q501I == 1
		gen byte income_source10 = 1 if Q501J == 1
		gen byte income_source11 = 1 if Q501K == 1
		label var income_source1 "Salary or wages"
		label var income_source2 "Trading"
		label var income_source3 "Service"
		label var income_source4 "Lend money"
		label var income_source5 "Rent out"
		label var income_source6 "Pension"
		label var income_source7 "Interest"
		label var income_source8 "NGO/Goverment Assistance"
		label var income_source9 "Community Based Organization"
		label var income_source10 "Household members"
		label var income_source11 "Not household members"
		
		
		//Checking do they rely on other person or other sources of income if all income source given is equal zero
		gen income_other_person = (Q502 ==  1)
		gen income_other_source = (Q502 == 77)
		
		//Source of income that rely on most
		gen income_main = Q503
		replace income_main = 12 if missing(Q503)
		
		label define main_source ///
			1 "Salary/Wages" ///
			2 "Trading/selling" ///
			3 "Service" ///
			4 "Lend money with interest" ///
			5 "Rent something out" ///
			6 "Pension" ///
			7 "Interest/earnings from investment" ///
			8 "From NGO or goverment assistance" ///
			9 "From a church/community based organizations" ///
			10 "Other household members" ///
			11 "Other individuals who are not household members" ///
			12 "Other"
		label values income_main main_source
		label var income_main "main source income for individuals"

		foreach i of numlist 1/12 {
			gen income_tamount`i' = Q511A`i' //Don't know = -98, Refused = -99
			gen amount_income`i' = Q511A`i' //Don't know = -98, Refused = -99
			replace amount_income`i' = 0 if missing(amount_income`i') | amount_income`i' == -98 | amount_income`i' == -99  
			label var income_tamount`i' "income source for category `i'"
		}
		
		foreach i of numlist 1/12 {
			gen income_period`i' = 0
			replace income_period`i' = 365	if Q511P`i' == 1 // daily payment
			replace income_period`i' = 52	if Q511P`i' == 2 // weekly payment
			replace income_period`i' = 12	if Q511P`i' == 3 // monthly payment
			replace income_period`i' = 3	if Q511P`i' == 4 // quarterly payment
			replace income_period`i' = 1	if Q511P`i' == 7 // yeary payment
		}
		
		* calculate the annual income for 1 year
		foreach i of numlist 1/12 {
			gen income_annual`i' = amount_income`i' * income_period`i'
		}
		
		* calculate the total amount of income a person have
		gen income_annual_total = 0
		foreach i of numlist 1/12 {
			replace income_annual_total = income_annual_total + income_annual`i'
		}
	}
	*****************************************************************************
	* ASSET OWNERSHIP SECTION 
	*****************************************************************************
	{
	* Create variable Asset Ownership (Mobile phone, Smartphone, Personal Computer,Internet)
		* Own their asset category
		gen byte asset_own_phone = (Q409A == 1)
		gen byte asset_own_sphone = (Q409B == 1)
		gen byte asset_own_PC = (Q409C == 1)
		gen byte asset_own_internet = (Q409D == 1)
		label var asset_own_phone "Individuals who had their own mobile phone"
		label var asset_own_sphone "Individuals who had their own smartphone"
		label var asset_own_PC "Individuals who had their own PC"
		label var asset_own_internet "Individuals who had Internet Access"

		* don't own the asset but can access using someone else category
		gen byte asset_access_phone = (Q409A == 2)
		gen byte asset_access_sphone = (Q409B == 2)
		gen byte asset_access_PC = (Q409C == 2)
		label var asset_access_phone "Individuals who can access a mobile phone but owned by someone else"
		label var asset_access_sphone "Individuals who can access a smartphone but owned by someone else"
		label var asset_access_PC "Individuals who can access a PC but owned by someone else"
		
		* don't have any access category
		gen byte asset_no_phone = (Q409A == 3)
		gen byte asset_no_sphone = (Q409B == 3)
		gen byte asset_no_PC = (Q409C == 3)
		gen byte asset_no_internet = (Q409D == 2)
		label var asset_no_phone "Individuals who don't have any access to a mobile phone"
		label var asset_no_sphone "Individuals who don't have any access to a smartphone"
		label var asset_no_PC "Individuals who don't have any access to a PC"
		label var asset_no_internet "Individuals who don't have any Access to internet"
	}
	*****************************************************************************
	* LITERACY SECTION 
	*****************************************************************************
	{
	* Create financial literacy variable
		
		gen literacy_financial1 = strpos(Q606,"A")>0
		gen literacy_financial2 = strpos(Q606,"B")>0
		gen literacy_financial3 = strpos(Q606,"C")>0
		gen literacy_financial4 = strpos(Q606,"D")>0
		gen literacy_financial5 = strpos(Q606,"E")>0
		gen literacy_financial6 = strpos(Q606,"F")>0
		gen literacy_financial7 = strpos(Q606,"G")>0
		gen literacy_financial8 = strpos(Q606,"H")>0
		gen literacy_financial9 = strpos(Q606,"I")>0
		gen literacy_financial10 = strpos(Q606,"J")>0
		gen literacy_financial11 = strpos(Q606,"K")>0
		gen literacy_financial12 = strpos(Q606,"L")>0
		gen literacy_financial13 = strpos(Q606,"V")>0
		gen literacy_financial14 = strpos(Q606,"W")>0
		label var literacy_financial1 "A Bank"
		label var literacy_financial2 "My Cooperative"
		label var literacy_financial3 "A Broker/Financial Advisor"
		label var literacy_financial4 "My Employer"
		label var literacy_financial5 "The Local Goverment office"
		label var literacy_financial6 "Friends and Family"
		label var literacy_financial7 "Leaders in my mosque, chruch"
		label var literacy_financial8 "A School Teacher"
		label var literacy_financial9 "The Village Head"
		label var literacy_financial10 "Online Information/Internet"
		label var literacy_financial11 "Television/Radio"
		label var literacy_financial12 "Magazines, books, other print media"
		label var literacy_financial13 "Other"
		label var literacy_financial14 "do not seek for financial advice"

		gen literacy_number = 0
		foreach i of numlist 1/13 {
			replace literacy_number = literacy_number + literacy_financial`i'
		}
		
	*Create training variable
		gen literacy_training = Q607
		replace literacy_training = 0 if literacy_training == 2
		label var literacy_training "Participation in Financial Edu Program"
	
	*Create individuals the information satisfaction
		label define satisfaction ///
			1 satisfied ///
			2 indifferecnt ///
			3 unsatisfied
		gen literacy_satisfied = Q612A
		label values literacy_satisfied satisfaction
		label var literacy_satisfied "Satisfied by the information given in the training"
		
	
	}
	*****************************************************************************
	* SAVINGS SECTION 
	*****************************************************************************
	{
	* Create savings variable
		gen saving_formal = Q704A_A + Q704A_B + Q704A_C + Q704A_D
		replace saving_formal = 1 if saving_formal > 1 & saving_formal != .
		
		gen saving_informal = Q704A_A + Q704A_B + Q704A_C + Q704A_D
		replace saving_informal = 1 if saving_informal > 1 & saving_informal != .
		
	* Create variable Bank Account Ownership
		gen byte saving_bank_own = 1 if (Q704A_A == 1| Q713 == 1)
		label var saving_bank_own "Own bank account"

		rename Q704A_A saving_bank_4savings
		rename Q715_A saving_bank_4salaries
		rename Q715_B saving_bank_4transfer
		rename Q715_C saving_bank_4receive
		rename Q715_D saving_bank_4borrow
		rename Q715_V saving_bank_4other
		label var saving_bank_4savings "use it to save money"
		label var saving_bank_4salaries "use it to receive salaries from employer"
		label var saving_bank_4transfer "use it to make payments / transfers from others"
		label var saving_bank_4receive "use it to receive payments / transfers from others"
		label var saving_bank_4borrow "use it to qualify borrowing money in the bank"
		label var saving_bank_4other "others"
		
	* Create saving reason variable
		* Do saving
		gen saving_reason1 = strpos(Q705A,"A")>0
		gen saving_reason2 = strpos(Q705A,"B")>0
		gen saving_reason3 = strpos(Q705A,"C")>0
		gen saving_reason4 = strpos(Q705A,"D")>0
		gen saving_reason5 = strpos(Q705A,"E")>0
		gen saving_reason6 = strpos(Q705A,"F")>0
		gen saving_reason7 = strpos(Q705A,"G")>0
		gen saving_reason8 = strpos(Q705A,"V")>0
		label var saving_reason1 "It’s very easy: the processes are simple"
		label var saving_reason2 "It is not expensive to do so"
		label var saving_reason3 "The place where I put my savings is near where I live"
		label var saving_reason4 "I am familiar with the institution; I know / understand their products"
		label var saving_reason5 "I trust the institution"
		label var saving_reason6 "I would like to access other services (e.g. a loan)"
		label var saving_reason7 "The security of money guaranteed"
		label var saving_reason8 "Others"
		
		* Not saving
		gen saving_reason_not = Q702
		label define neg_reason ///
			1 "All of the money I receive gets spent" ///
			2 "I do not have (regular) income/I do not have a job" ///
			3 "I do not know where to save" ///
			4 "There is nowhere convenient or safe to save" ///
			5 "I do not trust the institutions that offer savings services" ///
			6 "I have no reason or need to save" ///
			7 "I do not believe in saving" ///
			8 "I do not know" ///
			77 "Others"
		label values saving_reason_not neg_reason
		label var saving_reason_not "Reason for not savings"
	
	*
	}
	
	*****************************************************************************
	* REMITTANCE SECTION 
	*****************************************************************************
	{
	label define rem_category ///
			1 "Within Indonesia" ///
			2 "Outside Indonesia" ///
			3 "Both"
	label define method ///
			1 "Bank Transfer" ///
			2 "In Cash" ///
			3 "Through Mobile Phone" ///
			4 "Through a Payment Point" ///
			5 "Other"
			
	* Remittance activity: Receiving
		gen byte remittance_received = (Q901 == 1)
		label var remittance_received "Individuals who had received remittance"
		
		gen remittance_source = Q902
		label values remittance_source rem_category
		label var remittance_source "Source of the remittance"
		
		foreach i of numlist 1/5{
			gen remittance_rcv_method`i' = .
			replace remittance_rcv_method`i' = 0 if remittance_received == 1
		}
		
		replace remittance_rcv_method1 = 1 if strpos(Q903,"A")> 0
		replace remittance_rcv_method2 = 1 if strpos(Q903,"B")> 0
		replace remittance_rcv_method3 = 1 if strpos(Q903,"C")> 0
		replace remittance_rcv_method4 = 1 if strpos(Q903,"D")> 0
		replace remittance_rcv_method5 = 1 if strpos(Q903,"V")> 0
		label var remittance_rcv_method1 "Bank Transfer"
		label var remittance_rcv_method2 "In Cash"
		label var remittance_rcv_method3 "Through Mobile Phone"
		label var remittance_rcv_method4 "Payment Point"
		label var remittance_rcv_method5 "Other"
		
	* Remittance activity: Sending
		gen byte remittance_sent = (Q907 == 1)
		label var remittance_sent "Individuals who had sent remittance"
		
		gen remittance_destination = Q908
		label values remittance_destination rem_category
		label var remittance_destination "Destination of the remittance"

		gen remittance_sent_method = .
		replace remittance_sent_method = 0 if remittance_sent == 1
		replace remittance_sent_method = 1 if Q909 == 1
		replace remittance_sent_method = 2 if Q909 == 2
		replace remittance_sent_method = 3 if Q909 == 3
		replace remittance_sent_method = 4 if Q909 == 4
		replace remittance_sent_method = 5 if Q909 == 77
		label value remittance_sent_method method
		label var remittance_sent_method "Method of people to send money"
		
		gen remittance_do = .
		replace remittance_do = 1 if remittance_received == 1 | remittance_sent == 1
		replace remittance_do = 0 if remittance_received == 0 & remittance_sent == 0
		
	* In-depth learning
		label define cash_method ///
			1 "In person" ///
			2 "A courier/agent" ///
			3 "Family or friends" ///
			4 "Post office" ///
			5 "Pawnshop" ///
			6 "Convenience store" ///
			7 "Retailers" ///
			8 "Western Union" ///
			77 "Other"
		
		label define bank_method ///
			1 "Counter at a bank branch" ///
			2 "ATM" ///
			3 "Telephone Banking" ///
			4 "Mobile Phone" ///
			5 "On-Line Banking" ///
			77 "Other"
		
		
		* Receiving
		gen remittance_rcv_bank = .
		replace remittance_rcv_bank = Q904
		replace remittance_rcv_bank = 0 if Q904 > 1 & Q904 != .
		label var remittance_rcv_bank "Bank account is owned"
		
		gen remittance_rcv_cash = Q905A
		label value remittance_rcv_cash cash_method
		label var remittance_rcv_cash "method to collect the cash"
		
		gen remittance_rcv_mobile = Q906
		replace remittance_rcv_mobile = 0 if Q906 > 1 & Q906 != .
		label var remittance_rcv_mobile "Mobile Phone is owned"
		
		//gen remittance_rcv_pp = Q905B
		//label var remittance_rcv_pp "payment point individuals receive cash"
		
		
		* Sending
		gen remittance_sent_bank1 = .
		replace remittance_sent_bank1 = 1 if Q910 == 1
		replace remittance_sent_bank1 = 0 if Q910 > 1 & Q910 != .
		label var remittance_sent_bank1 "Bank account is owned"
		
		gen remittance_sent_bank2 = Q911
		label value remittance_sent_bank2 bank_method
		label var remittance_sent_bank2 "Method of bank transfer that they use"
		
		gen remittance_sent_cash = Q912A
		label value remittance_sent_cash cash_method
		label var remittance_sent_cash "Method to send the cash"
		
		gen remittance_sent_mobile1 = Q913
		replace remittance_sent_mobile1 = 0 if Q913> 1 & Q913 != .
		label var remittance_sent_mobile1 "Mobile Phone is owned"
		
		gen remittance_sent_mobile2 = . 
		replace remittance_sent_mobile2 = 1 if Q914 == 2
		replace remittance_sent_mobile2 = 0 if (Q914 == 1 | Q914 == 3 | Q914 == 77) & Q914 != .
		label var remittance_sent_mobile2 "Using their own bank account(mobile banking), false = without bank accothers"
		
		//gen remittance_sent_pp = Q912B
		//label var remittance_sent_pp "payment point individuals send cash through"
		
		* Reason to choose method to send money (numeric)
		label define reason ///
			1 "Quick to access money" ///
			2 "Easy to understand" /// 
			3 "Convenient(opening hours)" /// 
			4 "Not expensive(reasonable amount)" ///
			5 "The place is near" ///
			6 "Safe place to send/receive money" ///
			7 "The only way I can send money" ///
			8 "The only way the recipient can receive" ///
			9 "I do not know of other ways" ///
			10 "I don’t have to queue" ///
			11 "Other reasons"
		
		* Reason to choose method to send money (seperated)
		gen remittance_reason1 = strpos(Q915,"A")>0
		gen remittance_reason2 = strpos(Q915,"B")>0
		gen remittance_reason3 = strpos(Q915,"C")>0
		gen remittance_reason4 = strpos(Q915,"D")>0
		gen remittance_reason5 = strpos(Q915,"E")>0
		gen remittance_reason6 = strpos(Q915,"F")>0
		gen remittance_reason7 = strpos(Q915,"G")>0
		gen remittance_reason8 = strpos(Q915,"H")>0
		gen remittance_reason9 = strpos(Q915,"I")>0
		gen remittance_reason10 = strpos(Q915,"J")>0
		gen remittance_reason11 = strpos(Q915,"V")>0
		label var remittance_reason1 "Quick to access money (recipient gets money quickly)"
		label var remittance_reason2 "Very easy: the process is simple / easy to understand"
		label var remittance_reason3 "Convenient in terms of opening hours"
		label var remittance_reason4 "Not expensive: I am charged a small/reasonable amount"
		label var remittance_reason5 "The place where I send money / make the transfer is near"
		label var remittance_reason6 "It’s a safe place and/or way to send/receive money"
		label var remittance_reason7 "This is the only way I can send money"
		label var remittance_reason8 "This is the only way the recipient can receive money"
		label var remittance_reason9 "I do not know of other ways of sending money"
		label var remittance_reason10 "I don’t have to queue at the bank branch"
		label var remittance_reason11 "Other reasons"
	}
	*****************************************************************************
	* EXPORT SECTION 
	*****************************************************************************
	{
	* Include the weight of the data
		gen wt_vil = weightrake
		label var wt_vil "Village weight"
	
	
	* Generate data file	
		keep n_pid PROV_NM DIST DIST_NM STATUS PSU age_ind female_ind ///
		income* literacy* asset* /*saving* */ remittance* ///
		wt_vil 

		save "$temp\sofia-individual.dta", replace
	}
}
* merge data 
	{
	merge 1:m n_pid using "$temp\sofia-household.dta"	
	save "$temp\sofia-merge.dta", replace

	drop if _merge != 3
	drop _merge
	
	save "$final\sofia-merge.dta", replace
	}
