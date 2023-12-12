# 1. Validaciones de rango en negativo ---------------------------------------------------

rango <- list(
  list(
    variable = paste0("edu_asiste"),
    etiqueta_variable = paste0("Asiste o asistio a establecimiento educacional"),
    condicion = paste0("!edu_asiste%in%c(1:2,-99) & !is.na(edu_asiste)"),
    descripcion_validacion = paste0("Respuesta en asiste o asistio a establecimiento educacional se encuentra fuera de rango (1 a 2 o -99)"),
    vars_condicion = "edu_asiste"
  ),
  list(
    variable = paste0("edu_nivel"),
    etiqueta_variable = paste0("Nivel mas alto alcanzado"),
    condicion = paste0("edad_validada<=2 & !edu_nivel%in%c(1:4,6,-99) & !is.na(edu_nivel)"),
    descripcion_validacion = paste0("Respuesta en nivel educativo mas alto alcanzado, para personas con edad igual o menor a 2, fuera de rango (1 a 4 o 6 o -99)"),
    vars_condicion = "edu_nivel,edad_validada"
  ),
  list(
    variable = paste0("edu_nivel"),
    etiqueta_variable = paste0("Nivel mas alto alcanzado"),
    condicion = paste0("edad_validada%in%c(3:5) & !edu_nivel%in%c(1:7,-99) & !is.na(edu_nivel)"),
    descripcion_validacion = paste0("Respuesta en nivel educativo mas alto alcanzado, para personas con edad igual o mayor a 3 y menor o igual a 5, fuera de rango (1 a 7 o -99)"),
    vars_condicion = "edu_nivel,edad_validada"
  ),
  list(
    variable = paste0("edu_nivel"),
    etiqueta_variable = paste0("Nivel mas alto alcanzado"),
    condicion = paste0("edad_validada%in%c(6:10) & !edu_nivel%in%c(1:6, 8:10, -99) & !is.na(edu_nivel)"),
    descripcion_validacion = paste0("Respuesta en nivel educativo mas alto alcanzado, para personas con edad igual o mayor a 6 y menor o igual a 10, fuera de rango (1 a 6, 8 a 10 o -99)"),
    vars_condicion = "edu_nivel,edad_validada"
  ),
  list(
    variable = paste0("edu_nivel"),
    etiqueta_variable = paste0("Nivel mas alto alcanzado"),
    condicion = paste0("edad_validada%in%c(11:49) & !edu_nivel%in%c(1:7, 9:10, 13:16, -99) & !is.na(edu_nivel)"),
    descripcion_validacion = paste0("Respuesta en nivel educativo mas alto alcanzado, para personas con edad igual o mayor a 11 y menor o igual a 49, fuera de rango (1 a 7, 9 a 10, 13 a 16 o -99)"),
    vars_condicion = "edu_nivel,edad_validada"
  ),
  list(
    variable = paste0("edu_nivel"),
    etiqueta_variable = paste0("Nivel mas alto alcanzado"),
    condicion = paste0("edad_validada>=50 & !edu_nivel%in%c(1:16, -99) & !is.na(edu_nivel)"),
    descripcion_validacion = paste0("Respuesta en nivel educativo mas alto alcanzado, para personas con edad igual o mayor a 50 fuera de rango (1 a 16 o -99)"),
    vars_condicion = "edu_nivel,edad_validada"
  ),
  list(
    variable = paste0("edu_curso"),
    etiqueta_variable = paste0("Grado aprobado del nivel mas alto alcanzado"),
    condicion = paste0("!edu_curso%in%c(1:10,-99) & !is.na(edu_curso)"),
    descripcion_validacion = paste0("Respuesta en grado aprobado del nivel mas alto alcanzado fuera de rango (1 a 10 o -99)"),
    vars_condicion = "edu_curso,edu_nivel"
  ),
  list(
    variable = paste0("edu_nivel_completa"),
    etiqueta_variable = paste0("Finalizacion del nivel mas alto alcanzado declarado"),
    condicion = paste0("!edu_nivel_completa%in%c(1:2,-99) & !is.na(edu_nivel_completa)"),
    descripcion_validacion = paste0("Respuesta en finalizacion del nivel mas alto alcanzado declarado fuera de rango (1 a 2 o -99)"),
    vars_condicion = "edu_nivel_completa"
  ),
  list(
    variable = paste0("alfabet"),
    etiqueta_variable = paste0("Sabe leer y escribir"),
    condicion = paste0("!alfabet%in%c(1:2,-99) & !is.na(alfabet)"),
    descripcion_validacion = paste0("Respuesta en sabe leer y escribir fuera de rango (1 a 2 o -99)"),
    vars_condicion = "alfabet"
  )
)


