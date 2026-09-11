# Energy Price Intelligence

Proyecto de Machine Learning desarrollado en R para analizar y predecir el comportamiento del mercado eléctrico en España.

El proyecto utiliza datos históricos de generación de energía y variables climáticas de cinco ciudades principales de España obtenidos de Kaggle. La idea es combinar información temporal y geográfica para generar predicciones que puedan servir como apoyo para el análisis y la toma de decisiones.

## ¿Qué incluye el proyecto?

### Predicción del precio de energía

Se desarrolló un modelo Lasso (L1) que utiliza información histórica del mercado mediante variables temporales (lags) y factores relacionados con el clima y la ubicación geográfica.

El modelo alcanzó una precisión aproximada del 96.4% en las pruebas realizadas.

### Predicción del consumo personal

También se implementó un modelo Random Forest orientado a aprender los patrones de consumo de un usuario a partir de su propio historial.

La idea es que el modelo pueda adaptarse progresivamente a los hábitos de consumo en lugar de utilizar únicamente un patrón general.

### Dashboard interactivo

El proyecto cuenta con una aplicación desarrollada con Shiny que permite visualizar las predicciones y analizar diferentes escenarios.

Entre sus funciones se encuentran:

* Proyecciones financieras de hasta 24 meses.
* Visualización de tendencias del mercado.
* Análisis de variables climáticas.
* Simulación de posibles cambios o shocks climáticos.
* Comparación de diferentes escenarios.

### Validación de las predicciones

Se desarrolló una aplicación independiente para comparar las predicciones del modelo con los valores históricos reales.

Esto permite comprobar cómo se comporta el modelo frente a datos que no utilizó directamente durante el entrenamiento.

### Generación de reportes

El proyecto también incluye scripts para generar reportes en Word y gráficos que pueden utilizarse en presentaciones o análisis.

## Estructura del proyecto

```text
proyecto_r/
│
├── src/
│   ├── train_final_v2.R      # Entrenamiento del modelo
│   ├── app_geo.R             # Dashboard principal
│   └── app_validation.R      # Validación de predicciones
│
├── models/
│   └── lasso_geo_model.rds   # Modelo entrenado
│
├── data/
│   └── ...                   # Datos d
```
