library(lme4)
library(ggplot2)
library(dplyr)
library(tidyverse)
library(mgcViz)
library(glmmTMB)
library(MuMIn)
library(sjPlot)
# library(gratia)
library(mgcv)
library(DHARMa)
library(gridExtra)
library(broom)
library(Metrics)
library(caret)
library(rlang)
library(klaR)
# install.packages("Metrics")
# Install and load the package
# install.packages("AICcmodavg")
library(AICcmodavg)

# 1. Load data----
processed_path <- ".../Playback analysis/0. Data/Processed"
figures_path <- ".../Playback analysis/2. Output/figures"
output_path <- ".../Playback analysis/2. Output"
ampl_dist_spp <- read_csv(file.path(processed_path, "real data", "ampl_dist_spp_deleted_nas_both_mics.csv"))
ampl_dist_spp_with_ref <- read_csv(file.path(processed_path, "real data", "ampl_dist_spp_with_reference.csv"))
location_sm2 <- read_csv(file.path(processed_path, "real data", "locations sm2 status.csv"))
# View(ampl_dist_spp)

unique(ampl_dist_spp$species_code)

ampl_dist_spp_joined <- merge(ampl_dist_spp, location_sm2, by = "location")
nrow(ampl_dist_spp_joined)
nrow(ampl_dist_spp)
unique(ampl_dist_spp$location) # 149
unique(ampl_dist_spp_joined$location) # 149

locs_all <- c(unique(ampl_dist_spp$location))
locs_joined <- c(unique(ampl_dist_spp_joined$location))

ampl_dist_spp %>%
  filter(location == "PB-ASP10-25" )

class(ampl_dist_spp)

missing_in_all <- setdiff(locs_joined, locs_all)
missing_in_all


ampl_dist_spp <- ampl_dist_spp_joined
ampl_dist_spp$mean_amp <- rowMeans(ampl_dist_spp[, c('left_amplitude', 'right_amplitude')])
ampl_dist_spp_open <- ampl_dist_spp |> filter(forest == 'OP')
# ampl_dist_spp_open
ampl_dist_spp_forested <- ampl_dist_spp |> filter(forest != 'OP')
# ampl_dist_spp_forested

ampl_dist_spp$BinForest <-  ifelse(ampl_dist_spp$forest == "OP", "OP", "FO")
ampl_dist_spp$ForestDummy <-  ifelse(ampl_dist_spp$BinForest == "OP", 0, 1)
ampl_dist_spp$species_code <- factor(ampl_dist_spp$species_code)
ampl_dist_spp$ForestDummy <- factor(ampl_dist_spp$ForestDummy)
ampl_dist_spp$SM2 <- factor(ampl_dist_spp$SM2)
ampl_dist_spp$BinForest <- factor(ampl_dist_spp$BinForest)
ampl_dist_spp$distance <- as.numeric(ampl_dist_spp$distance)


View(ampl_dist_spp)
length(unique(ampl_dist_spp$location))

# Plot the response
# Set custom colors
my_colors <- c("OP" = "chocolate", "FO" = "seagreen")
amplitude_distance_plot <- ggplot(ampl_dist_spp, aes(distance, mean_amp, color = BinForest)) +
                                    geom_point() +
                                    facet_wrap(~species_code) +
                                    labs(x = "Distance (m)", y = expression(paste("Amplitude (dBFS)"))) +
                                    theme_bw() +
                                    # scale_color_discrete(name = "BinForest")
                                    scale_color_manual(name = "BinForest", values = my_colors)
amplitude_distance_plot
ggsave(filename = file.path(figures_path, "mean amplitude_distance_plot.png"), plot = amplitude_distance_plot)

filter(ampl_dist_spp, species_code == 'WEME', distance >= 100)
# Selected model (beofre ARU effect)
log10(1)

