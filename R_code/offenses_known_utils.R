library(stringr)
library(dplyr)
devtools::install_github("jacobkap/asciiSetupReader")
library(asciiSetupReader)
library(readr)
library(feather)
library(haven)
library(memisc)
library(zip)
# Clean column names and value labels -------------------------------------
cleaning_UCR <- function(data) {

  data <-
    data %>%
    dplyr::select_all(str_replace_all, col_names) %>%
    # To fix emojis/special characters
    dplyr::mutate_at(vars(toupper(to_ascii_cols)), iconv, to = "ASCII//TRANSLIT") %>%
    dplyr::mutate_if(is.factor, as.character) %>%
    dplyr::mutate_if(is.character, tolower) %>%
    dplyr::mutate(CORE_CITY_INDICATION = str_replace_all(CORE_CITY_INDICATION,
                                                         core_city_indication),
                  DIVISION = str_replace_all(DIVISION,
                                             division),
                  FOLLOWUP_INDICATION = str_replace_all(FOLLOWUP_INDICATION,
                                                        followup_indication),
                  GROUP_NUMBER = str_replace_all(GROUP_NUMBER,
                                                 group_number),
                  MONTHS_REPORTED = str_replace_all(MONTHS_REPORTED,
                                                    months_reported),
                  SPECIAL_MAILING_ADDRESS = str_replace_all(SPECIAL_MAILING_ADDRESS,
                                                            special_mailing_address),
                  SPECIAL_MAILING_GROUP = str_replace_all(SPECIAL_MAILING_GROUP,
                                                          special_mailing_group),
                  STATE = str_replace_all(STATE,
                                          states),
                  ORI = toupper(ORI))
  crime_cols <- grep("ACT|FOUND|CLR|KILL|ASS", names(data))
  crime_cols <- crime_cols[sapply(data[, crime_cols], is.character)]
  if (length(crime_cols) > 0) {
    data <- data %>%
      dplyr::mutate_at(vars(crime_cols), tolower) %>%
      dplyr::mutate_at(vars(crime_cols), str_replace_all, negatives) %>%
      dplyr::mutate_at(vars(crime_cols), as.character) %>%
      dplyr::mutate_at(vars(crime_cols), as.numeric)
  }

  return(data)
}

char_or_fac <- function(column) {
  return(is.character(column) || is.factor(column))
}

# Fixes column names to be consistent -------------------------------------

