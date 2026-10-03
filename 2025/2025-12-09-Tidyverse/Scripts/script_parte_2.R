#juncao das bases com os comandos
#inner_join, left_join, 


#############################################
# Pacotes
#############################################

library(tidyverse)
library(dplyr)


#############################################
# Leitura das bases
#############################################
dir()
setwd("..")
dir()
setwd("Dados")
dir()

base_NV <- readRDS("DNV_agregados.rds") #nascidos vivos
base_NV
base_OM <- readRDS("DOM_agregados.rds") #obito mae
base_OM

# Visualizar estrutura
glimpse(base_NV)
dim(base_NV)
glimpse(base_OM)
dim(base_OM)

base_NV
base_OM

#############################################
# Exemplos de joins pelo código do município
#############################################

# Inner join
base_inner = 
  inner_join(x = base_NV, 
             y = base_OM, 
             by = "CODMUNRES")
dim(base_inner)
glimpse(base_inner)
#ou, com outra sintaxe
base_inner = base_NV |> inner_join(base_OM, by = "CODMUNRES")
dim(base_inner)
glimpse(base_inner)

# Left join
base_left = left_join(base_NV, 
                      base_OM, 
                      by = "CODMUNRES")
dim(base_left)
glimpse(base_left)
#
base_left <- base_NV |> left_join(base_OM, by = "CODMUNRES")
dim(base_left)
glimpse(base_left)

# Right join
base_right <- right_join(base_NV, base_OM, by = "CODMUNRES")
dim(base_right)
glimpse(base_right)
#ou
base_right <- base_NV |> right_join(base_OM, by = "CODMUNRES")
dim(base_right)
glimpse(base_right)

# Full join
base_full = full_join(
  base_NV, 
  base_OM, by = "CODMUNRES")

dim(base_full)
glimpse(base_full)
#ou
base_full <- base_NV |> full_join(base_OM, by = "CODMUNRES")
dim(base_full)
glimpse(base_full)




#############################################
# Mais Exemplos com outras bases
#############################################

base_OM_BR = 
  read_csv("OM_BR.csv")
dim(base_OM_BR)
glimpse(base_OM_BR)
base_OM_BR$CODMUNRES = 
  as.character(base_OM_BR$CODMUNRES)
glimpse(base_OM_BR)


base_mun = read_csv("dados_mun.csv")
glimpse(base_mun)
base_mun$cod_municipio = 
  as.character(base_mun$cod_municipio)
base_mun$uf =as.factor(base_mun$uf)
base_mun$Ano =as.factor(base_mun$Ano)

base_mun = rename(base_mun,"CODMUNRES" = "cod_municipio")

base_mun = base_mun |> 
  rename("CODMUNRES" = "cod_municipio")
glimpse(base_mun)


base = base_OM_BR |> left_join(
  base_mun,
  by = "CODMUNRES")
glimpse(base)

# Vamos seguir a análise com essa base
dados = base
dim(dados)
glimpse(dados)


#############################################
# Verificação de NA
#############################################

is.na(dados)
sum(is.na(dados))


library(naniar)

gg_miss_var(dados)
#ou
dados |> gg_miss_var()

miss_var_table(dados)

dim(dados)

#vamos eliminar as linhas das variaveis com na
dados_sem_na = na.omit(dados)

dados_sem_na |> gg_miss_var()

dados = dados_sem_na

miss_var_table(dados)
sum(is.na(dados))
gg_miss_var(dados)

###########################################
# Análise univariada das categoricas
##########################################

glimpse(dados)
#Ano, uf
table(dados$Ano)
dados = dados |> select(-Ano)
glimpse(dados)

table(dados$uf)
barplot(table(dados$uf))
#ou 
table(dados$uf) |> barplot()
table(dados$uf) |> 
  barplot(col="red")
table(dados$uf) |> 
  barplot(col=c("blue","red"))
table(dados$uf) |> 
  barplot(col=gray((1:27)/27))
cod_cor = 
  1 - table(dados$uf)/max(table(dados$uf))
table(dados$uf) |> barplot(col=gray(cod_cor))


#############################################
# Variância nas numéricas
#############################################

#variancia por variavel
var(dados$total_mortes)
var(dados$n_brancos)
var(dados$n_preta)

#matriz de variancia e covariancia
var(dados |> select(-c(CODMUNRES,uf)))

