* ******************************************************************************
* PROGRAM: PODES SHAPE DATA
* AUTHORS: Lolita Moorena
* PURPOSE: Merge shape and PODES data
* DATE CREATED: 17 December 2019
* LAST MODIFIED: 11 September by Nadia Setiabudi
* ******************************************************************************


* Cleaning the shapefile before merging with podes data
	use "$shp\INDO_DESA_2019_data.dta", clear
	drop if desano == "000" //dropping geography feature e.g. lake, forest
	replace desano = "13a" if _ID == 83429 //replace the village ID of an unidentified duplicate village
	save "$temp\unique_shp_PODES19.dta", replace

	use "$shp\INDO_DESA_2019_data.dta", clear
	keep if desano == "000"
	save "$temp\geo_shp_PODES19.dta", replace

* Match the variable names for merging
	use "$podes/podes2018full_newvars.dta", clear
	rename r101n  provinsi 
	rename r102n kabkot 
	rename r103n kecamatan 
	rename r104n desa 

	rename r101 provno 
	tostring provno, replace
	rename r102 kabkotno 
	rename r103 kecno 
	rename r104 desano
	save "$temp\renamed_podes18.dta", replace

***MERGING***	
// We are using 2018 PODES, and the shapefile is 2019, thereby we need to match 
* First stage merging using Village ID
	merge 1:1 provno provinsi kabkotno kabkot kecno kecamatan desano desa using "$temp\unique_shp_PODES19.dta"
	save "$temp\merge1_podes18_shppodes19.dta", replace
	
	keep if _m == 3
	save "$temp\matched1_podes18_shppodes19.dta", replace

* Second stage merging using names
	use "$temp\merge1_podes18_shppodes19.dta", clear
	keep if _m == 2 //keep only unmatched from using
	drop _m
	dropmiss *, force
	save "$temp\unique_shp_PODES19-unmatched from merge1.dta", replace
	
	use "$temp\merge1_podes18_shppodes19.dta", clear
	keep if _m == 1 //keep only unmatched from master
	drop _m
	dropmiss *, force
	
	merge 1:1 provinsi kabkot kecamatan desa using "$temp\unique_shp_PODES19-unmatched from merge1.dta"
	save "$temp\merge2_podes18_shppodes19.dta", replace
	
	keep if _m == 3
	save "$temp\matched2_podes18_shppodes19.dta", replace

* Third stage for cases with kabkot changes
	use "$temp\merge2_podes18_shppodes19.dta", clear
	keep if _m == 2 //keep only unmatched from using
	drop _m
	dropmiss *, force
	save "$temp\unique_shp_PODES19-unmatched from merge2.dta", replace
	
	use "$temp\merge2_podes18_shppodes19.dta", clear
	keep if _m == 1 //keep only unmatched from master
	drop _m
	dropmiss *, force
	
	merge 1:1 provinsi kecamatan desa using "$temp\unique_shp_PODES19-unmatched from merge2.dta"
	save "$temp\merge3_podes18_shppodes19.dta", replace
	
	keep if _m == 3
	save "$temp\matched3_podes18_shppodes19.dta", replace

* Fourth stage for cases with kecamatan name changes
	use "$temp\merge3_podes18_shppodes19.dta", clear
	keep if _m == 2 //keep only unmatched from using
	drop _m
	dropmiss *, force
	save "$temp\unique_shp_PODES19-unmatched from merge3.dta", replace
	
	use "$temp\merge3_podes18_shppodes19.dta", clear
	keep if _m == 1 //keep only unmatched from master
	drop _m
	dropmiss *, force
	
	merge 1:1 provinsi kabkot desa desano using "$temp\unique_shp_PODES19-unmatched from merge3.dta"
	save "$temp\merge4_podes18_shppodes19.dta", replace
	
	keep if _m == 3
	save "$temp\matched4_podes18_shppodes19.dta", replace

* Fifth stage for cases with desa name changes
	use "$temp\merge4_podes18_shppodes19.dta", clear
	keep if _m == 2 //keep only unmatched from using
	drop _m
	dropmiss *, force
	save "$temp\unique_shp_PODES19-unmatched from merge4.dta", replace
	
	use "$temp\merge4_podes18_shppodes19.dta", clear
	keep if _m == 1 //keep only unmatched from master
	drop _m
	dropmiss *, force
	
	merge 1:1 provinsi kecno kabkot kabkotno desano using "$temp\unique_shp_PODES19-unmatched from merge4.dta"
	save "$temp\merge5_podes18_shppodes19.dta", replace
	
	keep if _m == 3
	save "$temp\matched5_podes18_shppodes19.dta", replace

* Unmatched
	use "$temp\merge5_podes18_shppodes19.dta", clear
	keep if _m != 3
	save "$temp\unmatched_podes18_shppodes19.dta", replace
	
* Append all the merge result
use "$temp\matched1_podes18_shppodes19.dta", clear //82,293 - provno provinsi kabkotno kabkot kecno kecamatan desano desa 
append using "$temp\geo_shp_PODES19.dta" //geographical features
append using "$temp\matched2_podes18_shppodes19.dta" //139 - provinsi kabkot kecamatan desa
append using "$temp\matched3_podes18_shppodes19.dta" //274 - provinsi kecamatan desa
append using "$temp\matched4_podes18_shppodes19.dta" //355 - provinsi kabkot desa desano
append using "$temp\matched5_podes18_shppodes19.dta" //564 - provinsi kabkot kabkotno kecno desano 
append using "$temp\unmatched_podes18_shppodes19.dta" //499 left

save "$final\matchedfin_shp_PODES.dta", replace
