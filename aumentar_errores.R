#=========================================================================================================================================#
# Script para aumentar errores y particionar dataset usado para el procesamiento de la validación de datos de censo
#
# Creado por: Hugo Soto Parada
# Cargo: Centífico de Datos. Subdirección Técnica.
# E-mail Institucional: hesotop@ine.gob.cl
# E-mail Particular: hugosotoparada@gmail.com
# Diciembre 2023
#
#=========================================================================================================================================#


library(arrow)
library(tidyverse)
library(stringr)

########## TRANSFORMAR VALIDADORES A DATA FRAME ---------------------------------------------------
source(file = "../funciones_validaciones_hs.R", encoding = "UTF-8")

source(file = "../04_rph_val_est_hs.R", encoding = "UTF-8")
rango_rph <- fn_list_dt(lista = rango, val = "rph_ran", validador = "Rango")
asignacion_rph <- fn_list_dt(lista = asignacion, val = "rph_asi", validador = "Asignacion")

source(file = "../09_educacion_val_est_hs.R", encoding = "UTF-8")
rango_edu <- fn_list_dt(lista = rango, val = "edu_ran", validador = "Rango")
asignacion_edu <- fn_list_dt(lista = asignacion, val = "edu_asi", validador = "Asignacion")

reglas <- list(
  rango_rph = rango_rph,
  # asignacion_rph = asignacion_rph,
  rango_edu = rango_edu
  # asignacion_edu = asignacion_edu
)

# dataset adapted for validation
# filename <- "../data/persona2017_adaptado_geo.feather"
filename <- "../data/persona2017_adaptado_geo_modalidad.feather"

data <- arrow::read_feather(
  filename,
  as_data_frame = T
)

# n_err <- 2.5e6
# n_err <- 5e6
# n_err <- 7.5e6
# n_err <- 10e6
# n_err <- 12.5e6
# n_err <- 15e6
# n_err <- 17.5e6
n_err <- 20e6

# aumentar errores registro de personas
lista_error_rph <- list(
  "rph_ran_1" = n_err,
  "rph_ran_2" = n_err,
  "rph_ran_3" = n_err
)
data_err <- aumentar_errores_rph(data, lista_error_rph)

# aumentar errores educación
lista_error_edu <- list(
  "edu_ran_1" = n_err
  # "edu_ran_2" = n_err,
  # "edu_ran_3" = n_err
)
data_err <- aumentar_errores_edu(data_err, lista_error_edu)

# validar aumento de errores
for (r in names(reglas)) {

  message <- (paste0("Errores: ",r))
  print(message)

  regla <- reglas[r][[1]]

  for (i in 1:nrow(regla)) {

    validacion <- regla[i,]$validacion

    n1 <- data %>%
      filter(!!rlang::parse_expr(regla[i,]$condicion)) %>%
      nrow()

    message1 <- (paste0("Errores en dataset original para validacion ",validacion,": ",n1))
    print(message1)

    n2 <- data_err %>%
      filter(!!rlang::parse_expr(regla[i,]$condicion)) %>%
      nrow()

    message2 <- (paste0("Errores en dataset aumentado para validacion ",validacion,": ",n2))
    print(message2)

  }

}

# write adapted dataset with entrevista_id
# file_out <- "../data/persona2017_adaptado_geo_err_aum"
file_out <- "../data/persona2017_adaptado_geo_modalidad_err_aum"
# arrow::write_csv_arrow(
#   data_err,
#   file=paste0(file_out,".csv")
# )
arrow::write_feather(data_err, paste0(file_out,".feather"))

# particionar data
# particionar_dataset(data, tipo_particion="3", path_sufix="")
particionar_dataset(data_err, tipo_particion="1", path_sufix="_err_aum")