#elementos da diagonal que representam as variâncias
mat_var = var(dados |> select(-c(CODMUNRES,uf)))
diag(mat_var)
min(diag(mat_var))
which.min(diag(mat_var))

#Analise univariada var quantitativa
hist(dados$total_mortes,
     main = "Histograma do total de mortes por município",
     xlab = "Total de mortes")

dados_RJ = dados |> 
  filter(uf=="RJ")
hist(dados_RJ$total_mortes,
     main = "Histograma do total de mortes por município",
     xlab = "Total de mortes")


#boxplot
boxplot(
  dados$total_mortes,
  main = "Boxplot do total de mortes por município",
  ylab = "Total de mortes",
  xlab = "BR")

boxplot(dados_RJ$total_mortes,
        main = "Boxplot do total de mortes por município",
        ylab = "Total de mortes",
        xlab = "RJ")

dados_SP = dados |> filter(uf=="SP")
boxplot(dados_RJ$total_mortes,
        dados_SP$total_mortes,
        main = "Boxplot do total de mortes por município",
        ylab = "Total de mortes",
        names = c("RJ","SP"))

dados_MG = dados |> 
  filter(uf=="MG")
dados_ES = dados |> 
  filter(uf=="ES")
boxplot(dados_RJ$total_mortes,
        dados_SP$total_mortes,
        dados_MG$total_mortes,
        dados_ES$total_mortes,
        main = "Boxplot do total de mortes por município",
        ylab = "Total de mortes",
        names = c("RJ","SP","MG","ES"),
        col = c("red","blue","green","yellow"))


boxplot(dados_RJ$total_mortes,
        dados_SP$total_mortes,
        dados_MG$total_mortes,
        dados_ES$total_mortes,
        main = "Boxplot do total de mortes por município",
        ylab = "Total de mortes",
        names = c("RJ","SP","MG","ES"),
        col = c("red3","skyblue","forestgreen","orange"))

windows(60,100)
boxplot(dados_RJ$total_mortes,
        dados_SP$total_mortes,
        dados_MG$total_mortes,
        dados_ES$total_mortes,
        main = "Boxplot - mortes por município",
        ylab = "Total de mortes",
        names = c("RJ","SP","MG","ES"),
        col = c("red3","skyblue","forestgreen","orange"))


max(dados_RJ$total_mortes)
which.max(dados_RJ$total_mortes)
dados_RJ = dados_RJ[-24,]

boxplot(dados_RJ$total_mortes,
        dados_SP$total_mortes,
        dados_MG$total_mortes,
        dados_ES$total_mortes,
        main = "Boxplot do total de mortes por município",
        ylab = "Total de mortes",
        names = c("RJ","SP","MG","ES"),
        col = c("red3","skyblue","forestgreen","orange"))


boxplot(
  total_mortes ~ uf,
  data = dados,
  main = "Boxplot do total de mortes por município",
  ylab = "Total de mortes")


boxplot(n_fundI ~ uf,data = dados,
        main = "Boxplot do total de mortes por município",
        ylab = "Total de mortes")


boxplot(dados$n_fundI, dados$n_fundII, dados$n_medio, dados$n_sup_incompleto, dados$n_sup,
        main = "Boxplot do total de mortes por município",
        ylab = "Total de mortes",
        names = c("FundI","FundII","Médio","Supo Inc","Sup"))

mat_cor = cor(dados |> select(-c(CODMUNRES,uf)))

View(mat_cor)

#analisando valores significativos]
colnames(mat_cor)
rownames(mat_cor)
j = 1
colnames(mat_cor)[j]
indices = which(mat_cor[,j]>0.8)
mat_cor[indices,j]

j = 14
colnames(mat_cor)[j]
indices = which(mat_cor[,j]>0.8)
mat_cor[indices,j]

#dispersao
plot(x = dados$pop,
     y = dados$total_mortes,
     main = "Gráfico de Dispersão entre o tamanho da pop e o totol de mortes",
     xlab = "nº de habitantes",
     ylab = "Total de mortes maternas"
     )


pairs(dados |> select(-c(CODMUNRES,uf)))
pairs(dados |> select(c(total_mortes,
                        pop,
                        pib)))


library(GGally)
ggpairs(dados |> select(-c(CODMUNRES,uf)))
ggpairs(dados |> select(c(total_mortes,
                        pop,
                        pib)))
