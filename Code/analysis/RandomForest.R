

###################################
##### LOAD NECESSARY PACKAGES #####
###################################

if (!require("pacman")) install.packages("pacman")
library(pacman)
p_load("glmnet", "abcrf", "tidyverse", "haven", "grf", "randomForest", "dplyr", "tidyr", "randomForestExplainer", "caret", "e1071", "ranger", "parallel", "doParallel", "rattle", "purrr", "xtable", "rsample")


##############################
######READ IN THE DATASET#####
##############################

#Change working directory to where the data file is saved
setwd("/Users/USER/Documents/GitHub/ifii_whitepaper/Database/Final Data/")


#read in data file
raw_fii_dataset <- read_dta("fii-clean-randomforestprofiles.dta") 


#######################
####PREP THE DATA#####
#######################  

#Make sure all variables are correctly identified as factors
raw_fii_dataset[sapply(raw_fii_dataset, is.numeric)] <- lapply(raw_fii_dataset[sapply(raw_fii_dataset, is.numeric)], as.factor)

#Remove Uncessary Vars
clean_fii_dataset <- select(raw_fii_dataset, -c(everuse, use_6mon_atm_bin, weight))  

# Subset by Gender
clean_fii_dataset_f <- subset(clean_fii_dataset, female == "1")
clean_fii_dataset_m <- subset(clean_fii_dataset, female == "0")

# Make into Data Frame
clean_fii_dataset=data.frame(clean_fii_dataset)
clean_fii_dataset_f=data.frame(clean_fii_dataset_f)
clean_fii_dataset_m=data.frame(clean_fii_dataset_m)

# Split in Training and Test
set.seed(8452)
split_frame = createDataPartition(clean_fii_dataset$ownership, p = 0.8, list = FALSE)
clean_fii_dataset_train = clean_fii_dataset[split_frame, ]
clean_fii_dataset_test = clean_fii_dataset[-split_frame, ]            

split_frame_f = createDataPartition(clean_fii_dataset_f$ownership, p = 0.8, list = FALSE)
clean_fii_dataset_f_train = clean_fii_dataset_f[split_frame_f, ]
clean_fii_dataset_f_test = clean_fii_dataset_f[-split_frame_f, ]    

split_frame_m = createDataPartition(clean_fii_dataset_m$ownership, p = 0.8, list = FALSE)
clean_fii_dataset_m_train = clean_fii_dataset_m[split_frame_m, ]
clean_fii_dataset_m_test = clean_fii_dataset_m[-split_frame_m, ]    

# Make into matrices
matrix_train <- select(clean_fii_dataset_train, -ownership)
matrix_train <- data.matrix(matrix_train)

matrix_train_f <- select(clean_fii_dataset_f_train, -ownership)
matrix_train_f <- data.matrix(matrix_train_f)

matrix_train_m <- select(clean_fii_dataset_m_train, -ownership)
matrix_train_m <- data.matrix(matrix_train_m)

#clean outcome var
matrix_train_outcome <- clean_fii_dataset_train$ownership
matrix_train_outcome <- data.matrix(matrix_train_outcome)

matrix_train_outcome_f <- clean_fii_dataset_f_train$ownership
matrix_train_outcome_f <- data.matrix(matrix_train_outcome_f)

matrix_train_outcome_m <- clean_fii_dataset_m_train$ownership
matrix_train_outcome_m <- data.matrix(matrix_train_outcome_m)

#prep test data
matrix_test <- select(clean_fii_dataset_test, -ownership)
matrix_test <- data.matrix(matrix_test)

matrix_test_f <- select(clean_fii_dataset_f_test, -ownership)
matrix_test_f <- data.matrix(matrix_test_f)

matrix_test_m <- select(clean_fii_dataset_m_test, -ownership)
matrix_test_m <- data.matrix(matrix_test_m)

#clean outcome var
matrix_test_outcome <- clean_fii_dataset_test$ownership
matrix_test_outcome <- data.matrix(matrix_test_outcome)

matrix_test_outcome_f <- clean_fii_dataset_f_test$ownership
matrix_test_outcome_f <- data.matrix(matrix_test_outcome_f)

matrix_test_outcome_m <- clean_fii_dataset_m_test$ownership
matrix_test_outcome_m <- data.matrix(matrix_test_outcome_m)

#hot coding
matrix_train_hot <- model.matrix(ownership~., clean_fii_dataset_train)[,-1]
matrix_test_hot <- model.matrix(ownership~., clean_fii_dataset_test)[,-1]

