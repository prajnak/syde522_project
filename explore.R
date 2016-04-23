library(Quandl)
library(ggplot2)
library(dplyr)
library(readr)

library(WDI)
library(rWBclimate)

library(caret)
library(AppliedPredictiveModeling)

## area_principal_crops_rice = Quandl("MOSPI/AREA_PRINCPL_CROPS_8_2_RICE",
##                                    api_key="Q_zK1Gdy59wWp8Bkh9wH")

## head(area_principal_crops_rice)
## f = ggplot(data=area_principal_crops_rice, aes(Year, Rice))
## f + geom_line()

## avg_yield_rice_1 = Quandl("MOSPI/AVG_YLD_PRINCPL_CROPS_8_4_RICE", api_key="Q_zK1Gdy59wWp8Bkh9wH")
## summary(avg_yield_rice_1)

## f=ggplot(data=avg_yield_rice_1, aes(Year, Rice))
## f + geom_line()

## ## read in the really big agricultural climate dataset

## raw_dat = read.table('rawdata/india60.cfm', sep=' ', header = F)
## rdf = reshape(raw_dat, 227, 271, direction='long')
## res <- lapply(raw_dat, function(ch) grep("[A-Z]+", ch))

## dim(res[res != 0])

## var_names = read.csv('rawdata/vars.txt', sep=' ', header=T)

## FUN <- function(x) {
##     x <- as.integer(x)
##     div <- seq_len(abs(x))
##     factors <- div[x %% div == 0L]
##     factors <- list(neg = -factors, pos = factors)
##     return(factors)
## }

## raw_dat = readLines('rawdata/india75.cfm')

## install packages to read data from the world bank dataset
# install.packages('rWBclimate')
# install.packages('WDI')

countries = c('IN')
WDIsearch('maize')
## read in data for cereal yield
cereal_yield = WDI(indicator = 'AG.YLD.CREL.KG', country = c('IN'),
                   start = 1960, end = 2013)
cereal_land = WDI(indicator = 'AG.LND.CREL.HA', country = c('IN'),
                  start = 1960, end = 2013)
head(cereal_land)
agri_machinery_value = WDI(indicator = 'NV.MNF.MTRN.ZS.UN', country=c('IN'), start=1960)


table(WDI(indicator = 'AG.CRP.MZE.CD')$country)
agri_machinery_value = WDI(indicator = 'NV.MNF.MTRN.ZS.UN', country=c('IN'), start=1960, end=2013)

f = ggplot(data = cereal_yield, aes(year, AG.YLD.CREL.KG))
f+geom_line() + ggtitle('Cereal Yield in India from 1960-2013')

## concat all yield, area under land into a single dataframe
df_cereal = data.frame(cereal_land$AG.LND.CREL.HA)
colnames(df_cereal) = c('land')
df_cereal$year = cereal_yield$year
df_cereal$yield = cereal_yield$AG.YLD.CREL.KG
df_cereal$machines = agri_machinery_value$NV.MNF.MTRN.ZS.UN

## Asia_country
## Asia_basin
## get_historical_temp(c("IND"), "year")

## options(kmlpath = '~/.kmltemp')
## as_basin = create_map_df(Asia_basin)

WDIsearch('loans')
fert_usage = WDI(indicator = "AG.CON.FERT.ZS", country = countries, start=1960, end=2013)

df_cereal$fertilizer = fert_usage$AG.CON.FERT.ZS

WDI(indicator = "AG.CON.FERT.PT.ZS", country = countries, start=1960, end=2013)

#ggplot(as_basin, aes(x=long, y=lat, group=group)) + geom_polygon()


#temps = get_historical_temp(c('IND'), time_scale = "year")
#get_historical_temp(c('IND'), time_scale = "daily")

#temps = arrange(temps, -row_number())
#temps_annual = temps$data[1:54]
#df_cereal$temps = temps_annual

## read in monthly temperature data
## two crop seasons in india for agriculture
## kharif: july-october and rabi:october-march
## lets take averages for each season and average them both
temp_1960_90 = read.xlsx('~/Downloads/tas5_1960_1990.xls', sheetIndex = 1)
temp_1990_2012 = read.xlsx('~/Downloads/tas5_1990_2012.xls', sheetIndex = 1)
temp_monthly = rbind(temp_1960_90, temp_1990_2012)
temp_monthly = arrange(temp_monthly, -row_number())
temps_kharif = temp_monthly[temp_monthly$X.Month %in% c(7,8,9,10),]
avg_temps_kharif = colMeans(matrix(temps_kharif$Temperature..C., nrow=4))

temps_rabi = temp_monthly[temp_monthly$X.Month %in% c(1,2,3),]
avg_temps_rabi = colMeans(matrix(temps_rabi$Temperature..C., nrow=3))
df_cereal$temp_rabi = avg_temps_rabi
df_cereal$temp_kharif = avg_temps_kharif

#avg_temps = rowMeans(cbind(avg_temps_kharif, avg_temps_rabi))

precip = get_historical_precip(c("IND"), "year")
precip = arrange(precip, -row_number())
precip_annual = precip$data[1:54]

precip_1900_2012 = read.xlsx('~/Downloads/pr5_1900_2012.xls', sheetIndex = 1)

ppp = precip_1900_2012[precip_1900_2012$X.Year %in% 1959:2012,]
ppp = arrange(ppp, -row_number())
precip_kharif = ppp[ppp$X.Month %in% c(7,8,9,10),]
avg_precip_kharif = colMeans(matrix(precip_kharif$Rainfall..mm., nrow=4))

precip_rabi = ppp[ppp$X.Month %in% c(1,2,3),]
avg_precip_rabi = colMeans(matrix(precip_rabi$Rainfall..mm., nrow=3))
length(avg_precip_rabi)

df_cereal$rain_rabi = avg_precip_rabi
df_cereal$rain_kharif = avg_precip_kharif
#avg_rainfall = rowMeans(cbind(avg_precip_kharif, avg_precip_rabi))
get_historical_precip(c("IND"), "month")

#df_cereal$rain = precip_annual

#pairs(df_cereal)
#WDIsearch('')
#methane_emission = WDI(indicator = 'EN.ATM.NOXE.AG.KT.CE', country=c('IN'), start=1960, end=2013)
#df_cereal$methane = methane_emission$EN.ATM.METH.AG.KT.CE




save(df_cereal, file='df_Cereal.RData')