col_names <- c(
  "TOT$"             =          "TOTAL",
  "_ACTUAL_"         =          "_ACT_",
  "_CLEARED_"        =          "_CLR_",
  "_UNDER_AGE18_"    =          "_18_",
  "TOTL$"            =          "TOTAL",
  "RAPE"             =          "RAPE",
  "NUMB"             =          "NUM",
  "CL_"              =          "CLR_",
  "OTHR_"            =          "OTH_",
  "_ASLT"            =          "_ASSLT",
  "_HND"             =          "_HAND",
  "UF_"              =          "UNFOUND_",
  "BURG_"            =          "BURGLARY_",
  "FRC_"             =          "FORCE_",
  "ROB$"             =          "ROBB",
  "_P_T"             =          "_PT",
  "FE$"              =          "FEL",
  "AC$"              =          "ACC",
  "ALL_OFFNCS"       =          "ALL_FIELDS",
  "THFT$"            =          "THEFT",
  "ENTY"             =          "ENTRY",
  "SIMPL_"           =          "SIMPLE_",
  "_FT_"             =          "_FEET_",
  "ROBBRY"           =          "ROBB",
  "FORC_"            =          "FORCE_",
  "_FRCE"            =          "_FORCE",
  "_ASSLT"           =          "_ASSAULT",
  "UNFOUND_"         =          "UNFOUNDED_",
  "TRCK_"            =          "TRUCK_",
  "_BS"              =          "_BUS",
  "TRUCK_T"          =          "TRUCK_BUS_T",
  "_LARCNY_"         =          "_LARCENY_",
  "_ENTR_"           =          "_ENTRY_",
  "_FORC$"           =          "__FORCE",
  "_RBRY$"           =          "_ROBB",
  "_ROBB_"           =          "_ROBBERY_",
  "_NUM_"            =          "_",
  "_ATMPTD_RA.*"     =          "_ATT_RAPE",
  "_UNFND_"          =          "_UNFOUND_",
  "_UNFOUNDED_"      =          "_UNFOUND_",
  "TOTA$"            =          "TOTAL",
  "_FRC$"            =          "_FORCE",
  "_THF$"            =          "_THEFT",
  "RAP$"             =          "RAPE",
  "_ASSL$"           =          "_ASSAULT",
  "_ATT_FORCE_ENTRY" =          "_ATT_BURGLARY",
  "_ATTMPTD_"        =          "_ATT_",
  "_BURGLR$"         =          "_BURGLARY",
  "_ASSAUL$"         =          "_ASSAULT",
  "_ROBRY$"          =          "_ROBBERY",
  "_TOT_"            =          "_",
  "_WPN_"            =          "_WEAP_",
  "CLR_18_VHC_THEFT$"=          "CLR_18_VHC_THEFT_TOTAL",
  "_TOTL_"           =          "_TOT_",
  "_BRGLRY_"         =          "_BURGLARY_",
  "CLR_ROBBERY"      =          "CLR_TOT_ROBBERY",
  "ALL_VHC_THEFT"    =          "VHC_THEFT_TOTAL",
  "_ASL$"            =          "_ASSAULT",
  "__"               =          "_",
  "_ASSAU$"          =          "_ASSAULT",
  "_FOR$"            =          "_FORCE",
  "_BURGLAR$"        =          "_BURGLARY",
  "_RBR$"            =          "_ROBBERY",
  "_BURGLRY"         =          "_BURGLARY",
  "_TO$"             =          "_TOTAL",
  "_ENTR$"           =          "_ENTRY",
  "_MANSLGHT"        =          "_MANSLAUGHTER",
  "_THEF$"           =          "_THEFT",
  "ERR"              =          "ER",
  "_FR$"             =          "_FORCE",
  "_LINE"            =          "_LINE_",
  "^ADDRESS"         =          "MAILING_ADDRESS",
  "SMSA"             =          "MSA",
  "__"               =          "_",
  "CITY_NUMER"       =          "CITY_SEQUENCE_NUMBER",
  "CITY_SEQUENCE_NUMER"       =          "CITY_SEQUENCE_NUMBER",
  "^STATE_CODE"      =          "NUMERIC_STATE_CODE",
  "^FOLLOW_UP$"      =          "FOLLOWUP_INDICATION",
  "^FOLLOW_UP_INDICATION$"      =          "FOLLOWUP_INDICATION",
  "NUMER_OF_MONTHS"  =          "MONTHS",
  "^CORE_CITY$"      =          "CORE_CITY_INDICATION",
  "^AGENCY_STATE$"   =          "AGENCY_STATE_NAME",
  "SPEC_MAILING_ADDRESS" =       "SPECIAL_MAILING_ADDRESS",
  "^SPECIAL_MAILING$" =       "SPECIAL_MAILING_ADDRESS",
  "^MAILING_GROUP$" =       "SPECIAL_MAILING_GROUP",
  "_BURG_"           =          "_BURGLARY_",
  "TRUCK_AND_VAN$"   =          "TRUCK_BUS_THEFT",
  "_OTHER_VEHICLE"   =          "_OTH_VHC_THEFT",
  "_GRAND_TOTAL"     =          "_ALL_FIELDS",
  "_ARST_"           =          "_",
  "_OFF_"            =          "_ACT_",
  "MANSAUGHTER"      =          "MANSLAUGHTER",
  "ROBBERY_TOTAL"    =          "TOT_ROBBERY",
  "_ATTEMPT_"        =          "_ATT_",
  "_RAPE_BY_FORCE"   =          "_FORCE_RAPE",
  "_NO_FORCE_ENTRY"  =          "_ENTRY_NO_FORCE",
  "_MOTOR_TOTAL"     =          "_VHC_THEFT_TOTAL",
  "_STRNG_"          =          "_STR_",
  "_VHC_THEFT_TOTAL" =          "_MTR_VHC_THEFT",
  "DATA_LAST"        =          "LAST",
  "TOT_ROB"          =          "ROB",
  "_IN$"             =          "",
  "ERER"             =          "ER",
  "_VAN_"            =          "_BUS_",
  "_ALL_OFFENSE.*"   =          "_ALL_FIELDS",
  "OFFICRS"          =          "OFFICERS",
  "THEFTS$"           =          "THEFT",
  "_ATMPT_FORCE_ENT" =          "_ATT_BURGLARY",
  "_ALL_VEHIC_THEFT" =          "_MTR_VHC_THEFT",
  "GROUP_NUMER"      =          "GROUP_NUMBER",
  "COR13_CITY"       =          "CORE_CITY_INDICATION",
  "NUMER$"           =          "NUMBER",
  "^STATE$"          =          "NUMERIC_STATE_CODE",
  "_ATTEMPTED_"      =          "_ATT_",
  "_STR_"            =          "_STRONG_",
  "_KNIFEL"          =          "_KNIFE",
  "_TOTAL_TOTAL"     =          "_TOTAL",
  "GRAND_OF_ALL_FIELDS_TOTAL" = "ALL_FIELDS",
  "_KILLED_ACCIDENTALLY"      = "_KILL_BY_ACC",
  "_KILLED_FELONIOUSLY"       =  "_KILL_BY_FEL",
  "_ASSAULT_WITH_KNIFE"       =      "_KNIFE_ASSAULT",
  "_ASSAULT_WITH_GUN"         =         "_GUN_ASSAULT",
  "_ASSAULT_OTHER_WEAPON"     =    "_OTH_WEAP_ASSAULT",
  "_ASSAULT_HAND_FEET"        =       "_HAND_FEET_ASSAULT",
  "_THEFT_THEFT"    =          "_THEFT",
  "_DATE_OF_"        =         "_",
  "ORI_CODE"        =          "ORI",
  "_THFT_"          =          "_THEFT_",
  "CLR_MTR_VHC_THEFT"    =     "CLR_VHC_THEFT_TOTAL",
  "CLR_18_MTR_VHC_THEFT"    =     "CLR_18_VHC_THEFT_TOTAL",
  "_TOTAL_CLR_"    =           "_CLR_",
  "_CLR_TOT_"      =           "_CLR_",
  "_BURGLARY_NO_FORCIBLE_ENTRY" = "_ENTRY_NO_FORCE",
  "_BURGLARY_FORCIBLE_ENTRY"    = "_FORCE_ENTRY",
  "_OF_ALL_FIELDS" =            "",
  "ROBB$"          =            "ROBBERY",
  "ROBBER$"        =            "ROBBERY",
  "_ROBBERY_WITH_KNIFE" =       "_KNIFE_ROBBERY",
  "_ROBBERY_WITH_GUN"   =       "_GUN_ROBBERY",
  "_ROBBERY_OTHER_WEAPON" =     "_OTH_WEAP_ROBBERY",
  "ROBR$"                 =     "ROBBERY",
  "ROBER$"         =            "ROBBERY",
  "_MTR_VHC_THEFT" =             "_MTR_VHC_THEFT_TOTAL",
  "_MOTOR_VEHICLE_" =           "_MTR_VHC_",
  "18_VHC_"        =            "18_MTR_VHC_",
  "CLR_VHC"        =            "CLR_MTR_VHC",
  "RO$"            =            "ROBBERY",
  "ROBBR"          =            "ROBBERY",
  "ROBERY"         =            "ROBBERY",
  "_TOTAL_BURG$"   =            "_BURGLARY_TOTAL",
  "_TOTAL_ASSAULT$" =           "_ASSAULT_TOTAL",
  "_TOTAL_LARCENY$" =            "_LARCENY_TOTAL",
  "_TOTAL_RAPE$"    =           "_RAPE_TOTAL",
  "_TOTAL_MOTOR$"   =            "_MTR_VHC_THEFT_TOTAL",
  "_TOTAL_ROBBERY"  =            "_ROBBERY",
  "_MTR_MTR"       =             "_MTR_",
  "ID_CODE"        =             "ICPSR_PART_NUMBER",
  "ACT_ROBBERY"    =             "ACT_ROBBERY_TOTAL",
  "CLR_ROBBERY"    =             "CLR_ROBBERY_TOTAL",
  "CLR_18_ROBBERY"    =          "CLR_18_ROBBERY_TOTAL",
  "UNFOUND_ROBBERY"    =        "UNFOUND_ROBBERY_TOTAL",
  "FORCE_ENTRY"    =             "BURG_FORCE_ENTRY",
  "ENTRY_NO_FORCE" =             "BURG_NO_FORCE_ENTRY",
  "KILL_BY_ACC"                 = "KILLED_BY_ACCIDENT",
  "KILL_BY_FEL"                  = "KILLED_BY_FELONY",
  #  "_BURG_"             =          "_BURGLARY_",
  "_OTH_WEAP_"               =     "_OTHER_WEAPON_",
  "_ATT_"                 =    "_ATTEMPTED_",
  "_OTH_"                    = "_OTHER_",
  "NUMERIC_STATE_CODE"      = "STATE"
)