matrix_train_hot_f <- model.matrix(ownership~., clean_fii_dataset_f_train)[,-1]
matrix_test_hot_f <- model.matrix(ownership~., clean_fii_dataset_f_test)[,-1]

matrix_train_hot_m <- model.matrix(ownership~., clean_fii_dataset_m_train)[,-1]
matrix_test_hot_m <- model.matrix(ownership~., clean_fii_dataset_m_test)[,-1]


##have to put outcome var back onto datasets
matrix_train_hot <- as.data.frame(cbind(matrix_train_outcome,matrix_train_hot))
colnames(matrix_train_hot)[1] <- c("ownership")
matrix_test_hot <- as.data.frame(cbind(matrix_test_outcome,matrix_test_hot))
colnames(matrix_test_hot)[1] <- c("ownership")
matrix_train <- as.data.frame(cbind(matrix_train_outcome,matrix_train))
colnames(matrix_train)[1] <- c("ownership")
matrix_test <- as.data.frame(cbind(matrix_test_outcome,matrix_test))
colnames(matrix_test)[1] <- c("ownership")

matrix_train_hot_f <- as.data.frame(cbind(matrix_train_outcome_f,matrix_train_hot_f))
colnames(matrix_train_hot_f)[1] <- c("ownership")
matrix_test_hot_f <- as.data.frame(cbind(matrix_test_outcome_f,matrix_test_hot_f))
colnames(matrix_test_hot_f)[1] <- c("ownership")
matrix_train_f <- as.data.frame(cbind(matrix_train_outcome_f,matrix_train_f))
colnames(matrix_train_f)[1] <- c("ownership")
matrix_test_f <- as.data.frame(cbind(matrix_test_outcome_f,matrix_test_f))
colnames(matrix_test_f)[1] <- c("ownership")

matrix_train_hot_m <- as.data.frame(cbind(matrix_train_outcome_m,matrix_train_hot_m))
colnames(matrix_train_hot_m)[1] <- c("ownership")
matrix_test_hot_m <- as.data.frame(cbind(matrix_test_outcome_m,matrix_test_hot_m))
colnames(matrix_test_hot_m)[1] <- c("ownership")
matrix_train_m <- as.data.frame(cbind(matrix_train_outcome_m,matrix_train_m))
colnames(matrix_train_m)[1] <- c("ownership")
matrix_test_m <- as.data.frame(cbind(matrix_test_outcome_m,matrix_test_m))
colnames(matrix_test_m)[1] <- c("ownership")

#Ensure all are factors
matrix_train_hot <- mutate_if(matrix_train_hot, is.character, as.factor)
matrix_test_hot <- mutate_if(matrix_test_hot, is.character, as.factor)
matrix_train <- mutate_if(matrix_train, is.character, as.factor)
matrix_test <- mutate_if(matrix_test, is.character, as.factor)

matrix_train_hot_f <- mutate_if(matrix_train_hot_f, is.character, as.factor)
matrix_test_hot_f <- mutate_if(matrix_test_hot_f, is.character, as.factor)
matrix_train_f <- mutate_if(matrix_train_f, is.character, as.factor)
matrix_test_f <- mutate_if(matrix_test_f, is.character, as.factor)

matrix_train_hot_m <- mutate_if(matrix_train_hot_m, is.character, as.factor)
matrix_test_hot_m <- mutate_if(matrix_test_hot_m, is.character, as.factor)
matrix_train_m <- mutate_if(matrix_train_m, is.character, as.factor)
matrix_test_m <- mutate_if(matrix_test_m, is.character, as.factor)

matrix_test_outcome <- as.factor(matrix_test_outcome)
matrix_test_outcome_f <- as.factor(matrix_test_outcome_f)
matrix_test_outcome_m <- as.factor(matrix_test_outcome_m)
matrix_train_outcome <- as.factor(matrix_train_outcome)
matrix_train_outcome_f <- as.factor(matrix_train_outcome_f)
matrix_train_outcome_m <- as.factor(matrix_train_outcome_m)


#######################
####RUN THE MODELS####
#######################  

#Now Run the Models
rf_model_hot <- ranger(dependent.variable.name = "ownership", data = matrix_train_hot, importance = 'impurity', seed = 1423)

rf_model_hot_f <- ranger(dependent.variable.name = "ownership", data = matrix_train_hot_f, importance = 'impurity', seed = 1423)

