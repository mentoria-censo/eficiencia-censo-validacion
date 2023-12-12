#=========================================================================================================================================#
# Script para crear plots con resultados del procesamiento de la validación de datos de censo
#
# Creado por: Hugo Soto Parada
# Cargo: Centífico de Datos. Subdirección Técnica.
# E-mail Institucional: hesotop@ine.gob.cl
# E-mail Particular: hugosotoparada@gmail.com
# Diciembre 2023
#
#=========================================================================================================================================#

library(openxlsx)
library(ggplot2)
library(tidyverse)
library(stringr)
library(dplyr)

path_results <- "../resultados/"

etapas <- c(
  "validar_rph",
  "validar_edu",
  "combinar_data_validada",
  "reporte_nivel_persona",
  "reporte_agregado_error",
  "total"
)

# dataframe to store all data
df_data_all <- data.frame()


# APACHE ARROW -------------------------------------------------

# read execution times for arrow
# xlsx_arrow = paste0(path_results,"tiempo_censo_validacion.xlsx")
# xlsx_arrow = paste0(path_results,"tiempo_censo_validacion_03.xlsx")
# xlsx_arrow = paste0(path_results,"tiempo_censo_validacion_04.xlsx")
xlsx_arrow = paste0(path_results,"tiempo_censo_validacion_05.xlsx")
sheet_arrow <- getSheetNames(xlsx_arrow)

# prepare data from arrow
list_data_arrow <- list()
for (i in 1:length(sheet_arrow)){
    s = sheet_arrow[i]
    print(s)
    data_tmp <- openxlsx::read.xlsx(xlsx_arrow, sheet=s)
    data_tmp["etapa"] <- etapas
    data_tmp["test_long"] <- rep(c(s), times=length(etapas))
    data_tmp["test"] <- rep(c(str_sub(s,1,-4)), times=length(etapas))
    data_tmp["algoritmo"] <- rep(c("arrow"), times=length(etapas))
    list_data_arrow <- append(list_data_arrow, list(data_tmp))
    df_data_all <- rbind(df_data_all, data_tmp)
}

test_levels <- unique(df_data_all$test)
etapa_levels <- unique(df_data_all$etapa)

# convert duracion to numeric (openxlsx reads it as character)
df_data_all$duracion <- as.numeric(df_data_all$duracion)

df_plot <- df_data_all %>%
    select(duracion, etapa, test) %>%
    group_by(etapa, test) %>%
    summarise(duracion_media=mean(duracion)) %>%
    mutate(test=fct_relevel(factor(test, levels=test_levels))) %>%
    mutate(etapa=fct_relevel(factor(etapa, levels=etapa_levels))) %>%
    mutate(duracion_media=round(duracion_media,2))

# PLOTTING ALL TESTS -------------------------------------------------

df_plot %>%
    ggplot(aes(x=etapa, y=duracion_media, label=duracion_media)) +
    geom_bar(stat = "identity", position="dodge", fill="darkgreen") +
    geom_text(size = 3, position = position_dodge(width = 1), vjust = -0.5) +
    facet_wrap(~test, ncol=1) +
    xlab("Etapa procesamiento") +
    ylab("Duración media [seg]")

# plot all
plot_filename = paste0("test_eficiencia_censo_validacion.png")
ggsave(plot_filename, path=path_results, device="png", width=40, height=50, units="cm", dpi=300)


# PLOTTING TEST: validation with arrow vs data.table -------------------------------------------------

test_plot <- "with_function_arrow"

df_plot %>%
    filter(test %in% c("p0_farrow_err_aum_no","p0_no_farrow_err_aum_no")) %>%
    ggplot(aes(x=etapa, y=duracion_media, fill=test, label = duracion_media)) +
    geom_bar(stat = "identity", position="dodge") +
    geom_text(size = 2.5, position = position_dodge(width = 1), vjust = -0.5)+
    # facet_wrap(~test_factor, ncol=1) +
    xlab("Etapa procesamiento") +
    ylab("Duración media [seg]")
    # ylim(0, 85)

# plot
plot_filename = paste0("test_eficiencia_censo_validacion_",test_plot,".png")
ggsave(plot_filename, path=path_results, device="png", width=35, height=18, units="cm", dpi=300)


# PLOTTING TEST: with partitions -------------------------------------------------

test_plot <- "with_partitions"