# Fixes differences in the value labels -----------------------------------

states <- c("washington, d.c"    = "district of columbia",
            "washington, d"      = "district of columbia",
            "dist of columbia"   = "district of columbia",
            "55"                 = "guam",
            "54"                 = "american samoa",
            "53"                 = "puerto rico",
            "52"                 = "canal zone",
            "99"                 = NA,
            "not reported"       = NA)



core_city_indication <- c("no$"                      = "no, not location in core city of msa",
                          "no, not core city of msa" = "no, not location in core city of msa",
                          "not core city"            = "no, not location in core city of msa",
                          "0"                        = NA,
                          "yes$"                     = "yes, located in core city of msa",
                          "yes, core city of msa"    = "yes, located in core city of msa",
                          "not ascertained"          = NA,
                          "location"                 = "located",
                          "^core city$"                = "yes, located in core city of msa")

months_reported <- c("^0$"                = "no months reported",
                     "0 months reported" = "no months reported",
                     "0 mth reported" = "no months reported",
                     "no mth reported"   = "no months reported",
                     "last r"            = "is the last month r",
                     "dec "              = "december ",
                     "nov "              = "november ",
                     "oct "              = "october ",
                     "feb "              = "february ",
                     "jan "              = "january ",
                     "sep "              = "september ",
                     "^0"                = "",
                     "last mth rep"      = "is the last month reported",
                     "^1$"                = "january is the last month reported",
                     "^2$"                = "february is the last month reported",
                     "^3$"                 = "march is the last month reported",
                     "^4$"                 = "april is the last month reported",
                     "^5$"                 = "may is the last month reported",
                     "^6$"                 = "june is the last month reported",
                     "^7$"                 = "july is the last month reported",
                     "^8$"                 = "august is the last month reported",
                     "^9$"                 = "september is the last month reported",
                     "^10$"                = "october is the last month reported",
                     "^11$"                = "november is the last month reported",
                     "^12$"                = "december is the last month reported",
                     "12.*"                = "december is the last month reported"
)

