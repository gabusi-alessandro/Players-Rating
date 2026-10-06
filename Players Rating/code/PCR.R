######################################
### PRINCIPAL COMPONENT REGRESSION ###
######################################

rm(list=ls())

#######################
## CARICHIAMO I DATI ##
#######################

# Dataset
data_g <- readRDS('Data_G.rds')
data_d <- readRDS('Data_D.rds')
data_m <- readRDS('Data_M.rds')
data_f <- readRDS('Data_F.rds')


m_g <- model.matrix(valutazione ~ . - 1, data=data_g)
m_d <- model.matrix(valutazione ~ . - 1, data=data_d)
m_m <- model.matrix(valutazione ~ . - 1, data=data_m)
m_f <- model.matrix(valutazione ~ . - 1, data=data_f)


# EFFETTUIAMO LA PCA
PCA_g <- prcomp(m_g, scale = T)
PCA_d <- prcomp(m_d, scale = T)
PCA_m <- prcomp(m_m, scale = T)
PCA_f <- prcomp(m_f, scale = T)

var_prop_g <- PCA_g$sdev^2 / sum(PCA_g$sdev^2)
var_prop_d <- PCA_d$sdev^2 / sum(PCA_d$sdev^2)
var_prop_m <- PCA_m$sdev^2 / sum(PCA_m$sdev^2)
var_prop_f <- PCA_f$sdev^2 / sum(PCA_f$sdev^2)


plot(var_prop_g, type='b', pch=16, main='Componenti Principali Portieri',
     ylab='Variance proportion')              
plot(var_prop_d, type='b', pch=16, main='Componenti Principali Difensori',
     ylab='Variance Proportion') 
plot(var_prop_m, type='b', pch=16, main='Componenti Principali Centrocampisti',
     ylab='Variance Proportion')              
plot(var_prop_f, type='b', pch=16, main='Componenti Principali Attaccanti',
     ylab='Variance Proportion') 


# Quante PC tenere?
(num_pc_g <- sum(PCA_g$sdev > mean(PCA_g$sdev)))
(num_pc_d <- sum(PCA_d$sdev > mean(PCA_d$sdev)))
(num_pc_m <- sum(PCA_m$sdev > mean(PCA_m$sdev)))
(num_pc_f <- sum(PCA_f$sdev > mean(PCA_f$sdev)))


# Costruiamo le nuove matrici di dati
PC_data_g <- data.frame(cbind(data_g$valutazione, PCA_g$x[,1:num_pc_g]))
PC_data_d <- data.frame(cbind(data_d$valutazione, PCA_d$x[,1:num_pc_d]))
PC_data_m <- data.frame(cbind(data_m$valutazione, PCA_m$x[,1:num_pc_m]))
PC_data_f <- data.frame(cbind(data_f$valutazione, PCA_f$x[,1:num_pc_f]))

colnames(PC_data_g)[1] <- "valutazione"
colnames(PC_data_d)[1] <- "valutazione"
colnames(PC_data_m)[1] <- "valutazione"
colnames(PC_data_f)[1] <- "valutazione"


# COSTRUIAMO I MODELLI DI REGRESSIONE
PCR_g <- lm(valutazione ~ ., data=PC_data_g)
PCR_d <- lm(valutazione ~ ., data=PC_data_d)
PCR_m <- lm(valutazione ~ ., data=PC_data_m)
PCR_f <- lm(valutazione ~ ., data=PC_data_f)

summary(PCR_g)


################################
## CARICHIAMO IL TEST-DATASET ##
################################

data_test_g <- readRDS('data_test_g.rds')
data_test_d <- readRDS('data_test_d.rds')
data_test_m <- readRDS('data_test_m.rds')
data_test_f <- readRDS('data_test_f.rds')


## PULIAMO I DATASET
data_test_g <- data_test_g[, colnames(data_g), drop=FALSE]
data_test_d <- data_test_d[, colnames(data_d), drop=FALSE]
data_test_m <- data_test_m[, colnames(data_m), drop=FALSE]
data_test_f <- data_test_f[, colnames(data_f), drop=FALSE]


X_test_g <- model.matrix(valutazione ~ . - 1, data = data_test_g)
X_test_d <- model.matrix(valutazione ~ . - 1, data = data_test_d)
X_test_m <- model.matrix(valutazione ~ . - 1, data = data_test_m)
X_test_f <- model.matrix(valutazione ~ . - 1, data = data_test_f)


# Ricostruiamo la PCA dei nuovi dati
X_test_pca_g <- scale(
  X_test_g,
  center = PCA_g$center,
  scale = PCA_g$scale
) %*% PCA_g$rotation[, 1:num_pc_g]


X_test_pca_d <- scale(
  X_test_d,
  center = PCA_d$center,
  scale = PCA_d$scale
) %*% PCA_d$rotation[, 1:num_pc_d]


X_test_pca_m <- scale(
  X_test_m,
  center = PCA_m$center,
  scale = PCA_m$scale
) %*% PCA_m$rotation[, 1:num_pc_m]


X_test_pca_f <- scale(
  X_test_f,
  center = PCA_f$center,
  scale = PCA_f$scale
) %*% PCA_f$rotation[, 1:num_pc_f]


# Manteniamo gli stessi nomi delle variabili usate nel PCR
colnames(X_test_pca_g) <- colnames(PC_data_g)[-1]
colnames(X_test_pca_d) <- colnames(PC_data_d)[-1]
colnames(X_test_pca_m) <- colnames(PC_data_m)[-1]
colnames(X_test_pca_f) <- colnames(PC_data_f)[-1]


################################
### CALCOLIAMO LE PREVISIONI ###
################################

Tvote_g <- predict(PCR_g, newdata = data.frame(X_test_pca_g))
Tvote_d <- predict(PCR_d, newdata = data.frame(X_test_pca_d))
Tvote_m <- predict(PCR_m, newdata = data.frame(X_test_pca_m))
Tvote_f <- predict(PCR_f, newdata = data.frame(X_test_pca_f))


## CALCOLIAMO GLI MSE
MSE_g <- mean((data_test_g$valutazione - Tvote_g)^2)
MSE_d <- mean((data_test_d$valutazione - Tvote_d)^2)
MSE_m <- mean((data_test_m$valutazione - Tvote_m)^2)
MSE_f <- mean((data_test_f$valutazione - Tvote_f)^2)

round(cbind(MSE_g, MSE_d, MSE_m, MSE_f),4)
