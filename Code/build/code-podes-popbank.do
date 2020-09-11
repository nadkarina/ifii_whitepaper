* ******************************************************************************
* PROGRAM: PODES DATA
* AUTHORS: Lolita Moorena
* PURPOSE: Distribution of bank access and population data
* DATE CREATED: 13 May 2020
* LAST MODIFIED: 11 September by Nadia Setiabudi
* ******************************************************************************


* Merge with PODES 2011 to get population data
use "$podes11\podes_desa_2011_d1.dta", clear
	g population = r401a + r401b
	keep population kode_prov nama_prov kode_kab nama_kab kode_kec nama_kec kode_desa nama_desa
	save "$temp\podes_pop.dta", replace

use "$podes18\podes2018full_newvars.dta", clear
	destring r101 r102 r103 r104, replace
	rename r101 kode_prov
	rename r101n nama_prov
	rename r102 kode_kab
	rename r102n nama_kab
	rename r103 kode_kec
	rename r103n nama_kec
	rename r104 kode_desa
	rename r104n nama_desa
	
merge 1:1 kode_prov kode_kab kode_kec kode_desa nama_desa using "$temp\podes_pop.dta"
* matched 71,507, not matched 18,878...if we do manual match we can increase it upto 82k/90k

	* (0) no bank service; (1) bank office; (2) no bank but ATM; (3) not bank office or ATM, but have an agent 
	gen bank = r1208ak2 + r1208bk2 +r1208ck2
	gen bank2 = bank > 0
	replace bank2 = 0 if bank == . 
	gen atm = r1209ck2 == 1
	gen agent = r1209gk2 == 1

	gen financialserv = bank2 == 1
	replace financialserv = 2 if bank2 == 0 & atm == 1
	replace financialserv = 3 if bank2 == 0 & atm == 0 & agent == 1
	replace financialserv = 4 if _m != 3

	keep kode_prov nama_prov kode_kab nama_kab kode_kec nama_kec kode_desa nama_desa financialserv _m population
	
keep if _m == 3 //only the matched ones, need some manual work for this to increase the match

	gen id = _n
save "$final\podes_popbank.dta", replace

