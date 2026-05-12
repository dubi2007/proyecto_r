# Aplicación Web: Intelligence Forecasting System (Master ML Edition - FINAL FIX)
# Ubicación: src/app_geo.R

library(shiny)
library(ggplot2)
library(dplyr)
library(tidyr)
library(glmnet)
library(bslib)
library(lubridate)
library(plotly)
library(randomForest)
library(DT)

# Asegurar directorio de trabajo
if (dir.exists("C:/Users/jinga/Videos/trabajo_final_R")) {
  setwd("C:/Users/jinga/Videos/trabajo_final_R")
}

# 1. CARGA DE RECURSOS Y CEREBRO IA
cat("Cargando cerebro IA y perfiles de mercado...\n")
mod_lasso <- readRDS("models/lasso_geo_model.rds")
# Obtener nombres EXACTOS de las variables del modelo
model_vars <- rownames(as.matrix(coef(mod_lasso)))
model_vars <- model_vars[model_vars != "(Intercept)"]

energy_data <- read.csv("data/energy_dataset.csv")
colnames(energy_data) <- make.names(colnames(energy_data))
energy_data$time_posix <- as.POSIXct(energy_data$time, tz="UTC")

# Crear Perfiles Promedio por Mes
cat("Sincronizando perfiles mensuales...\n")
monthly_profiles <- energy_data %>%
  mutate(mes_num = month(time_posix)) %>%
  group_by(mes_num) %>%
  summarise(
    precio_base_mwh = mean(price.actual, na.rm = TRUE),
    total.load.actual = mean(total.load.actual, na.rm = TRUE),
    generation.fossil.gas = mean(generation.fossil.gas, na.rm = TRUE),
    generation.solar = mean(generation.solar, na.rm = TRUE),
    generation.wind.onshore = mean(generation.wind.onshore, na.rm = TRUE),
    # Variables de clima base (promedios históricos)
    temp_Madrid = 288, temp_Barcelona = 289, temp_Valencia = 290, temp_Seville = 292, temp_Bilbao = 286,
    wind_speed_Madrid = 5, wind_speed_Barcelona = 5, wind_speed_Valencia = 5, wind_speed_Seville = 5, wind_speed_Bilbao = 5,
    .groups = "drop"
  )

# UI
ui <- page_navbar(
  theme = bs_theme(bootswatch = "flatly", primary = "#2c3e50"),
  title = "🏛️ Energy Strategic Predictor (Master ML)",
  
  nav_panel(
    title = "Simulador de Gastos",
    layout_sidebar(
      sidebar = sidebar(
        title = "Control de Inteligencia",
        fileInput("file_hist", "Subir Historial Consumo (.csv)", accept = ".csv"),
        helpText("Sube el archivo de 5 años con ruido para entrenar tu perfil."),
        hr(),
        h5("Escenario Externo"),
        sliderInput("clima_shock", "Desviación de Temperatura (°C):", -10, 10, 0),
        sliderInput("user_trend", "Ajuste de Hábito Personal (%):", -10, 10, 0),
        
        actionButton("run_prediction", " GENERAR PROYECCIÓN MASTER", class = "btn-primary w-100")
      ),
      
      layout_column_wrap(
        width = 1/2,
        value_box(
          title = "Nivel de Confianza (prediccion)",
          value = "%",
          showcase = icon("shield"), # Icono corregido
          theme = "primary"
        ),
        value_box(
          title = "Pago Anual Estimado",
          value = textOutput("vbox_pago"),
          showcase = icon("wallet"),
          theme = "success"
        )
      ),
      
      card(
        card_header("Pronóstico Combinado (Mercado + Hábitos)"),
        plotlyOutput("forecast_plot", height = "400px")
      ),
      
      card(
        card_header("Planilla de Costos Proyectados"),
        DTOutput("forecast_table")
      )
    )
  )
)

