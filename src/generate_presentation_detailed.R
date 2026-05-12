# Script para generar PPT Detallado con Explicaciones
library(officer)
library(ggplot2)
library(dplyr)
library(corrplot)
library(randomForest)
library(magrittr)

# Cargar datos y modelos necesarios
energy_data <- read.csv("data/energy_dataset.csv")
colnames(energy_data) <- make.names(colnames(energy_data))
mod_rf <- readRDS("models/random_forest_tuned.rds")

# Re-generar algunos datos para las explicaciones
set.seed(123)
test_sample <- energy_data[sample(nrow(energy_data), 50), ]
test_sample$temp <- 285; test_sample$pressure <- 1013; test_sample$humidity <- 60; test_sample$wind_speed <- 5
preds_rf <- predict(mod_rf, test_sample)

# --- CREACIÓN DEL PPT DETALLADO ---
doc <- read_pptx()

# 1. Portada
doc <- add_slide(doc, layout = "Title Slide", master = "Office Theme") %>%
  ph_with(value = "Análisis y Predicción del Precio de Energía", location = ph_location_label(ph_label = "Title 1")) %>%
  ph_with(value = "Explicación Detallada de Modelos y Resultados", location = ph_location_label(ph_label = "Subtitle 2"))

# 2. Explicación: ¿Cómo funcionan los modelos? (Teoría)
doc <- add_slide(doc, layout = "Title and Content", master = "Office Theme") %>%
  ph_with(value = "Fundamentos: Modelos de Regularización", location = ph_location_label(ph_label = "Title 1")) %>%
  ph_with(value = c(
    "Lasso (L1): Funciona eliminando variables poco importantes. Obliga a que algunos coeficientes sean cero, actuando como un selector automático de variables.",
    "Ridge (L2): No elimina variables, pero reduce el impacto de todas ellas para que ninguna domine el modelo. Es ideal cuando hay muchas variables relacionadas.",
    "Elastic Net: Combina lo mejor de ambos mundos (L1 y L2) para obtener un modelo robusto y simplificado."
  ), location = ph_location_label(ph_label = "Content Placeholder 2"))

# 3. Explicación: ¿Qué es Random Forest?
doc <- add_slide(doc, layout = "Title and Content", master = "Office Theme") %>%
  ph_with(value = "Fundamentos: Random Forest Tuned", location = ph_location_label(ph_label = "Title 1")) %>%
  ph_with(value = c(
    "¿Qué es?: Es un conjunto de muchos árboles de decisión que votan para dar un resultado promedio.",
    "Control de Sobreajuste: Hemos limitado la profundidad (maxnodes) y el tamaño de las hojas (nodesize).",
    "Ventaja: Capta relaciones no lineales que la regresión simple no puede ver (ej: el precio sube exponencialmente con la carga)."
  ), location = ph_location_label(ph_label = "Content Placeholder 2"))

# 4. Gráfico 1: Distribución + Explicación
doc <- add_slide(doc, layout = "Two Content", master = "Office Theme") %>%
  ph_with(value = "1. Distribución de Precios", location = ph_location_label(ph_label = "Title 1")) %>%
  ph_with(value = external_img("presentation/assets/plot1_dist.png"), location = ph_location_label(ph_label = "Content Placeholder 2")) %>%
  ph_with(value = "Significado: Muestra que los precios suelen concentrarse entre 40 y 60 EUR/MWh. Las 'colas' del gráfico indican momentos de crisis o picos de demanda donde el precio se dispara, lo cual es el mayor reto para el modelo.", location = ph_location_label(ph_label = "Content Placeholder 3"))

# 5. Gráfico 4: Correlación + Explicación
doc <- add_slide(doc, layout = "Two Content", master = "Office Theme") %>%
  ph_with(value = "2. Mapa de Correlación", location = ph_location_label(ph_label = "Title 1")) %>%
  ph_with(value = external_img("presentation/assets/plot4_corr.png"), location = ph_location_label(ph_label = "Content Placeholder 2")) %>%
  ph_with(value = "Significado: El color azul fuerte indica una relación directa. Aquí vemos que la 'Carga Total' tiene la correlación más alta con el precio. Si la carga sube, el precio sube. Esto confirma que la carga es nuestra variable principal.", location = ph_location_label(ph_label = "Content Placeholder 3"))

