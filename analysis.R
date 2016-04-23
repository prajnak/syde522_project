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

df_noNA = df_cereal[1:53,-c(4,5)]

nearZeroVar(df_noNA, saveMetrics = T)

predsArray = c(1,2,4,5,6,7)
df_predictors = df_noNA[, predsArray]
df_yield = df_noNA[, 3]

train_idx = createDataPartition(y=df_yield, p=0.70)
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
quartz()
ggplot(avNNetModel, metric='Rsquared')
out_name = paste("nnet_pred_obs", as.numeric(as.POSIXct(Sys.time())), ".png")
trellis.device(device="png", width=8, height=5, units="in", filename=out_name, res=100)
print(plot(df_noNA$year, df_noNA$yield, type='l', col=2))
print(lines(df_noNA$year, avnnetPred_all, col=3))
print(legend(x='topleft',c('actual', 'predicted'), fill=2:3))
dev.off()

ggplot(avNNetModel, metric="Rsquared") + ggtitle("Performance of average neural network model")        
ggsave("avgnnet_rsqr.png", width=8, height=5, units="in", dpi=100)

library(doMC)
registerDoMC(cores=4)

## Multiple adaptive Regressive Splines (MARS)
marsGrid = expand.grid(.degree=1:2, .nprune=2:38)

marsModel = train(x=pred_train, y=yield_train,
                  trControl = fitControl, preProcess = preproc_arguments,
                  method = "earth", tuneLength = 20,
                   tuneGrid = marsGrid)
anfisPreds = predict(marsModel, newdata=pred_test)

res = as.data.frame(cbind(pred_test$year, yield_test, anfisPreds))
res = melt(res, id.vars = "V1")
quartz()
ggplot(marsModel, metric="Rsquared")
quartz()
ggplot(res, aes(V1,value,col=variable)) + geom_line() + ggtitle("Validation performance for MARS model")
marsPred_all = predict(marsModel, newdata=df_predictors)
res = as.data.frame(cbind(df_predictors$year, df_yield, marsPred_all))
res = melt(res, id.vars ="V1")
quartz()
ggplot(res, aes(V1, value, col=variable)) + geom_line() + ggtitle("Training + Validation Data combined performance for MARS")

## Neural network with multiple layers
paramGrid <- expand.grid(.layer1 = c(10,9,8,7), .layer2 = c(6,5,4), .layer3 = c(1,2,3));
nnetModel = train(x=pred_train, y=yield_train, trControl = fitControl,
                  preProcess=preproc_arguments, method="neuralnet",
                  tuneLength=5, tuneGrid = paramGrid)

nnet_preds = predict(nnetModel, newdata=pred_test)
res = as.data.frame(cbind(pred_test$year, yield_test, nnet_preds ))
colnames(res) = c("year", "actual", "nnet_prediction")
res = melt(res, id.vars = "V1")
quartz()
ggplot(nnetModel, metric="Rsquared")
quartz()
ggplot(res, aes(V1, value, col=variable)) + geom_line() + ggtitle("Validation performance for ML NN")




## install.packages('forecast')
library(neuralnet)
trellis.par.set(caretTheme())
## nnet = neuralnet()
library(rpart)
library(randomForest)

## Use decision trees
fit_dectree <- rpart(yield ~ land + temps + rain, method="anova", data=df_noNA)
quartz()
plot(df_noNA$year, df_noNA$yield, type='l', col=2)
lines(df_noNA$year, fit_dectree$predicted, col=3)
legend(x='topright', c('actual', 'predicted', fill=2:3))


fit <- randomForest(yield ~ land + temps + rain, data=df_noNA, proximity = T)
df_noNA$predicted_rfs = fit$predicted

plotcp(fit)
printcp(fit)
summary(fit)
plot(fit)

library(reshape2)

d <- melt(df_noNA[,2:7], id.vars='year')
quartz()
ggplot(d, aes(year, value, col=variable)) + geom_line() + scale_y_log10() +scale_x_continuous(breaks = seq(1961,2012, by=5)) + geom_text(data=df_noNA[df_noNA$year==2012,],aes(label=))
       









