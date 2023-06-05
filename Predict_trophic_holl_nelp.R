library(randomForest)
library(LakeTrophicModelling)
library(tidyverse)

# setwd("P:/R projects/Lakes TMDL modeling/CT Lakes Trophic Estimate Models")

## This script will run the GIS random forest model from the Hollister et al 2016
## study and NELP study using a new dataset. The new dataset can come in two forms, 
## and both versions are imported and cleaned below to use in the model.

## Hollister, J. W., Milstead, W. B., &amp; Kreakie, B. J. (2016). 
## Modeling lake trophic state: A random forest approach. Ecosphere, 7(3).
## https://doi.org/10.1002/ecs2.1321 

## Olivero-Sheldon, A. and M.G. Anderson. 2016. Northeast Lake and Pond Classification. 
## The Nature Conservancy, Eastern Conservation Science, Eastern Regional Office. Boston, MA.



## load in Hollister files
load("hollister.RData") ## trained rf model & selected variables
holl_training <- ltmData %>%  ## the training dataset used
  column_to_rownames("NLA_ID") %>% 
  select(all_of(holl_vars_select))

## load in NELP files
load("nelp.RData") ## trained rf model & training dataset
nelp_var <- names(nelp_training) ## the variables selected for the model




## This part loads in the NEW dataset of lakes and their parameters that we want to 
## run in the model. To accomodate for different formats of spreadsheet data entry, 
## there are two different versions of the new dataset below, both reformatted into 
## the exact same data frame.

## import/clean NEW dataset with rows of parameters (version 1)
data_og <- read.csv("dataset_lake_rf_v1.csv")

## subset for Hollister parameters
data_holl <- data_og %>%
  select(-c(model, description)) %>%
  column_to_rownames("variable_names") %>%
  t() %>%
  as.data.frame() %>%
  select(all_of(holl_vars_select)) %>% 
  mutate_at(vars(-WSA_ECO9), as.numeric) %>%
  mutate_at(vars(WSA_ECO9), as.factor) %>% 
  mutate(WSA_ECO9 = factor(WSA_ECO9, levels = levels(holl_training$WSA_ECO9)))

## subset to NELP parameters
data_nelp <- data_og %>% 
  select(-c(model, description)) %>%
  column_to_rownames("variable_names") %>%
  t() %>%
  as.data.frame() %>% 
  drop_na() %>% 
  select(all_of(nelp_var)) %>% 
  mutate_at(vars(-TROP2_15), as.numeric)



## import and clean NEW dataset with variables as columns (version 2)
data_og2 <- read.csv("dataset_lake_rf_v2.csv")

## subset for Hollister parameters
data2_holl <- data_og2 %>% 
  column_to_rownames("lake") %>% 
  select(all_of(holl_vars_select)) %>% 
  mutate_at(vars(-WSA_ECO9), as.numeric) %>% ## convert to numeric
  mutate_at(vars(WSA_ECO9), as.factor) %>% ## convert eco region to factor
  mutate(WSA_ECO9 = factor(WSA_ECO9, levels = levels(holl_training$WSA_ECO9)))

## subset to NELP parameters
data2_nelp <- data_og2 %>% 
  column_to_rownames("lake") %>% 
  select(all_of(nelp_var))



## set up the trophic status breaks for ChlA (Hollister)

# trophic state chla classifications use in EPA National Lakes Assessment (NLA)
ts_4_brks_chla_epa <- c(min(ltmData$CHLA, na.rm=T) - 1,
                    2,
                    7,
                    30,
                    max(ltmData$CHLA, na.rm=T) + 1)

# trophic state chla classifications use in CT Water Quality Standards (WQS)
ts_4_brks_chla_ct <- c(min(ltmData$CHLA, na.rm=T) - 1,
                        2,
                        15,
                        30,
                        max(ltmData$CHLA, na.rm=T) + 1)

ts_4_cats <- c("oligotrophic", "mesotrophic", "eutrophic", "hypertrophic") ## labels for the breaks



## Running the GIS random forest models with the new dataset
predictions_holl <- predict(holl_rf, data_holl)
predictions_nelp <- predict(nelp_rf, data_nelp)


## Setting up the table that shows the predicted trophic level 
## based on the predicted Chla levels from the model (Hollister)
nelp_table <- as.data.frame(predictions_nelp) %>% rownames_to_column("lake")

pred_table <- predictions_holl %>% 
  as.data.frame() %>% 
  rownames_to_column() %>% 
  rename(lake = 1, pred_logCHLA_Holl = 2) %>%
  mutate(pred_CHLA_Holl = 10^(pred_logCHLA_Holl)) %>% 
  mutate(predict_holl_epa = cut(pred_CHLA_Holl, ts_4_brks_chla_epa, ts_4_cats)) %>%
  mutate(predict_holl_ct = cut(pred_CHLA_Holl, ts_4_brks_chla_ct, ts_4_cats)) %>%
  left_join(nelp_table, by = "lake") %>% 
  mutate(predictions_nelp = recode(predictions_nelp, 
                                   OM = "oligo/mesotrophic", 
                                   EH = "eu/hypereutrophic"))


## Might need to edit this line to export the csv file 
## to whichever folder you want. otherwise will export to
## the projects directory. Uncomment the following line
## and run to export table. 

# write.csv(pred_table, "trophic_prediction_table.csv")    