# 2. Spherical spread only----
SpherSpreadGLM <- glmmTMB(amplitude ~ species_code, data = ampl_dist_spp, offset = I(-10*log10(distance)))
AIC(SpherSpreadGLM) # 11281.76
summary(SpherSpreadGLM)
r.squaredGLMM(SpherSpreadGLM)   # R2m = 0.1685869   ,    R2c = 0.1685869

SpherSpreadGLM <- glmmTMB(amplitude ~ I(-10*log10(distance)), data = ampl_dist_spp)
AIC(SpherSpreadGLM) # 11194.02
summary(SpherSpreadGLM)
r.squaredGLMM(SpherSpreadGLM)  # R2m = 0.405204   ,    R2c = 0.405204

SpherSpreadGLM <- glmmTMB(amplitude ~species_code + I(-10*log10(distance)), data = ampl_dist_spp)
AIC(SpherSpreadGLM) # 10632.12
summary(SpherSpreadGLM)
r.squaredGLMM(SpherSpreadGLM)  # R2m = 0.58577   ,    R2c = 0.58577


# SpherSpreadGLM <- glmmTMB(amplitude ~ species_code, data = ampl_dist_spp, offset = I(-10*log10(distance^2)))
SpherSpreadGLM <- glmmTMB(amplitude ~ distance + BinForest + species_code, offset = I(-10*log10(distance^2)), data = ampl_dist_spp)
AIC(SpherSpreadGLM) # 10619.01
summary(SpherSpreadGLM)
r.squaredGLMM(SpherSpreadGLM)  # R2m = 0.3300957   ,    R2c = 0.3300957

SpherSpreadGLM <- glmmTMB(amplitude ~ distance + BinForest + species_code + I(-10*log10(distance^2)), data = ampl_dist_spp)
AIC(SpherSpreadGLM) # 10620
summary(SpherSpreadGLM)
r.squaredGLMM(SpherSpreadGLM)  # R2m = 0.03084074   ,    R2c = 0.03084074

SpherSpreadGLM <- glmmTMB(amplitude ~ distance + BinForest,  offset =I(-10*log10(distance^2)), data = ampl_dist_spp)
AIC(SpherSpreadGLM) # 11193.03
summary(SpherSpreadGLM)
r.squaredGLMM(SpherSpreadGLM)  # R2m = 0.5896744   ,    R2c =0.5896744

SpherSpreadGLM <- glmmTMB(amplitude ~ distance + BinForest + (1|species_code), offset = I(-10*log10(distance^2)), data = ampl_dist_spp)
AIC(SpherSpreadGLM) # 11193.03
summary(SpherSpreadGLM)
r.squaredGLMM(SpherSpreadGLM)  # R2m = 0.03084074   ,    R2c = 0.03084074

SpherSpreadGLM <- glmmTMB(amplitude ~ distance + BinForest + (distance + BinForest|species_code), offset =I(-10*log10(distance^2)), data = ampl_dist_spp)

summary(SpherSpreadGLM)

plot_model(SpherSpreadGLM,  type = "re",  title = "", 
                    axis.title = "Species Random Effects", 
                    colors = c("coral2", "darkgreen"),
                    vline.color = "darkslategrey",
                    axis.lim = c(-16,10))

unique_species <- unique(ampl_dist_spp$species_code)
dist_range <- seq.int(min(ampl_dist_spp$distance), 300, length.out = 300)

pred_data_SpherSpread <- expand.grid(distance = dist_range, species_code = unique_species)

## 2.1 Predict amplitude using pred_data_SpherSpread----
pred_data_SpherSpread$predicted <- predict(SpherSpreadGLM, newdata = pred_data_SpherSpread, type = "response")

## 2.2 Plot pred_data_SpherSpread----

# For BinForest = "OP", with no legend
SphereSpreadPlot <- ggplot(pred_data_SpherSpread, aes(x = distance, y = predicted, color = species_code)) +
  geom_line() +
  labs(title = "Predicted Amplitude, spherical spread only") +
  theme_minimal() +
  ylim(min(pred_data_SpherSpread$predicted), max(pred_data_SpherSpread$predicted)) +
  theme(plot.margin = unit(c(1,0,1,1), "cm")) +
  theme(legend.position = "right")

