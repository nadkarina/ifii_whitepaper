* ******************************************************************************
* PROJECT: IFII WHITEPAPER
* AUTHORS: NATALIE THEYS, NICK WISELY, LOLITA MOORENA, NADIA SETIABUDI
* PURPOSE: master do-file for whitepaper data cleaning and analysis
* ******************************************************************************

* A) PRELIMINARIES
version 15
set more off
clear all
cap log close

* B) WORKING FOLDER PATH
*gl path gl path ".../GitHub/ifii_whitepaper"
// Set path to GitHub folder
gl path "C:/Users/Nadia Setiabudi/Documents/GitHub/ifii_whitepaper"
gl path "/Users/theys/Documents/GitHub/ifii_whitepaper"

*gl rpath ""
// Set path to R
// NOTE: MUST ALSO CHANGE WORKING DIRECTORY IN THE FOLLOWING R SCRIPT:
//			"GitHub/ifii_whitepaper/Code/analysis/RandomForest.R"
gl rpath "C:\Program Files\R\R-4.0.2\bin\x64\R.exe"


*** The following paths will update automatically ***
gl raw "$path/Database/Raw Data"
	gl fii "$raw/FII 2018-19"
	gl susenas19 "$raw/Susenas 2019"
	gl podes18 "$raw/PODES 2018"
	gl podes11 "$raw/PODES 2011"
	gl shp "$raw/Shapefile 2019"
	gl sofia "$raw/SOFIA 2016"

gl temp "$path/Database/temp"
gl final "$path/Database/Final Data"

gl code "$path/Code"

gl fig "$path/Tables_Figures"

* C) INSTALL PACKAGES AND SCHEMES
*cap ssc install fre
*cap ssc install rsource, replace
*net from http://www.stata-journal.com/software/sj15-4		// Install dropmiss
*net install dm0085											// Install dropmiss
*net install dm89_2											// Install dropmiss
*net from http://www.stata-journal.com/software/sj14-2/		// Install estpost
*net install st0085_2										// Install estpost

// NOTE: NEED TO ADD OTHER INSTALLATIONS NEEDED

cd "${code}/analysis"
set scheme jpal


********************************************************************************
** STEP 1: Data Preparation 
********************************************************************************

*** Financial Inclusion Insights (FII) ***
do "$code/build/code-fii-clean.do"					


*** Survey on Financial Inclusion and Access (SOFIA) ***
do "$code/build/code-sofia-clean.do"


*** Potensi Desa (PODES) ***
do "$code/build/code-podes-shp-combine-match.do"
do "$code/build/code-podes-popbank.do"


*** Survei Sosio Ekonomi Nasional (SUSENAS) ***
do "$code/build/code-susenas-clean.do"



********************************************************************************
** STEP 2: Analysis and Creation of Tables and Figures
********************************************************************************

*** Random Forest (R codes) ***
// NOTE: CHANGE WORKING DIRECTORY IN R SCRIPT BEFORE RUNNING THE FOLLOWING LINE
rsource using "$code/analysis/RandomForest.R", rpath($rpath) roptions(`"--vanilla"')

*** Tables and Figures ***
do "$code/analysis/code-whitepaper-graph.do"	
