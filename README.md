# eficiencia-censo-validacion
Repositorio para almacenar y compartir material relacionado a mejorar la eficiencia en la etapa de validación de datos del Censo 2024

## Etapas de procesamiento

```mermaid
sequenceDiagram
  participant run as run_tests.R
  participant rph_val as 04_rph_val_est.R  
  participant rph as 04_rph_estructural.R
  participant edu_val as 09_educacion_val_est.R  
  participant edu as 09_educacion_estructural.R
  Note over run: arg: tipo_particion <br> (0: no, 1: region, 2: 1+provincia, 3: 2+comuna) 
  Note over run: arg: usar_arrow (TRUE, FALSE)
  Note over run: arg: errores_aumentado (no, 20e6, 30e6, 40e6)
  rect rgb(191, 223, 255)
  run ->> rph: args (tipo_particion, usar_arrow, errores_aumentado)
  rph_val ->> rph: rango, asignacion
  Note over run,rph: 1) Validación RPH
  end
  rect rgb(191, 223, 255)  
  run ->> edu: args (tipo_particion, usar_arrow, errores_aumentado)
  edu_val ->> edu: rango, asignacion
  Note over run,edu: 2) Validación EDU  
  end
  Note over run: 3) Combinar data validada
  Note over run: 4) Reporte a nivel persona
  Note over run: 5) Reporte agregado por error      
```

La siguiente tabla resume las etapas del procesamiento que se muestran en el diagrama anterior.
El proceso comienza ejecutando el script [`run_tests.R`](run_tests.R) con ciertos parámetros definidos por el usuario.
Este script internamente ejecuta la validación de las baterías del registro de personas (RPH, script [`04_rph_estructural_hs.R`](04_rph_estructural_hs.R)) y de educación (EDU, script [`09_educacion_estructural_hs.R`](09_educacion_estructural_hs.R)).
El resultado de estas validaciones se combina a continuación para generar reportes en dos formatos: a nivel de persona y agregado por regla de validación (tipo de error).

| Etapa                   | Detalle                                                           |
|-------------------------|-------------------------------------------------------------------|
| Validación RPH          | Aplicación de validadores de la batería del registro de personas  |
| Validación EDU          | Aplicación de validadores de la batería de educación              |
| Combinar data validada  | Se combina data validada de ambas baterías                        |
| Reporte nivel persona   | Creación de reporte de validación a nivel de persona              |
| Reporte agregado        | Creación de reporte de validación agregado por regla de validació |


## Ejecución de tests

Para poder ejecutar los tests, el primer paso es clonar este repositorio en la máquina que será utilizada para el procesamiento.

Luego se deben descargar los datasets que son usados por los diferentes scripts desde el siguiente link: 
[01_base_censo_publicada](https://inechile-my.sharepoint.com/:f:/g/personal/hesotop_ine_gob_cl/ElGhFSiQj6RMhkjWfSXLJEMB7WSehYdJpSNiHI6ENDlqWA?e=LCJjQS) <br>
Una vez se ha completado la descarga, es necesario copiar el contenido de la carpeta descargada al directorio [`data`](data/) del repositorio clonado, que contiene un archivo `info` de referencia.

El script [`run_tests.R`](run_tests.R) puede ser ejecutado ajustando los valores de ciertos parámetros dentro del script, cuyos valores se definen como strings y se indican en la siguiente tabla de acuerdo al tipo de **Test** ejecutado. <br>

| Test                                                             | Parámetro | Valores evaluadas             |
|-|-|-|
| (1) Uso de función de validación implementada en Arrow               | usar_arrow_para_validacion | TRUE, FALSE                     |
| (2) Particionamiento de input dataset usando variables geográficas:  | tipo_particion | 0: sin particionar <br> 1: region <br> 2: region, provincia <br> 3: region, provincia, comuna |
| (3) Aumento de errores en validación: <br> modificando artificialmente dataset original | errores_aumentado | no, 10e6, 20e6, 30e6, 40e6 |

En el caso del parámetro `tipo_particion`, los valores indicados corresponden a las columnas usadas para crear el dataset particionado. 
En tanto que los valores evaluados para el parámetro `errores_aumentado` llevan el prefijo "err_aum_" e indican la cantidad de errores que fueron introducidos aleatoriamente en el dataset original. 

## Resultados de procesamiento

Al final de cada ejecución del script [`run_tests.R`](run_tests.R), se imprime un dataframe con los tiempos en que las diferentes etapas del procesamiento fueron completadas.
Estos resultados también son almacenados en un archivo xlsx en el directorio [`resultados/tiempo_censo_validacion`](resultados/tiempo_censo_validacion/). El archivo xlsx se crea si no existe y los resultados se escriben a una nueva hoja.

Los resultados de tiempos de procesamiento para los tests implementados se resumen en los plots en el directorio [`resultados/*.png`](resultados). Estos plots también están incluidos en la presentación compartida y son creados por el script [`plot_execution_times.R`](scripts_extra/plot_execution_times.R), que usa como input el archivo xlsx antes mencionado.

Estos resultados fueron obtenidos en una máquina que cuenta con las siguientes características:

- S.O.: Linux, Ubuntu 22.04.3 LTS (jammy)
- RAM: 16 GB.
- CPU: 32 núcleos.
- Python: v3.11.4
- R: v4.3.1
