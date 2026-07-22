#################################
### DAL DATABASE AI DATAFRAME ###
#################################


################
### PORTIERI ###
################

rm(list=ls())
setwd("C:\\Users\\UTENTE\\Desktop\\Code")

library(DBI)
library(RSQLite)

###############################
### CONNESSIONE AL DATABASE ### 
###############################

path <- "sofascore_data.db"
db <- dbConnect(RSQLite::SQLite(), path)


# Estriamo i dati per i portieri

stat_port <- dbGetQuery(db,
           'SELECT * 
           FROM Statistiche AS s, Giocatori AS g, Partite AS p
           WHERE s.id_player = g.ID_PLAYER AND s.id_match = p.ID_match
                 AND valutazione is not NULL AND minutesPlayed >= 15 AND id_ruolo = "G"')

dbDisconnect(db) # Disconnettiamoci dal Db

########################
### PULIZIA DEI DATI ###
########################

# 1. Creiamo una nuova variabile esito
     # Assume solo 3 valori W = Win
                          # L = Lose
                          # D = Draw

stat_port$risultato <- ifelse(stat_port$id_esito == 'D', 'D',
       ifelse(stat_port$id_esito == 'H', ifelse(
         stat_port$id_squadra == stat_port$squadra_casa, "W", "L"
       ), ifelse(stat_port$id_squadra == stat_port$squadra_casa, "L", "W")))

stat_port$risultato <- as.factor(stat_port$risultato)

# Eliminiamo le variabili inutili (i vari id, i nomi, ...)
raw_data_G <- subset(stat_port,
                   select = setdiff(names(stat_port),
                                    c("id_match","id_player", "ratingVersions_original",
                                      "ratingVersions_alternative", "topSpeed",
                                      "ID_PLAYER", "nome","id_ruolo","id_squadra","ID_MATCH",
                                      "squadra_casa","squadra_trasferta","id_esito")))

# Eliminiamo dal dataset anche le variabili con varianza pari a 0 

raw_data_G <- raw_data_G[,-which(diag(var(raw_data_G[,-81])) == 0)]

# Eliminiamo anche quelle statistiche che non sono interpretabili
# ovvero dati aggregati che non sappiamo come sono stati calcolati

raw_data_G <- subset(raw_data_G,
                   select = setdiff(names(raw_data_G),
                                    c("goalkeeperValueNormalized","passValueNormalized",
                                      "keeperSaveValue", "dribbleValueNormalized",
                                      "defensiveValueNormalized")))

# Modifichiamo in percentuali le variabili che indicano la precisione
raw_data_G$possessionLostCtrl <- raw_data_G$possessionLostCtrl / raw_data_G$touches

raw_data_G$accurateOppositionHalfPasses <- raw_data_G$accurateOppositionHalfPasses/raw_data_G$totalOppositionHalfPasses

raw_data_G$unsuccessfulTouch <- raw_data_G$unsuccessfulTouch / raw_data_G$touches

raw_data_G$accurateLongBalls <- raw_data_G$accurateLongBalls / raw_data_G$totalLongBalls

raw_data_G$accurateOwnHalfPasses <- raw_data_G$accurateOwnHalfPasses / raw_data_G$totalOwnHalfPasses

raw_data_G$accuratePass <- raw_data_G$accuratePass / raw_data_G$totalPass


# Rimuoviamo le righe che presentano dei valori mancanti
  # I valori NA sono dati da degli zeri al denominatore introdutti dalle
  # precedenti divisioni

raw_data_G <- na.omit(raw_data_G)

# Salviamo il dataframe
saveRDS(raw_data_G, file='Data_G.rds') # per usarlo poi #readRDS


#####################################################################
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- 
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- 
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- 
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- 
#####################################################################

#################
### DIFENSORI ###
#################

rm(list=ls())

###############################
### CONNESSIONE AL DATABASE ### 
###############################

path <- "sofascore_data.db"
db <- dbConnect(RSQLite::SQLite(), path)

# Estraiamo i dati
stat_dif <- dbGetQuery(db,
                       'SELECT * 
           FROM Statistiche AS s, Giocatori AS g, Partite AS p
           WHERE s.id_player = g.ID_PLAYER AND s.id_match = p.ID_match
                 AND valutazione is not NULL AND minutesPlayed >= 15 AND id_ruolo = "D"')

dbDisconnect(db) # Disconnettiamoci dal DB

########################
### PULIZIA DEI DATI ###
########################

# 1. Creiamo una nuova variabile esito
# Assume solo 3 valori W = Win
# L = Lose
# D = Draw

stat_dif$risultato <- ifelse(stat_dif$id_esito == 'D', 'D',
                             ifelse(stat_dif$id_esito == 'H', ifelse(
                               stat_dif$id_squadra == stat_dif$squadra_casa, "W", "L"
                             ), ifelse(stat_dif$id_squadra == stat_dif$squadra_casa, "L", "W")))

stat_dif$risultato <- as.factor(stat_dif$risultato)

# Eliminiamo le variabili inutili (i vari id, i nomi, ...)
raw_data_D <- subset(stat_dif,
                     select = setdiff(names(stat_dif),
                                      c("id_match","id_player", "ratingVersions_original",
                                        "ratingVersions_alternative","ID_PLAYER",
                                        "nome","id_ruolo","id_squadra","ID_MATCH",
                                        "squadra_casa","squadra_trasferta","id_esito",
                                        "penaltyFaced")))

# Eliminiamo dal dataset anche le variabili con varianza pari a 0 

raw_data_D <- raw_data_D[,-which(diag(var(raw_data_D[,-81])) == 0)]
# Notiamo che sono tutte variabili riferite ai portieri

# Eliminiamo anche quelle statistiche che non sono interpretabili
# ovvero dati aggregati che non sappiamo come sono stati calcolati

raw_data_D <- subset(raw_data_D,
                     select = setdiff(names(raw_data_D),
                                      c("passValueNormalized","dribbleValueNormalized",
                                        "defensiveValueNormalized", "shotValueNormalized")))

# Modifichiamo in percentuali le variabili che indicano la precisione

raw_data_D$possessionLostCtrl <- raw_data_D$possessionLostCtrl / raw_data_D$touches

raw_data_D$accurateOppositionHalfPasses <- raw_data_D$accurateOppositionHalfPasses / raw_data_D$totalOppositionHalfPasses

# Creiamo la variabile totalDuel al posto di duelLost
raw_data_D$duelLost <- raw_data_D$duelLost + raw_data_D$duelWon

names(raw_data_D)[which(names(raw_data_D) == 'duelLost')] <- 'totalDuel'

# Modifichiamo duelWon in %
raw_data_D$duelWon <- raw_data_D$duelWon / raw_data_D$totalDuel

raw_data_D$unsuccessfulTouch <- raw_data_D$unsuccessfulTouch / raw_data_D$touches

raw_data_D$dispossessed <- raw_data_D$dispossessed / raw_data_D$touches

raw_data_D$accurateOwnHalfPasses <- raw_data_D$accurateOwnHalfPasses / raw_data_D$totalOwnHalfPasses

raw_data_D$accuratePass <- raw_data_D$accuratePass / raw_data_D$totalPass


# Rimuoviamo le righe che presentano dei valori mancanti
# I valori NA sono dati da degli zeri al denominatore introdutti dalle
# precedenti divisioni

raw_data_D <- na.omit(raw_data_D)

# Salviamo il dataframe
saveRDS(raw_data_D, file='Data_D.rds') # per usarlo poi #readRDS

# --> Ha senso tenere la variabile topSpeed?????


#####################################################################
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- 
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- 
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- 
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- 
#####################################################################

##################
### ATTACCANTI ###
##################

rm(list=ls())

###############################
### CONNESSIONE AL DATABASE ### 
###############################

path <- "sofascore_data.db"
db <- dbConnect(RSQLite::SQLite(), path)

# Estraiamo i dati
stat_att <- dbGetQuery(db,
                       'SELECT * 
           FROM Statistiche AS s, Giocatori AS g, Partite AS p
           WHERE s.id_player = g.ID_PLAYER AND s.id_match = p.ID_match
                 AND valutazione is not NULL AND minutesPlayed >= 15 AND id_ruolo = "F"')

dbDisconnect(db)  #Disconnessione dal DB

########################
### PULIZIA DEI DATI ###
########################

# 1. Creiamo una nuova variabile esito
# Assume solo 3 valori W = Win
# L = Lose
# D = Draw

stat_att$risultato <- ifelse(stat_att$id_esito == 'D', 'D',
                             ifelse(stat_att$id_esito == 'H', ifelse(
                               stat_att$id_squadra == stat_att$squadra_casa, "W", "L"
                             ), ifelse(stat_att$id_squadra == stat_att$squadra_casa, "L", "W")))

stat_att$risultato <- as.factor(stat_att$risultato)

# Eliminiamo le variabili inutili (i vari id, i nomi, ...)
raw_data_A <- subset(stat_att,
                     select = setdiff(names(stat_att),
                                      c("id_match","id_player", "ratingVersions_original",
                                        "ratingVersions_alternative","ID_PLAYER",
                                        "nome","id_ruolo","id_squadra","ID_MATCH",
                                        "squadra_casa","squadra_trasferta","id_esito",
                                        "penaltyFaced")))

# Eliminiamo dal dataset anche le variabili con varianza pari a 0 

raw_data_A <- raw_data_A[,-which(diag(var(raw_data_A[,-81])) == 0)]
# Notiamo che sono tutte variabili riferite ai portieri

# Eliminiamo anche quelle statistiche che non sono interpretabili
# ovvero dati aggregati che non sono come sono stati calcolati

raw_data_A <- subset(raw_data_A,
                     select = setdiff(names(raw_data_A),
                                      c("passValueNormalized","dribbleValueNormalized",
                                        "defensiveValueNormalized", "shotValueNormalized")))

# Modifichiamo in percentuali le variabili che indicano la precisione

raw_data_A$possessionLostCtrl <- raw_data_A$possessionLostCtrl / raw_data_A$touches

raw_data_A$accurateOppositionHalfPasses <- raw_data_A$accurateOppositionHalfPasses / raw_data_A$totalOppositionHalfPasses

# Creiamo la variabile totalDuel al posto di duelLost
raw_data_A$duelLost <- raw_data_A$duelLost + raw_data_A$duelWon

names(raw_data_A)[which(names(raw_data_A) == 'duelLost')] <- 'totalDuel'

# Modifichiamo duelWon in %
raw_data_A$duelWon <- raw_data_A$duelWon / raw_data_A$totalDuel

raw_data_A$unsuccessfulTouch <- raw_data_A$unsuccessfulTouch / raw_data_A$touches

raw_data_A$dispossessed <- raw_data_A$dispossessed / raw_data_A$touches

raw_data_A$accuratePass <- raw_data_A$accuratePass / raw_data_A$totalPass

# Rimuoviamo le righe che presentano dei valori mancanti
# I valori NA sono dati da degli zeri al denominatore introdutti dalle
# precedenti divisioni

raw_data_A <- na.omit(raw_data_A)

# Salviamo il dataframe
saveRDS(raw_data_A, file='Data_F.rds') # per usarlo poi #readRDS


# --> Ha senso tenere la variabile topSpeed?????


#####################################################################
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- 
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- 
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- 
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- 
#####################################################################

######################
### CENTROCAMPISTI ###
######################

rm(list=ls())

###############################
### CONNESSIONE AL DATABASE ### 
###############################

path <- "sofascore_data.db"
db <- dbConnect(RSQLite::SQLite(), path)

# Estraiamo i dati

stat_cen <- dbGetQuery(db,
                       'SELECT * 
           FROM Statistiche AS s, Giocatori AS g, Partite AS p
           WHERE s.id_player = g.ID_PLAYER AND s.id_match = p.ID_match
                 AND valutazione is not NULL AND minutesPlayed >= 15 AND id_ruolo = "M"')

dbDisconnect(db) # Disconnessione dal Db
 
########################
### PULIZIA DEI DATI ###
########################

# 1. Creiamo una nuova variabile esito
# Assume solo 3 valori W = Win
# L = Lose
# D = Draw

stat_cen$risultato <- ifelse(stat_cen$id_esito == 'D', 'D',
                             ifelse(stat_cen$id_esito == 'H', ifelse(
                               stat_cen$id_squadra == stat_cen$squadra_casa, "W", "L"
                             ), ifelse(stat_cen$id_squadra == stat_cen$squadra_casa, "L", "W")))



stat_cen$risultato <- as.factor(stat_cen$risultato)

# Eliminiamo le variabili inutili (i vari id, i nomi, ...)
raw_data_C <- subset(stat_cen,
                     select = setdiff(names(stat_cen),
                                      c("id_match","id_player", "ratingVersions_original",
                                        "ratingVersions_alternative","ID_PLAYER",
                                        "nome","id_ruolo","id_squadra","ID_MATCH",
                                        "squadra_casa","squadra_trasferta","id_esito",
                                        "penaltyFaced")))

# Eliminiamo dal dataset anche le variabili con varianza pari a 0 

raw_data_C <- raw_data_C[,-which(diag(var(raw_data_C[,-81])) == 0)]
# Notiamo che sono tutte variabili riferite ai portieri

# Eliminiamo anche quelle statistiche che non sono interpretabili
# ovvero dati aggregati che non sono come sono stati calcolati

raw_data_C <- subset(raw_data_C,
                     select = setdiff(names(raw_data_C),
                                      c("passValueNormalized","dribbleValueNormalized",
                                        "defensiveValueNormalized", "shotValueNormalized")))

# Modifichiamo in percentuali le variabili che indicano la precisione

raw_data_C$possessionLostCtrl <- raw_data_C$possessionLostCtrl / raw_data_C$touches

raw_data_C$accurateOppositionHalfPasses <- raw_data_C$accurateOppositionHalfPasses / raw_data_C$totalOppositionHalfPasses 

# Creiamo la variabile totalDuel al posto di duelLost
raw_data_C$duelLost <- raw_data_C$duelLost + raw_data_C$duelWon

names(raw_data_C)[which(names(raw_data_C) == 'duelLost')] <- 'totalDuel'

# Modifichiamo duelWon in %
raw_data_C$duelWon <- raw_data_C$duelWon / raw_data_C$totalDuel

raw_data_C$unsuccessfulTouch <- raw_data_C$unsuccessfulTouch / raw_data_C$touches

raw_data_C$dispossessed <- raw_data_C$dispossessed / raw_data_C$touches

raw_data_C$accurateOwnHalfPasses <- raw_data_C$accurateOwnHalfPasses / raw_data_C$totalOwnHalfPasses

raw_data_C$accuratePass <- raw_data_C$accuratePass / raw_data_C$totalPass


# Rimuoviamo le righe che presentano dei valori mancanti
# I valori NA sono dati da degli zeri al denominatore introdutti dalle
# precedenti divisioni

raw_data_C <- na.omit(raw_data_C)

# Salviamo il dataframe
saveRDS(raw_data_C, file='Data_M.rds') # per usarlo poi #readRDS


# --> Ha senso tenere la variabile topSpeed????