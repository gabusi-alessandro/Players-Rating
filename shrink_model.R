##############################
### SHRINKING LINEAR MODEL ###
##############################

setwd("C:\\Users\\UTENTE\\Desktop\\Code")
rm(list=ls())

data_G <- readRDS('Data_G.rds')
data_D <- readRDS('Data_D.rds')
data_M <- readRDS('Data_M.rds')
data_F <- readRDS('Data_F.rds')

###############################
### COSTRUZIONE DEI MODELLI ###
###############################

library(glmnet)

# PORTIERI
mod_pieno_G <- lm(valutazione ~ .*., data=data_G)

y_g <- data_G$valutazione
X_g <- model.matrix(mod_pieno_G)[,-1]

train_terms_g <- mod_pieno_G$terms
train_levels_g <- lapply(data_G, levels)

Ridge_g <- cv.glmnet(X_g, y_g, alpha=0) 
Lasso_g <- cv.glmnet(X_g, y_g, alpha=1)

# DIFENSORI
mod_pieno_D <- lm(valutazione ~ .*., data=data_D)

y_d <- data_D$valutazione
X_d <- model.matrix(mod_pieno_D)[,-1]

train_terms_d <- mod_pieno_D$terms
train_levels_d <- lapply(data_D, levels)

Ridge_d <- cv.glmnet(X_d, y_d, alpha=0) 
Lasso_d <- cv.glmnet(X_d, y_d, alpha=1)

# CENTROCAMPISTI
mod_pieno_M <- lm(valutazione ~ .*., data=data_M)

y_m <- data_M$valutazione
X_m <- model.matrix(mod_pieno_M)[,-1]

train_terms_m <- mod_pieno_M$terms
train_levels_m <- lapply(data_M, levels)

Ridge_m <- cv.glmnet(X_m, y_m, alpha=0) 
Lasso_m <- cv.glmnet(X_m, y_m, alpha=1)

# ATTACCANTI
mod_pieno_F <- lm(valutazione ~ .*., data=data_F)

y_f <- data_F$valutazione
X_f <- model.matrix(mod_pieno_F)[,-1]

train_terms_f <- mod_pieno_F$terms
train_levels_f <- lapply(data_F, levels)

Ridge_f <- cv.glmnet(X_f, y_f, alpha=0) 
Lasso_f <- cv.glmnet(X_f, y_f, alpha=1)


##############
### OUTPUT ###
##############

saveRDS(Ridge_g, file='ridge_g.rds')
saveRDS(Lasso_g, file='lasso_g.rds')
saveRDS(train_terms_g, file = 'train_terms_g.rds')
saveRDS(train_levels_g, file='train_levels_g.rds')

saveRDS(Ridge_d, file='ridge_d.rds')
saveRDS(Lasso_d, file='lasso_d.rds')
saveRDS(train_terms_d, file = 'train_terms_d.rds')
saveRDS(train_levels_d, file='train_levels_d.rds')

saveRDS(Ridge_m, file='ridge_m.rds')
saveRDS(Lasso_m, file='lasso_m.rds')
saveRDS(train_terms_m, file = 'train_terms_m.rds')
saveRDS(train_levels_m, file='train_levels_m.rds')

saveRDS(Ridge_f, file='ridge_f.rds')
saveRDS(Lasso_f, file='lasso_f.rds')
saveRDS(train_terms_f, file = 'train_terms_f.rds')
saveRDS(train_levels_f, file='train_levels_f.rds')
