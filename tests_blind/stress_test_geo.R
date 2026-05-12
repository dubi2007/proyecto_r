# Script de Prueba Extrema (Stress Test) - CORREGIDO
# Objetivo: Ver si el modelo reacciona lógicamente a cambios geográficos con 19 variables

library(glmnet)
library(dplyr)
library(tidyr)
library(lubridate)

# 1. Cargar el mejor modelo geográfico (96.4% precisión)
cat("Cargando modelo Lasso Maestro...\n")
setwd("C:/Users/jinga/Videos/trabajo_final_R")
mod_geo <- readRDS("models/lasso_geo_model.rds")

# Obtener los nombres EXACTOS de las 19 variables del modelo
model_vars <- rownames(as.matrix(coef(mod_geo)))
model_vars <- model_vars[model_vars != "(Intercept)"]

# 2. Cargar el dataset que creamos antes (sin precios)
datos_test <- read.csv("data_test/energy_test_no_price.csv")
colnames(datos_test) <- make.names(colnames(datos_test))

# 3. Crear el "Caso de Estrés"
# Tomamos una fila base y calculamos las variables de memoria necesarias
cat("Preparando datos base con memoria (lags)...\n")
caso_base <- head(datos_test, 1)

# Añadimos clima base para todas las ciudades
ciudades <- c("Madrid", "Barcelona", "Valencia", "Seville", "Bilbao")
for(c in ciudades) {
  caso_base[[paste0("temp_", c)]] <- 290 # 17 grados celsius aprox
  caso_base[[paste0("wind_speed_", c)]] <- 5
}

# Añadimos variables de Calendario y Memoria (para llegar a las 19 variables)
caso_base$hora <- 12
caso_base$mes <- 1
caso_base$es_fin_de_semana <- 0
caso_base$precio_lag_1h <- 50  # Precio base histórico
caso_base$carga_lag_1h <- caso_base$total.load.actual

# Creamos 3 escenarios
escenarios <- list(
  "Normal" = caso_base,
  "Calor_Madrid_40C" = caso_base,
  "Calor_Sevilla_40C" = caso_base
)

escenarios$Calor_Madrid_40C$temp_Madrid <- 313  # 40 grados Kelvin aprox
escenarios$Calor_Sevilla_40C$temp_Seville <- 313

# 4. Realizar predicciones
cat("\n--- RESULTADOS DEL STRESS TEST (19 VARIABLES) ---\n")

for(n in names(escenarios)) {
  # Asegurar que mat_input tiene exactamente las 19 columnas en el orden correcto
  mat_input <- as.matrix(escenarios[[n]][, model_vars])
  pred <- predict(mod_geo, mat_input)
  cat(sprintf("Escenario %-18s: Precio Predicho = %.2f EUR/MWh\n", n, pred))
}

cat("\nInterpretación:\n")
cat("- El modelo ahora usa 19 variables (incluyendo precios anteriores y hora).\n")
cat("- El estrés geográfico ahora es mucho más preciso al considerar el contexto temporal.\n")