special_mailing_address <- c(
  "9"       = NA,
  "y$"      = "special mailing address",
  "n$"      = "not a special mailing address",
  "missing" = NA)

division <- c("e. south central"                                   = "east south central",
              "east st south ceast tral"                           = "east south central",
              "west ast t south ceast tral"                        = "west south central,",
              "east st north central"                              = "east north central",
              "west ast t north central"                           = "west north central",
              "east st north ceast tral"                           = "east north central",
              "west ast t north ceast tral"                        = "west north central",
              "w. south central"                                   = "west south central",
              "e. north central"                                   = "east north central",
              "east st north central"                              = "east north central",
              "w. north central"                                   = "west north central",
              "east st south central"                              = "east south central",
              "west ast t south central"                           = "west south central",
              "east north ceast tral"                              = "east north central",
              "west nceast "                                       = "west north central",
              "neast  east land"                                   = "west north central",
              "u. s. posseast sion"                                = "possessions",
              "u.s. possessions"                                   = "possessions",
              "u. s. posessions"                                   = "possessions",
              " states"                                            = "",
              "eng1and"                                            = "england",
              "al,ky,ms,tn"                                        = "east south central",
              "az,co,id,mt,nv,n"                                   = "mountain",
              "ar,la,ok, texas"                                    = "west south central",
              "ak,ca,hi,or,wa"                                     = "pacific",
              "ct,me,ma,nh"                                        = "new england",
              "de,fl,ga,md,nort"                                   = "south atlantic",
              "il,in,mi,oh,wi"                                     = "east north central",
              "ia,ks,mn,mo,ne,n"                                   = "west north central",
              "nj ny pa"                                           = "mid-atlantic",
              "w ncen states"                                      = "west north central",
              "s atlantic sts"                                     = "south atlantic",
              "1$"                                                 = "new england",
              "2"                                                  = "mid-atlantic",
              "3"                                                  = "east north central",
              "4"                                                  = "west north central",
              "5"                                                  = "south atlantic",
              "6"                                                  = "east south central",
              "7"                                                  = "west south central",
              "8"                                                  = "mountain",
              "9"                                                  = "pacific",
              "alabama, kentucky, mississippi, tennessee"          = "east south central",
              "arizona, colorado, idaho, montana, nevada, new"     = "mountain",
              "arkansas, louisiana, oklahoma, texas"               = "west south central",
              "alaska, california, hawaii, oregon, washington"     = "pacific",
              "connecticut, maine, massachusetts, new hampshire,"  = "new enland",
              "delaware, florida, georgia, maryland, north"        = "south atlantic",
              "illinois, indiana, michigan, ohio, wisconsin"       = "east north central",
              "iowa, kansas, minnesota, missouri, nebraska, north" = "west north central",
              "new jersey, new york, pennsylvania"                 = "mid-atlantic",
              "midd1east atlantic"                                 = "mid-atlantic",
              "midast atlantic"                                    = "mid-atlantic",
              "^u$"                                                = NA,
              "e\\."                                                 = "east ",
              "w\\."                                                 = "west ",
              "cntrl"                                              = "central",
              "middle"                                             = "mid",
              "east st south ceast tral"                           = "east south central",
              "west ast t south ceast tral"                        = "west south central",
              "posseast sions"                                     = "possessions",
              "west nceast "                                       = "west north central",
              "east st north ceast tral"                           = "east north central",
              "new enland"                                         = "new england",
              "w ncen"                                             = "west north central",
              "midd1e atlantic"                                    = "mid-atlantic",
              "mid "                                               = "mid-",
              "u. s. possession"                                   = "possessions")



