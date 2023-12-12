############################################################:
# Autor: Censo de poblacion y vivienda 2024                #:
# Seccion: Cuestionario censal - funciones                 #:
# Fecha: marzo 2023                                        #:
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


# CARGAR FUNCIONES -------------------------------
# convertir lista a data frame
fn_list_dt <- function(lista, x = "validacion", val = "ran", sep = "_", validador = "validador") {
  library(data.table)
  if (is.null(names(lista))) names(lista) <- paste0(val,sep,1:length(lista))
  dt <- rbindlist(l = lista, fill = T, use.names = T, idcol = x)
  tipo_validador <- rep(validador, nrow(dt))
  dt <- cbind(tipo_validador, dt)
  return(dt)
}

# convertir lista a arrow table
fn_list_arrow <- function(lista, x = "validacion", val = "ran", sep = "_", validador = "validador") {

  library(arrow)

  if (is.null(names(lista))) names(lista) <- paste0(val,sep,1:length(lista))

  tabla <- lista[[1]]
  validacion <- rep(names(lista)[1], nrow(tabla))
  validacion <- arrow::Array$create(validacion)
  tipo_validador <- rep(validador, nrow(tabla))
  tabla$validacion <- validacion
  tabla$tipo_validador <- tipo_validador

  for (i in 2:length(lista)) {
    tabla_tmp <- lista[[i]]
    validacion <- rep(names(lista)[i], nrow(tabla_tmp))
    validacion <- arrow::Array$create(validacion)
    tipo_validador <- rep(validador, nrow(tabla_tmp))
    tabla_tmp$validacion <- validacion
    tabla_tmp$tipo_validador <- tipo_validador
    tabla <- arrow::concat_tables(tabla,tabla_tmp)
  }

  return(tabla)
}

# funcion para validar data
fn_val <- function(data, reglas, ids,  x = "validacion") {
  library(data.table)
  library(dplyr)
  library(purrr)
  data <- as.data.table(data)
  vals <- (1:nrow(reglas)) %>%
    map(function(.){
      vars <- reglas[.,]$vars %>% str_split(",") %>% unlist() %>% str_squish()
      if (is.na(vars[1])) vars <- NULL
      vs <- c(ids,vars, "id_regla","variable","descripcion") %>% unique()
      data[eval(parse(text = reglas[.,]$condicion))
      ][, `:=` (id_regla = reglas[.,]$validacion,
                variable = reglas[.,]$variable,
                descripcion = reglas[.,]$descripcion)
      ][, ..vs]
    })
  return(vals)
}

# funcion para validar data
fn_val_arrow <- function(data, reglas, ids,  x = "validacion") {
  library(dplyr)
  # library(purrr)
  library(arrow)

  vals_arrow <- (1:nrow(reglas)) %>%
    map(function(.x){
      vars <- reglas[.x,]$vars %>% str_split(",") %>% unlist() %>% str_squish()
      if (is.na(vars[1])) vars <- NULL
      vs <- c(ids,vars, "id_regla","variable","descripcion") %>% unique()
      data %>%
        filter(!!rlang::parse_expr(reglas[.x,]$condicion)) %>% # arrow no funciona con "eval(parse(...))"
        mutate(
          id_regla = reglas[.x,]$validacion,
          variable = reglas[.x,]$variable,
          descripcion = reglas[.x,]$descripcion_validacion,
        ) %>%
        select(all_of(vs)) %>%
        compute()
    })
  return(vals_arrow)
}

# renombrar variable
renombrar <- function(data, nombre, nombre_nuevo){
  if (nombre %in% names(data)) {
    names(data) <- replace(colnames(data),colnames(data)==nombre,nombre_nuevo)
  } else {}
  return(data)
}

# homologar -99
noresponde <- function(data){
  identificadores <- c("interview__key","interview__id","rst_hogares__id","rst_personas__id")
  columnas <- colnames(data)[which(!colnames(data) %in% identificadores)]
  for (i in 1:length(columnas)) {
    data[,columnas[i]] <- replace(data[,columnas[i]], data[,columnas[i]]==-999999999, -99)
  }
  return(data)
}


############################################################################################
# NUEVAS FUNCIONES -------------------------------