cols_test <- c(
  "p0_farrow_err_aum_no",
  "p1_farrow_err_aum_no",
  "p2_farrow_err_aum_no",
  "p3_farrow_err_aum_no"
)

df_plot %>%
    filter(test %in% cols_test) %>%
    ggplot(aes(x=etapa, y=duracion_media, fill=test, label = duracion_media)) +
    geom_bar(stat = "identity", position="dodge") +
    geom_text(size = 2.5, position = position_dodge(width = 1), vjust = -0.5)+
    xlab("Etapa procesamiento") +
    ylab("Duración media [seg]")
    # ylim(0, 85)

# plot
plot_filename = paste0("test_eficiencia_censo_validacion_",test_plot,".png")
ggsave(plot_filename, path=path_results, device="png", width=35, height=18, units="cm", dpi=300)


# PLOTTING TEST: with augmented error -------------------------------------------------

test_plot <- "with_augmented_error"

cols_test <- c(
  "p0_farrow_err_aum_no",
  "p0_farrow_err_aum_10e6",
  "p0_farrow_err_aum_20e6",
  "p0_farrow_err_aum_30e6",
  "p0_farrow_err_aum_40e6",
  "p0_farrow_err_aum_50e6",
  "p0_farrow_err_aum_60e6",
  "p0_farrow_err_aum_70e6"
)

df_plot %>%
    filter(test %in% cols_test) %>%
    ggplot(aes(x=etapa, y=duracion_media, fill=test, label = duracion_media)) +
    geom_bar(stat = "identity", position="dodge") +
    geom_text(size = 2.5, position = position_dodge(width = 1), vjust = -0.5)+
    xlab("Etapa procesamiento") +
    ylab("Duración media [seg]")
    # ylim(0, 85)

# plot
plot_filename = paste0("test_eficiencia_censo_validacion_",test_plot,".png")
ggsave(plot_filename, path=path_results, device="png", width=35, height=18, units="cm", dpi=300)


# PLOTTING TEST: with augmented error over partitions -------------------------------------------------

test_plot <- "with_augmented_error_by_partition"

cols_test <- c(
  "p0_farrow_err_aum_no",
  # "p0_farrow_err_aum_10e6",
  "p0_farrow_err_aum_20e6",
  "p0_farrow_err_aum_40e6",
  "p1_farrow_err_aum_no",
  # "p1_farrow_err_aum_10e6",
  "p1_farrow_err_aum_20e6",
  "p1_farrow_err_aum_40e6",
  "p2_farrow_err_aum_no",
  # "p2_farrow_err_aum_10e6",
  "p2_farrow_err_aum_20e6",
  "p2_farrow_err_aum_40e6",
  "p3_farrow_err_aum_no",
  # "p3_farrow_err_aum_10e6",
  "p3_farrow_err_aum_20e6",
  "p3_farrow_err_aum_40e6"
)

# cols_test <- c(
#   "p0_farrow_err_aum_no",
#   "p1_farrow_err_aum_no",
#   "p2_farrow_err_aum_no",
#   "p3_farrow_err_aum_no",
#   # "p0_farrow_err_aum_10e6",
#   # "p1_farrow_err_aum_10e6",
#   # "p2_farrow_err_aum_10e6",
#   # "p3_farrow_err_aum_10e6",
#   "p0_farrow_err_aum_20e6",
#   "p1_farrow_err_aum_20e6",
#   "p2_farrow_err_aum_20e6",
#   "p3_farrow_err_aum_20e6",
#   "p0_farrow_err_aum_40e6",
#   "p1_farrow_err_aum_40e6",
#   "p2_farrow_err_aum_40e6",
#   "p3_farrow_err_aum_40e6"
# )

df_plot %>%
    mutate(test=fct_relevel(factor(test, levels=cols_test))) %>%
    filter(test %in% cols_test) %>%
    ggplot(aes(x=etapa, y=duracion_media, fill=test, label=duracion_media)) +
    geom_bar(stat = "identity", position="dodge") +
    geom_text(size = 2.5, position = position_dodge(width = 1), vjust = -0.5)+
    xlab("Etapa procesamiento") +
    ylab("Duración media [seg]")
    # ylim(0, 85)

# plot
plot_filename = paste0("test_eficiencia_censo_validacion_",test_plot,".png")
ggsave(plot_filename, path=path_results, device="png", width=45, height=18, units="cm", dpi=300)