server <- function(input, output) {
  
  # MODELO 1: IA DE CONSUMO (Random Forest Dinámico)
  dynamic_rf_model <- reactive({
    if (is.null(input$file_hist)) return(NULL)
    df <- read.csv(input$file_hist$datapath, check.names = FALSE)
    colnames(df) <- trimws(gsub("\"", "", colnames(df)))
    if("Consumo_kWh" %in% colnames(df)) df$Consumo <- df$Consumo_kWh
    # Entrenar modelo
    randomForest(Consumo ~ Mes + Anio, data = df, ntree = 100)
  })

  # MODELO 2: IA DE MERCADO (Lasso L1) + PROYECCIÓN
  projection <- eventReactive(input$run_prediction, {
    rf_user <- dynamic_rf_model()
    
    # Crear grid de 24 meses (2026-2027)
    meses_futuros <- seq(as.Date("2026-01-01"), by = "month", length.out = 24)
    df_grid <- data.frame(
      Fecha = meses_futuros,
      Mes = month(meses_futuros),
      Anio = year(meses_futuros),
      Mes_Nombre = month(meses_futuros, label = TRUE, abbr = FALSE)
    )
    
    # A. Predecir Consumo
    if(!is.null(rf_user)) {
      df_grid$Consumo_IA <- predict(rf_user, df_grid)
    } else {
      df_grid$Consumo_IA <- 350 # Fallback
    }
    df_grid$Consumo_IA <- round(df_grid$Consumo_IA * (1 + (input$user_trend/100)), 2)
    
    # B. Predecir Precio usando el MODELO LASSO REAL
    # Fusionar con perfiles mensuales
    df_predict_price <- df_grid %>%
      inner_join(monthly_profiles, by = c("Mes" = "mes_num")) %>%
      mutate(
        # Ajustes climáticos
        temp_Madrid = temp_Madrid + input$clima_shock,
        temp_Barcelona = temp_Barcelona + input$clima_shock,
        temp_Seville = temp_Seville + input$clima_shock,
        temp_Valencia = temp_Valencia + input$clima_shock,
        temp_Bilbao = temp_Bilbao + input$clima_shock,
        # Variables de memoria y calendario (IGUAL QUE EN ENTRENAMIENTO)
        mes = Mes, # LOWERCASE como espera el modelo
        hora = 12,
        es_fin_de_semana = 0,
        precio_lag_1h = precio_base_mwh,
        carga_lag_1h = total.load.actual
      )
    
    # Asegurar que todas las columnas están presentes y en orden
    mat_in <- as.matrix(df_predict_price[, model_vars])
    
    # Predicción MWh
    pred_mwh <- as.vector(predict(mod_lasso, mat_in))
    df_grid$Precio_kWh_IA <- round(pred_mwh / 1000, 4)
    
    # C. Pago
    df_grid$Pago_Estimado <- round(df_grid$Consumo_IA * df_grid$Precio_kWh_IA, 2)
    
    list(df = df_grid, total_anio = sum(df_grid$Pago_Estimado[1:12]))
  }, ignoreNULL = FALSE)
  
  output$vbox_pago <- renderText({ paste0(round(projection()$total_anio, 2), " €") })
  
  output$forecast_plot <- renderPlotly({
    df <- projection()$df
    p <- ggplot(df, aes(x = Fecha)) +
      geom_line(aes(y = Consumo_IA, color = "Consumo_prediccion (kWh)"), size = 1) +
      geom_line(aes(y = Pago_Estimado * 5, color = "Gasto_prediccion (Euros x5)"), linetype = "dashed", size = 1) +
      scale_color_manual(values = c("Consumo_prediccion (kWh)" = "#3498db", "Gasto_prediccion (Euros x5)" = "#e67e22")) +
      theme_minimal() + labs(y = "Escala_prediccion", x = "", color = "Leyenda")
    ggplotly(p)
  })
  
  output$forecast_table <- renderDT({
    datatable(projection()$df %>% 
                select(Fecha, Mes_Nombre, Consumo_IA, Precio_kWh_IA, Pago_Estimado),
              options = list(pageLength = 12, dom = 't'))
  })
}

shinyApp(ui, server)
