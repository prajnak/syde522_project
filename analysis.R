library(dplyr)
library(ggplot2)

library(caret)
library(AppliedPredictiveModeling)

#transparentTheme(trans=0.4)
load('df_Cereal.RData') # loads the saved data from disk into the df_cereal data frame object

# [1] "land"     "year"     "yield"    "machines" "temps"    "rain"     "methane"
                                        # the predictors are all variables except

## get rid of columns with NA values
cols_NA = unlist(lapply(df_cereal[1:53,], function(x) any(is.na(x))))
##    land     year    yield machines    temps     rain  methane 
##    FALSE    FALSE   FALSE TRUE        FALSE     FALSE     TRUE 
predsArray = c(1,4,5);
df_noNA = df_cereal[1:53,-c(4,7)]
featurePlot(x=df_noNA[,predsArray], y=df_noNA$yield, plot='line', auto.key=list(columns=3))

decades = c('60s', '70s', '80s', '90s', '00s', '10s')
nearZeroVar(df_noNA, saveMetrics = T)

df_predictors = df_noNA[, predsArray]
df_yield = df_noNA[, 3]

train_idx = createDataPartition(y=df_noNA$yield, p=0.95)
pred_train = df_predictors[train_idx$Resample1, ]
yield_train = df_yield[train_idx$Resample1]
pred_test = df_predictors[-train_idx$Resample1, ]
yield_test = df_yield[-train_idx$Resample1]





## Using Caret's averaged neural network model to make the predictions
preproc_arguments = c('center', 'scale')
fitControl = trainControl(method = "repeatedcv", #10-fold cross validation
                         number=10,
                         repeats = 10,
                         returnResamp = "all")

set.seed(45)
avNNetModel = train(x=pred_train, y=yield_train, trControl = fitControl,
                    method="avNNet", preProc=preproc_arguments,
                    linout=TRUE,trace=FALSE,
                    MaxNWts=40 * (ncol(pred_train)+1) + 10 + 1, maxit=1000)

avNNetPred = predict(avNNetModel, newdata=pred_train)
avNNetPR = postResample(pred=avNNetPred, obs=yield_train)
rmses_training = c(avNNetPR[1])
r2s_training = c(avNNetPR[2])
methods = c("AvgNN")
avnnetPred_all = predict(avNNetModel, newdata=df_predictors)
avnnetPR_all = postResample(pred=avnnetPred_all, obs = df_yield)
rmses_testing = c(avnnetPR_all[1])
r2s_testing = c(avnnetPR_all[2])
ggplot(avNNetModel, metric='Rsquared')
out_name = paste("nnet_pred_obs", as.numeric(as.POSIXct(Sys.time())), ".png")
trellis.device(device="png", width=8, height=5, units="in", filename=out_name, res=100)
print(plot(df_noNA$year, df_noNA$yield, type='l', col=2))
print(lines(df_noNA$year, avnnetPred_all, col=3))
print(legend(x='topright',c('actual', 'predicted'), fill=2:3))
dev.off()

ggplot(avNNetModel, metric="Rsquared") + ggtitle("Performance of average neural network model")        
ggsave("avgnnet_rsqr.png", width=8, height=5, units="in", dpi=100)



## install.packages('forecast')
library(neuralnet)

nnet = neuralnet()
# convert to timeseries
