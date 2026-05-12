# Aplicación de Validación: Prueba de Fuego (Blind Data vs Realidad)
# Ubicación: src/app_validation.R

library(shiny)
library(ggplot2)
library(dplyr)
library(tidyr)
library(glmnet)
library(bslib)
library(lubridate)
library(plotly)
library(DT)

# 1. Cargar Recursos
cat("Cargando modelo y datasets para prueba real...\n")
setwd("C:/Users/jinga/Videos/trabajo_final_R")
mod_lasso <- readRDS("models/lasso_geo_model.rds")
model_vars <- rownames(coef(mod_lasso))
model_vars <- model_vars[model_vars != "(Intercept)"]

# Cargar Data Ciega (Sin Precios) y Data Original (Con Precios)
energy_blind <- read.csv("data_test/energy_test_no_price.csv")
energy_real  <- read.csv("data/energy_dataset.csv")
weather_data <- read.csv("data/weather_features.csv")

# 2. Preprocesamiento y Sincronización
cat("Sincronizando datos...\n")
energy_blind$time_posix <- as.POSIXct(energy_blind$time, tz="UTC")
energy_real$time_posix  <- as.POSIXct(energy_real$time, tz="UTC")
weather_data$time_posix <- as.POSIXct(weather_data$dt_iso, tz="UTC")

# Limpiar Clima
weather_wide <- weather_data %>%
  mutate(city_name = trimws(city_name)) %>%
  group_by(time_posix, city_name) %>%
  summarise(temp = mean(temp, na.rm=TRUE), wind_speed = mean(wind_speed, na.rm=TRUE), .groups = "drop") %>%
  pivot_wider(names_from = city_name, values_from = c(temp, wind_speed), names_glue = "{.value}_{city_name}")

# Fusionar todo para tener: [Data Ciega] + [Clima] + [Precio Real para comparar]
df_full <- energy_blind %>%
  inner_join(weather_wide, by = "time_posix") %>%
  inner_join(energy_real %>% select(time_posix, price.actual), by = "time_posix") %>%
  arrange(time_posix) %>%
  mutate(
    hora = hour(time_posix),
    mes = month(time_posix),
    dia_semana = wday(time_posix),
    es_fin_de_semana = ifelse(dia_semana %in% c(1, 7), 1, 0),
    precio_lag_1h = lag(price.actual, 1),
    carga_lag_1h = lag(total.load.actual, 1)
  ) %>%
  drop_na(any_of(c("price.actual", model_vars)))

# UI
ui <- page_navbar(
  theme = bs_theme(bootswatch = "flatly", primary = "#2c3e50"),
  title = " Auditoría de Precisión Real",
  
  nav_panel(
    title = "Prueba Ciega vs Realidad",
    layout_sidebar(
      sidebar = sidebar(
        title = "Control de Validación",
        helpText("Este panel toma los datos ciegos (sin precio) y los enfrenta a la realidad histórica."),
        selectInput("sel_mes", "Seleccionar Mes de Prueba:", 
                    choices = setNames(1:12, c("Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", 
                                             "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre")), 
                    selected = 1),
        hr(),
        h5("Métricas de la prediccion"),
        tableOutput("metrics_table")
      ),
      
      layout_column_wrap(
        width = 1,
        card(
          card_header("¿Qué tan bien adivinó la prediccion? (Línea de Tiempo)"),
          plotlyOutput("plot_compare", height = "450px")
        )
      ),
      
      card(
        card_header("Vista Detallada: Data Ciega + Predicción + Realidad"),
        DTOutput("table_compare")
      )
    )
  )
)

server <- function(input, output) {
  
  # Procesar predicciones para el mes elegido
  processed_data <- reactive({
    df <- df_full %>% filter(month(time_posix) == as.numeric(input$sel_mes))
    
    # Predecir usando el modelo sobre las columnas de la data ciega/clima
    x_val <- as.matrix(df[, model_vars])
    df$PREDICCION_IA <- round(as.vector(predict(mod_lasso, x_val)), 2)
    df$REALIDAD_PAGADA <- round(df$price.actual, 2)
    df$DIFERENCIA <- round(abs(df$REALIDAD_PAGADA - df$PREDICCION_IA), 2)
    
    return(df)
  })
  
  output$metrics_table <- renderTable({
    df <- processed_data()
    r2 <- cor(df$REALIDAD_PAGADA, df$PREDICCION_IA)^2
    mae <- mean(df$DIFERENCIA)
    
    data.frame(
      Métrica = c("Confianza (R²)", "Error Medio (MAE)"),
      Valor = c(paste0(round(r2*100, 1), "%"), paste0(mae, " €"))
    )
  })
  
  output$plot_compare <- renderPlotly({
    df <- head(processed_data(), 168) # 1 semana
    p <- ggplot(df, aes(x = time_posix)) +
      geom_line(aes(y = REALIDAD_PAGADA, color = "Realidad"), size = 1) +
      geom_line(aes(y = PREDICCION_IA, color = "Predicción_ml"), linetype = "dashed", size = 1) +
      scale_color_manual(values = c("Realidad" = "#e74c3c", "Predicción_ml" = "#2c3e50")) +
      theme_minimal() + labs(y = "Precio EUR/MWh", x = "Tiempo")
    
    ggplotly(p)
  })
  
  output$table_compare <- renderDT({
    datatable(processed_data() %>% 
                select(time_posix, total.load.actual, PREDICCION_IA, REALIDAD_PAGADA, DIFERENCIA),
              options = list(pageLength = 10, scrollX = TRUE))
  })
}

shinyApp(ui, server)
