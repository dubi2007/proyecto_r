# Script: Visualización del "Cerebro" del Modelo (Lasso L1)
# Ubicación: src/generate_model_plots.R

library(glmnet)
library(ggplot2)
library(dplyr)
library(tidyr)

cat("--- EXTRRAYENDO INTELIGENCIA DEL MODELO .RDS ---\n")
# 1. Cargar el modelo
mod <- readRDS("models/lasso_geo_model.rds")

# 2. Extraer coeficientes (Ignorar el Intercepto)
coefs <- as.matrix(coef(mod))
df_coefs <- data.frame(
  Variable = rownames(coefs),
  Peso = as.vector(coefs)
) %>% 
  filter(Variable != "(Intercept)" & Peso != 0) %>%
  mutate(
    Abs_Peso = abs(Peso),
    Direccion = ifelse(Peso > 0, "Sube el Precio (+)", "Baja el Precio (-)"),
    Categoria = case_when(
      grepl("temp", Variable) ~ "Clima (Temp)",
      grepl("wind", Variable) ~ "Clima (Viento)",
      grepl("generation", Variable) ~ "Generación Eléctrica",
      grepl("lag|carga", Variable) ~ "Memoria Temporal",
      TRUE ~ "Calendario/Otros"
    )
  )

# Carpeta de salida
if(!dir.exists("presentation/model_insights")) dir.create("presentation/model_insights", recursive=TRUE)

# --- GRÁFICO 1: IMPORTANCIA GLOBAL (MAGNITUD) ---
cat("Generando Gráfico 1: Importancia Global...\n")
png("presentation/model_insights/1_global_importance.png", width=900, height=700)
print(ggplot(df_coefs, aes(x=reorder(Variable, Abs_Peso), y=Abs_Peso, fill=Categoria)) +
  geom_col() + coord_flip() +
  scale_fill_brewer(palette="Set2") +
  theme_minimal(base_size = 14) +
  labs(title="Jerarquía de Variables: ¿Qué mira más la IA?", 
       x="", y="Fuerza del Impacto (Absoluto)",
       subtitle="Ranking de las 19 variables que definen el precio"))
dev.off()

# --- GRÁFICO 2: SENSIBILIDAD GEOGRÁFICA (CIUDADES) ---
cat("Generando Gráfico 2: Sensibilidad por Ciudad...\n")
df_geo <- df_coefs %>% filter(Categoria %in% c("Clima (Temp)", "Clima (Viento)"))
png("presentation/model_insights/2_city_sensitivity.png", width=900, height=700)
print(ggplot(df_geo, aes(x=Variable, y=Peso, fill=Direccion)) +
  geom_col() + coord_flip() +
  scale_fill_manual(values=c("#2ecc71", "#e74c3c")) +
  theme_minimal(base_size = 14) +
  labs(title="Sensibilidad Geográfica: Impacto de cada Ciudad", 
       x="", y="Peso en el Modelo (Direccional)",
       subtitle="Muestra cómo el clima local de cada ciudad mueve el precio nacional"))
dev.off()

# --- GRÁFICO 3: IMPACTO DE FUENTES DE ENERGÍA ---
cat("Generando Gráfico 3: Impacto de Generación...\n")
df_energy <- df_coefs %>% filter(Categoria == "Generación Eléctrica" | Variable == "total.load.actual")
png("presentation/model_insights/3_energy_impact.png", width=900, height=700)
print(ggplot(df_energy, aes(x=reorder(Variable, Peso), y=Peso, fill=Peso > 0)) +
  geom_col(width=0.6) +
  scale_fill_manual(values=c("#3498db", "#f1c40f"), labels=c("Reducción de Costo", "Aumento de Costo")) +
  theme_minimal(base_size = 14) +
  labs(title="Dinámica Energética: Fuentes vs Precio", 
       x="", y="Impacto Neto",
       fill="Efecto Económico"))
dev.off()

# --- GRÁFICO 4: MEMORIA VS CONTEXTO (ESTRUCTURA DEL MODELO) ---
cat("Generando Gráfico 4: Composición del Cerebro...\n")
df_cat <- df_coefs %>% group_by(Categoria) %>% summarise(Impacto_Total = sum(Abs_Peso))
png("presentation/model_insights/4_model_architecture.png", width=900, height=700)
print(ggplot(df_cat, aes(x="", y=Impacto_Total, fill=Categoria)) +
  geom_col(width=1) + coord_polar("y", start=0) +
  scale_fill_brewer(palette="Pastel1") +
  theme_void(base_size = 14) +
  labs(title="Arquitectura de Decisión: Composición del Modelo",
       subtitle="Reparto de peso entre Memoria, Clima y Generación"))
dev.off()

cat("\n¡4 GRÁFICOS GENERADOS EXITOSAMENTE EN 'presentation/model_insights/'!\n")
