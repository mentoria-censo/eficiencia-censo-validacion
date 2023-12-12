
############################################################:
# Autor: Censo de poblacion y vivienda 2024                #:
# Seccion: Cuestionario censal - persona                   #:
# Fecha: Abril 2023                                        #:
############################################################:

#=========================================================================================================================================#
#
# Script editado por: Hugo Soto Parada
# Cargo: Centífico de Datos. Subdirección Técnica.
# E-mail Institucional: hesotop@ine.gob.cl
# E-mail Particular: hugosotoparada@gmail.com
# Diciembre 2023
#
#=========================================================================================================================================#


############################################################################################
# PARAMETROS DE SCRIPT -------------------------------------------------

args <- commandArgs(trailingOnly=TRUE)

print(args)

parametros <- list()
parametros$tipo_particion <- args[1]
# parametros$formato_reporte <- args[2]
parametros$usar_arrow_para_validacion <- args[2]
parametros$errores_aumentado <- args[3]

print(parametros)

# # stop script execution
# quit(save="no")

############################################################################################

########## DEFINIR DIRECCIONES -------------------------------
ubi_tab <- paste0(getwd(),"/")
ubi_val <- ubi_tab
ubi_func <- ubi_tab
ubi_out <- ubi_tab

dir_in <- paste0(getwd(),"/data")
dir_out <- paste0(getwd(),"/resultados")

########## CARGAR LIBRERIAS -------------------------------
library(data.table)
library(readr)
library(openxlsx)
library(tidyverse)
library(feather)
library(arrow)

########## CARGAR FUNCIONES Y VALIDADORES -------------------------------------------------
source(file = paste0(ubi_func,"funciones_validaciones.R"), encoding = "UTF-8")
source(file = paste0(ubi_val,"04_rph_val_est.R"), encoding = "UTF-8")

# # stop script execution
# quit(save="no")

########## CARGAR TABLA -------------------------------------------------
# archivos <- tolower(list.files(ubi_tab, pattern = ".feather"))
# archivos <- archivos[str_detect(archivos,"persona")]

# data <- archivos |> 
#   map(~read_feather(paste0(ubi_tab,.x), 
#                     col_select = c("entrevista_id","tipo_operativo",
#                                    "hogar_id","persona_id", #corregir
#                                    "sexo_validado", "edad_validada","parentesco"),
#                     as_data_frame = FALSE))
# data <- do.call(rbind, data)
# data <- data |>
#   filter(across(starts_with("ignore"), ~is.na(.))) # check

columnas_input <- c(
  "entrevista_id",
  "tipo_operativo",
  "hogar_id",
  "persona_id",
  "sexo_validado",
  "edad_validada",
  "parentesco",
  "region",
  "provincia",
  "comuna",
  "modalidad",
  "capi",
  "cawi",
  "papi"
)

if (parametros$tipo_particion == "1") {
  particion <- "region"
  cols_partition <- c("region")
} else if (parametros$tipo_particion == "2") {
  particion <- "region_provincia"
  cols_partition <- c("region","provincia")
} else if (parametros$tipo_particion == "3") {
  particion <- "region_provincia_comuna"
  cols_partition <- c("region","provincia","comuna")
} else {
  particion <- "no"
}

if (particion != "no") {
  format_dataset <- "feather"
  path_dataset <- paste0(dir_in,"/persona_particionado_",particion)
  if (parametros$errores_aumentado != "err_aum_no") {
    path_dataset <- paste0(path_dataset,"_",parametros$errores_aumentado)
  }
  print(paste0("leyendo dataset particionado desde: ",path_dataset))
  data <- arrow::open_dataset(
    path_dataset,
    format=format_dataset,
    partitioning=cols_partition
  ) %>% 
    select(all_of(columnas_input))
} else {
  # path_dataset <- "persona2017_adaptado.feather"
  path_dataset <- paste0(dir_in,"/persona2017_adaptado_geo_modalidad.feather")
  if (parametros$errores_aumentado != "err_aum_no") {
    path_dataset <- paste0(str_replace(path_dataset,".feather",""),"_",parametros$errores_aumentado,".feather")
  }
  print(paste0("leyendo dataset no particionado desde: ",path_dataset))
  data <- arrow::read_feather(
    path_dataset,
    as_data_frame = FALSE,
    col_select=all_of(columnas_input)
  )
}

print(class(data))
print(dim(data))
print(names(data))
# print(as.data.frame(data) %>% head())

# # stop script execution
# quit(save="no")

########## TRANSFORMAR VALIDADORES A DATA FRAME ---------------------------------------------------
rango_df <- fn_list_dt(lista = rango, val = "rph_ran", validador = "Rango")
asignacion_df <- fn_list_dt(lista = asignacion, val = "rph_asi", validador = "Asignacion")


########## APLICACION VALIDACION ---------------------------------------------------
# aplicar validaciones

# unificacion tipos de validador
ids_val <- c("entrevista_id","hogar_id","persona_id","region","provincia","comuna","modalidad","capi","cawi","papi")
var_report <- c("entrevista_id","hogar_id","persona_id","region","provincia","comuna","modalidad","capi","cawi","papi","tipo_validador","id_regla","variable","descripcion")

if (parametros$usar_arrow_para_validacion == "FALSE") {

  vals_ran <- fn_val(data, rango_df, ids = ids_val)
  vals_ran_df <- fn_list_dt(lista = vals_ran, validador = "Rango")

  vals_asi <- fn_val(data, asignacion_df, ids = ids_val)
  vals_asi_df <- fn_list_dt(lista = vals_asi, validador = "Asignacion")

  # inconsistencia_04_rph <- full_join(vals_ran_df,
  #                                    vals_asi_df)

  vals_04_rph <- rbind(
    data.frame(vals_ran_df)[,var_report],
    data.frame(vals_asi_df)[,var_report]
  )

} else {

  vals_ran_arrow <- fn_val_arrow(data, rango_df, ids = ids_val)
  vals_ran_arrow <- fn_list_arrow(lista = vals_ran_arrow, validador = "Rango")

  vals_asi_arrow <- fn_val_arrow(data, asignacion_df, ids = ids_val)
  vals_asi_arrow <- fn_list_arrow(lista = vals_asi_arrow, validador = "Rango")

  vals_04_rph <- arrow::concat_tables(vals_ran_arrow,vals_asi_arrow) %>%
    select(all_of(var_report))

}

# EXPORTACION -------------------------------------------------------------

# TODO: implement partitioning of output data, need to check how to retrieve cols region, provincia, comuna from fn_val()

if (particion != "no") {
  path_dataset <- paste0(dir_out,"/04_rph_estructural_particionado_",particion)
  print(paste0("escribiendo dataset validado, particionado, a: ",path_dataset))
  unlink(path_dataset,recursive = TRUE)
  arrow::write_dataset(
    vals_04_rph,
    path_dataset,
    format=format_dataset,
    partitioning=cols_partition
  )
} else {
  path_dataset <- paste0(dir_out,"/04_rph_estructural.feather")
  print(paste0("escribiendo dataset validado, no particionado, a: ",path_dataset))
  arrow::write_feather(
    vals_04_rph,
    paste0(path_dataset)
  )
}

# arrow::write_csv_arrow(vals_04_rph,file=paste0(ubi_out,"04_rph_estructural.csv"))

borrar <- ls()
borrar <- borrar[!str_detect(borrar,"inicio")]
borrar <- borrar[!str_detect(borrar,"vals_0")]
borrar <- borrar[!str_detect(borrar,"vals_1")]
rm(list = borrar)
