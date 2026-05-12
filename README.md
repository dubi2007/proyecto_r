# Energy Price Intelligence Master Framework ⚡

Este proyecto es un sistema integral de **Machine Learning** desarrollado en **R** para la predicción y el análisis estratégico del mercado eléctrico español. Utiliza datos históricos de generación de energía y clima de 5 ciudades principales de España (Kaggle).

## 🚀 Características Principales

*   **IA de Mercado (96.4% precisión)**: Modelo Lasso L1 que utiliza memoria temporal (lags) y factores geoclimáticos.
*   **IA de Consumo Personalizada**: Modelo Random Forest dinámico que aprende los hábitos del usuario a partir de su historial.
*   **Dashboard Estratégico**: Aplicación web interactiva (Shiny) para proyecciones financieras a 24 meses y simulaciones de shocks climáticos.
*   **Auditoría de Confianza**: Herramienta de validación real comparando predicciones contra el histórico real.
*   **Reportes Senior Automáticos**: Generación de informes profesionales en Word y activos visuales para presentaciones.

## 📂 Estructura del Proyecto

*   `src/`: Scripts de entrenamiento, aplicaciones web y generadores de reportes.
    *   `train_final_v2.R`: Corazón del modelado ML.
    *   `app_geo.R`: Dashboard de simulación financiera.
    *   `app_validation.R`: Validador de precisión IA.
*   `models/`: Almacena el cerebro entrenado (`lasso_geo_model.rds`).
*   `data/`: Datasets originales de energía y clima.
*   `data_test/`: Datasets para pruebas ciegas y simulación de historial.
*   `presentation/`: Colección de 16 gráficos maestros e informes finales.

## 🛠️ Instalación y Uso

1.  Asegúrate de tener **R** y **RStudio** instalados.
2.  Clona este repositorio:
    ```bash
    git clone https://github.com/dubi2007/proyecto_r.git
    ```
3.  Instala las dependencias necesarias en R:
    ```R
    install.packages(c("shiny", "ggplot2", "dplyr", "glmnet", "randomForest", "plotly", "bslib", "officer", "tidyr", "lubridate", "DT"))
    ```
4.  Ejecuta la aplicación principal:
    ```R
    shiny::runApp('src/app_geo.R')
    ```

## 📊 Resultados Técnicos
El sistema ha demostrado una estabilidad excepcional, logrando un **MAE de 1.93€** y manteniendo la precisión en datos futuros (Backtesting 2018), lo que garantiza un aprendizaje estructural del mercado energético.

---
*Desarrollado por un Senior Data Analyst para toma de decisiones estratégicas.*
