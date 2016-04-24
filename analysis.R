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

methods = c("AvgNN", "MARS")
avnnetPred_all = predict(avNNetModel, newdata=pred_test)
avnnetPR_all = postResample(pred=avnnetPred_all, obs = yield_test)
rmses_testing = c(avnnetPR_all[1])
r2s_testing = c(avnnetPR_all[2])

res = as.data.frame(cbind(pred_train$year, yield_train, avNNetPred))
colnames(res) = c("Year", "Actual", "Predicted")
res = melt(res, id.vars = "Year")
ggplot(res, aes(Year,value,col=variable)) + geom_line() + ggtitle("Training performance for NN model")
ggsave("avgnnet_training.png", width=8, height=5, units="in", dpi=200)

ggplot(avNNetModel, metric="Rsquared") + ggtitle("Parameter tuning of average neural network model")        
ggsave("avgnnet_rsqr.png", width=8, height=5, units="in", dpi=200)

res = as.data.frame(cbind(pred_test$year, yield_test, avnnetPred_all))
colnames(res) = c("Year", "Actual", "Predicted")
res = melt(res, id.vars = "Year")
ggplot(res, aes(Year,value,col=variable)) + geom_line() + ggtitle("Validation performance for NN model")
ggsave("avgnnet_validate.png", width=8, height=5, units="in", dpi=200)

library(doMC)
registerDoMC(cores=4)

## Multiple adaptive Regressive Splines (MARS)
marsGrid = expand.grid(.degree=1:2, .nprune=2:38)

marsModel = train(x=pred_train, y=yield_train,
                  trControl = fitControl, preProcess = preproc_arguments,
                  method = "earth", tuneLength = 20,
                  tuneGrid = marsGrid)

anfisPreds = predict(marsModel, newdata=pred_train)
anfispostResample = postResample(pred=anfisPreds, obs=yield_train)
rmses_training = c(rmses_training, anfispostResample[1])
r2s_training = c(r2s_training, anfispostResample[2])

res = as.data.frame(cbind(pred_train$year, yield_train, anfisPreds))
colnames(res) = c("Year", "Actual", "Predicted")
res = melt(res, id.vars = "Year")
quartz()
ggplot(marsModel, metric="Rsquared") + ggtitle("Parameter tuning for MARS model")
ggsave("mars_rsqr.png", width=8, height=5, units="in", dpi=200)
ggplot(res, aes(Year,value,col=variable)) + geom_line() + ggtitle("Training performance for MARS model")
ggsave("mars_training.png", width=8, height=5, units="in", dpi=200)

marsPred_all = predict(marsModel, newdata=pred_test)
marsPostResample = postResample(pred=marsPred_all, obs = yield_test)
rmses_testing = c(rmses_testing, marsPostResample[1])
r2s_testing = c(r2s_testing, marsPostResample[2])

res = as.data.frame(cbind(pred_test$year, yield_test, marsPred_all))
colnames(res) = c("Year", "Actual", "Predicted")
res = melt(res, id.vars ="Year")
ggplot(res, aes(Year, value, col=variable)) + geom_line() + ggtitle("Validation Data performance for MARS")
ggsave("mars_validate.png", width=8, height=5, units="in", dpi=200)


res_training = data.frame( rmse=rmses_training, r2=r2s_training )
rownames(res_training) = methods
training_order = order( -res_training$rmse )
res_training = res_training[ training_order, ] # Order the dataframe so that the best results are at the bottom:
print( "Final Training Results" )
print( res_training )

library(Hmisc)
latex(res_training, file="train_results.tex")

res_testing = data.frame( rmse=rmses_testing, r2=r2s_testing )
rownames(res_testing) = methods
res_testing = res_testing[ training_order, ] # Order the dataframe so that the best results for the training set are at the bottom:
print( "Final Testing Results" ) 
print( res_testing )

latex(res_testing, file="testing_results.tex")

resamp = resamples( list(mars=marsModel, avnnet=avNNetModel) )
resamp_sum = summary(resamp)
library(lattice)
bwplot(resamp, scales="free")
dotplot(resamp, scales="free")
parallelplot(resamp, metric="RMSE")


ggplot(varImp(marsModel))
ggsave("mars_varimp.png", width=5, height=3, dpi=200, units="in")

ggplot(varImp(avNNetModel))
ggsave("avgnn_varimp.png", width=5, height=3, dpi=200, units="in")

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
       









