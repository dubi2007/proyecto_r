# Script para generar 5 años de consumo (Alta Variabilidad y Ruido Realista)
library(dplyr)

set.seed(456) # Nueva semilla para cambiar los datos

# 1. Ampliar a 5 años (2021 - 2025)
anios <- 2021:2025
meses <- 1:12

df_historial <- expand.grid(Mes = meses, Anio = anios)
df_historial <- df_historial[order(df_historial$Anio, df_historial$Mes), ]

# 2. Generar Consumo con "Caos Realista"
# Base de 300 + Estacionalidad + Tendencia + RUIDO EXTREMO
df_historial$Consumo <- round(
  320 + 
  (60 * sin(2 * pi * df_historial$Mes / 12 + 0.5)) + # Ciclos estacionales fuertes
  (1.5 * (df_historial$Anio - 2021) * 12 + df_historial$Mes) + # Crecimiento gradual
  rnorm(nrow(df_historial), mean = 0, sd = 75), # MUCHO RUIDO (SD=75)
  0
)

# 3. Inyectar "Anomalías Senior" (Picos y valles impredecibles)
# Simulamos meses de vacaciones o averías en electrodomésticos
anomalias <- sample(1:nrow(df_historial), 8)
df_historial$Consumo[anomalias[1:4]] <- df_historial$Consumo[anomalias[1:4]] * 1.8 # Picos locos
df_historial$Consumo[anomalias[5:8]] <- df_historial$Consumo[anomalias[5:8]] * 0.4 # Bajones drásticos

# Asegurar valores mínimos lógicos
df_historial$Consumo[df_historial$Consumo < 80] <- 120

# 4. Guardar archivo actualizado
output_path <- "data_test/consumo_historico_3anios.csv" # Mantenemos el nombre para que la app no falle
write.csv(df_historial, output_path, row.names = FALSE, quote = FALSE)

cat("Dataset de 5 años con ALTO RUIDO creado en:", output_path, "\n")
cat("Registros totales:", nrow(df_historial), "\n")
print(head(df_historial, 12)) # Mostrar 2021