SphereSpreadPlot
r.squaredGLMM(SpherSpreadGLM)   

## 2.3 Residuals of Spherical Spread model
SphSpreadResids <- residuals(SpherSpreadGLM)
plot(simulateResiduals(SpherSpreadGLM))
plot(SphSpreadResids)
ResidsGLM <- glmmTMB(SphSpreadResids ~ distance + BinForest, data = ampl_dist_spp)
summary(ResidsGLM)

plot(simulateResiduals(ResidsGLM))

plot(residuals(ResidsGLM))
#######
# 3. Best Model Fit
# should I add mean frequency as a parameter?
Model1 <- glmmTMB(mean_amp ~  distance + I(10*log10(distance^2)) + BinForest + (1|species_code), data = ampl_dist_spp)
null <- lm(mean_amp ~ offset(I(-10*log10(distance^2))), data = ampl_dist_spp)
null_formula <- mean_amp ~ offset(I(-10*log10(distance^2)))
species <- glmmTMB(mean_amp ~ (1|species_code) + offset(I(-10*log10(distance^2))), data = ampl_dist_spp)
forest <- glmmTMB(mean_amp ~ BinForest + (1|species_code) + offset(I(-10*log10(distance^2))), data = ampl_dist_spp)
distance <- glmmTMB(mean_amp ~ distance + (1|species_code) + offset(I(-10*log10(distance^2))), data = ampl_dist_spp)
distance_forest_main <- glmmTMB(mean_amp ~ distance + BinForest + (1|species_code) + offset(I(-10*log10(distance^2))), data = ampl_dist_spp)
distance_forest_2 <- glmmTMB(mean_amp ~ distance:BinForest + (1|species_code) + offset(I(-10*log10(distance^2))), data = ampl_dist_spp)
distance_forest_3 <- lmer(mean_amp ~ distance*BinForest + (1|species_code) + offset(I(-10*log10(distance^2))), data = ampl_dist_spp)
distance_forest_3 <- glmmTMB(mean_amp ~ distance*BinForest + (1|species_code) + offset(I(-10*log10(distance^2))), data = ampl_dist_spp)
summary(distance_forest_3)
distance_forest_3_sm2 <- glmmTMB(mean_amp ~ distance*BinForest + SM2 + (1|species_code) + offset(I(-10*log10(distance^2))), data = ampl_dist_spp)
summary(distance_forest_3_sm2)

distance_forest_4 <- glmmTMB(mean_amp ~ distance + distance:BinForest + (1|species_code) + offset(I(-10*log10(distance^2))), data = ampl_dist_spp)

plot(simulateResiduals(distance_forest_3_sm2))

Model1 <- glmmTMB(amplitude ~ distance + BinForest + (1|species_code), data = ampl_dist_spp, offset = I(-10*log10(distance^2)))
Model1lme4 <- lmer(amplitude ~ distance + BinForest + (1|species_code) + offset(I(-10*log10(distance^2))), data = ampl_dist_spp)
summary(distance_forest_3)
r.squaredGLMM(species)

Model1noOffset <- glmmTMB(amplitude ~ I(-10*log10(distance^2)) + distance + BinForest + (1|species_code), data = ampl_dist_spp)

AIC(distance_forest_3_sm2) # 10672
Model2 <- glmmTMB(amplitude ~ distance + BinForest + species_code, data = ampl_dist_spp, offset = I(-10*log10(distance^2)))
Model3 <- glmmTMB(amplitude ~ distance + distance:BinForest + (1|species_code), data = ampl_dist_spp, offset = I(-10*log10(distance^2)))

summary(Model1)$varcor$cond$species_code
sapply(summary(Model1)$varcor$cond$species_code, function(x) attr(x, "stddev"))
summary(distance_forest_3)
AIC(Model3) # 10667.94

write.csv(species_RE_df, file.path(output_path, "final model w sm2 speices random effect.csv"))

