#=========================================================================================================================================#
# Script para ejecutar tests para el procesamiento de la validación de datos de censo
#
# Desarrollado por: Hugo Soto Parada
# Cargo: Centífico de Datos. Subdirección Técnica.
# E-mail Institucional: hesotop@ine.gob.cl
# E-mail Particular: hugosotoparada@gmail.com
# Diciembre 2023
#
#=========================================================================================================================================#


library(openxlsx)
library(tidyverse)
library(arrow)

############################################################################################
# CORRER VALIDACION -------------------------------------------------

t0 <- Sys.time()

dir_in <- "data"
dir_out <- "resultados"

Rpath <- "/home/hugosoto/anaconda3/envs/r_ine/bin/Rscript"
source(file="funciones_validaciones.R", encoding = "UTF-8")

# definir parametros para test
test_parametros <- list()

# define nombre de sheet en workbook xlsx donde se escriben tiempos de procesamiento de test ejecutado
test_parametros$arg_iteracion <- "03"

# definir scripts
test_parametros$script_04 <- "04_rph_estructural.R"
test_parametros$script_09 <- "09_educacion_estructural.R"

# definir particionado de dataset
# test_parametros$tipo_particion <- "0" # cols: c()
test_parametros$tipo_particion <- "1" # cols: c("region")
# test_parametros$tipo_particion <- "2" # cols: c("region","provincia")
# test_parametros$tipo_particion <- "3" # cols: c("region","provincia","comuna")

# definir formato reporte
# test_parametros$formato_reporte <- "nivel_persona"
# test_parametros$formato_reporte <- "agregado_por_error"

# definir uso de sintaxis arrow en validación
# test_parametros$usar_arrow_para_validacion <- "FALSE"
test_parametros$usar_arrow_para_validacion <- "TRUE"

# definir simulación de errores (aumentación output dataset)
# test_parametros$errores_aumentado <- "err_aum_no"
# test_parametros$errores_aumentado <- "err_aum_10e6"
# test_parametros$errores_aumentado <- "err_aum_20e6"
# test_parametros$errores_aumentado <- "err_aum_30e6"
test_parametros$errores_aumentado <- "err_aum_40e6"
# test_parametros$errores_aumentado <- "err_aum_50e6"
# test_parametros$errores_aumentado <- "err_aum_60e6"
# test_parametros$errores_aumentado <- "err_aum_70e6"

# ejecutar script_04: validación registro de personas
test_args_04 <- c(
    test_parametros$script_04,
    test_parametros$tipo_particion,
    # test_parametros$formato_reporte,
    test_parametros$usar_arrow_para_validacion,
    test_parametros$errores_aumentado
)
system2(Rpath, args=test_args_04)

print("VALIDACION RPH -> OK")
t1 <- Sys.time()

# ejecutar script_09: validación educación
test_args_09 <- c(
    test_parametros$script_09,
    test_parametros$tipo_particion,
    # test_parametros$formato_reporte,
    test_parametros$usar_arrow_para_validacion,
    test_parametros$errores_aumentado
)
system2(Rpath, args=test_args_09)

print("VALIDACION EDU -> OK")
t2 <- Sys.time()

############################################################################################
# COMBINAR DATA VALIDADA -------------------------------------------------

if (test_parametros$tipo_particion == "1") {
  particion <- "region"
  cols_partition <- c("region")
} else if (test_parametros$tipo_particion == "2") {
  particion <- "region_provincia"
  cols_partition <- c("region","provincia")
} else if (test_parametros$tipo_particion == "3") {
  particion <- "region_provincia_comuna"
  cols_partition <- c("region","provincia","comuna")
} else {
  particion <- "no"
}

# leer data validado
# particion <- "no"

if (particion != "no") {
  format_dataset <- "feather"
  #
  # read data rph
  path_dataset_04 <- paste0(dir_out,"/04_rph_estructural_particionado_",particion)
  print(paste0("leyendo dataset validado, particionado, desde: ",path_dataset_04))
  data_validado_04 <- arrow::open_dataset(
    path_dataset_04,
    format=format_dataset,
    partitioning=cols_partition
  )
  print(dim(data_validado_04))
  #
  # read data educación
  path_dataset_09 <- paste0(dir_out,"/09_educacion_estructural_particionado_",particion)
  print(paste0("leyendo dataset validado, particionado, desde: ",path_dataset_09))
  data_validado_09 <- arrow::open_dataset(
    path_dataset_09,
    format=format_dataset,
    partitioning=cols_partition
  )
  print(dim(data_validado_09))
} else {
  #
  # read data rph
  path_dataset_04 <- paste0(dir_out,"/04_rph_estructural.feather")
  print(paste0("leyendo dataset validado, no particionado, desde: ",path_dataset_04))
  data_validado_04 <- arrow::read_feather(
    path_dataset_04,
    as_data_frame = FALSE
  )
  print(dim(data_validado_04))
  #
  # read data educación
  path_dataset_09 <- paste0(dir_out,"/09_educacion_estructural.feather")
  print(paste0("leyendo dataset validado, no particionado, desde: ",path_dataset_09))
  data_validado_09 <- arrow::read_feather(
    path_dataset_09,
    as_data_frame = FALSE
  )
  print(dim(data_validado_09))
}

# combinar data validado
if (particion != "no") {
  data_validado_04 <- data_validado_04 %>% compute()
  data_validado_09 <- data_validado_09 %>% compute()
}
# data_validado <- rbind(data_validado_04, data_validado_09)
data_validado <- arrow::concat_tables(data_validado_04, data_validado_09)
rm(data_validado_04,data_validado_09)

