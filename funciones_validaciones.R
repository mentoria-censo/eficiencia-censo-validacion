############################################################:
# Autor: Censo de poblacion y vivienda 2024                #:
# Seccion: Cuestionario censal - funciones                 #:
# Fecha: marzo 2023                                        #:
############################################################:


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
      vs   <- c(ids,vars, "id_regla","variable","descripcion") %>% unique()
      data[eval(parse(text = reglas[.,]$condicion))
      ][, `:=` (id_regla = reglas[.,]$validacion,
                variable = reglas[.,]$variable,
                descripcion = reglas[.,]$descripcion)
      ][, ..vs]
    })
  return(vals)
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
