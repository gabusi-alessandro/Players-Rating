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

# Dataset
data_g <- readRDS('Data_G.rds')
data_d <- readRDS('Data_D.rds')
data_m <- readRDS('Data_M.rds')
data_f <- readRDS('Data_F.rds')


#############################
### GRAFICO A DISPERSIONE ###
#############################
plot(data_g[,5:10], pch=16)

#############################
## MATRICE DI CORRELAZIONE ##
#############################
cor(data_g[,5:10])

###############################
## VARIANCE INFLATION FACTOR ##
###############################
library(car)
# Regressione Lineare
vif(linMod_G)[,1][vif(linMod_G)[,1] > 5]
vif(linMod_D)[,1][vif(linMod_D)[,1] > 5]
vif(linMod_M)[,1][vif(linMod_M)[,1] > 5]
vif(linMod_F)[vif(linMod_F) > 10]

#  Regressione Logistica
vif(logMod_G)[vif(logMod_G) > 5]
vif(logMod_D)[vif(logMod_D) > 5]
vif(logMod_M)[vif(logMod_M) > 5]
vif(logMod_F)[vif(logMod_F) > 5]

##############################
## CONDITION INDEX e NUMBER ##
##############################
library(mctest)
?mctest


?eigprop
eigprop(linMod_G)$ci[eigprop(linMod_G)$ci > 10]
eigprop(linMod_D)$ci[eigprop(linMod_D)$ci > 10]
eigprop(linMod_M)$ci[eigprop(linMod_M)$ci > 10]
eigprop(linMod_F)$ci[eigprop(linMod_F)$ci > 10]


#######################################
## VARIANCE DECOMPOSITION PROPORTION ##
#######################################

G <- eigprop(linMod_G)
idx_g <- which(G$ci > 10) # Condition Index > 10

vdp_g <- G$pi[,idx_g, drop=F] # Consideriamo i VDP superiore alla soglia di 0.5
apply(vdp_g > 0.5, 2, any) # Osserviamo le variabili coinvolte

# --- --- --- --- --- --- --- --- --- --- --- --- --- 

D <- eigprop(linMod_D)
idx_d <- which(D$ci > 10) # Condition Index > 10

vdp_d <- D$pi[,idx_d, drop=F] # Consideriamo i VDP superiore alla soglia di 0.5
apply(vdp_d > 0.5, 2, any) # Osserviamo le variabili coinvolte

# --- --- --- --- --- --- --- --- --- --- --- --- ---

M <- eigprop(linMod_M)
idx_m <- which(M$ci > 10) # Condition Index > 10

vdp_m <- M$pi[,idx_m, drop=F] # Consideriamo i VDP superiore alla soglia di 0.5
apply(vdp_m > 0.5, 2, any) # Osserviamo le variabili coinvolte

# --- --- --- --- --- --- --- --- --- --- --- --- ---

F <- eigprop(linMod_F)
idx_f <- which(F$ci > 10) # Condition Index > 10

vdp_f <- F$pi[,idx_f, drop=F] # Consideriamo i VDP superiore alla soglia di 0.5
apply(vdp_f > 0.5, 2, any) # Osserviamo le variabili coinvolte