agregar_columnas_geograficas <- function(x){
  # Agrega columnas con información geográfica a tabla.
  #
  # Inputs:
  #   x: tabla que contiene columna "entrevista_id" con información geográfica.
  #
  # Outputs:
  #     tabla: con columnas extras que contienen información geográfica.

  x <- x %>%
    mutate(
      entrevista_id_nchar = nchar(as.character(entrevista_id)),
      cut = str_sub(as.character(entrevista_id), start=1, end=-12),
      # cut_nchar = nchar(cut),
      region = case_when(
        nchar(cut) == 5 ~ str_sub(cut, start=1, end=2),
        nchar(cut) == 4 ~ str_sub(cut, start=1, end=1),
        TRUE ~ NA_character_
      ),
      provincia = case_when(
        nchar(cut) == 5 ~ str_sub(cut, start=3, end=3),
        nchar(cut) == 4 ~ str_sub(cut, start=2, end=2),
        TRUE ~ NA_character_
      ),
      comuna = case_when(
        nchar(cut) == 5 ~ str_sub(cut, start=4, end=5),
        nchar(cut) == 4 ~ str_sub(cut, start=3, end=4),
        TRUE ~ NA_character_
      )
    )

  return(x)

}

agregar_columna_modalidad <- function(x){
  # Agrega columna con información sobre modalidad de cuestionario.
  #
  # Inputs:
  #   x: tabla que contiene data con respuestas de cuestionario.
  #
  # Outputs:
  #   tabla: con columna extra que contiene modalidad.

  nrow <- dim(x)[1]

  x <- x %>%
    mutate(
      modalidad = round(runif(n=nrow, min=1, max=3), 0),
      capi = case_when(
        modalidad == 1 ~ 1,
        TRUE ~ 0
      ),
      cawi = case_when(
        modalidad == 2 ~ 1,
        TRUE ~ 0
      ),
      papi = case_when(
        modalidad == 3 ~ 1,
        TRUE ~ 0
      ),
    )

  return(x)
}


particionar_dataset <- function(x, tipo_particion="0", path_sufix=""){
  # Particiona dataset en tabla de entrada, generando subdirectorios que contienen la data para cada partición creada.
  #
  # Inputs:
  #   x: tabla que contiene data a particionar.

  format_dataset <- "feather"

  if (tipo_particion == "1") {
    particion <- "region"
    cols_partition <- c("region")
  } else if (tipo_particion == "2") {
    particion <- "region_provincia"
    cols_partition <- c("region","provincia")
  } else if (tipo_particion == "3") {
    particion <- "region_provincia_comuna"
    cols_partition <- c("region","provincia","comuna")
  } else {
    particion <- "no"
  }

  if (particion != "no") {
    path_dataset <- paste0("data/persona_particionado_",particion,path_sufix)
    print(paste0("creando partición en directorio: ", path_dataset))
    unlink(path_dataset, recursive = TRUE)
    arrow::write_dataset(x, path_dataset, format=format_dataset, partitioning=cols_partition)
  } else {
    print("partición no será creada!")
  }

}

calcular_reporte_nivel_persona <- function(data){
  # Calcula tabla que contiene reporte a nivel de persona, a partir de los resultados de la validación.
  #
  # Inputs:
  #   data: tabla que contiene resultados de la validación.
  #
  # Outputs:
  #   tabla: tabla que contiene reporte a nivel de persona.

  # reporte a nivel de persona
  tabla <- data %>%
    # collect() %>%
    # mutate(
    #   # modalidad = round(runif(n=nrow, min=1, max=3), 0)
    #   modalidad = runif(n=nrow, min=1, max=3)
    # ) %>%
    select(
      entrevista_id,
      tipo_validador,
      id_regla,
      variable,
      descripcion,
      hogar_id,
      persona_id,
      region,
      provincia,
      comuna,
      modalidad
    )

  return(tabla)

}

calcular_reporte_agregado_error_v1 <- function(data){
  # Calcula tabla que contiene reporte agregado por error, a partir de la tabla que contiene reporte a nivel de persona.
  #
  # Inputs:
  #   data: tabla que contiene resultados de la validación.
  #
  # Outputs:
  #   tabla: tabla que contiene reporte agregado por error.

  # TODO: adapt function to use arrow syntax

  # reporte agregado por error
  tabla_o <- data %>%
    group_by(id_regla) %>%
    # to_duckdb() %>%
    mutate(
      capi_sum=sum(capi),
      cawi_sum=sum(cawi),
      papi_sum=sum(papi),
      Total=capi_sum+cawi_sum+papi_sum
    ) %>%
    ungroup() %>%
    # select(-c(modalidad,entrevista_id,hogar_id,persona_id,capi_tmp,cawi_tmp,papi_tmp)) %>%
    select(c(id_regla,capi_sum,cawi_sum,papi_sum,Total,tipo_validador,variable,descripcion)) %>%
    rename(
      "capi"="capi_sum",
      "cawi"="cawi_sum",
      "papi"="papi_sum"
    ) %>%
    distinct() %>%
    arrange(id_regla)
    # to_arrow()
    # compute()

  return(tabla)
}