r.squaredGLMM(Model1)
r.squaredGLMM(Model1noOffset)
r.squaredGLMM(distance_forest_3_sm2)    # 0.1303362 0.5674525

# [1,] R2m 0.06321912 R2c: 0.4433997

#2.3 Metrics----
check_model <- distance_forest_3_sm2
logLik(check_model)
AICc(check_model)
r.squaredGLMM(check_model)
plot(simulateResiduals(check_model))
# Residual degrees of freedom
#df.r.squaredGLMM(Model1)residual(Model1)
r.squaredGLMM(Model1)[1]
# Model degrees of freedom (number of predictors + 1 for the intercept)
length(coef(null))
logLik(null)[1]

#2.5 Plot effects----

plot_model(distance_forest_3, type = "std") # standardized coefficients
plot_model(distance_forest_3, type = 'est')
?plot_model()
plot_model(distance_forest_3, type = "int")
dev.off()

png(file.path("2. Output", "figures",  "distance_forest_3_SM2 Species random effects .png"), width = 400, height = 300)
plot_model(distance_forest_3_sm2, type = "re",  title = "", 
                            colors = c("coral2", "darkgreen"),
                            vline.color = "darkslategrey",
                            axis.lim = c(-18,10)
                            )+
                  xlab(expression("Signal strength " ~ italic(S)[mu] ~ "(dBFS)")) + 
                  ylab("Species") +
                  theme(plot.title = element_blank(),  # Remove any figure title
                  axis.title.x = element_text(size = 14),  # Change x axis label size
                  axis.title.y = element_text(size = 14))
intercept_plot
dev.off()
plot_model(distance_forest_3, type = "est")
plot_model(distance_forest_3, type = "slope")
plot_model(Model1, type = "resid")
plot_model(Model1, type = "diag")
summary(Model1)
AIC(Model1) # [1] 10672.47


## 3.1 Create a new data frame for prediction----
# unique_species <- unique(ampl_dist_spp$species_code)
select_species <- c("BRBL", "WEME", "VESP", "CCSP", "AMRO")
all_species <- c('ALFL', 'AMCR', 'BRBL', 'LCSP', 'AMRO', 'BADO', 'VESP', 'DEJU',
       'CSWA', 'MAWR', 'BOCH', 'MGWA', 'CCSP', 'WEME', 'NSWO')
dist_range <- seq.int(min(ampl_dist_spp$distance), 500, length.out = 500)

# head(pred_data_OP)
pred_data_OP <- expand.grid(distance = dist_range, species_code = all_species, 
                            BinForest = "OP",
                            SM2 = 0:1)
pred_data_FO <- expand.grid(distance = dist_range, species_code = all_species, 
                            BinForest = "FO",
                            SM2 = 0:1)

# Generate combinations without SM2
# pred_data_OP <- expand.grid(distance = dist_range, 
#                             species_code = select_species, 
#                             BinForest = "OP")

# pred_data_FO <- expand.grid(distance = dist_range, 
#                             species_code = select_species, 
#                             BinForest = "FO")

OP_pred <- predict(distance_forest_3_sm2, newdata = pred_data_OP, type = "response", se.fit = TRUE)
FO_pred <- predict(distance_forest_3_sm2, newdata = pred_data_FO, type = "response", se.fit = TRUE)

# OP_pred <- predict(distance_forest_3, newdata = pred_data_OP, se.fit = TRUE, interval = 'confidence')

# predict(temp_mod, newdata = pred_trees, se.fit = TRUE, interval = 'confidence')$fit

# pred_data_OP$predicted <- OP_pred$fit
# # pred_data_FO$predicted <- FO_pred$fit
pred_data_OP$lwr <- OP_pred$fit - 1.96*OP_pred$se.fit
pred_data_OP$upr <- OP_pred$fit + 1.96*OP_pred$se.fit

pred_data_FO$lwr <- FO_pred$fit - 1.96*FO_pred$se.fit
pred_data_FO$upr <- FO_pred$fit + 1.96*FO_pred$se.fit

