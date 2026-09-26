############
### TEST ###
############

#########################
### FROM DB TO RATING ###
#########################

rm(list=ls())

library(DBI)
library(RSQLite)
library(glmnet)

###############################
### CONNESSIONE AL DATABASE ### 
###############################

path <- "sofascore_data.db"
db <- dbConnect(RSQLite::SQLite(), path)

# ESTRAZIONE DEI DATI

test_G <- dbGetQuery(db,
                         'SELECT * 
                         FROM test   
                         WHERE valutazione is not NULL AND minutesPlayed >= 15 
                         AND ruolo = "G"')
test_D <- dbGetQuery(db,
                         'SELECT * 
                         FROM test   
                         WHERE valutazione is not NULL AND minutesPlayed >= 15 
                         AND ruolo = "D"')

test_M <- dbGetQuery(db,
                         'SELECT * 
                         FROM test   
                         WHERE valutazione is not NULL AND minutesPlayed >= 15 
                         AND ruolo = "M"')

test_F <- dbGetQuery(db,
                         'SELECT * 
                         FROM test   
                         WHERE valutazione is not NULL AND minutesPlayed >= 15 
                         AND ruolo = "F"')

dbDisconnect(db) # Disconnettiamoci dal Db

######################
## PULIZIA DEI DATI ##
######################

# CAMBIO STRUTTURA DATI
test_G$risultato <- as.factor(test_G$risultato)
test_D$risultato <- as.factor(test_D$risultato)
test_M$risultato <- as.factor(test_M$risultato)
test_F$risultato <- as.factor(test_F$risultato)

# TRASFORMO LE VARIABILI
## Portieri
test_G$possessionLostCtrl <- ifelse(test_G$touches == 0,0,test_G$possessionLostCtrl / test_G$touches)
test_G$accurateOppositionHalfPasses <- ifelse(test_G$totalOppositionHalfPasses == 0,0,
                                                  test_G$accurateOppositionHalfPasses/test_G$totalOppositionHalfPasses)
test_G$unsuccessfulTouch <- ifelse(test_G$touches == 0,0,test_G$unsuccessfulTouch / test_G$touches)
test_G$accurateLongBalls <- ifelse(test_G$totalLongBalls == 0,0,test_G$accurateLongBalls / test_G$totalLongBalls)
test_G$accurateOwnHalfPasses <- ifelse(test_G$totalOwnHalfPasses,0,test_G$accurateOwnHalfPasses / test_G$totalOwnHalfPasses)
test_G$accuratePass <- ifelse(test_G$totalPass,0,test_G$accuratePass / test_G$totalPass)


## Difensori
test_D$possessionLostCtrl <- ifelse(test_D$touches == 0,0,test_D$possessionLostCtrl / test_D$touches)
test_D$accurateOppositionHalfPasses <- ifelse(test_D$totalOppositionHalfPasses == 0,0,test_D$accurateOppositionHalfPasses / test_D$totalOppositionHalfPasses)
# Creiamo la variabile totalDuel al posto di duelLost
test_D$duelLost <- test_D$duelLost + test_D$duelWon
names(test_D)[which(names(test_D) == 'duelLost')] <- 'totalDuel'
# Modifichiamo duelWon in %
test_D$duelWon <- ifelse(test_D$totalDuel == 0,0,test_D$duelWon / test_D$totalDuel)
test_D$unsuccessfulTouch <- ifelse(test_D$touches == 0,0,test_D$unsuccessfulTouch / test_D$touches)
test_D$dispossessed <- ifelse(test_D$touches == 0,0,test_D$dispossessed / test_D$touches)
test_D$accurateOwnHalfPasses <- ifelse(test_D$totalOwnHalfPasses == 0,0,test_D$accurateOwnHalfPasses / test_D$totalOwnHalfPasses)
test_D$accuratePass <- ifelse(test_D$totalPass == 0,0,test_D$accuratePass / test_D$totalPass)


## Centrocampsiti
test_M$possessionLostCtrl <- ifelse(test_M$touches == 0,0,test_M$possessionLostCtrl / test_M$touches)
test_M$accurateOppositionHalfPasses <- ifelse(test_M$totalOppositionHalfPasses == 0,0,test_M$accurateOppositionHalfPasses / test_M$totalOppositionHalfPasses)
# Creiamo la variabile totalDuel al posto di duelLost
test_M$duelLost <- test_M$duelLost + test_M$duelWon
names(test_M)[which(names(test_M) == 'duelLost')] <- 'totalDuel'
# Modifichiamo duelWon in %
test_M$duelWon <- ifelse(test_M$totalDuel == 0,0,test_M$duelWon / test_M$totalDuel)
test_M$unsuccessfulTouch <- ifelse(test_M$touches == 0,0,test_M$unsuccessfulTouch / test_M$touches)
test_M$dispossessed <- ifelse(test_M$touches == 0,0,test_M$dispossessed / test_M$touches)
test_M$accurateOwnHalfPasses <- ifelse(test_M$totalOwnHalfPasses == 0,0,test_M$accurateOwnHalfPasses / test_M$totalOwnHalfPasses)
test_M$accuratePass <- ifelse(test_M$totalPass == 0,0,test_M$accuratePass / test_M$totalPass)


## Attaccanti
test_F$possessionLostCtrl <- ifelse(test_F$touches == 0,0,test_F$possessionLostCtrl / test_F$touches)
test_F$accurateOppositionHalfPasses <- ifelse(test_F$totalOppositionHalfPasses == 0,0,test_F$accurateOppositionHalfPasses / test_F$totalOppositionHalfPasses)
# Creiamo la variabile totalDuel al posto di duelLost
test_F$duelLost <- test_F$duelLost + test_F$duelWon
names(test_F)[which(names(test_F) == 'duelLost')] <- 'totalDuel'
# Modifichiamo duelWon in %
test_F$duelWon <- ifelse(test_F$totalDuel == 0,0,test_F$duelWon / test_F$totalDuel)
test_F$unsuccessfulTouch <- ifelse(test_F$touches == 0,0,test_F$unsuccessfulTouch / test_F$touches)
test_F$dispossessed <- ifelse(test_F$touches == 0,0,test_F$dispossessed / test_F$touches)
test_F$accuratePass <- ifelse(test_F$totalPass == 0,0,test_F$accuratePass / test_F$totalPass)

#######################
## CARICHIAMO I DATI ##
#######################

# Modello di Regressione Lineare
linMod_G <- readRDS("R_data\\linear_model_G.rds")
linMod_D <- readRDS("R_data\\linear_model_D.rds")
linMod_M <- readRDS("R_data\\linear_model_M.rds")
linMod_F <- readRDS("R_data\\linear_model_F.rds")

# Modello di Regressione Logistica
logMod_G <- readRDS("R_data\\logistic_model_G.rds")
logMod_D <- readRDS("R_data\\logistic_model_D.rds")
logMod_M <- readRDS("R_data\\logistic_model_M.rds")
logMod_F <- readRDS("R_data\\logistic_model_F.rds")

# Modello di Regressione Ridge
ridge_g <- readRDS('R_data\\ridge_g.rds')
ridge_d <- readRDS('R_data\\ridge_d.rds')
ridge_m <- readRDS('R_data\\ridge_m.rds')
ridge_f <- readRDS('R_data\\ridge_f.rds')

train_terms_g <- readRDS("R_data\\train_terms_g.rds")
train_levels_g <- readRDS("R_data\\train_levels_g.rds")

train_terms_d <- readRDS("R_data\\train_terms_d.rds")
train_levels_d <- readRDS("R_data\\train_levels_d.rds")

train_terms_m <- readRDS("R_data\\train_terms_m.rds")
train_levels_m <- readRDS("R_data\\train_levels_m.rds")

train_terms_f <- readRDS("R_data\\train_terms_f.rds")
train_levels_f <- readRDS("R_data\\train_levels_f.rds")

# Modello di Regressione LASSO
lasso_g <- readRDS('lasso_g.rds')
lasso_d <- readRDS('lasso_d.rds')
lasso_m <- readRDS('lasso_m.rds')
lasso_f <- readRDS('lasso_f.rds')


# RICAVIAMO I DATASET DA USARE PER I MODELLI
## Regressione Logistica
data_predict_logG <- subset(test_G,
                            select = (names(test_G) %in% names(coef(logMod_G))) | 
                              names(test_G) == "risultato")
data_predict_logD <- subset(test_D,
                            select = (names(test_D) %in% names(coef(logMod_D))) | 
                              names(test_D) == "risultato")
data_predict_logM <- subset(test_M,
                            select = (names(test_M) %in% names(coef(logMod_M))) | 
                              names(test_M) == "risultato")
data_predict_logF <- subset(test_F,
                            select = (names(test_F) %in% names(coef(logMod_F))) | 
                              names(test_F) == "risultato")

# Trasformiamo il risultato in binario
data_predict_logG$risultato <- ifelse(data_predict_logG$risultato == "W", 1, 0)
data_predict_logD$risultato <- ifelse(data_predict_logD$risultato == "W", 1, 0)
data_predict_logM$risultato <- ifelse(data_predict_logM$risultato == "W", 1, 0)
data_predict_logF$risultato <- ifelse(data_predict_logF$risultato == "W", 1, 0)


## Regressione Ridge e LASSO

# Funzione helper: allinea i livelli dei fattori al training set e costruisce la matrice
build_shrink_matrix <- function(new_data, train_terms, train_levels) {
  for (col in names(train_levels)) {
    if (!is.null(train_levels[[col]]) && col %in% names(new_data)) {
      new_data[[col]] <- factor(new_data[[col]], levels = train_levels[[col]])
    }
  }
  model.matrix(train_terms, data = new_data)[, -1]  # tolgo l'intercetta come in training
}

# Costruiamo le matrici per ogni ruolo
X_new_g <- build_shrink_matrix(test_G, train_terms_g, train_levels_g)
X_new_d <- build_shrink_matrix(test_D, train_terms_d, train_levels_d)
X_new_m <- build_shrink_matrix(test_M, train_terms_m, train_levels_m)
X_new_f <- build_shrink_matrix(test_F, train_terms_f, train_levels_f)

#################
## VALUTAZIONI ##
#################

## Regressione Lineare 
G_lm_vote <- predict(linMod_G, newdata = test_G)
D_lm_vote <- predict(linMod_D, newdata = test_D)
M_lm_vote <- predict(linMod_M, newdata = test_M)
F_lm_vote <- predict(linMod_F, newdata = test_F)



## Regressione Logistica
## Regressione Logistica
df_mean_var <- readRDS('R_data\\mean_and_var_LogVote.rds') 

# Estraiamo medie e varianze
muG <- df_mean_var[1,1]
muD <- df_mean_var[2,1]
muM <- df_mean_var[3,1]
muF <- df_mean_var[4,1]

sdG <- df_mean_var[1,2]
sdD <- df_mean_var[2,2]
sdM <- df_mean_var[3,2]
sdF <- df_mean_var[4,2]


# Voti Portieri
voti_G <- predict(logMod_G, type='link')
G_log_vote <- 6 + ((voti_G - muG)/sdG) * 2
G_log_vote <- ifelse(G_log_vote < 0, 0, ifelse(G_log_vote > 10, 10, G_log_vote))

summary(G_log_vote)

# Voti Difensori
voti_D <- predict(logMod_D, type='link')
D_log_vote <- 6 + ((voti_D - muD)/sdD) * 2
D_log_vote <- ifelse(D_log_vote < 0, 0, ifelse(D_log_vote > 10, 10, D_log_vote))

summary(D_log_vote)

# Voti Centrocampisti
voti_M <- predict(logMod_M, type='link')
M_log_vote <- 6 + ((voti_M - muM)/sdM) * 2
M_log_vote <- ifelse(M_log_vote < 0, 0, ifelse(M_log_vote > 10, 10, M_log_vote))

summary(M_log_vote)

# Voti Attaccanti
voti_F <- predict(logMod_F, type='link')
F_log_vote <- 6 + ((voti_F - muF)/sdF) * 2
F_log_vote <- ifelse(F_log_vote < 0, 0, ifelse(F_log_vote > 10, 10, F_log_vote))

# Previsioni Ridge
G_ridge_vote <- as.vector(predict(ridge_g, newx = X_new_g, s = 'lambda.min'))
D_ridge_vote <- as.vector(predict(ridge_d, newx = X_new_d, s = 'lambda.min'))
M_ridge_vote <- as.vector(predict(ridge_m, newx = X_new_m, s = 'lambda.min'))
F_ridge_vote <- as.vector(predict(ridge_f, newx = X_new_f, s = 'lambda.min'))

# Previsioni LASSO
G_lasso_vote <- as.vector(predict(lasso_g, newx = X_new_g, s = 'lambda.min'))
D_lasso_vote <- as.vector(predict(lasso_d, newx = X_new_d, s = 'lambda.min'))
M_lasso_vote <- as.vector(predict(lasso_m, newx = X_new_m, s = 'lambda.min'))
F_lasso_vote <- as.vector(predict(lasso_f, newx = X_new_f, s = 'lambda.min'))

###########
### MSE ###
###########

mean((test_G$valutazione - G_lm_vote)^2)
mean((test_D$valutazione - D_lm_vote)^2)
mean((test_M$valutazione - M_lm_vote)^2)
mean((test_F$valutazione - F_lm_vote)^2)

mean((test_G$valutazione - G_ridge_vote)^2)
mean((test_D$valutazione - D_ridge_vote)^2)
mean((test_M$valutazione - M_ridge_vote)^2)
mean((test_F$valutazione - F_ridge_vote)^2)

mean((test_G$valutazione - G_lasso_vote)^2)
mean((test_D$valutazione - D_lasso_vote)^2)
mean((test_M$valutazione - M_lasso_vote)^2)
mean((test_F$valutazione - F_lasso_vote)^2)

mean((test_G$valutazione - G_log_vote)^2)
mean((test_D$valutazione - D_log_vote)^2)
mean((test_M$valutazione - M_log_vote)^2)
mean((test_F$valutazione - F_log_vote)^2)

MSE <- round(cbind(rbind(mean((test_G$valutazione - G_lm_vote)^2),
  mean((test_D$valutazione - D_lm_vote)^2),
  mean((test_M$valutazione - M_lm_vote)^2),
  mean((test_F$valutazione - F_lm_vote)^2)),
  
  rbind(mean((test_G$valutazione - G_ridge_vote)^2),
        mean((test_D$valutazione - D_ridge_vote)^2),
        mean((test_M$valutazione - M_ridge_vote)^2),
        mean((test_F$valutazione - F_ridge_vote)^2)),
  
  rbind(mean((test_G$valutazione - G_lasso_vote)^2),
        mean((test_D$valutazione - D_lasso_vote)^2),
        mean((test_M$valutazione - M_lasso_vote)^2),
        mean((test_F$valutazione - F_lasso_vote)^2)),
  
  rbind(mean((test_G$valutazione - G_log_vote)^2),
        mean((test_D$valutazione - D_log_vote)^2),
        mean((test_M$valutazione - M_log_vote)^2),
        mean((test_F$valutazione - F_log_vote)^2))
),4)

rownames(MSE) <- c("G", "D", "M", "F")
colnames(MSE) <- c("linear model", "ridge", "lasso", "logistic")
MSE
