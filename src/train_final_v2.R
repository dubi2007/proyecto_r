# Script de Entrenamiento Ultra-Mejorado: Memoria Temporal y Calendario
# Ubicación: src/train_final_v2.R

library(glmnet)
library(dplyr)
library(tidyr)
library(lubridate)

cat("Cargando y mejorando el cerebro del modelo...\n")
energy_data <- read.csv("data/energy_dataset.csv")
weather_data <- read.csv("data/weather_features.csv")

# 1. Limpieza y Fechas
energy_data$time <- as.POSIXct(energy_data$time, tz="UTC")
colnames(energy_data) <- make.names(colnames(energy_data))

weather_wide <- weather_data %>%
  mutate(city_name = trimws(city_name)) %>%
  mutate(dt_iso = as.POSIXct(dt_iso, tz="UTC")) %>%
  group_by(dt_iso, city_name) %>%
  summarise(temp = mean(temp, na.rm=TRUE), wind_speed = mean(wind_speed, na.rm=TRUE), .groups = "drop") %>%
  pivot_wider(names_from = city_name, values_from = c(temp, wind_speed), names_glue = "{.value}_{city_name}")

df <- merge(energy_data, weather_wide, by.x = "time", by.y = "dt_iso")

# 2. INGENIERÍA DE CARACTERÍSTICAS SENIOR
cat("Añadiendo Memoria Temporal y Calendario...\n")
df <- df %>%
  arrange(time) %>%
  mutate(
    # A. Calendario
    hora = hour(time),
    dia_semana = wday(time),
    es_fin_de_semana = ifelse(dia_semana %in% c(1, 7), 1, 0),
    mes = month(time),
    
    # B. Lags (Memoria de corto plazo)
    precio_lag_1h = lag(price.actual, 1),
    carga_lag_1h = lag(total.load.actual, 1),
    
    # C. Tendencia (Promedio móvil de 24h)
    precio_roll_24h = stats::filter(price.actual, rep(1/24, 24), sides=1)
  )

# 3. Preparar variables para el modelo
vars_clima <- grep("temp_|wind_speed_", colnames(df), value = TRUE)
vars_base <- c("total.load.actual", "generation.solar", "generation.wind.onshore", "generation.fossil.gas")
vars_calendario <- c("hora", "es_fin_de_semana", "mes")
vars_memoria <- c("precio_lag_1h", "carga_lag_1h")

target <- "price.actual"

# Seleccionar y limpiar
df_final <- df[, c(target, vars_base, vars_clima, vars_calendario, vars_memoria)]
df_final <- na.omit(df_final) # Los lags crean NAs al inicio

# 4. Entrenamiento Lasso L1 con Validación Cruzada
set.seed(42)
train_idx <- sample(seq_len(nrow(df_final)), 0.8 * nrow(df_final))
x_train <- as.matrix(df_final[train_idx, -1])
y_train <- df_final[train_idx, 1]
x_test <- as.matrix(df_final[-train_idx, -1])
y_test <- df_final[-train_idx, 1]

cat("Entrenando Lasso con memoria...\n")
cv_mod <- cv.glmnet(x_train, y_train, alpha = 1)
final_model <- glmnet(x_train, y_train, alpha = 1, lambda = cv_mod$lambda.min)

# 5. Evaluación de Confianza
preds <- as.vector(predict(final_model, x_test))
r2 <- cor(y_test, preds)^2
mae <- mean(abs(y_test - preds))

cat("\n--- RESULTADOS DEL NUEVO MODELO ---\n")
cat(sprintf("Nueva Confianza (R²): %.2f%%\n", r2 * 100))
cat(sprintf("Nuevo Error (MAE): %.2f €\n", mae))

# Guardar
saveRDS(final_model, "models/lasso_geo_model.rds")
cat("\nModelo actualizado con éxito en models/lasso_geo_model.rds\n")
