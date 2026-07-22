######################
### LOGISTIC MODEL ###
######################
setwd("C:\\Users\\UTENTE\\Desktop\\Code")
rm(list=ls())

data_G <- readRDS('Data_G.rds')
data_D <- readRDS('Data_D.rds')
data_M <- readRDS('Data_M.rds')
data_F <- readRDS('Data_F.rds')


###############################
### PRIMO APPROCCIO : ESITO ###
###############################

# PORTIERI
set_G <- data_G[,-1]
set_G$risultato <- ifelse(set_G$risultato == "W", 1, 0)

mod_pieno_G <- glm(risultato ~ ., data = set_G, family = binomial())

mod_G <- step(mod_pieno_G, direction = 'both')

summary(mod_G) 



# DIFENSORI
set_D <- data_D[,-1]
set_D$risultato <- ifelse(set_D$risultato == "W", 1, 0)

mod_pieno_D <- glm(risultato ~ ., data = set_D, family = binomial())

mod_D <- step(mod_pieno_D, direction = 'both')

summary(mod_D) 


# CENTROCAMPISTI
set_M <- data_M[,-1]
set_M$risultato <- ifelse(set_M$risultato == "W", 1, 0)

mod_pieno_M <- glm(risultato ~ ., data = set_M, family = binomial())

mod_M <- step(mod_pieno_M, direction = 'both')

summary(mod_M) 


# ATTACCANTI
set_F <- data_F[,-1]
set_F$risultato <- ifelse(set_F$risultato == "W", 1, 0)

mod_pieno_F <- glm(risultato ~ ., data = set_F, family = binomial())

mod_F <- step(mod_pieno_F, direction = 'both')

summary(mod_F) 

########################################
### SECONDO  APPROCCIO : VALUTAZIONE ###
########################################
# --> Scartato

# PORTIERI
# Trasformiamo la valutazione in una variabile binaria
#dG <- data_G 

# dG$valutazione <- ifelse(dG$valutazione >= 7.5, 1, 0)

# Calcoliamo il modello

# mod_pieno_G1 <- glm(valutazione ~ ., data=dG, family = binomial())

# mod_G1 <- step(mod_pieno_G1, direction='both')

# summary(mod_G1)

# Le variabili considerate non mi sembrano le più adatte per valutare un portiere


# DIFENSORI

# Trasformiamo la valutazione in una variabile binaria
# dD <- data_D 

# dD$valutazione <- ifelse(dD$valutazione >= 7.5, 1, 0)

# Calcoliamo il modello

# mod_pieno_D1 <- glm(valutazione ~ ., data=dD, family = binomial())

# mod_D1 <- step(mod_pieno_D1, direction='both')

# summary(mod_D1)


# CENTROCAMPISTI
# Trasformiamo la valutazione in una variabile binaria
# dM <- data_M 

# dM$valutazione <- ifelse(dM$valutazione >= 7.5, 1, 0)

# Calcoliamo il modello

# mod_pieno_M1 <- glm(valutazione ~ ., data=dM, family = binomial())

# mod_M1 <- step(mod_pieno_M1, direction='both')

# summary(mod_M1)



# ATTACCANTI
# Trasformiamo la valutazione in una variabile binaria
# dF <- data_F

# dF$valutazione <- ifelse(dF$valutazione >= 7.5, 1, 0)

# Calcoliamo il modello

# mod_pieno_F1 <- glm(valutazione ~ ., data=dF, family = binomial())

# mod_F1 <- step(mod_pieno_F1, direction='both')

# summary(mod_F1)


##############
### OUTPUT ###
##############

saveRDS(mod_G, file='logistic_model_G.rds')
saveRDS(mod_D, file='logistic_model_D.rds')
saveRDS(mod_M, file="logistic_model_M.rds")
saveRDS(mod_F, file="logistic_model_F.rds")