calcular_reporte_agregado_error_v2 <- function(data){
  # Calcula tabla que contiene reporte agregado por error, a partir de la tabla que contiene reporte a nivel de persona.
  #
  # Inputs:
  #   data: tabla que contiene resultados de la validación.
  #
  # Outputs:
  #   tabla: tabla que contiene reporte agregado por error.

  # reporte agregado por error
  tabla_tmp <- data %>%
    group_by(id_regla) %>%
    summarise(
      capi_sum=sum(capi),
      cawi_sum=sum(cawi),
      papi_sum=sum(papi),
      Total=capi_sum+cawi_sum+papi_sum
    ) %>%
    compute()

  tabla <- data %>%
    select(c(id_regla,tipo_validador,variable,descripcion)) %>%
    left_join(
      tabla_tmp,
      by = c("id_regla")
    ) %>%
    distinct() %>%
    rename(
      "capi"="capi_sum",
      "cawi"="cawi_sum",
      "papi"="papi_sum"
    ) %>%
    select(c(id_regla,capi,cawi,papi,Total,tipo_validador,variable,descripcion)) %>%
    arrange(id_regla) %>%
    compute()

  return(tabla)
}

crear_reporte_xlsx_v1 <- function(nombre_reporte, data){
  # Crea reporte, el cual puede ser con formato a nivel de persona o agregado por error.
  #
  # Inputs:
  #   nombre_reporte: nombre reporte. E.g. "reporte_nivel_persona", "reporte_agregado_error", etc.
  #   data: tabla que contiene reporte.
  #
  # Outputs:
  #   wb: objeto Workbook que contiene reporte.

  archivo_xlsx <- paste0(nombre_reporte,".xlsx")

  sheet_name <- "reporte"

  # load / create worksheet
  if(file.exists(archivo_xlsx)) {
    print(paste0(archivo_xlsx," already exists!"))
    wb <- openxlsx::loadWorkbook(archivo_xlsx)
    if (sheet_name %in% names(wb)) {
      openxlsx::removeWorksheet(wb, sheet_name)
    }
  } else {
    print(paste0(archivo_xlsx," doesn't exist, so will be created!"))
    wb <- openxlsx::createWorkbook()
  }

  # add new sheet
  openxlsx::addWorksheet(wb, sheet_name)

  start_row <- 1
  n_iteration <- 1

  while(start_row < nrow(data)) {

    nrows <- 100
    end_row <- start_row + nrows - 1
    message <- paste0("Escribiendo ",nrows," filas a archivo xlsx...")
    print(message)
    print(c(n_iteration, start_row,end_row))
    start_row <- end_row + 1
    n_iteration <- n_iteration + 1

    # openxlsx::writeData(wb, sheet=sheet_name, x=data, startRow=1, startCol=1, colNames=TRUE)
    openxlsx::writeDataTable(wb, sheet=sheet_name, x=data[start_row:end_row, ], startRow=start_row, startCol=1, colNames=TRUE)

    # save xlsx file
    openxlsx::saveWorkbook(wb, file=archivo_xlsx, overwrite=TRUE)

  }

  # # add new sheet
  # openxlsx::addWorksheet(wb, sheet_name)
  # # openxlsx::writeData(wb, sheet=sheet_name, x=data, startRow=1, startCol=1, colNames=TRUE)
  # openxlsx::writeDataTable(wb, sheet=sheet_name, x=data[start_row:end_row, ], startRow=1, startCol=1, colNames=TRUE)

  # # save xlsx file
  # openxlsx::saveWorkbook(wb, file=archivo_xlsx, overwrite=TRUE)

  return(wb)

}

crear_reporte_xlsx_v2 <- function(nombre_reporte, data){
  # Crea reporte, el cual puede ser con formato a nivel de persona o agregado por error.
  #
  # Inputs:
  #   nombre_reporte: nombre reporte. E.g. "reporte_nivel_persona", "reporte_agregado_error", etc.
  #   data: tabla que contiene reporte.
  #
  # Outputs:
  #   wb: objeto Workbook que contiene reporte.

  library(data.table)
  library(dplyr)
  library(purrr)

  archivo_xlsx <- paste0(nombre_reporte,".xlsx")

  sheet_name <- "reporte"

  # load / create worksheet
  if(file.exists(archivo_xlsx)) {
    print(paste0(archivo_xlsx," already exists!"))
    wb <- openxlsx::loadWorkbook(archivo_xlsx)
    if (sheet_name %in% names(wb)) {
      openxlsx::removeWorksheet(wb, sheet_name)
    }
  } else {
    print(paste0(archivo_xlsx," doesn't exist, so will be created!"))
    wb <- openxlsx::createWorkbook()
  }

  # add new sheet
  openxlsx::addWorksheet(wb, sheet_name)

  # start_row <- 1
  # n_iteration <- 1

  # while(start_row < nrow(data)) {

  data <- as.data.table(data)

  # nrows <- 100
  nrows <- nrow(data)
  # end_row <- start_row + nrows - 1
  message <- paste0("Escribiendo ",nrows," filas a archivo xlsx...")
  print(message)
  # print(c(n_iteration, start_row,end_row))
  # start_row <- end_row + 1
  # n_iteration <- n_iteration + 1

  # openxlsx::writeData(wb, sheet=sheet_name, x=data, startRow=1, startCol=1, colNames=TRUE)
  openxlsx::writeDataTable(wb, sheet=sheet_name, x=data, startRow=1, startCol=1, colNames=TRUE)

  # save xlsx file
  openxlsx::saveWorkbook(wb, file=archivo_xlsx, overwrite=TRUE)

  # }

  return(wb)

}

