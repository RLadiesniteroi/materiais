#Definir o diretorio onde estao os arquivos e serão gravados
install.packages("bibliometrix")
install.packages("openxlsx")
#Carregar o app Bibliometrix para o ambiente R
library(bibliometrix)

#Importar os arquivos da busca para o ambiente R e converte-los em tabela (dataframe)

S=convert2df("scopus.bib", dbsource = "scopus", format = "bibtex")
View(S)
W=convert2df("savedrecs.bib", dbsource = "isi", format = "bibtex")
View(W)

#Fazer a uniao das duas tabelas com os dados das buscas nas base de dados

Database=mergeDbSources(S, W, remove.duplicated = TRUE)

View(Database)
dim(Database)
#Gravar a tabela resultante em um arquivo formato Excel para a limpeza final dos dados
library(openxlsx)
write.xlsx(Database, file = "Database.xlsx")

library(bibliometrix)
biblioshiny()