# 6. Gráfico 2: Carga vs Precio + Explicación
doc <- add_slide(doc, layout = "Two Content", master = "Office Theme") %>%
  ph_with(value = "3. Relación Carga vs Precio", location = ph_location_label(ph_label = "Title 1")) %>%
  ph_with(value = external_img("presentation/assets/plot2_scatter.png"), location = ph_location_label(ph_label = "Content Placeholder 2")) %>%
  ph_with(value = "Significado: La línea roja es la tendencia. Cada punto es una hora del día. Vemos que a mayor carga (demanda), el precio tiende a subir linealmente, aunque hay mucha dispersión por factores externos como el clima.", location = ph_location_label(ph_label = "Content Placeholder 3"))

# 7. Gráfico 5: Importancia + Explicación
doc <- add_slide(doc, layout = "Two Content", master = "Office Theme") %>%
  ph_with(value = "4. ¿Qué influye más en el precio?", location = ph_location_label(ph_label = "Title 1")) %>%
  ph_with(value = external_img("presentation/assets/plot5_imp.png"), location = ph_location_label(ph_label = "Content Placeholder 2")) %>%
  ph_with(value = "Significado: El Random Forest nos dice que la Carga Total y el Gas Fósil son los reyes del precio. Curiosamente, el viento y el sol también aparecen, indicando que las renovables ayudan a mover la aguja del mercado.", location = ph_location_label(ph_label = "Content Placeholder 3"))

# 8. Gráfico 6: Validación + Explicación
doc <- add_slide(doc, layout = "Two Content", master = "Office Theme") %>%
  ph_with(value = "5. Precisión del Modelo", location = ph_location_label(ph_label = "Title 1")) %>%
  ph_with(value = external_img("presentation/assets/plot6_pred.png"), location = ph_location_label(ph_label = "Content Placeholder 2")) %>%
  ph_with(value = "Significado: Comparamos la realidad (línea continua) con lo que dijo el modelo (línea puntos). Como se siguen de cerca, sabemos que el modelo es capaz de 'aprender' los ciclos diarios de precio.", location = ph_location_label(ph_label = "Content Placeholder 3"))

# 9. Gráfico 7: Residuales + Explicación
doc <- add_slide(doc, layout = "Two Content", master = "Office Theme") %>%
  ph_with(value = "6. Análisis de Errores", location = ph_location_label(ph_label = "Title 1")) %>%
  ph_with(value = external_img("presentation/assets/plot7_res.png"), location = ph_location_label(ph_label = "Content Placeholder 2")) %>%
  ph_with(value = "Significado: Este gráfico muestra la distribución de nuestros fallos. Al estar centrado en cero, significa que el modelo no tiene un sesgo sistemático (no siempre predice por arriba o siempre por abajo).", location = ph_location_label(ph_label = "Content Placeholder 3"))

# 10. Gráfico 8: Comparativa + Conclusión
doc <- add_slide(doc, layout = "Two Content", master = "Office Theme") %>%
  ph_with(value = "7. Comparativa y Conclusión", location = ph_location_label(ph_label = "Title 1")) %>%
  ph_with(value = external_img("presentation/assets/plot8_rmse.png"), location = ph_location_label(ph_label = "Content Placeholder 2")) %>%
  ph_with(value = "Significado: El Random Forest (barra más baja) es el más preciso. Sin embargo, Lasso y Ridge son fundamentales porque aseguran que el modelo funcione bien con datos nuevos que nunca ha visto.", location = ph_location_label(ph_label = "Content Placeholder 3"))

# Guardar la versión final
print(doc, target = "presentation/Explicacion_Detallada_Proyecto.pptx")
cat("Presentación detallada generada exitosamente en: presentation/Explicacion_Detallada_Proyecto.pptx\n")
