#########################
### FROM DB TO RATING ###
#########################

rm(list=ls())
setwd("C:\\Users\\UTENTE\\Desktop\\Code")

library(DBI)
library(RSQLite)
library(glmnet)

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

# Modello di Regressione Ridge
ridge_g <- readRDS('ridge_g.rds')
ridge_d <- readRDS('ridge_d.rds')
ridge_m <- readRDS('ridge_m.rds')
ridge_f <- readRDS('ridge_f.rds')

train_terms_g <- readRDS("train_terms_g.rds")
train_levels_g <- readRDS("train_levels_g.rds")

train_terms_d <- readRDS("train_terms_d.rds")
train_levels_d <- readRDS("train_levels_d.rds")

train_terms_m <- readRDS("train_terms_m.rds")
train_levels_m <- readRDS("train_levels_m.rds")

train_terms_f <- readRDS("train_terms_f.rds")
train_levels_f <- readRDS("train_levels_f.rds")

# Modello di Regressione LASSO
lasso_g <- readRDS('lasso_g.rds')
lasso_d <- readRDS('lasso_d.rds')
lasso_m <- readRDS('lasso_m.rds')
lasso_f <- readRDS('lasso_f.rds')


# RICAVIAMO I DATASET DA USARE PER I MODELLI
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
                           select = (names(new_data_F) %in% names(coef(logMod_F))) | 
                             names(new_data_F) == "risultato")

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
X_new_g <- build_shrink_matrix(new_data_G, train_terms_g, train_levels_g)
X_new_d <- build_shrink_matrix(new_data_D, train_terms_d, train_levels_d)
X_new_m <- build_shrink_matrix(new_data_M, train_terms_m, train_levels_m)
X_new_f <- build_shrink_matrix(new_data_F, train_terms_f, train_levels_f)

#################
## VALUTAZIONI ##
#################

## Regressione Lineare 
G_lm_vote <- predict(linMod_G, newdata = new_data_G)
D_lm_vote <- predict(linMod_D, newdata = new_data_D)
M_lm_vote <- predict(linMod_M, newdata = new_data_M)
F_lm_vote <- predict(linMod_F, newdata = new_data_F)



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

###################
### VALUTAZIONI ###
###################

final_rating <- cbind(
  c(G_lm_vote,    D_lm_vote,    M_lm_vote,    F_lm_vote),
  c(G_log_vote,   D_log_vote,   M_log_vote,   F_log_vote),
  c(G_ridge_vote, D_ridge_vote, M_ridge_vote, F_ridge_vote),
  c(G_lasso_vote, D_lasso_vote, M_lasso_vote, F_lasso_vote)
)

ruolo <- ifelse(rownames(final_rating) %in% rownames(new_data_G), "Portiere",
                ifelse(rownames(final_rating) %in% rownames(new_data_D), "Difensore",
                       ifelse(rownames(final_rating) %in% rownames(new_data_M), "Centrocampista",
                              "Attaccante")))

final_rating <- cbind(ruolo, round(final_rating,2))


colnames(final_rating) <- c("Ruolo", "Regressione Lineare",
                            "Regressione Logistica",
                            "Ridge", "LASSO")


# OUTPUT 
library(shiny)

ui <- fluidPage(
  titlePanel("Valutazioni dei Giocatori"),
  
  mainPanel(
    tags$head(
      tags$style(HTML("
                      table{ 
                        margin-left: auto;
                        margin-right: auto;
                      }"))
    ),
    div(style='text-align: left;',
      tableOutput("voti_df")
    )
  )
)

server <- function(input, output){
  df <- final_rating
  
  output$voti_df <- renderTable({
    df
    }, rownames = T)
}

shinyApp(ui = ui, server = server)

