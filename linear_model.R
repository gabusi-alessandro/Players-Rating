#######################
### MODELLI LINEARI ###
#######################
setwd("C:\\Users\\UTENTE\\Desktop\\Code")
rm(list=ls())

data_G <- readRDS('Data_G.rds')
data_D <- readRDS('Data_D.rds')
data_M <- readRDS('Data_M.rds')
data_F <- readRDS('Data_F.rds')

###############################
### COSTRUZIONE DEI MODELLI ###
###############################

# PORTIERI
mod_pieno_G <- lm(valutazione ~ ., data = data_G)
# mod_pieno_G_int  <- lm(valutazione ~ .*., data_G)

mod_G <- step(mod_pieno_G, direction = 'both')
# mod_G_int <- step(mod_pieno_G_int, direction = 'both') # AIC Infinito 
# --> Capire il perché --> Overfitting (p > n)

summary(mod_G)

# DIFENSORI
mod_pieno_D <- lm(valutazione ~ ., data = data_D)
# mod_pieno_D_int  <- lm(valutazione ~ .*., data_D) --> Troppi parametri
# step non funziona => Proviamo regressione LASSO

mod_D <- step(mod_pieno_D, direction = 'both')
# mod_D_int <- step(mod_pieno_D_int, direction = 'both')

summary(mod_D)
# summary(mod_D_int)

# CENTROCAMPISTI
mod_pieno_M <- lm(valutazione ~ ., data = data_M)
# mod_pieno_M_int  <- lm(valutazione ~ .*., data_M)

mod_M <- step(mod_pieno_M, direction = 'both')
# mod_M_int <- step(mod_pieno_M_int, direction = 'both')

summary(mod_M)
# summary(mod_M_int)

# ATTACCANTI
mod_pieno_F <- lm(valutazione ~ ., data = data_F)
# mod_pieno_F_int  <- lm(valutazione ~ .*., data_F)

mod_F <- step(mod_pieno_F, direction = 'both')
#mod_F_int <- step(mod_pieno_F_int, direction = 'both')

summary(mod_F)
# summary(mod_F_int)

# Curiosità: Quanti parametri per modello
length(coef(mod_G))
length(coef(mod_D))
length(coef(mod_M))
length(coef(mod_F))

#################
## DIAGNOSTICA ##
#################

# Saltiamo per ora

# Una volta costruiti i modelli devo salvarli con saveRDS

saveRDS(mod_G, 'linear_model_G.rds')
saveRDS(mod_D, 'linear_model_D.rds')
saveRDS(mod_M, 'linear_model_M.rds')
saveRDS(mod_F, 'linear_model_F.rds')

