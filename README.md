# IFII Whitepaper
This repository houses the code and documentation of analyses for the Inclusive Financial Innovation Initiative (IFII) Whitepaper. The whitepaper  aims to share evidence on how DFS digital finance services (DFS) can be marshalled to support shared economic prosperity and explore research opportunities to support DFS development.

## Data
The whitepaper draws on the following four datasets:
* the 2019 Financial Inclusion Insights Survey (FII)
* the 2019 National Socioeconomic Survey (SUSENAS)*
* the 2016 Survey on Financial Inclusion and Access (SOFIA)
* the 2018 Village Potential Statistics (PODES)**

The whitepaper also includes analysis of 1 set of primary data, which is included in the repository:
* Online survey on DFS adoption during Covid-19

\* We combined the SUSENAS data with poverty line data available on Badan Pusat Statistik (BPS) [website](https://www.bps.go.id/subject/23/kemiskinan-dan-ketimpangan.html). \
\*\* Figure 1 uses the 2011 PODES data for population estimates and the 2019 shapefile with breakdown up to the village level from Badan Pusat Statistik (BPS).


### How to obtain secondary Data
The 2019 Financial Inclusion Insights Survey (FII) from Kantar can be accessed by submitting a data request form [here](http://finclusion.org/data_fiinder/).

The 2019 National Socioeconomic Survey (SUSENAS), the 2011 and 2018 Village Potential Statistics (PODES), and the 2019 shapefile can be obtained through the Badan Pusat Statistik (BPS) Pelayanan Statistik Terpadu [website](https://webapi.bps.go.id/consumen/88582261b976073c4aee562850e51881?redirect_uri=http://silastik.bps.go.id/v3/index.php/site/login/).

To request access to the 2017 Survey on Financial Inclusion Access (SOFIA), contact sofia@opml.co.id.


### Online survey on DFS adoption during Covid-19
We conducted an online survey with approximately 2,000 respondents to gauge how the pandemic has impacted DFS use, including digital banking, e-money and e-commerce. We used the Google Surveys platform, which uses convenience sampling. The online survey respondents are younger, more likely to live in urban areas, and more likely to live on Java. Estimates are weighted to match demographic characteristics in the 2019 SUSENAS, though this cannot fully address the fact that the online survey respondents are a highly selected, digitally engaged group. Even so many had never used DFS prior to the pandemic (52% of women and 45% of men). Thus, our results provide a snapshot of how a group of “likely adopters” is faring during COVID-19.

The survey was divided into 2 parts:
* General population
* Screened: respondents who never used DFS since February 2020 were screened out of the survey
* Pooled: the pooled dataset is merged from the general population and the screened survey. Questions included in the pooled dataset are questions 1-5 in each survey.

The survey questionnaire and codebook are included along with the datasets.


### Database structure
The paths in the code are set for the following the folder structure:

```
Database
└───Raw data
|   └───Poverty line per municipal 2015-2019.xlsx
│   └───FII 2018-19
│   │   └───FII Indonesia 2018 (public+ANONGPS).xlsx
│   └───PODES 2011
│   │   └───podes_desa_2011_d1.dta
│   └───PODES 2018
│   │   └───podes2018full_newvars.dta
│   └───Shapefile 2019
│   │   └───2019shp
│   │   │   └───INDO_DESA_2019_data.dta
│   │   └───idn_adm123_bps_2019_shp
│   │       └───indo_coord_adm1.dta
│   └───SOFIA 2017
│   │   └───HHD_ROSTER.data
│   │   └───Individual_revised26Sept2017.dta
│   └───Susenas 2019
│       └───kor19rt_revisi1_diseminasi.dta
│       └───kor19ind_diseminasi_merge.dta
│       └───kor19region.dta
│   
└───Final Data
│   └───Online Survey-DFS Adoption_Covid-19
│       └───onlinesurvey-generalpop.dta
│       └───onlinesurvey-pooled.dta
│       └───onlinesurvey-screened.dta
│   
└───temp
```

## Codes
For a push-button replication, use "0 master-whitepaper.do". Ensure that you have:
* Set the path to the GitHub folder
* Set the path to R program
* Set working directory in R script "RandomForest.R"
* Install the necessary Stata packages
* Placed all secondary datasets following the above folder structure

Alternatively, to recreate particular figures and tables, you can run the associated lines in "Code/analysis/code-whitepaper-graph.do"
* Check which of the four datasets the table/figure is drawn from
* Ensure you have run the relevant data preparation code (in "Code/build") for the correct dataset