pred_data_OP$predicted <- predict(distance_forest_3_sm2, newdata = pred_data_OP, type = "response", se.fit = TRUE)$fit
pred_data_FO$predicted <- predict(distance_forest_3_sm2, newdata = pred_data_FO, type = "response", se.fit = TRUE)$fit
# pred_data_OP$lwr <- predict(Model1, newdata = pred_data_OP, type = "response", se.fit = TRUE)$fit


pred_data <- rbind(pred_data_FO, pred_data_OP)
view()
write.csv(pred_data, file.path(processed_path, "real data", "predicted_distance_amplitudes_500m_all_species.csv"))
# dim(pred_data)
# dim(pred_data_FO)
# dim(pred_data_OP)
# View(pred_data)
# For BinForest = "OP", with no legend
ampl_dist_select_spp <- ampl_dist_spp |>
                        filter(species_code %in% all_species )
OP_ampl_dist_select_spp <- ampl_dist_select_spp |>
                            filter(BinForest == "OP")
OP_plot <- pred_data_OP |>
  ggplot(aes(x = distance, y = predicted, color = species_code)) +
  geom_ribbon(aes(x = distance, ymin = lwr, ymax = upr), fill = 'grey',  alpha = .3, linetype = 0) + 
  geom_line() +
  geom_point(aes(x = distance, y = mean_amp, color = species_code), alpha = .5,
            data = OP_ampl_dist_select_spp, inherit.aes = FALSE) +
  labs(title = "Open") +
  theme_minimal() +
  ylab(expression("Signal strength " ~ italic(S)[mu] ~ "(dBFS)")) + # italic S with subscript mu
  xlab("Distance (m)") +
  ylim(min(min(pred_data_OP$predicted, pred_data_FO$predicted)), 
      max(max(pred_data_OP$predicted, pred_data_FO$predicted))) +
  xlim(1, 250) +
  theme(legend.position = "none",
        axis.text.x = element_text(size = 12),
        axis.text.y = element_text(size = 12),
        axis.title = element_text(size = 14),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.background = element_blank())
OP_plot
pointSize <- 5
textSize <- 12
spaceLegend <- 0.1

FO_ampl_dist_select_spp <- ampl_dist_select_spp |>
                            filter(BinForest == "FO")


FO_plot <-  pred_data_FO |>
  ggplot(aes(x = distance, y = predicted, color = species_code)) +
  geom_ribbon(aes(x = distance, ymin = lwr, ymax = upr), fill = 'grey',  alpha = .3, linetype = 0) + 
  geom_line() +
  geom_point(aes(x = distance, y = mean_amp, color = species_code), alpha = .5,
            data = FO_ampl_dist_select_spp, inherit.aes = FALSE) +
  labs(title = "Forested") +
  theme_minimal() +
  ylab(expression("Signal strength " ~ italic(S)[mu] ~ "(dBFS)")) + # italic S with subscript mu
  xlab("Distance (m)") +
  ylim(min(min(pred_data_OP$predicted, pred_data_FO$predicted)), 
      max(max(pred_data_OP$predicted, pred_data_FO$predicted))) +
  xlim(1, 250) +
  labs(color = "Species") +
  theme(legend.position = c(.9, 0.75),
        axis.text.x = element_text(size = 12),
        axis.text.y = element_text(size = 12),
        axis.title = element_text(size = 14),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.background = element_blank()) 
FO_plot
combined_plots <- grid.arrange(OP_plot, FO_plot, ncol = 2)

ggsave(filename = file.path(figures_path, "distance_forest_3_SM2 sound attenuation obs lighter data no grid.png"), plot = combined_plots, width = 10, height = 6)


pointSize <- 5
textSize <- 8
spaceLegend <- 0.1