group_number <- c("msa co. 100,000 +"                    =   "msa county 100,000+",
                  "cit 25,000-49,999"                    =   "cities between 25,000 and 49,999",
                  "cit 250,000-499,999"                  =   "cities 250,000 thru 499,999",
                  "cit 10,000-24,999"                    =   "cities between 10,000 and 24,999",
                  "cit 2,500-9,999"                      =   "cities between 2,500 and 9,999",
                  "msa co. 25,000-99,999"                =   "msa counties 25,000 thru 99,999",
                  "cit 100,000-249,999"                  =   "cities between 100,000 and 249,999",
                  "non-msa co. 10,000-24,999"            =   "non-msa counties 10,000 thru 24,999",
                  "non-msa co. 25,000-99,999"            =   "non-msa counties 25,000 thru 99,999",
                  "non-msa co. < 10,000"                 =   "non-msa counties under 10,000",
                  "cit 50,000-99,999"                    =   "cities between 50,000 and 99,999",
                  "cit < 2,500"                          =   "cities under 2,500",
                  "msa co. 10,000-24,999"                =   "msa counties 10,000 thru 24,999",
                  "msa co. < 10,000"                     =   "msa counties under 10,000",
                  "cit 1,000,000 +"                      =   "cities 1,000,000 or over",
                  "cit 500,000-999,999"                  =   "cities 500,000 thru 999,999",
                  "non-msa co. 100,000 +"                =   "non-msa counties 100,000 or over",
                  "msa st police"                        =   "msa state police",
                  "non-msa st police"                    =   "non-msa state policy",
                  "non-smsa cntys"                       =   "non-msa counties",
                  "cities < 2,500"                       =   "cities under 2,500",
                  "smsa counties"                        =   "msa counties",
                  "cities 25k-49999"                     =   "cities between 25,000 and 49,999",
                  "cities >250k"                         =   "cities 250,000 or over",
                  "cities 20k-24999"                     =   "cities between 10,000 and 24,999",
                  "cities 2500-9999"                     =   "cities between 2,500 and 9,999",
                  "cities 100k-249k"                     =   "cities between 100,000 and 249,999",
                  "cities 50k-99999"                     =   "cities between 50,000 and 99,999",
                  "under 2,500"                          =   "cities under 2,500",
                  "5,000-49,999"                         =   "cities between 25,000 and 49,999",
                  "all city>249,999"                     =   "cities 250,000 or over",
                  "1,000-24,999"                         =   "cities between 10,000 and 24,999",
                  "2,500-9,999"                          =   "cities between 2,500 and 9,999",
                  "100,000-249,000"                      =   "cities between 100,000 and 249,999",
                  "50,000-99,999"                        =   "cities between 50,000 and 99,999",
                  "nonsmsa counties"                     =   "non-smsa counties",
                  "cities, 0<2.5k"                       =   "cities under 2,500",
                  "cities,25k<50k"                       =   "cities between 25,000 and 49,999",
                  "cities 250k+"                         =   "cities 250,000 or over",
                  "cities, 10k<25k"                      =   "cities between 10,000 and 24,999",
                  "cities, 2.5k<10k"                     =   "cities between 2,500 and 9,999",
                  "cities,100k<250k"                     =   "cities between 100,000 and 249,999",
                  "cities,50k<100k"                      =   "cities between 50,000 and 99,999",
                  "non-smsa countie"                     =   "non-msa counties",
                  "cities lt 2500"                       =   "cities under 2,500",
                  "cities25th-49999"                     =   "cities between 25,000 and 49,999",
                  "cities 250th +"                       =   "cities 250,000 or over",
                  "cities10th-24999"                     =   "cities between 10,000 and 24,999",
                  "cities2500-9999"                      =   "cities between 2,500 and 9,999",
                  "city100th-249999"                     =   "cities between 100,000 and 249,999",
                  "cities50th-99999"                     =   "cities between 50,000 and 99,999",
                  "non-smsa counties"                    =   "non-msa counties",
                  "cities under 2,500"                   =   "cities under 2,500",
                  "cities between 25,000 and 49,999"     =   "cities between 25,000 and 49,999",
                  "cities 250,000 or over"               =   "cities 250,000 or over",
                  "cities between 10,000 and 24,999"     =   "cities between 10,000 and 24,999",
                  "cities between 2,500 and 9,999"       =   "cities between 2,500 and 9,999",
                  "cities between 100,000 and 249,999"   =   "cities between 100,000 and 249,999",
                  "cities between 50,000 and 99,999"     =   "cities between 50,000 and 99,999",
                  "non-smsa countys"                     =   "non-msa counties",
                  "cities <2500"                         =   "cities under 2,500",
                  "cities 25k-50k"                       =   "cities between 25,000 and 49,999",
                  "cities 250k up"                       =   "cities 250,000 or over",
                  "cities 10k-25k"                       =   "cities between 10,000 and 24,999",
                  "cities 100k-250k"                     =   "cities between 100,000 and 249,999",
                  "cities 50k-100k"                      =   "cities between 50,000 and 99,999",
                  "msa counties"                         =   "cities between 25,000 and 49,999",
                  "cities 25-50"                         =   "cities between 25,000 and 49,999",
                  "cities 250+"                          =   "cities 250,000 or over",
                  "cities 10-25"                         =   "cities between 10,000 and 24,999",
                  "cities 2.5-10"                        =   "cities between 2,500 and 9,999",
                  "cities under 2.5"                     =   "cities under 2,500",
                  "cities 100-250"                       =   "cities between 100,000 and 249,999",
                  "cities 50-100"                        =   "cities between 50,000 and 99,999",
                  "non-msa counties under 10,000"        =   "non-msa counties under 10,000",
                  "msa counties 100,000 or over"         =   "msa counties 100,000 or over",
                  "cities 25,000 thru 49,999"            =   "cities between 25,000 and 49,999",
                  "cities 250,000 thru 499,999"          =   "cities 250,000 thru 499,999",
                  "cities 10,000 thru 24,999"            =   "cities between 10,000 and 24,999",
                  "cities 2,500 thru 9,999"              =   "cities between 2,500 and 9,999",
                  "cities 100,000 thru 249,999"          =   "cities between 100,000 and 249,999",
                  "7b"                                   = NA,
                  "\\+\\+"                               = "\\+"
)