print("COMBINAR DATA VALIDADA -> OK")
t3 <- Sys.time()

############################################################################################
# CREAR REPORTES -------------------------------------------------

# # TODO: check how it would work with arrow table
# # calcular reportes
# tablas_reporte <- calcular_tablas_reporte(data_validado)
# rm(data_validado)

# # generar archivos xlsx que contienen reportes
# # Nota: archivos xlsx tienen un límite de 1,048,576 filas, por lo que es imposible guardar reporte_nivel_persona que podría fácilmente tener >10M filas
# wb_1 <- crear_reporte_xlsx(nombre_reporte="reporte_nivel_persona", data=tablas_reporte$reporte_nivel_persona)
# wb_2 <- crear_reporte_xlsx(nombre_reporte="reporte_agregado_error", data=tablas_reporte$reporte_agregado_error)

# reporte nivel persona
reporte_nivel_persona <- calcular_reporte_nivel_persona(data_validado)
#
if (particion != "no") {
  path_reporte_01 <- paste0(dir_out,"/reporte_nivel_persona_particionado_",particion)
  print(paste0("escribiendo reporte particionado a: ",path_reporte_01))
  unlink(path_reporte_01,recursive = TRUE)
  print(dim(reporte_nivel_persona))
  arrow::write_dataset(
    reporte_nivel_persona,
    path_reporte_01,
    format=format_dataset,
    partitioning=cols_partition
  )
} else {
  path_reporte_01 <- paste0(dir_out,"/reporte_nivel_persona")
  print(paste0("escribiendo reporte ",path_reporte_01,"..."))
  print(dim(reporte_nivel_persona))
  arrow::write_feather(
    reporte_nivel_persona,
    paste0(path_reporte_01,".feather")
  )
  # arrow::write_csv_arrow(
  #   reporte_nivel_persona,
  #   file=paste0(path_reporte_01,".csv")
  # )
}

print("REPORTE NIVEL PERSONA -> OK")
t4 <- Sys.time()

# TODO: save report with partions.
# -> function calcular_reporte_agregado_error() needs to be adapted to use arrow syntax
#
# reporte agregado por error
reporte_agregado_error <- calcular_reporte_agregado_error_v2(data_validado)
#
path_reporte_02 <- paste0(dir_out,"/reporte_agregado_error")
print(paste0("escribiendo reporte ",path_reporte_02,"..."))
print(dim(reporte_agregado_error))
arrow::write_feather(
  reporte_agregado_error,
  paste0(path_reporte_02,".feather")
)
# arrow::write_csv_arrow(
#   reporte_agregado_error,
#   file=paste0(path_reporte_02,".csv")
# )
wb_2 <- crear_reporte_xlsx_v2(nombre_reporte=path_reporte_02, data=reporte_agregado_error)

print("REPORTE AGREGADO POR ERROR -> OK")
t5 <- Sys.time()

# EVALUAR TIEMPO DE PROCESAMIENTO -------------------------------------------------

tiempos_dt <- data.frame(
  proceso = c(
    "validar rph",
    "validar edu",
    "combinar data validada",
    "crear reporte nivel persona",
    "crear reporte agregado error",
    "total"
  ),
  duracion = c(
    t1-t0,
    t2-t1,
    t3-t2,
    t4-t3,
    t5-t4,
    t5-t0
  )
)

print(tiempos_dt)

file_xlsx <- paste0(dir_out,"/tiempo_censo_validacion.xlsx")

data_prefix_short <- paste0("p",test_parametros$tipo_particion)

if (test_parametros$usar_arrow_para_validacion == "TRUE") {
  sheet_name <- paste0(data_prefix_short,"_farrow")
} else {
  sheet_name <- paste0(data_prefix_short,"_no_farrow")
}

sheet_name <- paste0(sheet_name,"_",test_parametros$errores_aumentado)

sheet_name <- paste0(sheet_name,"_",test_parametros$arg_iteracion)

print(sheet_name)

# load / create worksheet
if(file.exists(file_xlsx)) {
  print(paste0(file_xlsx," already exists!"))
  file_sheet_names <- getSheetNames(file_xlsx)
  wb <- loadWorkbook(file_xlsx)
  if (sheet_name %in% names(wb)) {
    removeWorksheet(wb, sheet_name)
  }
} else {
  print(paste0(file_xlsx," doesn't exist!"))
  file_sheet_names <- c()
  wb <- createWorkbook()
}

# copy data from already existent sheets
# -> this is necessary because saveWorkbook(overwrite=TRUE) overwrites all sheets, not only the current one.
for (s in file_sheet_names){
  if (s != sheet_name){
    data_tmp <- read.xlsx(file_xlsx, sheet=s)
    removeWorksheet(wb, s)
    addWorksheet(wb, s)
    writeData(wb, sheet=s, x=data_tmp, startRow=1, startCol=1, colNames=TRUE)
  }
}

# add current sheet
addWorksheet(wb, sheet_name)
# writeData(wb, sheet=sheet_name, x=tiempos_dt, startRow=1, startCol=1, colNames=TRUE)
writeDataTable(wb, sheet=sheet_name, x=tiempos_dt, startRow=1, startCol=1, colNames=TRUE)

# save xlsx file
saveWorkbook(wb, file=file_xlsx, overwrite=TRUE)


# LIMPIAR MEMORIA -------------------------------------------------

# Rprof(NULL)
# summaryRprof(file_rprof)

rm(list = ls())
# rm(persona)
gc()
