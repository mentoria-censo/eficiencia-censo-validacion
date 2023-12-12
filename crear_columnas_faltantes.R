#=========================================================================================================================================#
# Script para crear columnas faltantes para ejecutar el procesamiento de la validación de datos de censo
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

source(file="../funciones_validaciones_hs.R", encoding = "UTF-8")

# dataset adapted for validation
filename <- "../data/persona2017_adaptado.feather"

persona <- arrow::read_feather(
  filename,
  as_data_frame = T
)

persona <- agregar_columnas_geograficas(persona)

persona <- agregar_columna_modalidad(persona)

# # dataset previously used for integration
# filename <- "/home/hugosoto/Work/ine/validaciones_Censo_2017/persona_with_entrevistaid_arrow.feather"

# persona_integracion <- arrow::read_feather(
#   filename,
#   as_data_frame = T
# )

# # join both datasets, to search for common entrevista_id values in dataset from integracion
# persona_out <- persona %>%
#   left_join(
#     persona_integracion %>%
#       select(c("entrevista_id","REGION","PROVINCIA","COMUNA")) %>%
#       group_by(entrevista_id) %>%
#       mutate(
#         region = REGION[[1]],
#         provincia = PROVINCIA[[1]],
#         comuna = COMUNA[[1]]
#       ) %>%
#     ungroup() %>%
#     distinct() %>%
#     select(c("entrevista_id","region","provincia","comuna")),
#     by = c("entrevista_id")
#   )

# write adapted dataset with entrevista_id
# file_out <- "../data/persona2017_adaptado_geo"
file_out <- "../data/persona2017_adaptado_geo_modalidad"
arrow::write_csv_arrow(
  persona,
  file=paste0(file_out,".csv")
)
arrow::write_feather(persona, paste0(file_out,".feather"))

# particionar data
particionar_dataset(persona, tipo_particion="1")