agency_count <- c("all oth agencies"                      = "all other agencies",
                  "u.s. park police"                      = "us park & state police",
                  "u.s. park police"                      = "us park & state police",
                  "parks,state,etc."                      = "us park & state police",
                  "park police etc"                       = "us park & state police",
                  "us park police & state police (sp,99)" = "us park & state police",
                  "us park police & state police"         = "us park & state police",
                  "9"                                     = NA,
                  "u$"                                    = NA,
                  "not ascertained"                       = NA,
                  "oris wsp cds"                          = NA)


special_mailing_group <- c(
  "agency not on ls"                          = "agency-contributor, not on mail list",
  "inap.$"                                    = "not special mail group agency",
  "agcy not snt frm"                          = "agency-non-contributor, not sent form",
  "retrn sent elsew"                          = "return sent to another agency",
  "agency contribut"                          = "agency-contributor, not on mail list",
  "agency non-cont"                           = "agency-non-contributor, not sent form",
  "return sent out$"                          = "return sent to another agency",
  "mail lst- no frm"                          = "agency-contributor, not on mail list",
  "no form- non con"                          = "agency-non-contributor, not sent form",
  "rtrn snt to othr"                          = "return sent to another agency",
  "agency is a contributor but not on the mailing list"= "agency-contributor, not on mail list",
  "agency is a"                               = "agency-contributor, not on mail list",
  "^inap$"                                    = "not special mail group agency",
  "cntrib no mail"                            = "agency-contributor, not on mail list",
  "^non-contributor$"                         = "agency-non-contributor, not sent form",
  "^another agency$"                          = "return sent to another agency",
  "not on list"                               = "agency-contributor, not on mail list",
  "sent to other"                             = "return sent to another agency",
  "inap, not special mail group agency"       = "not special mail group agency",
  "not special mail"                          = "not special mail group agency",
  "otr agency"                                = "return sent to another agency"
)