# For BinForest = "FO"
p_FO <- ggplot(pred_data_FO, aes(x = distance, y = predicted, color = species_code)) +
  geom_line() +
  labs(title = "Predicted Amplitude, Forested") +
  theme_minimal() +
  ylim(min(min(pred_data_OP$predicted, pred_data_FO$predicted)), max(max(pred_data_OP$predicted, pred_data_FO$predicted))) + 
  theme(plot.margin = unit(c(1,1,1,1), "cm")) +
  theme(legend.position = c(.9, 0.75)) +
  guides(shape = guide_legend(override.aes = list(size = pointSize)),
    color = guide_legend(override.aes = list(size = pointSize))) +
  theme(legend.title = element_text(size = textSize), 
    legend.text  = element_text(size = textSize),
    legend.key.size = unit(spaceLegend, "lines"))

# addSmallLegend <- function(myPlot, pointSize = 5, textSize = 10, spaceLegend = 0.1) {
#     myPlot +
#         guides(shape = guide_legend(override.aes = list(size = pointSize)),
#                color = guide_legend(override.aes = list(size = pointSize))) +
#         theme(legend.title = element_text(size = textSize), 
#               legend.text  = element_text(size = textSize),
#               legend.key.size = unit(spaceLegend, "lines"))
# }

# Apply on original plot
# addSmallLegend(p_FO)

# Display the plots side by side
combined_plots <-grid.arrange(p_OP, p_FO, ncol = 2)

ggsave(filename = file.path(figures_path, "SelectedModel with offset.png"), plot = combined_plots, width = 10, height = 6)

#3. Identify amplitudes at given distances for given species, in given habitats.----

TruncDistance <- 150
Habitat <- 'FO'
Spp <- "AMRO"

filter(pred_data, between(distance, (TruncDistance-1),(TruncDistance+1)) , species_code == Spp, BinForest == Habitat)
# 4. Set up the plots----


#5. Train and test----
View(ampl_dist_spp)
set.seed(123) # for reproducibility
index <- sample(1:nrow(ampl_dist_spp), round(0.7*nrow(ampl_dist_spp)))
train_data <- ampl_dist_spp[index, ]
test_data <- ampl_dist_spp[-index, ]

predictions <- predict(distance_forest_3_sm2, newdata = test_data, type = "response") # adjust type as needed

rmse_value <- rmse(test_data$mean_amp, predictions)
mae_value <- mae(test_data$mean_amp, predictions)
rmse_value
mae_value
?rmse

# k-fold cross validuation with caret
set.seed(222)
train_control <- trainControl(method = 'cv',
                              number = 10, returnData = TRUE)

cv_fit <- train(form = amplitude ~ distance, data = ampl_dist_spp,
                trControl = train_control, method = "lm")
cv_fit
# the train() fucntion in caret does not support random effects. Will have to build the cross-validation form scratch.
model <- train(form = null_formula, data = ampl_dist_spp,
                trControl = train_control, method = "lm")
null_formula
model

# Set up cross-validation
set.seed(123) # For reproducibility
folds <- createFolds(ampl_dist_spp$mean_amp, k = 10, list = TRUE)

# Initialize a vector to store the performance metric for each fold
rmse_values <- numeric(length(folds))
mae_values <- numeric(length(folds))
# Cross-validation loop
for(i in seq_along(folds)) {
  # Split the data
  train_data <- ampl_dist_spp[-folds[[i]], ]
  test_data <- ampl_dist_spp[folds[[i]], ]

  # Fit the model
  model <- distance_forest_3_sm2
  # model <- lmer(mean_amp ~ (1|species_code) + offset(I(-10*log10(distance^2))), data = ampl_dist_spp)
  # model <- lmer(mean_amp ~ BinForest + (1|species_code) + offset(I(-10*log10(distance^2))), data = ampl_dist_spp)
  # model <- lmer(mean_amp ~ distance + (1|species_code) + offset(I(-10*log10(distance^2))), data = ampl_dist_spp)
  # model <- lmer(mean_amp ~ distance + BinForest + (1|species_code) + offset(I(-10*log10(distance^2))), data = ampl_dist_spp)
  # model <- lmer(mean_amp ~ distance:BinForest + (1|species_code) + offset(I(-10*log10(distance^2))), data = ampl_dist_spp)
  # model <- lmer(mean_amp ~ distance*BinForest + (1|species_code) + offset(I(-10*log10(distance^2))), data = ampl_dist_spp)
  # model <- lmer(mean_amp ~ distance + distance:BinForest + (1|species_code) + offset(I(-10*log10(distance^2))), data = ampl_dist_spp)

  # Predict and evaluate
  predictions <- predict(model, newdata = test_data, type = "response")
  rmse_values[i] <- sqrt(mean((predictions - test_data$mean_amp)^2))
  mae_values[i] <- mean(abs(predictions - test_data$mean_amp))
}

