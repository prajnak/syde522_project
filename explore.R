library(Quandl)
library(ggplot2)
library(dplyr)
library(readr)

library(WDI)
library(rWBclimate)

area_principal_crops_rice = Quandl("MOSPI/AREA_PRINCPL_CROPS_8_2_RICE",
                                   api_key="Q_zK1Gdy59wWp8Bkh9wH")

head(area_principal_crops_rice)
f = ggplot(data=area_principal_crops_rice, aes(Year, Rice))
f + geom_line()

avg_yield_rice_1 = Quandl("MOSPI/AVG_YLD_PRINCPL_CROPS_8_4_RICE", api_key="Q_zK1Gdy59wWp8Bkh9wH")
summary(avg_yield_rice_1)

f=ggplot(data=avg_yield_rice_1, aes(Year, Rice))
f + geom_line()

## read in the really big agricultural climate dataset

raw_dat = read.table('rawdata/india60.cfm', sep=' ', header = F)
rdf = reshape(raw_dat, 227, 271, direction='long')
res <- lapply(raw_dat, function(ch) grep("[A-Z]+", ch))

dim(res[res != 0])

var_names = read.csv('rawdata/vars.txt', sep=' ', header=T)

FUN <- function(x) {
    x <- as.integer(x)
    div <- seq_len(abs(x))
    factors <- div[x %% div == 0L]
    factors <- list(neg = -factors, pos = factors)
    return(factors)
}

raw_dat = readLines('rawdata/india75.cfm')

## install packages to read data from the world bank dataset
install.packages('rWBclimate')
install.packages('WDI')

WDIsearch('maize')
## read in data for cereal yield
cereal_yield = WDI(indicator = 'AG.YLD.CREL.KG', country = c('IN'),
                   start = 1960, end = 2013)
cereal_land = WDI(indicator = 'AG.LND.CREL.HA', country = c('IN'),
                  start = 1960, end = 2013)
head(cereal_land)

table(WDI(indicator = 'AG.CRP.MZE.CD')$country)

f = ggplot(data = cereal_yield, aes(year, AG.YLD.CREL.KG))
f+geom_line() + ggtitle('Cereal Yield in India from 1960-2013')

## concat all yield, area under land into a single dataframe
df_cereal = data.frame(cereal_land$AG.LND.CREL.HA)
colnames(df_cereal) = c('land')
df_cereal$year = cereal_yield$year
df_cereal$yield = cereal_yield$AG.YLD.CREL.KG

