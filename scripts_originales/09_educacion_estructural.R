
############################################################:
# Autor: Censo de poblacion y vivienda 2024                #:
# Seccion: Cuestionario censal - persona                   #:
# Fecha: Abril 2023                                        #:
############################################################:

inicio_validaciones <- Sys.time()

########## DEFINIR DIRECCIONES -------------------------------
ubi_tab <- "../data_in_censo/02_data_integrada/"
ubi_val <- "scripts/03_validaciones/validadores/estructural/"
ubi_func <- "scripts/funciones/"
ubi_out <- "../data_in_censo/04_data_validada/estructural/"

########## CARGAR LIBRERIAS -------------------------------
library(data.table)
library(readr)
library(openxlsx)
library(tidyverse)
library(feather)
library(arrow)

########## CARGAR FUNCIONES Y VALIDADORES -------------------------------------------------
source(file = paste0(ubi_func,"funciones_validaciones.R"), encoding = "UTF-8")

source(file = paste0(ubi_val,"09_educacion_val_est.R"), encoding = "UTF-8")


########## CARGAR TABLA -------------------------------------------------
archivos <- tolower(list.files(ubi_tab, pattern = ".feather"))
archivos <- archivos[str_detect(archivos,"persona")]

data <- archivos |> 
  map(~read_feather(paste0(ubi_tab,.x), 
                    col_select = c("entrevista_id",
                                   "hogar_id","persona_id","sexo_validado", #corregir
                                   "edad_validada","alfabet","edu_nivel","edu_curso","edu_nivel_completa","edu_asiste"),
                    as_data_frame = FALSE))
data <- do.call(rbind, data)
data <- data |>
  filter(across(starts_with("ignore"), ~is.na(.)))


########## TRANSFORMAR VALIDADORES A DATA FRAME ---------------------------------------------------
rango_df <- fn_list_dt(lista = rango, val = "edu_ran", validador = "Rango")
asignacion_df <- fn_list_dt(lista = asignacion, val = "edu_asi", validador = "Asignacion")

########## APLICACION VALIDACION ---------------------------------------------------
# aplicar validaciones
vals_ran <- fn_val(data, rango_df, ids = c("entrevista_id","hogar_id","persona_id"))
vals_ran_df <- fn_list_dt(lista = vals_ran, validador = "Rango")

vals_asi <- fn_val(data, asignacion_df, ids = c("entrevista_id","hogar_id","persona_id"))
vals_asi_df <- fn_list_dt(lista = vals_asi, validador = "Asignacion")

# unificacion tipos de validador
var_report <- c("entrevista_id","hogar_id","persona_id","tipo_validador","id_regla","variable","descripcion")

# inconsistencia_09_educacion <- full_join(vals_ran_df,
#                                         vals_err_df)

vals_09_educacion <- rbind(data.frame(vals_ran_df)[,var_report],
                         data.frame(vals_asi_df)[,var_report])


# EXPORTACION -------------------------------------------------------------
write_feather(x = vals_09_educacion, paste0(ubi_out,"09_educacion_estructural.feather"))

borrar <- ls()
borrar <- borrar[!str_detect(borrar,"inicio")]
borrar <- borrar[!str_detect(borrar,"vals_0")]
borrar <- borrar[!str_detect(borrar,"vals_1")]
rm(list = borrar)

# Duración implementacion -------------------------------------------------

secs <- difftime(Sys.time(), inicio_validaciones, units = "sec")
# 4. Tiempo ---------------------------------------------------

library(openxlsx)

archivo_exportacion <- paste0("../data_in_censo/02_data_integrada/duracion_validacion/01_duracion/duracion_validacion_estructural.xlsx")

# Verificar si el archivo existe
if (file.exists(archivo_exportacion)) {
  # Cargar el archivo existente y obtener el data frame actual
  wb <- loadWorkbook(archivo_exportacion)
  df_actual <- read.xlsx(wb)
  
  # Agregar las nuevas filas al data frame actual
  fecha <- as.character(Sys.Date())
  script <- "09_educacion_estructural.R"
  duracion <- secs
  nueva_fila <- data.frame(fecha = fecha, script = script, duracion = duracion)
  df_actual <- rbind(df_actual, nueva_fila)
  
  # Sobrescribir el contenido del archivo con el data frame actualizado
  write.xlsx(df_actual, file = archivo_exportacion, rowNames = FALSE)
} else {
  
  fecha <- as.character(Sys.Date())
  script <- "09_educacion_estructural.R"
  duracion <- secs
  df_actual <- data.frame(fecha = fecha, script = script, duracion = duracion)
  
  # Escribir la nueva fila en el archivo
  write.xlsx(df_actual, file = archivo_exportacion, append = TRUE, rowNames = FALSE)
}