followup_indication <- c("^y$" = "yes, send a follow-up",
                         "^n$" = "no, do not send a follow-up",
                         "9"  = NA)


negatives <- c("0+\\}"                = "0",
               "0+j"                  = "-1",
               "0+k"                  = "-2",
               "0+l"                  = "-3",
               "0+m"                  = "-4",
               "0+n"                  = "-5",
               "0+o"                  = "-6",
               "0+p"                  = "-7",
               "0+q"                  = "-8",
               "0+r"                  = "-9",
               "0+1\\}"               = "-10",
               "0+1j"                 = "-11",
               "0+1k"                 = "-12",
               "0+1l"                 = "-13",
               "0+1m"                 = "-14",
               "0+1n"                 = "-15",
               "zero or not reported" = "0")

fix_negatives <- function(column) {
  column <- str_replace_all(column, negatives)
  return(column)
}


make_agg_assault <- function(data) {
  crime_type <- c("_ACT", "_CLR_18", "_CLR", "_UNFOUND")
  months <- toupper(month.abb)
  for (month in months) {
    for (type in crime_type) {
      data[, paste0(month, type, "_aggravated_assault")] <-
        rowSums(data[, grep(paste0(month, type, "_(OTH|GUN|KNIFE|HAND).*ASSA"),
                            names(data))])
    }
  }
  return(data)
}

