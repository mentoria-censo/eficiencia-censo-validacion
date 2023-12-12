# 1. Validaciones de rango en negativo ---------------------------------------------------

rango <- list(
  # list(
  #   variable = paste0("rph_sexo"),
  #   etiqueta_variable = paste0("Sexo de la persona"),
  #   condicion = paste0("!rph_sexo%in%c(1:2,-99) & !is.na(rph_sexo)"),
  #   descripcion_validacion = paste0("Respuesta en Sexo de la persona fuera de rango (1 a 2 o -99)"),
  #   vars_condicion = "rph_sexo"
  # ),
  # list(
  #   variable = paste0("rph_edad"),
  #   etiqueta_variable = paste0("Edad de la persona"),
  #   condicion = paste0("!rph_edad%in%c(0:119,-99) & !is.na(rph_edad)"),
  #   descripcion_validacion = paste0("Respuesta en Edad de la persona fuera de rango (0 a 119 o -99)"),
  #   vars_condicion = "rph_edad"
  # ),
  list(
    variable = paste0("sexo_validado"),
    etiqueta_variable = paste0("Sexo de la persona"),
    condicion = paste0("!sexo_validado%in%c(1:2,-99) & !is.na(sexo_validado)"),
    descripcion_validacion = paste0("Respuesta en Sexo de la persona fuera de rango (1 a 2 o -99)"),
    vars_condicion = "sexo_validado"
  ),
  list(
    variable = paste0("edad_validada"),
    etiqueta_variable = paste0("Edad seleccionada de la persona"),
    condicion = paste0("!edad_validada%in%c(0:119,-99) & !is.na(edad_validada)"),
    descripcion_validacion = paste0("Respuesta en Edad seleccionada de la persona fuera de rango (0 a 119 o -99)"),
    vars_condicion = "edad_validada"
  ),
  list(
    variable = paste0("parentesco"),
    etiqueta_variable = paste0("Relacion de parentesco con jefatura del hogar"),
    condicion = paste0("!parentesco%in%c(1:16,-99) & !is.na(parentesco)"), 
    descripcion_validacion = paste0("Respuesta en Relacion de parentesco con jefatura del hogar fuera de rango (1 a 16 o -99)"),
    vars_condicion = "parentesco"
  )
)


# 2. Validaciones de asignacion en negativo --------------------------------------

asignacion <- list(
  list(
    variable = paste0("parentesco"),
    etiqueta_variable = paste0("Relacion de parentesco con jefatura del hogar"),
    condicion = paste0("tipo_operativo!=2 & parentesco==-99"), 
    descripcion_validacion = paste0("No responde en Relacion de parentesco con jefatura del hogar mal asignado"),
    vars_condicion = "tipo_operativo,parentesco"
  ),
  list(
    variable = paste0("parentesco"),
    etiqueta_variable = paste0("Relacion de parentesco con jefatura del hogar"),
    condicion = paste0("tipo_operativo==2 & is.na(parentesco)"), 
    descripcion_validacion = paste0("Falta respuesta en Relacion de parentesco con jefatura del hogar"),
    vars_condicion = "tipo_operativo,parentesco"
  )
)