rf_model_hot_m <- ranger(dependent.variable.name = "ownership", data = matrix_train_hot_m, importance = 'impurity', seed = 1423)

# Predictions and Confusion Matrix
rf_pred_hot <- predict(rf_model_hot, matrix_test_hot, positive="1")
cm_rf_hot <- confusionMatrix(rf_pred_hot[["predictions"]], as.factor(matrix_test_outcome),positive="1") 
cm_rf_hot

rf_pred_hot_f <- predict(rf_model_hot_f, matrix_test_hot_f, positive="1")
cm_rf_hot_f <- confusionMatrix(rf_pred_hot_f[["predictions"]], as.factor(matrix_test_outcome_f),positive="1") 
cm_rf_hot_f

rf_pred_hot_m <- predict(rf_model_hot_m, matrix_test_hot_m, positive="1")
cm_rf_hot_m <- confusionMatrix(rf_pred_hot_m[["predictions"]], as.factor(matrix_test_outcome_m),positive="1") 
cm_rf_hot_m

# aggregate important accuracy stats
accstat <- as.data.frame(cbind(cm_rf_hot[["overall"]][["Accuracy"]], cm_rf_hot[["byClass"]][["Sensitivity"]], cm_rf_hot[["byClass"]][["Specificity"]], cm_rf_hot[["overall"]][["AccuracyNull"]], cm_rf_hot[["overall"]][["AccuracyPValue"]]))
accstat_f <- as.data.frame(cbind(cm_rf_hot_f[["overall"]][["Accuracy"]], cm_rf_hot_f[["byClass"]][["Sensitivity"]], cm_rf_hot_f[["byClass"]][["Specificity"]], cm_rf_hot_f[["overall"]][["AccuracyNull"]], cm_rf_hot_f[["overall"]][["AccuracyPValue"]]))
accstat_m <- as.data.frame(cbind(cm_rf_hot_m[["overall"]][["Accuracy"]], cm_rf_hot_m[["byClass"]][["Sensitivity"]], cm_rf_hot_m[["byClass"]][["Specificity"]], cm_rf_hot_m[["overall"]][["AccuracyNull"]], cm_rf_hot_m[["overall"]][["AccuracyPValue"]]))

colnames(accstat) <- c("Overall","Sensitivity", "Specificity", "NoInfo", "Pvalue")
colnames(accstat_f) <- c("Overall","Sensitivity", "Specificity", "NoInfo", "Pvalue")
colnames(accstat_m) <- c("Overall","Sensitivity", "Specificity", "NoInfo", "Pvalue")

#Variable Importance
rf_varimp_hot <- as.data.frame(rf_model_hot[["variable.importance"]])
colnames(rf_varimp_hot) <- "Importance_rf"
rf_varimp_hot<-tibble::rownames_to_column(rf_varimp_hot, "Variables") 
rf_varimp_hot <- rf_varimp_hot[order(-rf_varimp_hot$Importance_rf),]

rf_varimp_hot_f <- as.data.frame(rf_model_hot_f[["variable.importance"]])
colnames(rf_varimp_hot_f) <- "Importance_rf"
rf_varimp_hot_f <-tibble::rownames_to_column(rf_varimp_hot_f, "Variables") 
rf_varimp_hot_f <- rf_varimp_hot_f[order(-rf_varimp_hot_f$Importance_rf),]

rf_varimp_hot_m <- as.data.frame(rf_model_hot_m[["variable.importance"]])
colnames(rf_varimp_hot_m) <- "Importance_rf"
rf_varimp_hot_m <-tibble::rownames_to_column(rf_varimp_hot_m, "Variables") 
rf_varimp_hot_m <- rf_varimp_hot_m[order(-rf_varimp_hot_m$Importance_rf),]

# add additional column to identify sample
accstat$sample="Full"
accstat_f$sample="Female"
accstat_m$sample="Male"

rf_varimp_hot$sample="Full"
rf_varimp_hot_f$sample="Female"
rf_varimp_hot_m$sample="Male"

# Combine
accuracy_table <- rbind(accstat, accstat_f, accstat_m)
varimp_table <- rbind(rf_varimp_hot, rf_varimp_hot_f, rf_varimp_hot_m)

# EXPORT
write_dta(varimp_table, "fii-routput-varimp.dta")
write_dta(accuracy_table, "fii-routput-accuracy.dta")
