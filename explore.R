library(Quandl)
library(ggplot2)


area_principal_crops_rice = Quandl("MOSPI/AREA_PRINCPL_CROPS_8_2_RICE",
                                   api_key="Q_zK1Gdy59wWp8Bkh9wH")

head(area_principal_crops_rice)
f = ggplot(data=area_principal_crops_rice, aes(Year, Rice))
f + geom_line()

avg_yield_rice_1 = Quandl("MOSPI/AVG_YLD_PRINCPL_CROPS_8_4_RICE", api_key="Q_zK1Gdy59wWp8Bkh9wH")
summary(avg_yield_rice_1)

f=ggplot(data=avg_yield_rice_1, aes(Year, Rice))