rmse1 <- rmse_values
rmse2 <- rmse_values
rmse3 <- rmse_values
rmse4 <- rmse_values
rmse5 <- rmse_values
rmse6 <- rmse_values
rmse7 <- rmse_values

# Average RMSE
mean_rmse <- mean(rmse_values)
mean_MAE <- mean(mae_values)
mean_rmse
mean_MAE
# Calculate standard deviation
std_dev_rmse <- sd(rmse_values)
std_dev_MAE <- sd(mae_values)
std_dev_rmse
std_dev_MAE
# Calculate Coefficient of Variation
coef_variation_rmse <- (std_dev_rmse / mean_rmse) * 100
coef_variation_rmse
# Calculate Range
range_rmse <- range(rmse_values)
range_rmse
mean_rmse # 6.271881
rmse1 <- rmse_values
rmse2 <- rmse_values
boxplot(c(rmse1, rmse2), main = "RMSE Values Across Folds", ylab = "RMSE")

# Example data
rmse_data <- data.frame(
    model = rep(c("Reference model", "Forest", "Distance", "Distance & Forest", "Distance & Forest 2", "Distance & Forest 3", "Distance & Forest 4"), each = 10),
    rmse = c(rmse1, rmse2, rmse3, rmse4, rmse5, rmse6, rmse7) # Replace with your actual RMSE values
)

# Create the boxplot
RMSE_model_comparison <- ggplot(rmse_data, aes(x = model, y = rmse, fill = model)) +
    geom_boxplot() +
    theme_minimal() +
    labs(x = "Model",
         y = "RMSE") +
    scale_x_discrete(guide = guide_axis(angle = 50))
RMSE_model_comparison
ggsave(filename = file.path(figures_path, "RMSE model comparison boxplot mean amp.png"), plot = RMSE_model_comparison)

# Assuming data_for_plot contains the actual and predicted values
rmse_score <- mean(rmse_values)
mae_score <- mean(mae_values)
r_squared <- 1 - sum((data_for_plot$Actual - data_for_plot$Predicted)^2) / sum((data_for_plot$Actual - mean(data_for_plot$Actual))^2)

# Print the scores
cat("RMSE:", rmse_score, "\n") # RMSE: 6.205237
cat("MAE:", mae_score, "\n") # MAE: 4.77788
cat("R-squared:", r_squared, "\n") # R-squared: 0.5894396

# Create a sequence of distances (starting slightly above 0 to avoid log(0))
distances <- seq(0.1, 300, by = 1)

# Compute the amplitude
amplitude <- -10 * log10(distances^2)

# Create a data frame for plotting
data <- data.frame(Distance = distances, Amplitude = amplitude)

# Plot using ggplot2
ggplot(data, aes(x = Distance, y = Amplitude)) +
        geom_line() + 
        labs(title = "Amplitude vs Distance",
            x = "Distance (m)",
            y = "Amplitude (dB)") +
        ylim(-50, 0)
        theme_minimal()

pred_trees <- data.frame(fake_trees = c(-3, -2, -1, 0, 1, 2, 3)) #seq or modelr would do thte same thing
# temp_mod <- lm(fake_temp_obs ~ 1 + fake_trees,
                # data = fake_data)
