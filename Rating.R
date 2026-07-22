#########################
### FROM DB TO RATING ###
#########################

rm(list=ls())
setwd("C:\\Users\\UTENTE\\Desktop\\Code")

library(DBI)
library(RSQLite)

###############################
### CONNESSIONE AL DATABASE ### 
###############################

path <- "sofascore_data.db"
db <- dbConnect(RSQLite::SQLite(), path)

# ESTRAZIONE DEI DATI

new_data_G <- dbGetQuery(db,
                        'SELECT * 
                         FROM nuovi_dati   
                         WHERE valutazione is not NULL AND minutesPlayed >= 15 
                         AND ruolo = "G"')
new_data_D <- dbGetQuery(db,
                         'SELECT * 
                         FROM nuovi_dati   
                         WHERE valutazione is not NULL AND minutesPlayed >= 15 
                         AND ruolo = "D"')

new_data_M <- dbGetQuery(db,
                         'SELECT * 
                         FROM nuovi_dati   
                         WHERE valutazione is not NULL AND minutesPlayed >= 15 
                         AND ruolo = "M"')

new_data_F <- dbGetQuery(db,
                         'SELECT * 
                         FROM nuovi_dati   
                         WHERE valutazione is not NULL AND minutesPlayed >= 15 
                         AND ruolo = "F"')

dbDisconnect(db) # Disconnettiamoci dal Db

######################
## PULIZIA DEI DATI ##
######################

# CAMBIO STRUTTURA DATI
new_data_G$risultato <- as.factor(new_data_G$risultato)
new_data_D$risultato <- as.factor(new_data_D$risultato)
new_data_M$risultato <- as.factor(new_data_M$risultato)
new_data_F$risultato <- as.factor(new_data_F$risultato)

# CAMBIO NOME RIGHE
rownames(new_data_G) <- new_data_G$nome_giocatore
rownames(new_data_D) <- new_data_D$nome_giocatore
rownames(new_data_M) <- new_data_M$nome_giocatore
rownames(new_data_F) <- new_data_F$nome_giocatore

# TRASFORMO LE VARIABILI
## Portieri
new_data_G$possessionLostCtrl <- ifelse(new_data_G$touches == 0,0,new_data_G$possessionLostCtrl / new_data_G$touches)
new_data_G$accurateOppositionHalfPasses <- ifelse(new_data_G$totalOppositionHalfPasses == 0,0,
                                                  new_data_G$accurateOppositionHalfPasses/new_data_G$totalOppositionHalfPasses)
new_data_G$unsuccessfulTouch <- ifelse(new_data_G$touches == 0,0,new_data_G$unsuccessfulTouch / new_data_G$touches)
new_data_G$accurateLongBalls <- ifelse(new_data_G$totalLongBalls == 0,0,new_data_G$accurateLongBalls / new_data_G$totalLongBalls)
new_data_G$accurateOwnHalfPasses <- ifelse(new_data_G$totalOwnHalfPasses,0,new_data_G$accurateOwnHalfPasses / new_data_G$totalOwnHalfPasses)
new_data_G$accuratePass <- ifelse(new_data_G$totalPass,0,new_data_G$accuratePass / new_data_G$totalPass)


## Difensori
new_data_D$possessionLostCtrl <- ifelse(new_data_D$touches == 0,0,new_data_D$possessionLostCtrl / new_data_D$touches)
new_data_D$accurateOppositionHalfPasses <- ifelse(new_data_D$totalOppositionHalfPasses == 0,0,new_data_D$accurateOppositionHalfPasses / new_data_D$totalOppositionHalfPasses)
# Creiamo la variabile totalDuel al posto di duelLost
new_data_D$duelLost <- new_data_D$duelLost + new_data_D$duelWon
names(new_data_D)[which(names(new_data_D) == 'duelLost')] <- 'totalDuel'
# Modifichiamo duelWon in %
new_data_D$duelWon <- ifelse(new_data_D$totalDuel == 0,0,new_data_D$duelWon / new_data_D$totalDuel)
new_data_D$unsuccessfulTouch <- ifelse(new_data_D$touches == 0,0,new_data_D$unsuccessfulTouch / new_data_D$touches)
new_data_D$dispossessed <- ifelse(new_data_D$touches == 0,0,new_data_D$dispossessed / new_data_D$touches)
new_data_D$accurateOwnHalfPasses <- ifelse(new_data_D$totalOwnHalfPasses == 0,0,new_data_D$accurateOwnHalfPasses / new_data_D$totalOwnHalfPasses)
new_data_D$accuratePass <- ifelse(new_data_D$totalPass == 0,0,new_data_D$accuratePass / new_data_D$totalPass)


## Centrocampsiti
new_data_M$possessionLostCtrl <- ifelse(new_data_M$touches == 0,0,new_data_M$possessionLostCtrl / new_data_M$touches)
new_data_M$accurateOppositionHalfPasses <- ifelse(new_data_M$totalOppositionHalfPasses == 0,0,new_data_M$accurateOppositionHalfPasses / new_data_M$totalOppositionHalfPasses)
# Creiamo la variabile totalDuel al posto di duelLost
new_data_M$duelLost <- new_data_M$duelLost + new_data_M$duelWon
names(new_data_M)[which(names(new_data_M) == 'duelLost')] <- 'totalDuel'
# Modifichiamo duelWon in %
new_data_M$duelWon <- ifelse(new_data_M$totalDuel == 0,0,new_data_M$duelWon / new_data_M$totalDuel)
new_data_M$unsuccessfulTouch <- ifelse(new_data_M$touches == 0,0,new_data_M$unsuccessfulTouch / new_data_M$touches)
new_data_M$dispossessed <- ifelse(new_data_M$touches == 0,0,new_data_M$dispossessed / new_data_M$touches)
new_data_M$accurateOwnHalfPasses <- ifelse(new_data_M$totalOwnHalfPasses == 0,0,new_data_M$accurateOwnHalfPasses / new_data_M$totalOwnHalfPasses)
new_data_M$accuratePass <- ifelse(new_data_M$totalPass == 0,0,new_data_M$accuratePass / new_data_M$totalPass)


## Attaccanti
new_data_F$possessionLostCtrl <- ifelse(new_data_F$touches == 0,0,new_data_F$possessionLostCtrl / new_data_F$touches)
new_data_F$accurateOppositionHalfPasses <- ifelse(new_data_F$totalOppositionHalfPasses == 0,0,new_data_F$accurateOppositionHalfPasses / new_data_F$totalOppositionHalfPasses)
# Creiamo la variabile totalDuel al posto di duelLost
new_data_F$duelLost <- new_data_F$duelLost + new_data_F$duelWon
names(new_data_F)[which(names(new_data_F) == 'duelLost')] <- 'totalDuel'
# Modifichiamo duelWon in %
new_data_F$duelWon <- ifelse(new_data_F$totalDuel == 0,0,new_data_F$duelWon / new_data_F$totalDuel)
new_data_F$unsuccessfulTouch <- ifelse(new_data_F$touches == 0,0,new_data_F$unsuccessfulTouch / new_data_F$touches)
new_data_F$dispossessed <- ifelse(new_data_F$touches == 0,0,new_data_F$dispossessed / new_data_F$touches)
new_data_F$accuratePass <- ifelse(new_data_F$totalPass == 0,0,new_data_F$accuratePass / new_data_F$totalPass)

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


# RICAVIAMO I DATASET DA USARE PER I MODELLI
## Regressione Lineare
data_predict_lmG <- subset(new_data_G,
                           select = (names(new_data_G) %in% names(coef(linMod_G))) | 
                             names(new_data_G) == "risultato")

data_predict_lmD <- subset(new_data_D,
       select = (names(new_data_D) %in% names(coef(linMod_D))) | 
                                               names(new_data_D) == "risultato")

data_predict_lmM <- subset(new_data_M,
                           select = (names(new_data_M) %in% names(coef(linMod_M))) | 
                             names(new_data_M) == "risultato")

data_predict_lmF <- subset(new_data_F,
                           select = (names(new_data_F) %in% names(coef(linMod_F))) | 
                             names(new_data_F) == "risultato")

## Regressione Logistica
data_predict_logG <- subset(new_data_G,
                            select = (names(new_data_G) %in% names(coef(logMod_G))) | 
                              names(new_data_G) == "risultato")
data_predict_logD <- subset(new_data_D,
                            select = (names(new_data_D) %in% names(coef(logMod_D))) | 
                              names(new_data_D) == "risultato")
data_predict_logM <- subset(new_data_M,
                            select = (names(new_data_M) %in% names(coef(logMod_M))) | 
                              names(new_data_M) == "risultato")
data_predict_logF <- subset(new_data_F,
                           select = (names(new_data_M) %in% names(coef(logMod_M))) | 
                             names(new_data_M) == "risultato")

# Trasformiamo il risultato in binario
data_predict_logG$risultato <- ifelse(data_predict_logG$risultato == "W", 1, 0)
data_predict_logD$risultato <- ifelse(data_predict_logD$risultato == "W", 1, 0)
data_predict_logM$risultato <- ifelse(data_predict_logM$risultato == "W", 1, 0)
data_predict_logF$risultato <- ifelse(data_predict_logF$risultato == "W", 1, 0)


#################
## VALUTAZIONI ##
#################

## Regressione Lineare 
G_lm_vote <- predict(linMod_G, newdata = data_predict_lmG)
D_lm_vote <- predict(linMod_D, newdata = data_predict_lmD)
M_lm_vote <- predict(linMod_M, newdata = data_predict_lmM)
F_lm_vote <- predict(linMod_F, newdata = data_predict_lmF)


## Regressione Logistica
df_mean_var <- readRDS('mean_and_var_LogVote.rds') 

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
voti_G <- rowSums(coef(logMod_G) * data_predict_logG)
G_log_vote <- 6 + ((voti_G - muG)/sdG) * 2
G_log_vote <- ifelse(G_log_vote < 0, 0, ifelse(G_log_vote > 10, 10, G_log_vote))

summary(G_log_vote)

# Voti Difensori
voti_D <- rowSums(coef(logMod_D) * data_predict_logD)
D_log_vote <- 6 + ((voti_D - muD)/sdD) * 2
D_log_vote <- ifelse(D_log_vote < 0, 0, ifelse(D_log_vote > 10, 10, D_log_vote))

summary(D_log_vote)

# Voti Centrocampisti
voti_M <- rowSums(coef(logMod_M) * data_predict_logM)
M_log_vote <- 6 + ((voti_M - muM)/sdM) * 2
M_log_vote <- ifelse(M_log_vote < 0, 0, ifelse(M_log_vote > 10, 10, M_log_vote))

summary(M_log_vote)

# Voti Attaccanti
voti_F <- rowSums(coef(logMod_F) * data_predict_logF)
F_log_vote <- 6 + ((voti_F - muF)/sdF) * 2
F_log_vote <- ifelse(F_log_vote < 0, 0, ifelse(F_log_vote > 10, 10, F_log_vote))

summary(F_log_vote)



###################
### VALUTAZIONI ###
###################
final_rating <- cbind(cbind(c(G_lm_vote, D_lm_vote, M_lm_vote, F_lm_vote)),
      cbind(c(G_log_vote, D_log_vote, M_log_vote, F_log_vote)))

colnames(final_rating) <- c("Regressione Lineare",
                            "Regressione Logistica")
round(final_rating,2)