# 2. Validaciones de asignacion en negativo --------------------------------------

asignacion <- list(
  list(
    variable = paste0("edu_asiste"),
    etiqueta_variable = paste0("Asiste o asistio a establecimiento educacional"),
    condicion = paste0("sexo_validado%in%c(1:2) & edad_validada>=0 & is.na(edu_asiste)"),
    descripcion_validacion = paste0("Falta respuesta en Asiste o asistio a establecimiento educacional"), 
    vars_condicion = "sexo_validado,edad_validada,edu_asiste"
  ),
  list(
    variable = paste0("edu_nivel"),
    etiqueta_variable = paste0("Nivel mas alto alcanzado"),
    condicion = paste0("sexo_validado%in%c(1:2) & edad_validada>=0 & is.na(edu_nivel)"),
    descripcion_validacion = paste0("Falta respuesta en Nivel mas alto alcanzado"),
    vars_condicion = "sexo_validado,edad_validada,edu_nivel"
  ),
  list(
    variable = paste0("edu_curso"),
    etiqueta_variable = paste0("Grado aprobado del nivel mas alto alcanzado"),
    condicion = paste0("edu_nivel%in%c(1:6) & edu_curso==-99"),
    descripcion_validacion = paste0("No responde en Grado aprobado del nivel mas alto alcanzado mal asignado, ya que tiene un nivel educacional menor a Educacion basica"), 
    vars_condicion = "edu_curso, edu_nivel"
  ),
  list(
    variable = paste0("edu_curso"),
    etiqueta_variable = paste0("Grado aprobado del nivel mas alto alcanzado"),
    condicion = paste0("edu_nivel%in%c(7:16) & is.na(edu_curso)"),
    descripcion_validacion = paste0("Falta respuesta en Grado aprobado del nivel mas alto alcanzado"), 
    vars_condicion = "edu_curso, edu_nivel"
  ),
  list(
    variable = paste0("edu_nivel_completa"),
    etiqueta_variable = paste0("Finalizacion del nivel mas alto alcanzado declarado"),
    condicion = paste0("edu_nivel%in%c(1:6) & edu_nivel_completa==-99"),
    descripcion_validacion = paste0("No responde en Finalizacion del nivel mas alto alcanzado mal asignado, ya que tiene un nivel educacional menor a Educacion basica"), 
    vars_condicion = "edu_nivel_completa, edu_nivel"
  ),
  list(
    variable = paste0("edu_nivel_completa"),
    etiqueta_variable = paste0("Finalizacion del nivel mas alto alcanzado declarado"),
    condicion = paste0("edu_nivel%in%c(7:16) & is.na(edu_nivel_completa)"),
    descripcion_validacion = paste0("Falta respuesta en Finalizacion del nivel mas alto alcanzado"), 
    vars_condicion = "edu_nivel_completa, edu_nivel"
  ),
  list(
    variable = paste0("alfabet"),
    etiqueta_variable = paste0("Sabe leer y escribir"),
    condicion = paste0("edad_validada<5 & alfabet==-99"),
    descripcion_validacion = paste0("No responde en Sabe leer y escribir mal asignado, ya que tiene edad menor a 5"),
    vars_condicion = "edad_validada, alfabet"
  ),
  list(
    variable = paste0("alfabet"),
    etiqueta_variable = paste0("Sabe leer y escribir"),
    condicion = paste0("edu_nivel%in%c(9:10,13:16) & alfabet==-99"),
    descripcion_validacion = paste0("No responde en Sabe leer y escribir mal asignado, ya que tiene una educacion formal de eduacion media o mayor"),
    vars_condicion = "edu_nivel, alfabet"
  ),
  list(
    variable = paste0("alfabet"),
    etiqueta_variable = paste0("Sabe leer y escribir"),
    condicion = paste0("edad_validada>=5 & edu_nivel%in%c(1:8,11:12) & is.na(alfabet)"),
    descripcion_validacion = paste0("Falta respuesta en Sabe leer y escribir"),
    vars_condicion = "edad_validada,edu_nivel,alfabet"
  )
 )