pred_temp <- predict(temp_mod, newdata = pred_trees, se.fit = TRUE, interval = 'confidence')$fit
pred_temp <- predict(temp_mod, newdata = pred_trees, se.fit = TRUE, interval = 'prediction')$fit
?predict()
pred_line <- cbind(pred_trees, pred_temp)

pred_line |>
    ggplot(aes(x = fake_trees, y = fit)) +
    geom_ribbon(aes(x = fake_trees, ymin = lwr, ymax = upr), fill = 'pink') +
    geom_line() +
    geom_point(aes(x = fake_trees, y = fake_temp_obs),
                data = fake_data, inherit.aes = FALSE)

# Create a sequence of distances (starting slightly above 0 to avoid log(0))
distances <- seq(1, 300, by = 1)
BinForest <- c(0,1)
species <- unique(ampl_dist_spp$species_code)

# Compute the amplitude
# amplitude <- -10 * log10(distances^2)
ModelnoOffset <- lmer(amplitude ~ distance + BinForest + (1|species_code), data = ampl_dist_spp)

pred_dist <- data.frame(Distance = distances, BinForest = BinForest, species_code = species)
pred_amp <- predict(ModelnoOffset, newdata = pred_dist, se.fit = TRUE)$fit
View(pred_dist)
pred_amp <- predict(ModelnoOffset, newdata = pred_dist)


predicted_amp <- predict(Model1, type = "response", se.fit = TRUE)

pred_line <- cbind(pred_dist, predicted_amp)


predicted_dB <- predcit(Model1, )
plot(actual_values, predicted_values, xlab = "Actual Values", ylab = "Predicted Values", main = "Predicted vs Actual Values")
abline(0, 1, col = "red")  # Adds a y=x line for reference

# Or, using ggplot2
data_for_plot <- data.frame(Actual = actual_values, Predicted = predicted_values)
ggplot(data_for_plot, aes(x = Actual, y = Predicted)) +
  geom_point() +
  geom_abline(intercept = 0, slope = 1, color = "red") +
  labs(title = "Predicted vs Actual Amplitudes", x = "Actual Amplitudes", y = "Predicted Amplitudes") +
  theme_minimal()

# Calculating residuals
data_for_plot$Residuals <- data_for_plot$Actual - data_for_plot$Predicted

# Predicted vs Actual Values with Density
ggplot(data_for_plot, aes(x = Actual, y = Predicted)) +
  geom_point(alpha = 0.5) +
  # geom_density_2d(aes(color = ..level..), size = 0.5) + # 2D density contour
  geom_smooth(method = "loess", color = "blue") +
  # geom_abline(intercept = 0, slope = 1, color = "red", linetype = "dashed") +
  labs(title = "Predicted vs Actual Amplitudes with Density Contours", 
       x = "Actual Amplitudes", y = "Predicted Amplitudes") +
  theme_minimal()
View(data_for_plot)

# Combine actual values, predicted values, and BinForest into one dataframe
data_for_plot <- data.frame(
  Actual = ampl_dist_spp$amplitude,
  Predicted = predicted_values,
  BinForest = ampl_dist_spp$BinForest
)

ggplot(data_for_plot, aes(x = Actual, y = Predicted)) +
  geom_point(alpha = 0.5) +
  geom_smooth(method = "loess", color = "blue", aes(group = BinForest)) +
  facet_wrap(~BinForest) +  # Faceting by BinForest
  geom_abline(intercept = 0, slope = 1, color = "red", linetype = "dashed") +
  labs(title = "Predicted vs Actual, Model2", 
       x = "Actual Amplitudes", y = "Predicted Amplitudes") +
  theme_minimal()

# Residuals vs Actual Values
ggplot(data_for_plot, aes(x = Actual, y = Residuals)) +
  geom_point(alpha = 0.5) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  labs(title = "Residuals vs Actual Amplitudes", 
       x = "Actual Amplitudes", y = "Residuals") +
  theme_minimal()