aumentar_errores_rph <- function(x, lista_error){
  # Introduce errores en tabla de entrada, según la lista de errores dada.
  #
  # Inputs:
  #   x: tabla que contiene data sobre el cual se aumentarán los errores.
  #   lista_error: lista que contiene la cantidad de filas que tendrán error aumentados por cada nombre de error.

  error_nombres <- names(lista_error)
  nrow <- nrow(x)

  if ("rph_ran_1" %in% error_nombres) {
    nerr <- lista_error$rph_ran_1
    message <- paste0("Introduciendo ",nerr," errores para validación rph_ran_1")
    print(message)
    columna_err <- round(runif(n=nerr, min=3, max=10), 0)
    columna <- sample(x$sexo_validado, nrow-nerr)
    columna <- c(columna,columna_err)
    columna <- sample(columna)
    x$sexo_validado <- columna
  }

  if ("rph_ran_2" %in% error_nombres) {
    nerr <- lista_error$rph_ran_2
    message <- paste0("Introduciendo ",nerr," errores para validación rph_ran_2")
    print(message)
    columna_err <- round(runif(n=nerr, min=120, max=150), 0)
    columna <- sample(x$edad_validada, nrow-nerr)
    columna <- c(columna,columna_err)
    columna <- sample(columna)
    x$edad_validada <- columna
  }

  if ("rph_ran_3" %in% error_nombres) {
    nerr <- lista_error$rph_ran_3
    message <- paste0("Introduciendo ",nerr," errores para validación rph_ran_3")
    print(message)
    columna_err <- round(runif(n=nerr, min=17, max=50), 0)
    columna <- sample(x$parentesco, nrow-nerr)
    columna <- c(columna,columna_err)
    columna <- sample(columna)
    x$parentesco <- columna
  }

  # TODO: implement augmentation for errors of asignacion: rph_asi_1, rph_asi_2

  return(x)
}

aumentar_errores_edu <- function(x, lista_error){
  # Introduce errores en tabla de entrada, según la lista de errores dada.
  #
  # Inputs:
  #   x: tabla que contiene data sobre el cual se aumentarán los errores.
  #   lista_error: lista que contiene la cantidad de filas que tendrán error aumentados por cada nombre de error.

  error_nombres <- names(lista_error)
  nrow <- nrow(x)

  if ("edu_ran_1" %in% error_nombres) {
    nerr <- lista_error$edu_ran_1
    message <- paste0("Introduciendo ",nerr," errores para validación edu_ran_1")
    print(message)
    columna_err <- round(runif(n=nerr, min=3, max=10), 0)
    columna <- sample(x$edu_asiste, nrow-nerr)
    columna <- c(columna,columna_err)
    columna <- sample(columna)
    x$edu_asiste <- columna
  }

  # TODO
  # if ("edu_ran_2" %in% error_nombres) {
  #   nerr <- lista_error$edu_ran_2
  #   message <- paste0("Introduciendo ",nerr," errores para validación edu_ran_2")
  #   print(message)
  #   columna_err <- round(runif(n=nerr, min=120, max=150), 0)
  #   columna <- sample(x$edad_validada, nrow-nerr)
  #   columna <- c(columna,columna_err)
  #   columna <- sample(columna)
  #   x$edad_validada <- columna
  # }

  # TODO
  # if ("edu_ran_3" %in% error_nombres) {
  #   nerr <- lista_error$edu_ran_3
  #   message <- paste0("Introduciendo ",nerr," errores para validación edu_ran_3")
  #   print(message)
  #   columna_err <- round(runif(n=nerr, min=17, max=50), 0)
  #   columna <- sample(x$parentesco, nrow-nerr)
  #   columna <- c(columna,columna_err)
  #   columna <- sample(columna)
  #   x$parentesco <- columna
  # }

  return(x)
}
