##################################
### ANALISI MULTICOLLINEARITA' ###
##################################

rm(list=ls())

library(car)

#######################
## CARICHIAMO I DATI ##
#######################

# Modello di Regressione Lineare
linMod_G <- readRDS("linear_model_G.rds")
linMod_D <- readRDS("linear_model_D.rds")
linMod_M <- readRDS("linear_model_M.rds")
linMod_F <- readRDS("linear_model_F.rds")

# Modello di Regressione Logistica
logMod_G <- readRDS("logistic_model_G.rds")
logMod_D <- readRDS("logistic_model_D.rds")
logMod_M <- readRDS("logistic_model_M.rds")
logMod_F <- readRDS("logistic_model_F.rds")

# Modello di Regressione Ridge
ridge_g <- readRDS('ridge_g.rds')
ridge_d <- readRDS('ridge_d.rds')
ridge_m <- readRDS('ridge_m.rds')
ridge_f <- readRDS('ridge_f.rds')

# Modello di Regressione LASSO
lasso_g <- readRDS('lasso_g.rds')
lasso_d <- readRDS('lasso_d.rds')
lasso_m <- readRDS('lasso_m.rds')
lasso_f <- readRDS('lasso_f.rds')

library(car)
# Regressione Lineare
vif(linMod_G)[,1][vif(linMod_G)[,1] > 5]
vif(linMod_D)[,1][vif(linMod_D)[,1] > 5]
vif(linMod_M)[,1][vif(linMod_M)[,1] > 5]
vif(linMod_F)[vif(linMod_F) > 5]

# Regressione Logistica
vif(logMod_G)[vif(logMod_G) > 5]
vif(logMod_D)[vif(logMod_D) > 5]
vif(logMod_M)[vif(logMod_M) > 5]
vif(logMod_F)[vif(logMod_F) > 5]

library(genridge)
# Regressione Ridge
vif(ridge_g)
vif(logMod_D)[vif(logMod_D) > 5]
vif(logMod_M)[vif(logMod_M) > 5]
vif(logMod_F)[vif(logMod_F) > 5]



library(mctest)
eigprop(linMod_D)

mctest(linMod_D)
?mctest
?eigprop