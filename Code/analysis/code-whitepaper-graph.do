* ******************************************************************************
* PROGRAM: Whitepaper Graph
* AUTHORS: Nick Wisely, Natalie Theys, Lolita Moorena, Nadia Setiabudi
* PURPOSE: Create tables and figures for whitepaper
* DATE CREATED: 23 June 2020
* LAST MODIFIED: 15 October 2020 by Nadia Setiabudi
* ******************************************************************************

************************************************
* FIGURE 1:	Village-Level Access to 	   	   *
*  Financial Services	   					   *
************************************************
{

use "$final\matchedfin_shp_PODES.dta", clear
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



* Indonesia heatmap
// ENGLISH
	colorpalette gs12 "45 171 159" "242 196 19" "227 89 37" gs15
	
	spmap financialserv using "$shp/2019shp/INDO_DESA_2019_coord.dta", id(_ID) clmethod(unique) ///
	ocolor(none ..) fcolor(`r(p)') ndocolor(gs12) ///
	polygon(data("$final/border_all.dta") ocolor(black) fcolor(none) osize(medium)) ///
	legend(label(2 "No Bank")) legend(label(3 "Bank") label(4 "No Bank, but ATM") ///
	label(5 "No Bank/ATM, but Agent") label(6 "No Data") ) ///
	legorder(lohi) legend(ring(1) position(6) ///
		rows(1))  
	
 	gr export "$fig/heatmap_financialserv.png", replace
	
// INDONESIAN
	colorpalette gs12 "45 171 159" "242 196 19" "227 89 37" gs15
	
	spmap financialserv using "$shp/2019shp/INDO_DESA_2019_coord.dta", id(_ID) clmethod(unique) ///
	ocolor(none ..) fcolor(`r(p)') ndocolor(gs12) ///
	polygon(data("$final/border_all.dta") ocolor(black) fcolor(none) osize(medium)) ///
	legend(label(2 "Tidak Ada Bank")) legend(label(3 "Bank") label(4 "Tidak Ada Bank, tapi Ada ATM") ///
	label(5 "Tidak Ada Bank/ATM, tapi Ada Agen") label(6 "Tidak Ada Data") ) ///
	legorder(lohi) legend(ring(1) position(6) ///
		rows(1))  
	
 	gr export "$fig/heatmap_financialserv_IND.png", replace
	

*SUB-FIGURE: Indonesia financial service PIE CHART

 use "$final/podes-popbank.dta", clear

 collapse (sum) population (count)  id, by(financialserv)

 	label define FIN 0 "No Bank" 1 "Bank" 2 "No Bank, Only ATM" 3 "No Bank/ATM, Only Agent" 4"No Data", replace
 	label values financialserv FIN

 colorpalette gs12 "45 171 159" "242 196 19" "227 89 37" gs15

// ENGLISH 
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
		 
// INDONESIAN
* Indonesia population pie chart
	graph pie population, over(financialserv) legend(off) ///
 	pie(1, color(gs12)) pie(2, color("45 171 159")) pie(3, color("242 196 19")) pie(4, color("227 89 37")) pie(5, color(gs15)) ///
 	title("Populasi", size(vhuge)) ///
 	plotregion(color(white) fcolor(white)) ///
 	name("population_ind", replace) plotregion(margin(zero))

* Indonesia location pie chart
	graph pie id, over(financialserv) legend(off) ///
 	pie(1, color(gs12)) pie(2, color("45 171 159")) pie(3, color("242 196 19")) pie(4, color("227 89 37")) pie(5, color(gs15)) ///
 	title("Desa", size(vhuge)) ///
 	plotregion(color(white) fcolor(white)) ///
 	name("village_ind", replace)  plotregion(margin(zero))

 graph combine population_ind village_ind

  		 gr export "$fig/heatmappie_IND.png", replace
}


************************************************
* FIGURE 2:	Influence on and Involvement	   *
*  in Household Financial Decision-making	   *
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
// ENGLISH	
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
	
// INDONESIA
	twoway 	(bar est marker if cat == 1, bcolor("227 89 37"))  ///
			(bar est marker if cat == 3, bcolor("227 89 37") fintensity(inten60))   ///
			(bar est marker if cat == 2, bcolor("45 171 159"))   ///
			(bar est marker if cat == 4, bcolor("45 171 159") fintensity(inten60))  , ///
			ytit("Proporsi", size(small)) ///
			graphregion(color(white) fcolor(white)) ///
			yscale(range(0 1)) ylab(#6, labsize(small)) ///
			legend(on order(1 2 3 4) label(1 "Wanita Kawin") label(2 "Wanita Tidak Kawin") ///
			label(3 "Pria Kawin") label(4 "Pria Tidak Kawin") symysize(*.6) symxsize(*.6) ///
			size(small) rows(1) region(lwidth(none)) span) xtit(" ")  ///
			xlab(2.5 `" "Terlibat dalam bagaimana"  "penghasilan digunakan" "' 7.5 `" "Memiliki pengaruh" "bagaimana penghasilan" "digunakan jika" "ada perselisihan"' 12.5 `" "Cenderung menyampaikan" "ketidaksepakatan pada" "bagaimana penghasilan" "digunakan`'" "' 17.5`" "Mengambil keputusan akhir" "pada bagaimana uang"  "sendiri digunakan" "', ///
			labsize(small) notick)  
		
	gr export "$fig/HH_DecisionMaking_IND.png", replace	
}

************************************************
* TABLE 3:	Use of Financial Services	       *
*  by Males and Females	   					   *
************************************************
{
use "$final/fii2018.dta", clear

estpost tabstat hasatm savings bsa savmicro savecoop loanbank loanmulti loanpawn loanmicro loancoop  emoney invest haveother included_bin2, by(female) listwise statistics(mean) columns(statistics) esample 	
		
		esttab using "$fig/ServicesByGender.tex", cells("mean(fmt(2) label())") ///
		noobs not label eqlabels(,none) varlabels(`e(labels)') collabels(,none) varwidth(80) ///
		replace nostar unstack fragment compress tex nonum nomtitle /// 
		prehead("\begin{table}[H] \begin{adjustbox}{max width=\textwidth} \begin{threeparttable} \caption{Use of Financial Services by Males and Females} \label{servgender} {\begin{tabular}{l*{1}{llll}} \toprule  & Males & Females & Overall \\") ///
		prefoot("\bottomrule")  ///
		posthead("\hline") postfoot("\addlinespace[1.5ex] \end{tabular}} \begin{tablenotes}[flushleft]  \small \item \emph{Notes:} Weighted estimates using 2019 FII data. Those with accounts at unknown institutions reported owning an account but did report owning an account at the specific institutions \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table} \vspace*{-5mm}")			
		
}

************************************************
* TABLE 4:Method of Account Withdrawls         *
*  and Deposits	   					           *
************************************************
{
use "$final/fii2018.dta", clear

*Weighted means overall
	preserve 
		collapse (mean) any_withdraw withdrawteller withdrawatm withdrawagent any_deposit dep_teller dep_atm dep_agent [w=weight]
		xpose, clear varname
		rename v1 Overall
		
		tempfile overall
		save "`overall'"
	restore

*Weighted means by gender
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

*Weighted means by urbanicity	
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
	
*Merge them together	
	use "`gender'", clear
	merge 1:1 _varname using "`urban'", gen(m1)
	merge 1:1 _varname using "`overall'", gen(m2)
	
	*Put them in the correct order for the table
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
	
*Export Table	
		sort order
		estpost tabstat Males Females Rural Urban Overall if order<5, by(order) s(mean) nototal
					
		esttab using "$fig/TransactionTypes.tex" ,  ///
		cells("Males(fmt(2)) Females(fmt(2)) Rural(fmt(2)) Urban(fmt(2)) Overall(fmt(2))") ///
		not noobs label nomtitle  eqlabels(`e(labels)') varlabels(`e(labels)') collabels(none) ///
		replace nostar unstack fragment compress tex nonum  /// 
		prehead("\begin{table}[H] \begin{adjustbox}{max width=1.3\textwidth} \begin{threeparttable} \caption{Method of Account Withdrawls and Deposits} \label{transtypetable} {\begin{tabular}{l*{1}{llllll}} \toprule &{Males}&{Females}&{Rural}&{Urban}&{Overall} \\ ") 	
						
		estpost tabstat Males Females Rural Urban Overall if order>4, by(order) s(mean) nototal
						
		esttab using "$fig/TransactionTypes.tex",  ///
		cells("Males(fmt(2)) Females(fmt(2)) Rural(fmt(2)) Urban(fmt(2)) Overall(fmt(2))") ///
		not noobs label nomtitle  eqlabels(,none) varlabels(`e(labels)') collabels(none) ///
		append nostar unstack fragment compress tex nonum  ///				
		postfoot("\bottomrule \addlinespace[1.5ex] \end{tabular}} \begin{tablenotes}[flushleft]  \small \item \emph{Notes:} Weighted estimates using 2019 FII data. Only asked of individuals who report currently having an individual or joint savings account at a bank. Captures transactions from the past 6 months. \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table} \vspace*{-5mm}")
	

}

************************************************
* FIGURE 3:	Account Ownership and E-Money 	   *
*  Usage Across Socioeconomic Status	   	   *
************************************************
{
use "$final/fii2018.dta", clear
 
*Create a new age_group var for ease of calculating estimates
	replace age_group = age_group -1  if !missing(age_group)
		lab define age_group 0"15-24" 1"25-34" 2"35-44" 3"45-54" 4"55+"
		lab values age_group age_group
 
*Create Matrix for Estimates
	 mat res=J(150,6,.)
	 local row = 1
		 local j = 1

*Calculate Estimates		 
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
	
*Put Estimates in Matrix
drop _all
mat colnames res= est ul ll cat outcome grpvar
	svmat res, names(col)
	bysort outcome grpvar: g index =  _n
	drop if est==.
		
*Create Figures
// ENGLISH
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
			xlab(1 "15-24" 2 "25-34" 3 "35-44" ///
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
			
	graph combine education urban age, ///
	ycommon title("Account Ownership", size(medsmall))	col(1)	name("g1", replace)	
			
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
			xlab(1 "15-24" 2 "25-34" 3 "35-44" ///
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
				
	graph combine education urban age, ///
	ycommon title("E-Money Usage", size(medsmall))	col(1)	name("g2", replace)	
	
*Combine
	graph combine g1 g2, col(2)
			
	gr export "$fig/sesgradient.png", replace

	
// INDONESIAN
	twoway 	(bar est index if grpvar == 1 & outcome==1, barwidth(.9)) ///
			(rcap ul ll index if grpvar==1 & outcome==1, lcol(gs4)), ///
			ytit("Proporsi", size(small)) ///
			graphregion(color(white) fcolor(white)) ///
			yscale(range(0 1)) ylab(#5, labsize(small)) ///
			legend(off)  ///
			xlab(1 "Tidak sekolah" 2 "SD" 3 "SMP" ///
			4 "SMA" 5 "Pasca SMA", angle(hor) labsize(medsmall) notick) ///			
			xtit(" ") title("A. Pendidikan", size(medsmall)) name("education", replace)
				
	twoway 	(bar est index if grpvar == 3 & outcome==1, bcolor("45 171 159") barwidth(.9)) ///
			(rcap ul ll index if grpvar==3 & outcome==1, lcol(gs4)), ///
			ytit("Proporsi", size(small)) ///
			graphregion(color(white) fcolor(white)) ///
			yscale(range(0 1)) ylab(#5, labsize(small)) ///
			legend(off)  ///
			xlab(1 "15-24" 2 "25-34" 3 "35-44" ///
			4 "45-54" 5 "55+", angle(hor) labsize(medsmall) notick) ///			
			xtit(" ") title("C. Usia", size(medsmall)) name("age", replace)	
				
	twoway 	(bar est index if grpvar == 2 & outcome==1,  bcolor("242 196 19")  barwidth(.9)) ///
			(rcap ul ll index if grpvar==2 & outcome==1, lcol(gs4)), ///
			ytit("Proporsi", size(small)) ///
			graphregion(color(white) fcolor(white)) ///
			yscale(range(0 1)) ylab(#5, labsize(small)) ///
			legend(off)  ///
			xlab(1 "Pedesaan" 2 "Perkotaan" , angle(hor) labsize(medsmall) notick) ///			
			xtit(" ") title("B. Perkotaan/Pedesaan", size(medsmall)) name("urban", replace)					
			
	graph combine education urban age, ///
	ycommon title("Kepemilikan Rekening", size(medsmall))	col(1)	name("g1_ind", replace)	
			
	twoway 	(bar est index if grpvar == 1 & outcome==2, barwidth(.9)) ///
			(rcap ul ll index if grpvar==1 & outcome==2, lcol(gs4)), ///
			ytit("Proporsi", size(small)) ///
			graphregion(color(white) fcolor(white)) ///
			yscale(range(0 .5)) ylab(#5, labsize(medsmall)) ///
			legend(off)  ///
			xlab(1 "Tidak sekolah" 2 "SD" 3 "SMP" ///
			4 "SMA" 5 "Pasca SMA", angle(hor) labsize(small) notick) ///			
			xtit(" ") title("D. Pendidikan", size(medsmall)) name("education", replace)
				
	twoway 	(bar est index if grpvar == 3 & outcome==2,  bcolor("45 171 159")  barwidth(.9)) ///
			(rcap ul ll index if grpvar==3 & outcome==2, lcol(gs4)), ///
			ytit("Proporsi", size(small)) ///
			graphregion(color(white) fcolor(white)) ///
			yscale(range(0 .5)) ylab(#5, labsize(small)) ///
			legend(off)  ///
			xlab(1 "15-24" 2 "25-34" 3 "35-44" ///
			4 "45-54" 5 "55+", angle(hor) labsize(medsmall) notick) ///			
			xtit(" ") title("F. Usia", size(medsmall)) name("age", replace)	
				
	twoway 	(bar est index if grpvar == 2 & outcome==2,  bcolor("242 196 19")   barwidth(.9)) ///
			(rcap ul ll index if grpvar==2 & outcome==2, lcol(gs4)), ///
			ytit("Proporsi", size(small)) ///
			graphregion(color(white) fcolor(white)) ///
			yscale(range(0 .5)) ylab(#5, labsize(small)) ///
			legend(off)  ///
			xlab(1 "Pedesaan" 2 "Perkotaan" , angle(hor) labsize(medsmall) notick) ///			
			xtit(" ") title("E. Pedesaan/Perkotaan", size(medsmall)) name("urban", replace)				
				
	graph combine education urban age, ///
	ycommon title("Penggunaan Uang Elektronik", size(medsmall))	col(1)	name("g2_ind", replace)	
	
*Combine
	graph combine g1_ind g2_ind, col(2)
			
	gr export "$fig/sesgradient_IND.png", replace
}	

************************************************
* FIGURE 4:	Types of Uses for ATM Cards		   *
*  in Urban and Rural Areas	   				   *
************************************************
{
 use "$final/fii2018", clear
 
*Make Matrix for Estimates	
	mat res=J(30,5,.)
	local k=1
	local j=1
	
*Calculate Estimates	
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
	
*Put Estimates in Matrix	
	drop _all
	mat colnames res= est ll ul urban cat
	svmat res, names(col)
	g marker= cat+urban*.5
		replace marker= marker+.5 if cat==2
		replace marker= marker+1 if cat==3	
		replace marker= marker+1.5 if cat==4	
		replace marker= marker+2 if cat==5	
		replace marker= marker+2.5 if cat==6

*Create Figure	
// ENGLISH	
	sort cat
	twoway (bar est marker if urban==0, barw(.45) yla(0(.2)1)) ///
	(bar est marker if urban==1, barw(.45) yla(0(.2)1))  ///
	(rcap ul ll marker, mcol(black) lcol(black)), ///
	legend(on order(1 2) label(1 "Rural") label(2 "Urban")  si(small) region(lwidth(none)) span)  ///
	xlab(1.25 "Withdrawal" 2.75 "Remit/Transfer" 4.25 "Deposit"  5.75 "Gov't Benefits" 7.25 "Purchases" 8.75 "Bill Pay" ,  labsize(small)) ///
	xtit(" ") ytit("Share") ///
	graphregion(color(white) fcolor(white))
	
	graph export "$fig/ATM_Transactions.png", replace

// INDONESIAN	
	sort cat
	twoway (bar est marker if urban==0, barw(.45) yla(0(.2)1)) ///
	(bar est marker if urban==1, barw(.45) yla(0(.2)1))  ///
	(rcap ul ll marker, mcol(black) lcol(black)), ///
	legend(on order(1 2) label(1 "Pedesaan") label(2 "Perkotaan")  si(small) region(lwidth(none)) span)  ///
	xlab(1.25 "Penarikan" 2.75 "Pengiriman" 4.25 "Deposit"  5.75 `""Bantuan" "Pemerintah""' 7.25 "Pembelian" 8.75 `""Pembayaran" "Tagihan"' ,  labsize(small)) ///
	xtit(" ") ytit("Proporsi") ///
	graphregion(color(white) fcolor(white))
	
	graph export "$fig/ATM_Transactions_IND.png", replace	
}

************************************************
* TABLE 5: Random Forest Model Accuracy        *
************************************************
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
	cells("NoInfo(fmt(1) label(No Information Rate)) Overall(fmt(1)) Pvalue(fmt(2) label(P-Value*)) Sensitivity(fmt(1)) Specificity(fmt(1))") not noobs  nomtitle ///
	title(Random Forest Model Accuracy \label{rfacc}) ///
	varwidth(80) eqlabels(`e(eqlabels)')  replace nonum nostar drop("Total") label ///
	addnotes("*Null hypothesis is no difference in random forest’s overall accuracy and the no information rate")

}

************************************************
* TABLE 6: Top 10 Most Important Variables     *
*  in Random Forest Model  					   *
************************************************
{
use "$final/fii-routput-varimp.dta", clear	

*Properly label the most important variables
	gsort -Importance_rf
	sort sample, stable
	by sample: gen Rank = _n
	
	gen varlab = "Receives Government Assistance" if Variables=="money_govt_asst1"
		replace varlab = "Ever had BPJS Health" if Variables=="bpjs_health1"
		replace varlab = "Owns any Mobile Phone" if Variables=="own_mobilephone1"
		replace varlab = "Has Drivers License" if Variables=="has_DrivLic1"
		replace varlab = "Ever had BPJS Labor" if Variables=="bpjs_labor1"
		replace varlab = "Owns Smartphone" if Variables=="own_smartphone1"
		replace varlab = "Has Tax Card" if Variables=="has_TaxCard1"
		replace varlab = "Highest Education: HS/Vocational" ///
			if Variables=="highestedu_respondent5"
		replace varlab = "Has done 2 basic phone tasks in past week" ///
			if Variables=="phonetasks_bas_week2"
		replace varlab = "Has done 2 basic phone tasks in past month" ///
			if Variables=="phonetasks_bas_month2"
		replace varlab = "Female" if Variables=="female1"
		replace varlab = "Has done all three advanced phone tasks" ///
			if Variables=="phonetasks_adv_ever3"
		replace varlab = "Receives scholarship" if Variables=="money_scholarship1"
		replace varlab = "Has done all five phone tasks" if Variables=="phonetasks_ever5"
		replace varlab = "Housewife" if Variables=="jobtype7"
		replace varlab = "Has complete ability to make/receive a call on a mobile" ///
			if Variables=="ability_call4"
		replace varlab = "Trusts Financial Providers to Keep Personal Information Private" ///
			if Variable=="trust_in_system5"

		assert !missing(varlab) if Rank<=10

*Only keep top ten
	keep if Rank<=10 | (varlab=="Female" & sample=="Full")
				 
*Label
	lab var Rank "Rank"
	lab var Importance_rf "Importance"
	lab var varlab "Feature"
	
	keep Rank Importance_rf varlab sample
	
*Create Table - Full Sample	
	preserve 
	
		keep if sample=="Full"
		estimates clear
		labmask Rank, values(varlab)	
		g var=Rank
		lab values var Rank
		
		estpost tabstat Rank Importance_rf , by(var)  statistics(mean) nototal
					
		esttab using "$fig/Varimptable.tex",  ///
			cells("Rank Importance_rf(fmt(2))") not noobs label nomtitle ///
			eqlabels(`e(labels)') varlabels(`e(labels)') collabels(none) ///
			replace nostar unstack fragment compress tex nonum  /// 
			prehead("\begin{table}[H] \begin{adjustbox}{max width=1.3\textwidth} \begin{threeparttable} \caption{Top 10 Most Important Variables in Random Forest Model} \label{varimpt} {\begin{tabular}{l*{1}{lll}} \toprule {Feature}&{Rank}&{Importance} \\ \midrule \multicolumn{3}{c}{\textbf{A. Overall}} \\") 
	restore						
				
*Create Table - Males	
	preserve 
	
		keep if sample=="Male"
		estimates clear
		labmask Rank, values(varlab)	
		g var=Rank
		lab values var Rank
		
		estpost tabstat Rank Importance_rf , by(var)  statistics(mean) nototal
					
		esttab using "$fig/Varimptable.tex",  ///
			cells("Rank Importance_rf(fmt(2))") ///
			not noobs label nomtitle  ///
			eqlabels(,none) varlabels(`e(labels)') collabels(none) ///
			append nostar unstack fragment compress tex nonum  /// 
			prehead("\midrule \multicolumn{3}{c}{\textbf{B. Males}} \\ ") 
	restore
	
*Create Table - Females	
	preserve 
	
		keep if sample=="Female"
		estimates clear
		labmask Rank, values(varlab)	
		g var=Rank
		lab values var Rank
		
		estpost tabstat Rank Importance_rf , by(var)  statistics(mean) nototal
					
		esttab using "$fig/Varimptable.tex",  ///
			cells("Rank Importance_rf(fmt(2))") not noobs label nomtitle  ///
			eqlabels(,none) varlabels(`e(labels)') collabels(none) ///
			append nostar unstack fragment compress tex nonum  /// 
			prehead("\midrule \multicolumn{3}{c}{\textbf{C. Females}} \\  ")  ///
			postfoot(" \bottomrule \addlinespace[1.5ex] \end{tabular}} \begin{tablenotes}[flushleft]  \small \item \emph{Notes:} Unweighted data from 2019 FII. The table displays the ten most important variables identified by the random forest modeling, as well as the ranking for the female variable in the overall model. Ranking is based on the variables' value in decreasing Gini inpurity. For a more in depth explanation of random forest and its components, refer to \cite{rfart} \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table} \vspace*{-5mm}")
	restore		
			
			}

************************************************
* FIGURE 5:	Top 100 Predictor Variables 	   *
*   from Random Forest Model	   			   *
************************************************
{
*First Males then Females	
foreach Sample in Male Female{
	use "$final/fii-routput-varimp.dta", clear	

		keep if sample=="`Sample'"
		gsort -Importance_rf
		gen Rank = _n	
		keep if Rank<101

*Create a Variable to Track Category of Predictor Variable		
	gen varcat = .

	replace Variables = subinstr(Variables," ", "", .)

	
*Digital Engagement	
	local dige ability_call4 ability_dwldapp1 ability_dwldapp4 ability_fintrans4 ability_internet1 ability_internet4 ability_navmenu4 ability_text4 own_mobilephone1 own_smartphone1 phonetasks_adv_ever3 phonetasks_bas_ever2 phonetasks_bas_month2 phonetasks_bas_today1 phonetasks_bas_today2 phonetasks_bas_week2 phonetasks_ever5 phonetasks_today1 phoneusage_adv_n12 phoneusage_basic_n12 used_shared1 ability_navmenu1 ability_navmenu3 ability_text1 laku_dist2 phonetasks_adv_today2 phonetasks_adv_week2 phonetasks_ever2 phonetasks_month5 phonetasks_today2 phoneusage_adv_n3

*ID Ownership	
	local idown has_DrivLic1 has_TaxCard1
	
*Gov't Assistance	
	local gov bpjs_health1 bpjs_labor1 has_KTP1 money_govt_asst1
	
*SES/Economic	
	local ses can_read2 employment_male3 employment_male5 fridge1 highestedu_female1 highestedu_female2 highestedu_female3 highestedu_respondent2 highestedu_respondent3 highestedu_respondent5 income_pct2 income_pct3 jobsector7 jobtype7 money_dom_remit1 money_own1 money_scholarship1 poverty_bin1 read_bahasa4 scooter1 workertype1 workertype5 write_bahasa4 cookfuel2 income_pct5 jobsector10 jobtype3 jobtype5 jobtype8 money_ag1 money_bus_less101 read_bahasa3 workertype3 workertype4 workertype6

*Demographics/Other	
	local demo any_teenage_girls1 atm_dist1 atm_dist2 atm_dist3 bank_dist2 bank_dist3 bank_dist4 fems_9t121 hh_head_age_bin5 hh_head_age_bin6 hh_head_age_bin7 hh_head_fem1 hh_members3 hh_members4 hh_num_females1 hh_num_females2 hh_num_males1 hh_num_males2 hh_size3 hh_size4 hh_size5 insur_dist4  know_mobilemoney1 laku_dist3 males_9t121 males_u41 multi_dist3 multi_dist4 pawnshop_dist3 pawnshop_dist4 pos_dist3 pos_dist4 province10 province11 province9 rel_hh_head2 resp_age_bin5 resp_age_bin6 use_mobilemoney1 urban1 any_teenage_boys1 coop_dist3 married1 sh_micro_dist3
	
*Agency/Trust	
	local agency finaldec_hhinc5 finaldec_ownmoney4 finaldec_ownmoney5 influence_spending5 invovle_basics5 invovle_beybasics5 invovle_hhinc5  trust_in_system4 trust_in_system5 voice_disagreement5 influence_spending1 influence_spending4 invovle_beybasics3 invovle_hhinc1 invovle_hhinc2 voice_disagreement4

*Now Code Accordingly
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

*Create Figure
// ENGLISH				
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

{
*First Males then Females	
foreach Sample in Male Female{
	use "$final/fii-routput-varimp.dta", clear	

		keep if sample=="`Sample'"
		gsort -Importance_rf
		gen Rank = _n	
		keep if Rank<101

*Create a Variable to Track Category of Predictor Variable		
	gen varcat = .

	replace Variables = subinstr(Variables," ", "", .)

	
*Digital Engagement	
	local dige ability_call4 ability_dwldapp1 ability_dwldapp4 ability_fintrans4 ability_internet1 ability_internet4 ability_navmenu4 ability_text4 own_mobilephone1 own_smartphone1 phonetasks_adv_ever3 phonetasks_bas_ever2 phonetasks_bas_month2 phonetasks_bas_today1 phonetasks_bas_today2 phonetasks_bas_week2 phonetasks_ever5 phonetasks_today1 phoneusage_adv_n12 phoneusage_basic_n12 used_shared1 ability_navmenu1 ability_navmenu3 ability_text1 laku_dist2 phonetasks_adv_today2 phonetasks_adv_week2 phonetasks_ever2 phonetasks_month5 phonetasks_today2 phoneusage_adv_n3

*ID Ownership	
	local idown has_DrivLic1 has_TaxCard1
	
*Gov't Assistance	
	local gov bpjs_health1 bpjs_labor1 has_KTP1 money_govt_asst1
	
*SES/Economic	
	local ses can_read2 employment_male3 employment_male5 fridge1 highestedu_female1 highestedu_female2 highestedu_female3 highestedu_respondent2 highestedu_respondent3 highestedu_respondent5 income_pct2 income_pct3 jobsector7 jobtype7 money_dom_remit1 money_own1 money_scholarship1 poverty_bin1 read_bahasa4 scooter1 workertype1 workertype5 write_bahasa4 cookfuel2 income_pct5 jobsector10 jobtype3 jobtype5 jobtype8 money_ag1 money_bus_less101 read_bahasa3 workertype3 workertype4 workertype6

*Demographics/Other	
	local demo any_teenage_girls1 atm_dist1 atm_dist2 atm_dist3 bank_dist2 bank_dist3 bank_dist4 fems_9t121 hh_head_age_bin5 hh_head_age_bin6 hh_head_age_bin7 hh_head_fem1 hh_members3 hh_members4 hh_num_females1 hh_num_females2 hh_num_males1 hh_num_males2 hh_size3 hh_size4 hh_size5 insur_dist4  know_mobilemoney1 laku_dist3 males_9t121 males_u41 multi_dist3 multi_dist4 pawnshop_dist3 pawnshop_dist4 pos_dist3 pos_dist4 province10 province11 province9 rel_hh_head2 resp_age_bin5 resp_age_bin6 use_mobilemoney1 urban1 any_teenage_boys1 coop_dist3 married1 sh_micro_dist3
	
*Agency/Trust	
	local agency finaldec_hhinc5 finaldec_ownmoney4 finaldec_ownmoney5 influence_spending5 invovle_basics5 invovle_beybasics5 invovle_hhinc5  trust_in_system4 trust_in_system5 voice_disagreement5 influence_spending1 influence_spending4 invovle_beybasics3 invovle_hhinc1 invovle_hhinc2 voice_disagreement4

*Now Code Accordingly
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
		local tit "Wanita"
				}
	if "`Sample'"=="Male" {
		local tit "Pria"
				}

*Create Figure
// INDONESIAN				
	twoway 	(bar  Importance Rank if varcat==1, color("242 196 19") lcolor(black)) ///
			(bar Importance Rank if varcat==2,  color(black) lcolor(black)) ///
			(bar  Importance Rank if varcat==3,  color("227 89 37") lcolor(black)) ///
			(bar Importance Rank if varcat==4,  color("104 175 193") fintensity(inten40) lcolor(black)) ///
			(bar  Importance Rank if varcat==5,  color("45 171 159") lcolor(black)) ///
			(bar Importance Rank if varcat==6,  color(gray) lcolor(black)), ///
			legend(region(lwidth(none)) order(1 4 2 3 5 6) ///
			label(1 "Keterlibatan Digital") label(2 "Kepemilikan ID") label(3 "Bantuan Pemerintah") ///
			label(4 "SES/Ekonomi") label(5 "Demografi/Lainnya") label(6 "Agensi/Kepercayaan") ///
			size(small) rows(2)) title({bf:`tit'}, size(medium)) ///
			name("`tit'", replace) ytitle("Kepentingan") 
			
	}
					


	grc1leg Pria Wanita, ycommon col(1) 	
		
	gr export "$fig/rftop100_IND.png", replace
	
}


************************************************
* TABLE 7: Estimates of Remittance Use         *
************************************************
{
*Prep SOFIA Data to Merge to FII Data	
use "$final/sofia-merge.dta", clear
	g everremit = remittance_received==1 | remittance_sent==1
	g urban = STATUS=="URBAN"
	
	rename female_ind female 
	rename wt_vil weight
	g dataset = "SOFIA"
	
	keep everremit urban female weight dataset
		
		tempfile sofia 
		save "`sofia'"
	
*Prep FII Data to Merge to SOFIA Data	
use "$final/fii2018.dta", clear
 
 keep if province== 11 | province==22 | province==23 | province==32
 g everremit = bi_e28a_d=="1" | bi_e28b_d=="1" | ojk10_3==1 | dl4_4==1 |  dl4_5==1
 
 g dataset = "FII"
	
 
 	keep everremit urban female weight dataset
	
	append using "`sofia'"
	
*Collapse and Reshape	
	collapse (mean) everremit (count) N=everremit [w=weight], by(urban female  dataset)
	
	reshape wide everremit N, i( urban female) j(dataset) string
	
		lab define female 0"Male" 1"Female"
		lab values female female

*Export Table		
		estpost tabstat everremitFII NFII everremitSOFIA NSOFIA if urban==0 , by(female)  statistics(mean) nototal
					
		esttab using "$fig/RemittanceCompare.tex",  cells("everremitFII(fmt(2)) NFII(fmt(0)) everremitSOFIA(fmt(2)) NSOFIA(fmt(0))") not noobs label nomtitle  eqlabels(`e(labels)') varlabels(`e(labels)') collabels(none) ///
						replace nostar unstack fragment compress tex nonum  /// 
						prehead("\begin{table}[H] \begin{adjustbox}{max width=1.3\textwidth} \begin{threeparttable} \caption{Estimates of Remittance Use} \label{remitcompate} {\begin{tabular}{l*{1}{lllll}} \hline \toprule &{FII}&{N}&{SOFIA}&{N} \\ \midrule \multicolumn{5}{l}{\textbf{Rural}} \\") 		
		
		
		estpost tabstat everremitFII NFII everremitSOFIA NSOFIA if urban==1 , by(female)  statistics(mean) nototal
					
		esttab using "$fig/RemittanceCompare.tex",  cells("everremitFII(fmt(2)) NFII(fmt(0)) everremitSOFIA(fmt(2)) NSOFIA(fmt(0))")  not noobs label nomtitle  eqlabels(,none) varlabels(`e(labels)') collabels(none) ///
						append nostar unstack fragment compress tex nonum  /// 
						prehead("\hline \multicolumn{5}{l}{\textbf{Urban}} \\")  ///
						posthead("\hline") ///
				postfoot(" \bottomrule \addlinespace[1.5ex] \end{tabular}} \begin{tablenotes}[flushleft]  \small \item \emph{Notes:} Weighted estimates using the 2019 FII data and the 2016 SOFIA data. The SOFIA data are representative of adults 17 years and older living in East Java, West Nusa Tenggara, East Nusa Tenggara and South Sulawesi. FII data has been subset accordingly. Remittance use is captured by a series of questions in the FII including receipt of remittances in the past year, use of ATM cards for remittances, and the use of the post office for remittances. In SOFIA, respondents are asked if they sent or received money in the past year. \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table} \vspace*{-5mm}")		
}		
	
************************************************
* FIGURE 6:	DFS Use Transitions and  	 	   *
*   Frequency, by Gender	   				   *
************************************************
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


// ENGLISH	
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
		legend(region(lwidth(none))  row(2) on order(1 2 3 4 5 6) label(1 "First Time User") ///
		label(2 "Use More Often") label(3 "Use Same Amount") ///
		label(4 "Use Less Often") label(5 "Stopped Use") ///
		label(6 "Never Use") ///
		size(small)) ///
		xlabel(3.5 "Females" 10.75 "Males", angle(hor) labsize(small) notick)
			
			
	gr export "$fig/onlinesurvey_gender.png", replace
	
// INDONESIAN	
twoway (bar est marker if dfs == 1) || ///
		(bar est marker if dfs == 2) || ///
		(bar est marker if dfs == 4) || ///
		(bar est marker if dfs == 3) || ///
		(bar est marker if dfs == 6) || ///
		(bar est marker if dfs == 5, fcolor("74 156 101")) || ///
		(rcap ul ll marker, lcol(gs4) lwidth(thin) msize(tiny)), ///
		ytit("Proporsi", size(small)) ///
		graphregion(color(white) fcolor(white)) ///
		yscale(range(0 .4)) ylab(#5, labsize(small)) ///
		xtit("") ///
		legend(region(lwidth(none))  row(3) on order(1 2 3 4 5 6) label(1 "Pengguna Pertama Kali") ///
		label(2 "Menggunakan Lebih Sering") label(3 "Menggunakan Sama") ///
		label(4 "Menggunakan Lebih Jarang") label(5 "Berhenti Menggunakan") ///
		label(6 "Tidak Pernah Menggunakan") ///
		size(small)) ///
		xlabel(3.5 "Wanita" 10.75 "Pria", angle(hor) labsize(small) notick)
			
			
	gr export "$fig/onlinesurvey_gender_IND.png", replace	

}

************************************************
* FIGURE 7:	Phone Capabilities by Gender 	   *
************************************************
{
use "$final/fii2018", clear
 
*Create Matrix 
 mat res=J(150,5,.)
 local k = 1
 local row = 1

*Calculate Estimates 
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
	
*Put Estimates into Matrix
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

*Create Figure
// ENGLISH	
	twoway 	(bar est index if female==0 & catvar<7, yscale(range(0) axis(1)) ytitle("Share", size(small) axis(1)))  /// 
		(bar est index if female==1 & catvar<7) ///
		(bar est index if female==0 & catvar>6, yaxis(2) yscale(range(0) axis(2)) ytitle("Number of Tasks", size(small) orientation(rvertical) axis(2)) fcolor("227 89 37") )  /// 
		(bar est index if female==1 & catvar>6, yaxis(2) fcolor("45 171 159")) ///
		(rcap ul ll index if catvar<7, lcolor(black)) ///
		(rcap ul ll index if catvar>6, lcolor(black) yaxis(2)) , ///
		xtitle(" ") legend(row(1) size(small) region(lwidth(none)) ///
		on order(1 "Male" 2 "Female"))  ///
		xlabel( 1.5 "Calls" 4.5 "Navigate Menu" 7.5 "Text" 10.5 "Search Internet" 13.5 "Fin. Transaction" 16.5 "Download App" 20.5"Basic Tasks" 23.5"Advanced Tasks" 26.5"Total Tasks", angle(45)) ///
		xline(18.5, lpattern(dash) lcolor(gs13))  
			
 	 gr export "$fig/phonecapability.png", replace
	 
// INDONESIAN
	twoway 	(bar est index if female==0 & catvar<7, yscale(range(0) axis(1)) ytitle("Proporsi", size(small) axis(1)))  /// 
		(bar est index if female==1 & catvar<7) ///
		(bar est index if female==0 & catvar>6, yaxis(2) yscale(range(0) axis(2)) ytitle("Jumlah Aktivitas", size(small) orientation(rvertical) axis(2)) fcolor("227 89 37") )  /// 
		(bar est index if female==1 & catvar>6, yaxis(2) fcolor("45 171 159")) ///
		(rcap ul ll index if catvar<7, lcolor(black)) ///
		(rcap ul ll index if catvar>6, lcolor(black) yaxis(2)) , ///
		xtitle(" ") legend(row(1) size(small) region(lwidth(none)) ///
		on order(1 2) label(1 "Pria") label(2 "Wanita"))  ///
		xlabel( 1.5 "Telepon" 4.5 "Navigasi Menu" 7.5 "SMS" 10.5 "Mencari di Internet" 13.5 "Transaksi Fin." 16.5 "Unduh App" 20.5"Aktivitas Dasar" 23.5"Aktivitas Lanjutan" 26.5"Total Aktivitas", angle(45)) ///
		xline(18.5, lpattern(dash) lcolor(gs13))  
			
 	 gr export "$fig/phonecapability_IND.png", replace
}

************************************************
* FIGURE 8:	Advanced Phone Capabilities Among  *
* Smartphone Owners Across Levels of Education *
************************************************
{
	use "$final/fii2018.dta", clear

*Subset to 18+	
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

// ENGLISH	
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
	
// INDONESIAN
twoway 	(bar est index2 if dl_ability == 1) || ///
		(bar est index2 if dl_ability == 2) || ///
		(rcap ul ll index2, lcol(gs4)), ///
			ytit("Proporsi", size(small)) ///
			graphregion(color(white) fcolor(white)) ///
			yscale(range(0 1)) ylab(#5, labsize(small)) ///
			legend(on order(1 2) label(1 "Kemampuan Penuh") label(2 "Kemampuan Penuh atau Beberapa") ///
			size(small) region(lwidth(none)) rows(1)) ///
			xlab(1.5 "Tidak Berpendidikan Formal" 4.5 "SD" 7.5 "SMP" ///
			10.5 "SMA" 13.5 "Universitas", angle(hor) labsize(vsmall) notick) ///
			xtit(" ", size(small))
			
	gr export "$fig/litbyeducation_IND.png", replace
		
}

************************************************
* FIGURE 9:	Use of Digital and Cash for  	   *
*  Remittances, by Gender					   *
************************************************
{
use "$final/sofia-merge.dta", clear
	
	g cashonly_rec = remittance_rcv_method2==1 &  (remittance_rcv_method1==0 & remittance_rcv_method3==0 & remittance_rcv_method4==0) if remittance_received==1
	g dig_rec = cashonly_rec==0 &  (remittance_rcv_method1==1 | remittance_rcv_method3==1 | remittance_rcv_method4==1) 	if remittance_received==1
	
	
	g cashonly_send = remittance_sent_method==2 if remittance_sent==1
	g dig_send = cashonly_send==0 & (remittance_sent_method==1 | remittance_sent_method==3 | remittance_sent_method==4 | remittance_sent_method==5) if remittance_sent==1
	
	collapse (mean) cashonly_rec dig_rec cashonly_send dig_send [weight=wt_vil], by(female_ind) 

	label define female 0"Males" 1"Females"
	lab values female_ind female

// ENGLISH		
	graph bar cashonly_rec dig_rec , over(female) stack legend(on  label(1 "Cash Only") label(2 "Digital") size(small) region(lwidth(none))) 	title("Receipt of Remittances", size(medsmall)) name("a", replace) intensity(80)

	graph bar cashonly_send dig_send , over(female) stack legend(on  label(1 "Cash Only") label(2 "Digital") size(small) region(lwidth(none))) 	title("Sending of Remittances", size(medsmall)) name("b", replace)	 intensity(80)
	
	grc1leg a b, ycommon
			
	gr export "$fig/remittancechannel.png", replace
	
	
// INDONESIAN
	label define female_ind 0"Pria" 1"Wanita"
	lab values female_ind female_ind
	
	graph bar cashonly_rec dig_rec , over(female) stack legend(on  label(1 "Hanya Tunai") label(2 "Digital") size(small) region(lwidth(none))) 	title("Penerimaan Remitansi", size(medsmall)) name("a", replace) intensity(80)

	graph bar cashonly_send dig_send , over(female) stack legend(on  label(1 "Hanya Tunai") label(2 "Digital") size(small) region(lwidth(none))) 	title("Pengiriman Remitansi", size(medsmall)) name("b", replace)	 intensity(80)
	
	grc1leg a b, ycommon
			
	gr export "$fig/remittancechannel_IND.png", replace	
}

************************************************
* FIGURE 10:Share of Households Reporting Bank *
*  Account Ownership, by Beneficiary Status    *
*  and Household Member						   *
************************************************
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

// ENGLISH	
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

// INDONESIAN	
	twoway 	(bar est socprot if category == 2, barw(.5)) || ///
			(rbar ul ll socprot if category == 3, barw(.5)) || ///
			(rbar ul ll socprot if category == 4, barw(.5)), ///
			ytit("Proporsi", size(small)) ///
			graphregion(color(white) fcolor(white)) ///
			yscale(range(0 0.6)) ylab(#5, labsize(small)) ///
			xtit("") ///
			xlab(1 "Semua Rumah Tangga" 2 "Rumah Tangga PKH" 3 "Rumah Tangga BPNT" 4 "Rumah Tangga PIP", angle(hor) labsize(small) notick) ///	
			legend( on order(1 2 3) label(1 "Hanya KRT dan/atau pasangan") ///
			label(2 "KRT dan anggota rumah tangga lainnya")  label(3 "Hanya anggota rumah tangga lainnya") rows(2) size(small) region(lwidth(none)))  
			
			
	gr export "$fig/account_shroud_stack_IND.png", replace	
}

************************************************
* FIGURE 11: Frequency of Online Purchasing    *
*  of Basic Goods						       *
************************************************
{

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

// ENGLISH
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
	
// INDONESIAN
twoway	(bar est marker if buy == 1) || ///
		(rbar ul ll marker if buy == 2) || ///
		(rbar ul ll marker if buy == 3), ///
		ytit("Proporsi", size(small)) ///
		graphregion(color(white) fcolor(white)) ///
		yscale(range(0 1)) ylab(#5, labsize(small)) ///
		xscale(range(0 4)) xtit("") ///
		legend(size(small) region(lwidth(none)) on order(1 2 3) label(1 "Tidak Pernah Daring") ///
		label(2 "Beberapa Daring") label(3 "Kebanyakan Daring") row(1)) ///
		xlabel(1 "Wanita" 3 "Pria", angle(hor) labsize(small) notick)
			
	gr export "$fig/onlinesurvey_ecomm_IND.png", replace	
}

