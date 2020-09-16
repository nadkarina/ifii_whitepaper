* ******************************************************************************
* PROGRAM: Whitepaper Graph
* AUTHORS: Nick Wisely, Natalie Theys, Lolita Moorena, Nadia Setiabudi
* PURPOSE: Create tables and figures for whitepaper
* DATE CREATED: 23 June 2020
* LAST MODIFIED: 25 August 2020 by Nadia Setiabudi
* ******************************************************************************

************************************************
* FIGURE 1:	Village-Level Access to 	   	   *
* Financial Services	   					   *
************************************************
{
*PODES Data Matched
	use "$final/matchedfin_shp_PODES.dta", clear
		gen bank = r1208ak2 + r1208bk2 +r1208ck2
		gen bank2 = bank > 0
			replace bank2 = 0 if bank == . 
		gen atm = r1209ck2 == 1
		gen agent = r1209gk2 == 1

		gen financialserv = bank2 == 1
			replace financialserv = 2 if bank2 == 0 & atm == 1
			replace financialserv = 3 if bank2 == 0 & atm == 0 & agent == 1
			replace financialserv = 4 if _m != 3

		drop if _ID == . //dropping the unmatched
		destring provno, replace

*Create Map

	colorpalette gs12 "45 171 159" "242 196 19" "227 89 37" gs15
	
	spmap financialserv using "$final/INDO_DESA_2019_coord.dta", id(_ID) clmethod(unique) ///
	ocolor(none ..) fcolor(`r(p)') ndocolor(gs12) ///
	polygon(data("$final/border_all.dta") ocolor(black) fcolor(none) osize(medium)) ///
	legend(label(2 "No Bank")) legend(label(3 "Bank") label(4 "No Bank, ATM Only") ///
	label(5 "No Bank or ATM, Only Agent") label(6 "No Data") ) ///
	legorder(lohi) legend(ring(1) position(6) ///
		rows(1))  
	
	gr export "$fig/heatmap_financialserv.png", replace
}


*FIGURE: Indonesia financial service PIE CHART
{
use "$final/podes-popbank.dta", clear

collapse (sum) population (count)  id, by(financialserv)

	label define FIN 0 "No Bank" 1 "Bank" 2 "No Bank, but ATM" 3 "No Bank/ATM, but Agent" 4"No Data", replace
	label values financialserv FIN

colorpalette gs12 "45 171 159" "242 196 19" "227 89 37" gs15

* Indonesia population pie chart
graph pie population, over(financialserv) legend(off) ///
	pie(1, color(gs12)) pie(2, color("45 171 159")) pie(3, color("242 196 19")) pie(4, color("227 89 37")) pie(5, color(gs15)) ///
	title("Population", size(vhuge)) ///
	plotregion(color(white) fcolor(white)) ///
	name("population", replace) plotregion(margin(zero))

* Indonesia location pie chart
graph pie id, over(financialserv) legend(off) ///
	pie(1, color(gs12)) pie(2, color("45 171 159")) pie(3, color("242 196 19")) pie(4, color("227 89 37")) pie(5, color(gs15)) ///
	title("Villages", size(vhuge)) ///
	plotregion(color(white) fcolor(white)) ///
	name("village", replace)  plotregion(margin(zero))

graph combine population village 

 		 gr export "$fig/heatmappie.png", replace
		 
*Legend on its own
	local new = _N + 1
    set obs `new'
	replace financialserv = 4 if financialserv==.
		replace population =1 if financialserv==4
	
	
	graph pie population if financial<2, over(financialserv) legend(all region(lwidth(none)) row(1)) ///
	pie(1, color(gs12)) pie(2, color("45 171 159")) pie(3, color("242 196 19")) pie(4, color("227 89 37")) pie(5, color(gs15))
	
	
	gr export "$fig/heatmap_legend1.png", replace

	graph pie population if financial>1, over(financialserv) legend(all region(lwidth(none)) row(1)) ///
	pie(1, color("242 196 19")) pie(2, color("227 89 37")) pie(3, color(gs15))	
	
	
	gr export "$fig/heatmap_legend2.png", replace
}

************************************************
* FIGURE 2:	Influence on and Involvement	   *
* in Household Financial Decision-making	   *
************************************************
{
*Use 2018 FII Data
	use "$final/fii2018", clear

*Subset to 18 or Older
	keep if age >17

*Set-up Matrix for Estimates	
	mat res=J(100,5,.)
	 local row = 1
	 local k=1
	 
*Run Estimates	 
	foreach group in any_invovle_hhinc any_influence_spending any_voice_disagreement any_finaldec_ownmoney {
		reg `group' female if married == 1 [w=weight]
			//Married - Females
				lincom _b[_cons]+_b[female]
					mat res[`row',1]= r(estimate)
					mat res[`row',2]= r(estimate)-1.96*r(se)
					mat res[`row',3]= r(estimate)+1.96*r(se)
					mat res[`row',4]= `k'
					mat res[`row',5]= 1
				local ++row
					
			//Married - Males
					mat res[`row',1]= _b[_cons]
					mat res[`row',2]= _b[_cons]-1.96*_se[_cons]
					mat res[`row',3]= _b[_cons]+1.96*_se[_cons]
					mat res[`row',4]= `k'
					mat res[`row',5]= 2
				local ++row
					
		reg `group' female if married == 0 [w=weight]
			//Unmarried - Females
				lincom _b[_cons]+_b[female]
					mat res[`row',1]= r(estimate)
					mat res[`row',2]= r(estimate)-1.96*r(se)
					mat res[`row',3]= r(estimate)+1.96*r(se)
					mat res[`row',4]= `k'
					mat res[`row',5]= 3
				local ++row
					
			//Unmarried - Males
				mat res[`row',1]= _b[_cons]
					mat res[`row',2]= _b[_cons]-1.96*_se[_cons]
					mat res[`row',3]= _b[_cons]+1.96*_se[_cons]
					mat res[`row',4]= `k'
					mat res[`row',5]= 4
				local ++row					
		
				local ++k	
						}
*Put Estimates in Matrix	
	drop _all
	mat colnames res= est ul ll indic cat
		svmat res, names(col)
		drop if est==.

		gen marker = _n
		
		replace marker = marker - 1 if cat==3
		replace marker = marker + 1 if cat==2
		sort marker
		gen gender = cat==1 | cat==3
	
	*Generate a Marker Variable
		levelsof(indic), local(lvls)
		foreach l in `lvls'{
			local l2 = `l'-1
			if `l'>1{
			replace marker = marker + `l2' if indic==`l'
					}
					}
*Generate Figure	
	twoway 	(bar est marker if cat == 1, bcolor("227 89 37"))  ///
			(bar est marker if cat == 3, bcolor("227 89 37") fintensity(inten60))   ///
			(bar est marker if cat == 2, bcolor("45 171 159"))   ///
			(bar est marker if cat == 4, bcolor("45 171 159") fintensity(inten60))  , ///
			ytit("Share", size(small)) ///
			graphregion(color(white) fcolor(white)) ///
			yscale(range(0 1)) ylab(#6, labsize(small)) ///
			legend(on order(1 2 3 4) label(1 "Married Females") label(2 "Unmarried Females") ///
			label(3 "Married Males") label(4 "Unmarried Males") symysize(*.6) symxsize(*.6) ///
			size(small) rows(1) region(lwidth(none)) span) xtit(" ")  ///
			xlab(2.5 `" "Involved in how"  "HH income is spent" "' 7.5 `" "Has influence" "on how HH income" "is spent if disagreement" "' 12.5 `" "Likely to voice" "disagreement on how" "HH income is spent`'" "' 17.5`" "Has final decision" "on how own"  "money is spent" "', ///
			labsize(small) notick)  
		
	gr export "$fig/HH_DecisionMaking.png", replace
}


*Table 1
{
use "$final/fii2018.dta", clear

lab var included_bin2 "Any Formal Account Ownership"

estpost tabstat hasatm savings bsa savmicro savecoop loanbank loanmulti loanpawn loanmicro loancoop  emoney invest haveother included_bin2, by(female) listwise statistics(mean) columns(statistics) esample 	
		
		cd "$fig"
		esttab using "ServicesByGender.tex", cells("mean(fmt(2) label())") ///
		noobs not ///
		label ///
		varlabels(`e(labels)') collabels(none) varwidth(80) ///
		replace nostar unstack fragment compress tex nonum /// 
		prehead("\begin{table}[H] \begin{adjustbox}{max width=\textwidth} \begin{threeparttable} \caption{Use of Financial Services by Males and Females} \label{servgender} {\begin{tabular}{l*{1}{llll}} \hline  & Males & Females & Overall \\") ///
		prefoot("\hline")  ///
		posthead("\hline")  ///
		postfoot("\end{tabular}} \end{threeparttable} \end{adjustbox} \end{table} \vspace*{-5mm}")			
		

}

*Table 2
{
use "$final/fii2018.dta", clear


*deposits
	gen any_deposit = (bi_e9a=="1" | bi_e9b=="1" | bi_e9c=="1" | bi_e9v=="1") if (bi_e9a!=" "| bi_e9b!=" " | bi_e9c!=" " | bi_e9v!=" ")
	
	gen dep_teller= bi_e9a=="1" if any_deposit==1
	gen dep_atm= bi_e9b=="1" if any_deposit==1
	gen dep_agent= bi_e9c=="1" if any_deposit==1
	gen dep_other= bi_e9v=="1" if any_deposit==1

*withdrawl
	gen any_withdraw = (bi_e11a=="1" | bi_e11b=="1" | bi_e11c=="1" | bi_e11v=="1") if (bi_e11a!=" "| bi_e11b!=" " | bi_e11c!=" " | bi_e11v!=" ")
	gen withdrawteller= bi_e11a=="1" if any_withdraw==1
	gen withdrawatm= bi_e11b=="1" if any_withdraw==1
	gen withdrawagent= bi_e11c=="1" if any_withdraw==1		
	gen withdrawother= bi_e11v=="1" if any_withdraw==1

	preserve 
		collapse (mean) any_withdraw withdrawteller withdrawatm withdrawagent any_deposit dep_teller dep_atm dep_agent [w=weight]
		xpose, clear varname
		rename v1 Overall
		
		tempfile overall
		save "`overall'"
	restore
	
	preserve
		collapse (mean) any_withdraw withdrawteller withdrawatm withdrawagent any_deposit dep_teller dep_atm dep_agent [w=weight], by(female)
		
		xpose, clear varname
		assert v1==0 if _varname=="female"
		rename v1 Males
		rename v2 Females
		
		drop if _varname=="female"
		
		tempfile gender
		save "`gender'"
	restore
	
	preserve
		collapse (mean) any_withdraw withdrawteller withdrawatm withdrawagent any_deposit dep_teller dep_atm dep_agent [w=weight], by(urban)
		
		xpose, clear varname
		assert v1==0 if _varname=="urban"
		rename v1 Rural
		rename v2 Urban
		
		drop if _varname=="urban"
		
		tempfile urban
		save "`urban'"
	restore	
	
	use "`gender'", clear
	merge 1:1 _varname using "`urban'", gen(m1)
	merge 1:1 _varname using "`overall'", gen(m2)
	
	g order = 1 if _varname=="any_withdraw"
		replace order = 2 if _varname=="withdrawteller"
		replace order = 3 if _varname=="withdrawatm"
		replace order = 4 if _varname=="withdrawagent"
		
		replace order = 5 if _varname=="any_deposit"
		replace order = 6 if _varname=="dep_teller"
		replace order = 7 if _varname=="dep_atm"		
		replace order = 8 if _varname=="dep_agent"		

	lab define order 1"\bf{Any Withdrawl}" 2"\MyIndent Teller" 3"\MyIndent ATM" 4"\MyIndent Agent" 5"\bf{Any Deposit}" 6"\MyIndent Teller" 7"\MyIndent ATM" 8"\MyIndent Agent", replace
	lab values order order
	
		sort order
		estpost tabstat Males Females Rural Urban Overall if order<5, by(order)  statistics(mean) nototal
			
			
			
		esttab using "$fig/TransactionTypes.tex" ,  cells("Males(fmt(2)) Females(fmt(2)) Rural(fmt(2)) Urban(fmt(2)) Overall(fmt(2))") not noobs label nomtitle  eqlabels(`e(labels)') varlabels(`e(labels)') collabels(none) ///
						replace nostar unstack fragment compress tex nonum  /// 
						prehead("\begin{table}[H] \begin{adjustbox}{max width=1.3\textwidth} \begin{threeparttable} \caption{Method of Account Withdrawls and Deposits} \label{transtypetable} {\begin{tabular}{l*{1}{llllll}} \hline \toprule &{Males}&{Females}&{Rural}&{Urban}&{Overall} \\ \midrule ") 	
						
		estpost tabstat Males Females Rural Urban Overall if order>4, by(order)  statistics(mean) nototal
						
				esttab using "$fig/TransactionTypes.tex",  cells("Males(fmt(2)) Females(fmt(2)) Rural(fmt(2)) Urban(fmt(2)) Overall(fmt(2))")  not noobs label nomtitle  eqlabels(,none) varlabels(`e(labels)') collabels(none) ///
						append nostar unstack fragment compress tex nonum  ///				
					postfoot(" \bottomrule \addlinespace[1.5ex] \end{tabular}} \begin{tablenotes}[flushleft]  \small \item \emph{Notes:} Weighted estimates using 2019 FII data. Only asked of individuals who report currently having an individual or joint savings account at a bank. Captures transactions from the past 6 months. \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table} \vspace*{-5mm}")
	

}



*TABLE: Remittance Estimates [SOMETHING IS WRONG WITH THIS TABLE]
{
use "$final/sofia-merge.dta", clear
	g everremit = remittance_received==1 | remittance_sent==1
	
	g urban = STATUS=="URBAN"
	g female = female_ind
	g weight = wt_vil
	g dataset = "SOFIA"
	
	keep everremit urban female weight dataset
		
		tempfile sofia 
		save "`sofia'"
		
use "$final/fii2018.dta", clear
 
 keep if province== 11 | province==22 | province==23 | province==32
 g everremit = bi_e28a_d=="1" | bi_e28b_d=="1" | ojk10_3==1 | dl4_4==1 |  dl4_5==1
 
 g dataset = "FII"
	
 
 	keep everremit urban female weight dataset
	
	append using "`sofia'"
	
	collapse (mean) everremit (count) N=everremit [w=weight], by(urban female  dataset)
	
	reshape wide everremit N, i( urban female) j(dataset) string
	
		lab define female 0"Male" 1"Female"
		lab values female female

		
		estpost tabstat everremitFII NFII everremitSOFIA NSOFIA if urban==0 , by(female)  statistics(mean) nototal
					
		esttab using "$fig/RemittanceCompare.tex",  cells("everremitFII(fmt(2)) NFII(fmt(0)) everremitSOFIA(fmt(2)) NSOFIA(fmt(0))") not noobs label nomtitle  eqlabels(`e(labels)') varlabels(`e(labels)') collabels(none) ///
						replace nostar unstack fragment compress tex nonum  /// 
						prehead("\begin{table}[H] \begin{adjustbox}{max width=1.3\textwidth} \begin{threeparttable} \caption{Estimates of Remittance Use} \label{remitcompate} {\begin{tabular}{l*{1}{lllll}} \hline \toprule &{FII}&{N}&{SOFIA}&{N} \\ \midrule \multicolumn{5}{l}{\textbf{Rural}} \\") 		
		
		
		estpost tabstat everremitFII NFII everremitSOFIA NSOFIA if urban==1 , by(female)  statistics(mean) nototal
					
		esttab using "$fig/RemittanceCompare.tex",  cells("everremitFII(fmt(2)) NFII(fmt(0)) everremitSOFIA(fmt(2)) NSOFIA(fmt(0))")  not noobs label nomtitle  eqlabels(,none) varlabels(`e(labels)') collabels(none) ///
						append nostar unstack fragment compress tex nonum  /// 
						prehead("\multicolumn{5}{l}{\textbf{Urban}} \\")  ///
				postfoot(" \bottomrule \addlinespace[1.5ex] \end{tabular}} \begin{tablenotes}[flushleft]  \small \item \emph{Notes:} Weighted estimates using the 2019 FII data and the 2016 SOFIA data. The SOFIA data are representative of adults 17 years and older living in East Java, West Nusa Tenggara, East Nusa Tenggara and South Sulawesi. FII data has been subset accordingly. Remittance use is captured by a series of questions in the FII including receipt of remittances in the past year, use of ATM cards for remittances, and the use of the post office for remittances. In SOFIA, respondents are asked if they sent or received money in the past year. \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table} \vspace*{-5mm}")		
		
	
*FIGURE: ATM Transaction Types
{
 use "$final/fii2018", clear
 
	gen use_atm_purchase = bi_e28a_a == "1" if bi_e28a_a!= " "
	gen use_atm_withdraw =  bi_e28a_b == "1" if bi_e28a_b!= " "
	gen use_atm_paybill =  bi_e28a_c == "1" if bi_e28a_c!= " "
	gen use_atm_remit =  bi_e28a_d == "1" if bi_e28a_d!= " "
	gen use_atm_govt =  bi_e28a_e == "1" if bi_e28a_e!= " "
	gen use_atm_deposit =  bi_e28a_f == "1" if bi_e28a_f!= " "
	gen use_atm_other =  bi_e28a_v == "1" if bi_e28a_v!= " "

	egen any_atm_use = rowmax(use_atm_purchase use_atm_withdraw use_atm_paybill use_atm_remit use_atm_govt use_atm_deposit use_atm_other)
	
	count if any_atm_use!=.
	global tot = `r(N)'
	
	mat res=J(30,5,.)
	local k=1
	local j=1
foreach var in use_atm_withdraw use_atm_remit use_atm_deposit use_atm_govt use_atm_purchase use_atm_paybill   {
		reg `var' urban [w= weight], r
			mat res[`k',1]= _b[_cons]
				mat res[`k',2]= _b[_cons]-1.96*_se[_cons]
				mat res[`k',3]= _b[_cons]+1.96*_se[_cons]
			lincom _cons+urban	
				mat res[`k'+1,1]= r(estimate)
					mat res[`k'+1,2]= r(estimate)-1.96*r(se)
					mat res[`k'+1,3]= r(estimate)+1.96*r(se)	
			mat res[`k',4]=0
			mat res[`k'+1,4]=1
			mat res[`k',5]=`j'
			mat res[`k'+1,5]=`j'
		local ++j
		local k=`k'+2		
			}
	
preserve
	drop _all
	mat colnames res= est ll ul urban cat
	svmat res, names(col)
	g marker= cat+urban*.5
		replace marker= marker+.5 if cat==2
		replace marker= marker+1 if cat==3	
		replace marker= marker+1.5 if cat==4	
		replace marker= marker+2 if cat==5	
		replace marker= marker+2.5 if cat==6
		
sort cat
twoway (bar est marker if urban==0, barw(.45) yla(0(.2)1)) || (bar est marker if urban==1, barw(.45) yla(0(.2)1)) || ///
	(rcap ul ll marker, mcol(black) lcol(black)), legend(order(1 2) label(1 "Rural") label(2 "Urban")  si(small) region(lwidth(none)) span)  ///
	xlab(1.25 "Withdrawl" 2.75 "Remit/Transfer" 4.25 "Deposit"  5.75 "Gov't Benefits" 7.25 "Purchases" 8.75 "Bill Pay" ,  labsize(small) )  xtit(" ") ytit("Share") ///
	graphregion(color(white) fcolor(white))
	
	graph export "$fig/ATM_Transactions.png", replace
								
restore
}





*FIGURE: Phone Use Capabilities
{
use "$final/fii2018", clear
 
 
 g calls = mt18a_1==3 | mt18a_1==4 if mt18a_1!=-2
 g navigate = mt18a_2==3 | mt18a_2==4 if mt18a_2!=-2
 g texts = mt18a_3==3 | mt18a_3==4 if mt18a_3!=-2
 g internet = mt18a_4==3 | mt18a_4==4 if mt18a_4!=-2
 g fintrans = mt18a_5==3 | mt18a_5==4 if mt18a_5!=-2
 g dwldapp = mt18a_6==3 | mt18a_6==4 if mt18a_6!=-2
 
 egen basic = rowtotal(calls navigate texts), missing
 egen advanced = rowtotal(internet fintrans dwldapp), missing
 egen totals = rowtotal(basic advanced), missing
 
 mat res=J(150,5,.)
 local k = 1
 local row = 1

 foreach group in calls navigate texts internet fintrans dwldapp basic advanced totals {
		reg `group' i.female [w=weight], clu(province)
			mat res[`row',1]= _b[_cons]
			mat res[`row',2]= _b[_cons]-_se[_cons]*1.96
			mat res[`row',3]= _b[_cons]+_se[_cons]*1.96
			mat res[`row',4]=0
			mat res[`row',5]=`k'
			local ++row
		lincom _cons+1.female
			mat res[`row',1]= r(estimate)
			mat res[`row',2]= r(estimate)-1.96*r(se)
			mat res[`row',3]= r(estimate)+1.96*r(se)		
			mat res[`row',4]= 1
			mat res[`row',5]= `k'
			local ++row
			local ++k			
							}
	

drop _all
mat colnames res= est ul ll female catvar
	svmat res, names(col)
	
	drop if est==.
	
gen index = _n	


	replace index = index + 9 if index==17 | index==18
	replace index = index + 8 if index==15 | index==16
	replace index = index + 7 if index==13 | index==14
	replace index = index + 5 if index==11 | index==12
	replace index = index + 4 if index==9 | index==10
	replace index = index + 3 if index==7 | index==8
	replace index = index + 2 if index==5 | index==6
	replace index = index + 1 if index==3 | index==4

	twoway 	(bar est index if female==0 & catvar<7, yscale(range(0) axis(1)) ytitle("Share", size(small) axis(1)))  /// 
			(bar est index if female==1 & catvar<7) ///
			(bar est index if female==0 & catvar>6, yaxis(2) yscale(range(0) axis(2)) ytitle("Number of Tasks", size(small) orientation(rvertical) axis(2)) fcolor("227 89 37") )  /// 
			(bar est index if female==1 & catvar>6, yaxis(2) fcolor("45 171 159")) ///
			(rcap ul ll index if catvar<7, lcolor(black)) ///
			(rcap ul ll index if catvar>6, lcolor(black) yaxis(2)) , ///
			xtitle(" ") ///
			legend(row(1) size(small) region(lwidth(none)) order(1 "Male" 2 "Female"))  ///
			xlabel( 1.5 "Calls" 4.5 "Navigate Menu" 7.5 "Text" 10.5 "Search Internet" 13.5 "Fin. Transaction" 16.5 "Download App" 20.5"Basic Tasks" 23.5"Advanced Tasks" 26.5"Total Tasks", angle(45)) ///
			xline(18.5, lpattern(dash) lcolor(gs13))  
			
 		 gr export "$fig/phonecapability.png", replace

}


*FIGURE: Digital ability by education
{
	use "$final/fii2018.dta", clear
	
	keep if age >17

	* Education
	rename hs_orhigher higherhs
	
	foreach var in 	noedu primary jrhigh hs higherhs {
		replace `var'=. if edu1==1
	}


	gen complete = mt18a_4 == 4 | mt18a_6 == 4
	gen compsome = inlist(mt18a_4,3,4) | inlist(mt18a_6, 8,3,4)
	
	
 mat res=J(150,5,.)
 local j = 1
 local row = 1

 foreach group2 in noedu primary jrhigh hs higherhs {
			local k=1
			foreach group in complete compsome {
				reg `group' own_smartphone if `group2'==1  [w=weight], clu(province)
					lincom _b[_cons]+_b[own_smartphone]
					mat res[`row',1]= r(estimate)
					mat res[`row',2]= r(estimate)-1.96*r(se)
					mat res[`row',3]= r(estimate)+1.96*r(se)
					mat res[`row',4]= `k'
					mat res[`row',5]= `j'
					local ++row
					local ++k
					}
					local ++j	
				}
	

drop _all
mat colnames res= est ul ll dl_ability edu
	svmat res, names(col)
	g index = edu * 3 - 2 
	g index2 = index + dl_ability - 1

twoway 	(bar est index2 if dl_ability == 1) || ///
		(bar est index2 if dl_ability == 2) || ///
		(rcap ul ll index2, lcol(gs4)), ///
			ytit("Share", size(small)) ///
			graphregion(color(white) fcolor(white)) ///
			yscale(range(0 1)) ylab(#5, labsize(small)) ///
			legend(on order(1 2) label(1 "Complete Ability") label(2 "Complete or Some Ability") ///
			size(small) region(lwidth(none)) rows(1)) ///
			xlab(1.5 "No Formal Education" 4.5 "Primary School" 7.5 "Junior High School" ///
			10.5 "High School" 13.5 "University", angle(hor) labsize(vsmall) notick) ///
			xtit(" ", size(small))
			
	gr export "$fig/litbyeducation.png", replace
}



*FIGURE: Remittance by Channel
{
use "$final/sofia-merge.dta", clear
	
	g cashonly_rec = remittance_rcv_method2==1 &  (remittance_rcv_method1==0 & remittance_rcv_method3==0 & remittance_rcv_method4==0) if remittance_received==1
	g dig_rec = cashonly_rec==0 &  (remittance_rcv_method1==1 | remittance_rcv_method3==1 | remittance_rcv_method4==1) 	if remittance_received==1
	
	
	g cashonly_send = remittance_sent_method==2 if remittance_sent==1
	g dig_send = cashonly_send==0 & (remittance_sent_method==1 | remittance_sent_method==3 | remittance_sent_method==4 | remittance_sent_method==5) if remittance_sent==1
	
	collapse (mean) cashonly_rec dig_rec cashonly_send dig_send [weight=wt_vil], by(female_ind) 
	
	label define female 0"Males" 1"Females"
	lab values female_ind female
	
	graph bar cashonly_rec dig_rec , over(female) stack legend(on  label(1 "Cash Only") label(2 "Digital") size(small) region(lwidth(none))) 	title("Receipt of Remittances", size(medsmall)) name("a", replace) intensity(80)

	graph bar cashonly_send dig_send , over(female) stack legend(on  label(1 "Cash Only") label(2 "Digital") size(small) region(lwidth(none))) 	title("Sending of Remittances", size(medsmall)) name("b", replace)	 intensity(80)
	
	grc1leg a b, ycommon
			
	gr export "$fig/remittancechannel.png", replace
}

*FIGURE: Account Shrouding
{
	use "$final/susenas-merge19.dta", clear

	gen all = 1
	bys URUT: egen total_savacc = sum(saving_account)

	gen any_savacc = saving_account
	gen onlyhead_savacc = saving_account == 1 & rel_head < 3 
	gen onlyothers_savacc = saving_account == 1 & rel_head > 2 

	collapse (max) all pkh pip bpnt saving_account *_savacc wt_hh province_code, by(URUT)

	gen both_savacc = onlyhead_savacc == 1 & onlyothers_savacc == 1
	replace onlyhead_savacc = 0 if both_savacc == 1
	replace onlyothers_savacc = 0 if both_savacc == 1

	order URUT  *_savacc

	mat res=J(50,5,.)
	local j = 1
	local row = 1

	foreach group in any_savacc onlyhead_savacc both_savacc onlyothers_savacc {
		reg `group' all  [w=wt_hh], clu(province_code)
			lincom _b[_cons]+_b[all]
			mat res[`row',1]= r(estimate)
			mat res[`row',2]= r(estimate)-1.96*r(se)
			mat res[`row',3]= r(estimate)+1.96*r(se)
			mat res[`row',4]= 1
			mat res[`row',5]= `j'
			local ++row
		
		reg `group' pkh [w=wt_hh], clu(province_code)
			lincom _b[_cons]+_b[pkh]
			mat res[`row',1]= r(estimate)
			mat res[`row',2]= r(estimate)-1.96*r(se)
			mat res[`row',3]= r(estimate)+1.96*r(se)
			mat res[`row',4]= 2
			mat res[`row',5]= `j'
			local ++row
			
		reg `group' bpnt [w=wt_hh], clu(province_code)
			lincom _b[_cons]+_b[bpnt]
			mat res[`row',1]= r(estimate)
			mat res[`row',2]= r(estimate)-1.96*r(se)
			mat res[`row',3]= r(estimate)+1.96*r(se)
			mat res[`row',4]= 3
			mat res[`row',5]= `j'
			local ++row
		
		reg `group' pip  [w=wt_hh], clu(province_code)
			lincom _b[_cons]+_b[pip]
			mat res[`row',1]= r(estimate)
			mat res[`row',2]= r(estimate)-1.96*r(se)
			mat res[`row',3]= r(estimate)+1.96*r(se)
			mat res[`row',4]= 4
			mat res[`row',5]= `j'
			local ++row
		
		local ++j
		}
	
	drop _all
	mat colnames res= est ul ll socprot category 
	svmat res, names(col)
	g index = socprot * 6 - 5 
	g index2 = index + category - 1
	
	drop if category == 1
	drop index index2
	bys socprot (category): gen temp =  sum(est)
	replace ul = temp
	bys socprot (category): gen temp2 = temp[_n-1]
	replace ll = temp2
	
	twoway 	(bar est socprot if category == 2, barw(.5)) || ///
			(rbar ul ll socprot if category == 3, barw(.5)) || ///
			(rbar ul ll socprot if category == 4, barw(.5)), ///
			ytit("Share", size(small)) ///
			graphregion(color(white) fcolor(white)) ///
			yscale(range(0 0.6)) ylab(#5, labsize(small)) ///
			xtit("") ///
			xlab(1 "All Households" 2 "PKH Households" 3 "BPNT Households" 4 "PIP Households", angle(hor) labsize(small) notick) ///	
			legend( on order(1 2 3) label(1 "Only the household head or/and spouse") ///
			label(2 "Both heads and other HH members")  label(3 "Only other HH members") rows(2) size(small) region(lwidth(none)))  
			
			
	gr export "$fig/account_shroud_stack.png", replace
}


****RANDOM FOREST*****
*Table: Accuracy
{
use "$final/fii-routput-accuracy.dta", clear
	
	gen Sample = 1 if sample=="Full"
	replace Sample = 2 if sample=="Female"
	replace Sample = 3 if sample=="Male"
	lab define Sample 1"Full Sample" 2"Females" 3"Males"
	lab values Sample Sample
	
	lab var Overall "Overall Accuracy"
	lab var Sensitivity "Sensitivity"
 	lab var Specificity "Specificity"
 	lab var NoInfo "No Information Rate"
 	lab var Pvalue "P-Value"

	foreach var in Overall Sensitivity Specificity NoInfo{
		replace `var'=`var'*100
	}
 
estpost tabstat NoInfo Overall Pvalue Sensitivity Specificity, by(Sample)  listwise statistics(mean) 

	esttab using "$fig/rfaccuracy.tex", ///
	cells("NoInfo(fmt(1) label(No Information Rate)) Overall(fmt(1)) Pvalue(fmt(2) label(P-Value*)) Sensitivity(fmt(1)) Specificity(fmt(1))") not noobs  nomtitle title(Random Forest Model Accuracy \label{rfacc}) ///
				 varwidth(80) eqlabels(`e(eqlabels)')  replace nonum nostar drop("Total") label ///
				 addnotes("*Null hypothesis is no difference in random forest’s overall accuracy and the no information rate")
				 	
	
	
	
}


*Table: Var Importance
{
use "$final/fii-routput-varimp.dta", clear	
	gsort -Importance_rf
	sort sample, stable
	by sample: gen Rank = _n
		gen varlab = "Receives Government Assistance" if Variables=="money_govt_asstYes"
		replace varlab = "Ever had BPJS Health" if Variables=="bpjs_healthYes"
		replace varlab = "Owns any Mobile Phone" if Variables=="own_mobilephoneYes"
		replace varlab = "Has Drivers License" if Variables=="has_DrivLicYes"
		replace varlab = "Ever had BPJS Labor" if Variables=="bpjs_laborYes"
		replace varlab = "Owns Smartphone" if Variables=="own_smartphoneYes"
		replace varlab = "Has Tax Card" if Variables=="has_TaxCardYes"
		replace varlab = "Highest Education: HS/Vocational" if Variables=="highestedu_respondentHS Vocational"
		replace varlab = "Has done 2 basic phone tasks in past week" if Variables=="phonetasks_bas_week2"
		replace varlab = "Has done 2 basic phone tasks in past month" if Variables=="phonetasks_bas_month2"
		replace varlab = "Female" if Variables=="femaleYes"
		replace varlab = "Has done all three advanced phone tasks" if Variables=="phonetasks_adv_ever3"
		replace varlab = "Receives scholarship" if Variables=="money_scholarshipYes"
		replace varlab = "Has done all five phone tasks" if Variables=="phonetasks_ever5"
		replace varlab = "Housewife" if Variables=="jobtypeHousewife"
		replace varlab = "Has complete ability to make/receive a call on a mobile" if Variables=="ability_callcomplete"
		replace varlab = "Trusts Financial Providers to Keep Personal Information Private" if Variable=="trust_in_systemstrong agree"

		assert !missing(varlab) if Rank<=10

		
		keep if Rank<=10 | (varlab=="Female" & sample=="Full")
				 
			
	*
	lab var Rank "Rank"
	lab var Importance_rf "Importance"
	lab var varlab "Feature"
	
	keep Rank Importance_rf varlab sample
	
	preserve 
	
		keep if sample=="Full"
		estimates clear
		labmask Rank, values(varlab)	
		g var=Rank
		lab values var Rank
		
			estpost tabstat Rank Importance_rf , by(var)  statistics(mean) nototal
					
			esttab using "$fig/Varimptable.tex",  cells("Rank Importance_rf(fmt(2))") not noobs label nomtitle  eqlabels(`e(labels)') varlabels(`e(labels)') collabels(none) ///
						replace nostar unstack fragment compress tex nonum  /// 
								prehead("\begin{table}[H] \begin{adjustbox}{max width=1.3\textwidth} \begin{threeparttable} \caption{Top 10 Most Important Variables in Random Forest Model} \label{varimpt} {\begin{tabular}{l*{1}{lll}} \hline \toprule {Feature}&{Rank}&{Importance} \\ \midrule \multicolumn{3}{c}{\textbf{A. Overall}} \\") 
	restore						
				
				
	preserve 
	
		keep if sample=="Male"
		estimates clear
		labmask Rank, values(varlab)	
		g var=Rank
		lab values var Rank
		
			estpost tabstat Rank Importance_rf , by(var)  statistics(mean) nototal
					
			esttab using "$fig/Varimptable.tex",  cells("Rank Importance_rf(fmt(2))") not noobs label nomtitle  eqlabels(,none) varlabels(`e(labels)') collabels(none) ///
						append nostar unstack fragment compress tex nonum  /// 
								prehead("\midrule \multicolumn{3}{c}{\textbf{B. Males}} \\  ") 
	restore
	
	preserve 
	
		keep if sample=="Female"
		estimates clear
		labmask Rank, values(varlab)	
		g var=Rank
		lab values var Rank
		
			estpost tabstat Rank Importance_rf , by(var)  statistics(mean) nototal
					
			esttab using "$fig/Varimptable.tex",  cells("Rank Importance_rf(fmt(2))") not noobs label nomtitle  eqlabels(,none) varlabels(`e(labels)') collabels(none) ///
						append nostar unstack fragment compress tex nonum  /// 
						prehead("\midrule \multicolumn{3}{c}{\textbf{C. Females}} \\  ")  ///
						postfoot(" \bottomrule \addlinespace[1.5ex] \end{tabular}} \begin{tablenotes}[flushleft]  \small \item \emph{Notes:} Unweighted data from 2019 FII. The table displays the ten most important variables identified by the random forest modeling, as well as the ranking for the female variable in the overall model. Ranking is based on the variables' value in decreasing Gini inpurity. For a more in depth explanation of random forest and its components, refer to \cite{rfart} \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table} \vspace*{-5mm}")
	restore		
			
			}

}

*Figure: Var Importance
{
	foreach Sample in Male Female{
	use "$final/fii-routput-varimp.dta", clear	
		
		keep if sample=="`Sample'"
		gsort -Importance_rf
		gen Rank = _n	
		keep if Rank<101
		
	gen varcat = .

	replace Variables = subinstr(Variables," ", "", .)

	local dige own_mobilephoneYes own_smartphoneYes phonetasks_ever5 phonetasks_adv_ever3 phonetasks_bas_ever2 phonetasks_bas_week2 ability_internetcomplete phoneusage_basic_n12 phonetasks_bas_today2 phonetasks_bas_month2 ability_navmenucomplete ability_callcomplete phonetasks_bas_today1 ability_textcomplete phoneusage_adv_n12 ability_dwldappcomplete phonetasks_today1 ability_internetnone ability_fintranscomplete ability_dwldappnone phonetasks_ever2 phonetasks_adv_week2 ability_navmenunone phoneusage_adv_n3 phonetasks_adv_today2 phonetasks_month5 phonetasks_adv_month3 ability_textnone phonetasks_week5 phonetasks_today2 ability_navmenusome

	local idown has_TaxCardYes has_DrivLicYes
	
	local gov money_govt_asstYes bpjs_healthYes  bpjs_laborYes has_KTPYes
	
	local ses poverty_binYes fridgeYes used_sharedYes money_dom_remitYes read_bahasagood can_readsomehelp scooterYes money_scholarshipYes read_bahasasomewhatbadly write_bahasagood cookfuelfas jobtypeHousewife workertypeHousewife/husband employment_maleWageorsalaryemployee jobsectorservice employment_maleSelf-employed income_pctalittle workertypeWorkingfull-timewithreg.salary income_pctabouthalf workertypeSelf-employed jobtypeSelfEmply workertypeWorkingoccassionally,irregularpay/seasonal income_pctalmostall workertypeFull-timestudent jobtypeStudent jobsectorlaborer jobtypeIrreg money_agYes highestedu_femalePrimary highestedu_respondentPrimary highestedu_respondentJr.High highestedu_respondentHSVocational highestedu_femaleJrHigh highestedu_femaleVocationalHSlevel money_ownYes

	
	local demo provinceProvince9 provinceProvince11  hh_num_females1 hh_num_females2 multi_distmorethan5km urbanUrban any_teenage_girlsYes atm_distbtwn1and5km hh_num_males1 pos_distbtwn1and5km hh_num_males2 males_9t121 resp_age_binage40to45   bank_distbtwn1and5km  insur_distmorethan5km rel_hh_headspouse hh_head_femYes atm_distbtwn.5and1km resp_age_binage35to40 atm_distlessthan.5km hh_size4 pos_distmorethan5km hh_members4 hh_head_age_binage35to40 hh_size3 provinceProvince10 know_mobilemoneyYes pawnshop_distbtwn1and5km hh_members3 bank_distmorethan5km use_mobilemoneyYes hh_head_age_binage45to50 fems_9t121 multi_distbtwn1and5km laku_distbtwn1and5km hh_size5 pawnshop_distmorethan5km hh_head_age_binage40to45  provinceProvince33 males_u41 coop_distbtwn1and5km  males_5t81 marriedYes any_teenage_boysYes  sh_micro_distbtwn1and5km money_bus_less10Yes laku_distbtwn.5and1km mta_distbtwn1and5km  bank_distbtwn.5and1km  
	
	local agency trust_in_systemstrongagree voice_disagreementvlikely invovle_beybasicsvinvolved finaldec_ownmoneystrongagree finaldec_hhincstrongagree invovle_basicsvinvolved influence_spendingalmostall invovle_hhincvinvolved trust_in_systemsomeagree finaldec_ownmoneysomeagree finaldec_hhincsomeagree influence_spendingmost invovle_hhincvuninvolved influence_spendingnone invovle_hhincsomeuninvolved voice_disagreementsomelikely invovle_beybasicsneither



	
	foreach x in `dige'{
			replace varcat = 1 if Variables=="`x'"
		}
		
	foreach x in `idown'{
			replace varcat = 2 if Variables=="`x'"
		}
		
	foreach x in `gov'{
			replace varcat = 3 if Variables=="`x'"
		}
		
	foreach x in `ses'{
			replace varcat = 4 if Variables=="`x'"
		}	
		
		
	foreach x in `demo'{
			replace varcat = 5 if Variables=="`x'"
		}
		
	foreach x in `agency'{
			replace varcat = 6 if Variables=="`x'"
		}		
		
	assert !missing(varcat)
	
	if "`Sample'"=="Female"{
		local tit "Females"
				}
	if "`Sample'"=="Male" {
		local tit "Males"
				}
	
	twoway 	(bar  Importance Rank if varcat==1, color("242 196 19") lcolor(black)) ///
			(bar Importance Rank if varcat==2,  color(black) lcolor(black)) ///
			(bar  Importance Rank if varcat==3,  color("227 89 37") lcolor(black)) ///
			(bar Importance Rank if varcat==4,  color("104 175 193") fintensity(inten40) lcolor(black)) ///
			(bar  Importance Rank if varcat==5,  color("45 171 159") lcolor(black)) ///
			(bar Importance Rank if varcat==6,  color(gray) lcolor(black)), ///
			legend(region(lwidth(none)) order(1 4 2 3 5 6) ///
			label(1 "Digital Engagement") label(2 "ID Ownership") label(3 "Gov't Benefits") ///
			label(4 "SES/Economic") label(5 "Demographics/Other") label(6 "Agency/Trust") ///
			size(small) rows(2)) title({bf:`tit'}, size(medium)) ///
			name("`tit'", replace) ytitle("Importance") 

					}


	grc1leg Males Females, ycommon col(1) 	
		
				 gr export "$fig/rftop100.png", replace

	
}


*BOX 2: ONLINE SURVEY BY GENDER
{
** BY GENDER **
use "$final/Online Survey-DFS Adoption_Covid-19/onlinesurvey-pooled.dta", clear 

clear matrix
set more off

count if female == 1
local f = `r(N)'
count if female == 0
local m = `r(N)'

mat res=J(20,5,.)
 local row = 1
 local k=1

gen male = female == 0
tab dfs_use_num, gen(dfs)

forval i=1/6 {
	reg dfs`i' female [aw=weight]
	lincom _b[_cons]+_b[female]
		mat res[`row',1]= r(estimate)
		mat res[`row',2]= r(estimate)-1.96*r(se)
		mat res[`row',3]= r(estimate)+1.96*r(se)
		mat res[`row',4]= 1
		mat res[`row',5]= `i'
		local ++row
	
	reg dfs`i' male [aw=weight]
	lincom _b[_cons]+_b[male]
		mat res[`row',1]= r(estimate)
		mat res[`row',2]= r(estimate)-1.96*r(se)
		mat res[`row',3]= r(estimate)+1.96*r(se)
		mat res[`row',4]= 0
		mat res[`row',5]= `i'
		local ++row
}

drop _all
mat colnames res= est ul ll female dfs 
svmat res
rename res1 est
rename res2 ul
rename res3 ll
rename res4 female
rename res5 dfs

gen counter = 2 if female == 0
replace counter = 1 if female == 1

gen marker = .
replace marker = dfs + (counter - 1) * 7 if dfs < 3
replace marker = 3 + (counter - 1) * 7 if dfs == 4
replace marker = 4 + (counter - 1) * 7 if dfs == 3
replace marker = 5 + (counter - 1) * 7 if dfs == 6
replace marker = 6 + (counter - 1) * 7 if dfs == 5


	**add a little space between non-user and users for ease of readability
	replace marker = marker +.1 if marker>4
	replace marker = marker +.1 if marker>12
	
twoway (bar est marker if dfs == 1) || ///
		(bar est marker if dfs == 2) || ///
		(bar est marker if dfs == 4) || ///
		(bar est marker if dfs == 3) || ///
		(bar est marker if dfs == 6) || ///
		(bar est marker if dfs == 5, fcolor("74 156 101")) || ///
		(rcap ul ll marker, lcol(gs4) lwidth(thin) msize(tiny)), ///
		ytit("Share", size(small)) ///
		graphregion(color(white) fcolor(white)) ///
		yscale(range(0 .4)) ylab(#5, labsize(small)) ///
		xtit("") ///
		legend(region(lwidth(none))  row(2) on order(1 2 3 4 5 6) label(1 "First Time Usee") ///
		label(2 "Use More Often") label(3 "Use Same Amount") ///
		label(4 "Use Less Often") label(5 "Stopped Use") ///
		label(6 "Never Use") ///
		size(small)) ///
		xlabel(3.5 "Females" 10.75 "Males", angle(hor) labsize(small) notick)
			
			
	gr export "$fig/onlinesurvey_gender.png", replace

}

*BOX 3: ONLINE SHOPPING
{
	
** ONLINE SHOPPING **
* by gender
use "$final/Online Survey-DFS Adoption_Covid-19/onlinesurvey-screened.dta", clear 

clear matrix
set more off

count if female == 1
local f = `r(N)'
count if female == 0
local m = `r(N)'

mat res=J(20,5,.)
 local row = 1
 local k=1

gen male = female == 0

// Bin without transition
gen buy_basic = .
replace buy_basic = 1 if buy_basicneeds1_num == 1								// Never online
replace buy_basic = 2 if buy_basicneeds1_num == 2 | buy_basicneeds1_num == 4	// Some online
replace buy_basic = 3 if buy_basicneeds1_num == 3 | buy_basicneeds1_num == 5	// Most online

tab buy_basic, gen(buy_basic)

forval i=1/3 {
	reg buy_basic`i' female [aw=weight]
	lincom _b[_cons]+_b[female]
		mat res[`row',1]= r(estimate)
		mat res[`row',2]= r(estimate)-1.96*r(se)
		mat res[`row',3]= r(estimate)+1.96*r(se)
		mat res[`row',4]= 1
		mat res[`row',5]= `i'
		local ++row
	
	reg buy_basic`i' male [aw=weight]
	lincom _b[_cons]+_b[male]
		mat res[`row',1]= r(estimate)
		mat res[`row',2]= r(estimate)-1.96*r(se)
		mat res[`row',3]= r(estimate)+1.96*r(se)
		mat res[`row',4]= 0
		mat res[`row',5]= `i'
		local ++row
}

drop _all
mat colnames res= est ul ll female buy
svmat res
rename res1 est
rename res2 ul
rename res3 ll
rename res4 female
rename res5 buy

bys female (buy): gen temp =  sum(est)
	replace ul = temp
bys female (buy): gen temp2 = temp[_n-1]
	replace ll = temp2
gen marker = female
replace marker = 3 if female == 0

twoway	(bar est marker if buy == 1) || ///
		(rbar ul ll marker if buy == 2) || ///
		(rbar ul ll marker if buy == 3), ///
		ytit("Share", size(small)) ///
		graphregion(color(white) fcolor(white)) ///
		yscale(range(0 1)) ylab(#5, labsize(small)) ///
		xscale(range(0 4)) xtit("") ///
		legend(size(small) region(lwidth(none)) on order(1 2 3) label(1 "Never Online") ///
		label(2 "Some Online") label(3 "Mostly Online") row(1)) ///
		xlabel(1 "Females" 3 "Males", angle(hor) labsize(small) notick)
			
	gr export "$fig/onlinesurvey_ecomm.png", replace
}

			




*FIGURE: SES GRADIENT
{
use "$final/fii2018.dta", clear
 
 gen edu_cat = 0 if highestedu_respondent==1 | highestedu_respondent==9
 replace edu_cat = 1 if highestedu_respondent==2
 replace edu_cat = 2 if highestedu_respondent==3
 replace edu_cat = 3 if highestedu_respondent==5
 replace edu_cat = 4 if highestedu_respondent==6 | highestedu_respondent==7 | highestedu_respondent==8
 
 
	lab define edu_cat 0"None" 1"Primary" 2"Jr High" 3"HS" 4"Post HS", replace
	lab values edu_cat edu_cat
	
	lab define urban 0"Rural" 1"Urban"
	lab values urban urban
	
	replace age_group = age_group -1  if !missing(age_group)
	lab define age_group 0"15-24" 1"25-34" 2"35-44" 3"45-54" 4"55+"
	lab values age_group age_group
 
 mat res=J(150,6,.)
 local row = 1
 	 local j = 1

 foreach outcome in ownership use_mobilemoney{
	 local k=1

	foreach group in edu_cat urban age_group {
				reg `outcome' i.`group'  [w=weight], clu(aa1)
					mat res[`row',1]= _b[_cons]
					mat res[`row',2]= _b[_cons]-_se[_cons]*1.96
					mat res[`row',3]= _b[_cons]+_se[_cons]*1.96
					mat res[`row',4]=0
					mat res[`row',5]=`j'
					mat res[`row',6]=`k'
					local ++row
				lincom _cons+1.`group'
					mat res[`row',1]= r(estimate)
					mat res[`row',2]= r(estimate)-1.96*r(se)
					mat res[`row',3]= r(estimate)+1.96*r(se)		
					mat res[`row',4]= 1
					mat res[`row',5]= `j'
					mat res[`row',6]= `k'
					local ++row
				if "`group'" == "edu_cat" | "`group'"=="age_group" {
					forvalues i=2/4{
				lincom _cons+`i'.`group'
						mat res[`row',1]= r(estimate)
						mat res[`row',2]= r(estimate)-1.96*r(se)
						mat res[`row',3]= r(estimate)+1.96*r(se)		
						mat res[`row',4]= `i'
						mat res[`row',5]= `j'						
						mat res[`row',6]= `k'						
						local ++row
						
					}	
					}	
					
					local ++k		
				}
				local ++j
				}
	

drop _all
mat colnames res= est ul ll cat outcome grpvar
	svmat res, names(col)
	bysort outcome grpvar: g index =  _n
	drop if est==.
// 		replace index = index+1 if grpvar==2
// 		replace index = index+2 if grpvar==3
		

twoway 	(bar est index if grpvar == 1 & outcome==1, barwidth(.9)) ///
		(rcap ul ll index if grpvar==1 & outcome==1, lcol(gs4)), ///
			ytit("Share", size(small)) ///
			graphregion(color(white) fcolor(white)) ///
			yscale(range(0 1)) ylab(#5, labsize(small)) ///
			legend(off)  ///
			xlab(1 "None" 2 "Primary" 3 "Jr. HS" ///
			4 "HS" 5 "Post HS", angle(hor) labsize(medsmall) notick) ///			
			xtit(" ") title("A. Education", size(medsmall)) name("education", replace)
			
twoway 	(bar est index if grpvar == 3 & outcome==1, bcolor("45 171 159") barwidth(.9)) ///
		(rcap ul ll index if grpvar==3 & outcome==1, lcol(gs4)), ///
			ytit("Share", size(small)) ///
			graphregion(color(white) fcolor(white)) ///
			yscale(range(0 1)) ylab(#5, labsize(small)) ///
			legend(off)  ///
			xlab(1 "15-24" 2 "25-24" 3 "35-44" ///
			4 "45-54" 5 "55+", angle(hor) labsize(medsmall) notick) ///			
			xtit(" ") title("C. Age", size(medsmall)) name("age", replace)	
			
twoway 	(bar est index if grpvar == 2 & outcome==1,  bcolor("242 196 19")  barwidth(.9)) ///
		(rcap ul ll index if grpvar==2 & outcome==1, lcol(gs4)), ///
			ytit("Share", size(small)) ///
			graphregion(color(white) fcolor(white)) ///
			yscale(range(0 1)) ylab(#5, labsize(small)) ///
			legend(off)  ///
			xlab(1 "Rural" 2 "Urban" , angle(hor) labsize(medsmall) notick) ///			
			xtit(" ") title("B. Urbanicity", size(medsmall)) name("urban", replace)					
			
graph combine education urban age, ycommon title("Account Ownership", size(medsmall))	col(1)	name("g1", replace)	
			
twoway 	(bar est index if grpvar == 1 & outcome==2, barwidth(.9)) ///
		(rcap ul ll index if grpvar==1 & outcome==2, lcol(gs4)), ///
			ytit("Share", size(small)) ///
			graphregion(color(white) fcolor(white)) ///
			yscale(range(0 .5)) ylab(#5, labsize(medsmall)) ///
			legend(off)  ///
			xlab(1 "None" 2 "Primary" 3 "Jr. HS" ///
			4 "HS" 5 "Post HS", angle(hor) labsize(small) notick) ///			
			xtit(" ") title("D. Education", size(medsmall)) name("education", replace)
			
twoway 	(bar est index if grpvar == 3 & outcome==2,  bcolor("45 171 159")  barwidth(.9)) ///
		(rcap ul ll index if grpvar==3 & outcome==2, lcol(gs4)), ///
			ytit("Share", size(small)) ///
			graphregion(color(white) fcolor(white)) ///
			yscale(range(0 .5)) ylab(#5, labsize(small)) ///
			legend(off)  ///
			xlab(1 "15-24" 2 "25-24" 3 "35-44" ///
			4 "45-54" 5 "55+", angle(hor) labsize(medsmall) notick) ///			
			xtit(" ") title("F. Age", size(medsmall)) name("age", replace)	
			
twoway 	(bar est index if grpvar == 2 & outcome==2,  bcolor("242 196 19")   barwidth(.9)) ///
		(rcap ul ll index if grpvar==2 & outcome==2, lcol(gs4)), ///
			ytit("Share", size(small)) ///
			graphregion(color(white) fcolor(white)) ///
			yscale(range(0 .5)) ylab(#5, labsize(small)) ///
			legend(off)  ///
			xlab(1 "Rural" 2 "Urban" , angle(hor) labsize(medsmall) notick) ///			
			xtit(" ") title("E. Urbanicity", size(medsmall)) name("urban", replace)				
			
graph combine education urban age, ycommon title("E-Money Usage", size(medsmall))	col(1)	name("g2", replace)	
	
			
	graph combine g1 g2, col(2) xsize(*.75)
			
	gr export "$fig/sesgradient.png", replace
	
}