make_yearly_cols <- function(dataset, types, crimes, officers) {
  for (crime in crimes) {
    for (type in types) {
      dataset[, paste0(type, "_", crime)] <- rowSums(dataset[,
                                                             grep(paste0(type,
                                                                         "_",
                                                                         crime),
                                                                  names(dataset),
                                                                  value = TRUE)])
    }
  }

  if (any(grepl("officers", names(dataset)))) {
    for (officer in officers) {
      dataset[, officer] <- rowSums(dataset[, grep(officer, names(dataset), value = TRUE)])
    }
  }

  return(dataset)
}



fix_outliers <- function(data, year) {
  if (year == 1972) {
    data$ORI[data$NUMERIC_STATE_CODE == "virginia" &
               data$POPULATION_1 == "446963"] <- "VA02901"
  }
  if (year == 1974) {
    data$NOV_OFFICERS_KILLED_BY_ACCIDENT[data$ORI == "MA01301"] <- NA
  }
  if (year == 1978) {
    data$MAR_OFFICERS_KILLED_BY_ACCIDENT[data$ORI == "PAPPD00"] <- NA

    data$APR_OFFICERS_KILLED_BY_FELONY[data$ORI == "NY06240"] <- NA
    data$JUN_OFFICERS_KILLED_BY_FELONY[data$ORI == "NY06240"] <- NA
    data$APR_OFFICERS_KILLED_BY_ACCIDENT[data$ORI == "NY06240"] <- NA
    data$JUN_OFFICERS_KILLED_BY_ACCIDENT[data$ORI == "NY06240"] <- NA

    data$MAY_OFFICERS_KILLED_BY_ACCIDENT[data$ORI == "NY04040"] <- NA
    data$MAY_OFFICERS_KILLED_BY_FELONY[data$ORI == "NY04040"] <- NA
  }
  if (year == 1996) {
    data$SEP_OFFICERS_KILLED_BY_FELONY[data$ORI == "LA03102"] <- NA
  }
  if (year == 1997) {
    data$MAR_OFFICERS_KILLED_BY_FELONY[data$ORI == "MO0950E"] <- NA
  }
  if (year %in% 2014:2016) {
    data[data$ORI == "LANPD00", grep("UNFOUND_", names(data))] <- NA
  }
  return(data)
}

to_ascii_cols <- c("jul_card_3_pt", "aug_card_3_pt", "mailing_address_line_4")
starting_cols <- c("ori",
                   "ori9",
                   "year",
                   "state",
                   "state_abb",
                   "months_reported")
other_cols <- c("fips_state_code",
                "fips_county_code",
                "fips_state_county_code",
                "fips_place_code",
                "fips_state_place_code",
                "agency_type",
                "agency_subtype_1",
                "agency_subtype_2",
                "group_number",
                "division",
                "city_sequence_number",
                "core_city_indication",
                "covered_by_code",
                "last_update",
                "field_office",
                "total_population",
                "population_1",
                "county_1",
                "msa_1",
                "population_2",
                "county_2",
                "msa_2",
                "population_3",
                "county_3",
                "msa_3",
                "followup_indication",
                "special_mailing_group",
                "special_mailing_address",
                "agency_name",
                "agency_state_name",
                "mailing_address_line_1",
                "mailing_address_line_2",
                "mailing_address_line_3",
                "mailing_address_line_4",
                "zip_code")
