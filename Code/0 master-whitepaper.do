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
*gl path gl path "...\GitHub\ifii_whitepaper"
gl path "C:\Users\Nadia Setiabudi\Documents\GitHub\ifii_whitepaper"

*** The following paths will update automatically ***
gl raw "$path\Database\Raw Data"
	gl fii "$raw\FII data"
	gl susenas19 "$raw\Susenas 2019"
	gl podes
	gl sofia "$raw\SOFIA"

gl temp "$path\Database\temp"
gl final "$path\Database\Final Data"

gl code "$path\Code"

gl fig "$path\Tables_Figures"

* C) INSTALL PACKAGES AND SCHEMES
cap ssc install fre
set scheme jpal


********************************************************************************
** STEP 1: Data Preparation 
********************************************************************************

*** Financial Inclusion Insights (FII) ***
do "$code\build\code-fii-clean.do"
do "$code\build\code-fii-clean-randomforest.do" // NOTE: Some clarifications needed


*** Survey on Financial Inclusion and Access (SOFIA) ***
do "$code\build\code-sofia-clean.do"


*** Potensi Desa (PODES) ***


*** Survei Sosio Ekonomi Nasional (SUSENAS) ***
do "$code\build\code-susenas-clean-2019.do"



********************************************************************************
** STEP 2: Analysis and Creation of Tables and Figures
********************************************************************************

*** Random Forest ***


*** Tables and Figures ***
do "$code\analysis\code-whitepaper-graph.do"
