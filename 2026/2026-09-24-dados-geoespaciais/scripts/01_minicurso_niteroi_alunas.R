#########################################################################################
#=======================================================================================#
# TRABALHANDO COM DADOS GEOESPACIAIS NO R
# R-Ladies Niterói 2026
# Profa. Dra. Cássia Silva
#=======================================================================================#
#########################################################################################

#=======================================================================================#
# 1. PROJETO E CONFIGURAÇÃO DO AMBIENTE
#=======================================================================================#

# Boas-vindas! Vamos trabalhar dentro do projeto 'Rladies_Niteroi.Rproj'.
# DICA: Trabalhar com Projetos no RStudio (.Rproj) garante que os caminhos relativos
# funcionem perfeitamente em qualquer computador sem precisar usar setwd().

getwd() # getwd() (get working directory): exibe no console a pasta que o R está usando como raiz.

# DICA DIDÁTICA PARA A AULA:
# Para testar o script do zero, salve este arquivo e reinicie a sessão no RStudio:
# Vá no menu superior: Session > Restart R ou selecione o atalho ctrl + shift + f10
# Execute os blocos sequencialmente. Se um erro ocorrer, resolva-o antes de prosseguir!


#---------------------------------------------------------------------------------------#
# 1.1 CARREGAMENTO DE PACOTES
#---------------------------------------------------------------------------------------#

# Pacotes essenciais do nosso ecossistema geoespacial:
# -> tidyverse: manipulação de dados (dplyr, ggplot2, readr, purrr)
# -> sf: manipulação e análise de vetores (Simple Features)
# -> ggspatial: elementos cartográficos para o ggplot2 (seta de Norte e barra de escala)
# -> terra: processamento de dados matriciais/rasters (SpatRaster e SpatVector)
# -> patchwork: composição e montagem de múltiplos mapas na mesma figura

# Instalação (caso algum pacote não esteja instalado):
# install.packages(c("tidyverse", "sf", "ggspatial", "terra", "patchwork"))

library(tidyverse)
library(sf)
library(ggspatial)
library(terra)
library(patchwork)


#---------------------------------------------------------------------------------------#
# 1.2 CRIAÇÃO DA ESTRUTURA DE PASTAS DE SAÍDA
#---------------------------------------------------------------------------------------#
# Boas práticas: organizamos o projeto separando dados brutos, processados e mapas finais.

dir.create( # dir.create(): cria uma nova pasta no diretório do projeto.
  path = "dados/processados",
  recursive = TRUE,   # recursive = TRUE: permite criar pastas intermediárias (subpastas) de uma vez.
  showWarnings = FALSE # showWarnings = FALSE: evita mensagens de aviso no console caso a pasta já exista.
)

dir.create(
  path = "resultados/mapas",
  recursive = TRUE,
  showWarnings = FALSE
)


#---------------------------------------------------------------------------------------#
# 1.3 CAMINHOS DOS ARQUIVOS DE ENTRADA
#---------------------------------------------------------------------------------------#

# Armazenar o endereço dos arquivos em variáveis evita repetição de código
# e facilita a manutenção do script caso os arquivos mudem de pasta.

arquivo_shape <- 
  "dados/brutos/shapefile_niteroi/limite_niteroi.shp"

arquivo_vetorial <-
  "dados/brutos/dados_vetoriais_niteroi.gpkg"

arquivo_mapbiomas <-
  "dados/brutos/mapbiomas_entorno_niteroi_2025.tif"

arquivo_legenda_mapbiomas <-
  "dados/brutos/legenda_mapbiomas_10m_colecao4.csv"

arquivo_mde <-
  "dados/brutos/elevation/srtm_28_17.tif"

arquivo_b04 <-
  "dados/brutos/sentinel2_entorno_niteroi_B04_reflectancia.tif"

arquivo_b08 <-
  "dados/brutos/sentinel2_entorno_niteroi_B08_reflectancia.tif"


# CHECAGEM PREVENTIVA: Conferir se todos os arquivos brutos estão presentes no computador.
file.exists(
  c(
    arquivo_shape,
    arquivo_vetorial,
    arquivo_mapbiomas,
    arquivo_legenda_mapbiomas,
    arquivo_mde,
    arquivo_b04,
    arquivo_b08
  )
)

# RESULTADO ESPERADO NO CONSOLE: [1] TRUE TRUE TRUE TRUE TRUE TRUE TRUE
# 
# ⚠️ O QUE FAZER SE APARECER 'FALSE'?
# - Verifique se o projeto RStudio correto está aberto no canto superior direito;
# - Confirme se a pasta 'dados' foi extraída completamente na raiz do projeto;
# - Confira se não há erros de digitação nos caminhos ou extensoes dos arquivos.


#=======================================================================================#
# 2. COMO OS DADOS GEOESPACIAIS CHEGAM NO R?
#=======================================================================================#
#
# CONCEITO FUNDAMENTAL: Diferenciar ESTRUTURA de FORMATO.
#
# ESTRUTURA ESPACIAL (Como o espaço é representado numericamente):
# -> Vetor: Representa o mundo através de pontos, linhas e polígonos com atributos.
# -> Raster: Representa o mundo através de uma grade regular de células/pixels.
#
# FORMATO DE ARMAZENAMENTO (Como os arquivos são salvos no disco do computador):
# -> Shapefile (.shp + .dbf + .shx + .prj): Formato vetorial clássico legado.
# -> GeoPackage (.gpkg): Formato vetorial moderno, rápido e em arquivo único.
# -> GeoTIFF (.tif): Formato padrão internacional para dados matriciais/raster.


#---------------------------------------------------------------------------------------#
# 2.1 SHAPEFILE (VETOR TRADICIONAL)
#---------------------------------------------------------------------------------------#

# Um "Shapefile" NÃO é apenas um arquivo .shp! Ele exige um conjunto mínimo de arquivos:
# -> .shp (geometria das feições)
# -> .dbf (tabela de atributos)
# -> .shx (índice de busca espacial)
# -> .prj (metadados do sistema de coordenadas/projeção)
#
# DICA: Para compartilhar um Shapefile, envie sempre todos os arquivos juntos (compactados em .zip).

niteroi_shape <- st_read(
  dsn = arquivo_shape, # dsn (Data Source Name): especifica o caminho/endereço do arquivo a ser lido.
  quiet = TRUE          # quiet = TRUE: oculta a mensagem detalhada de importação no console.
)

# Verificação da classe do objeto no R
class(
  x = niteroi_shape # Retorna "sf" (Simple Features) e "data.frame" (Tabela).
)


#---------------------------------------------------------------------------------------#
# 2.2 GEOPACKAGE (BANCO DE DADOS ESPACIAL MODERNO)
#---------------------------------------------------------------------------------------#
# O GeoPackage (.gpkg) é um formato aberto e compacto que funciona como um banco de dados.
# Ele permite salvar múltiplas camadas vetoriais e tabelas dentro de um único arquivo!

# 1. Consulta das camadas disponíveis no arquivo com st_layers()
st_layers(
  dsn = arquivo_vetorial # Lista todas as camadas armazenadas no GeoPackage sem carregá-las na RAM.
)

# 2. Importação de uma camada específica com st_read()
niteroi <- st_read(
  dsn = arquivo_vetorial,    # dsn: caminho do arquivo GeoPackage.
  layer = "limite_niteroi", # layer: especifica qual camada do banco de dados queremos importar.
  quiet = TRUE               # quiet = TRUE: oculta mensagens no console.
)

# Verificação da classe do objeto
class(
  x = niteroi
) 

# 💡 RESUMO PARA FIXAR:
# Qualquer arquivo vetorial lido pelo pacote 'sf' (Shapefile, GeoPackage, GeoJSON)
# se transforma em um objeto da classe 'sf' dentro do ambiente R!


# INSPEÇÃO DE ATRIBUTOS E METADADOS DE UM OBJETO ESPACIAL (sf)

# 1. QUAIS SÃO OS NOMES DE TODAS AS COLUNAS (ATRIBUTOS + GEOMETRIA)?
names(
  x = niteroi # Retorna as colunas da tabela de dados, incluindo a coluna especial 'geometry'.
)

# 2. COMO TRABALHAR APENAS COM A TABELA ALFANUMÉRICA (SEM A GEOMETRIA)?
niteroi |>
  st_drop_geometry() # Desconecta temporariamente a coluna espacial, convertendo em uma tabela comum (tibble).

# 3. QUAL É O TIPO DE FEIÇÃO GEOMÉTRICA DO MAPA?
st_geometry_type(
  x = niteroi # Retorna o tipo de feição (ex: POLYGON, MULTIPOLYGON, POINT, LINESTRING).
)

# 4. QUAL É O SISTEMA DE REFERÊNCIA DE COORDENADAS (CRS / PROJEÇÃO)?
st_crs(
  x = niteroi # Consulta o SRC (ex: SIRGAS 2000 Geográfico = EPSG:4674; WGS 84 = EPSG:4326).
)

# 5. QUAIS SÃO OS LIMITES GEOGRÁFICOS RETANGULARES (BOUNDING BOX) DA CAMADA?
st_bbox(
  obj = niteroi # Calcula as coordenadas extremas do retângulo envelope (xmin, ymin, xmax, ymax).
)


#---------------------------------------------------------------------------------------#
# 2.3 GEOTIFF (DADOS MATRICIAIS / RASTER)
#---------------------------------------------------------------------------------------#
# CONCEITO: O QUE É UM RASTER?
# -> Uma matriz retangular dividida em células/pixels organizadas em linhas e colunas.
# -> Cada pixel possui uma posição física na Terra e UM VALOR numérico associado.
# -> O valor pode significar altitude (m), temperatura (°C), uso do solo (códigos), etc.

# Importação da imagem raster com a função rast() do pacote 'terra'
raster_exemplo <- rast(
  x = arquivo_mapbiomas # x: endereço do arquivo matricial (.tif / GeoTIFF).
)

# Verificação da classe do objeto no R
class(
  x = raster_exemplo # Retorna "SpatRaster", a classe oficial do pacote 'terra'.
)

# 💡 RESUMO PARA FIXAR:
# Vetores viram a classe 'sf' (pacote sf).
# Rasters viram a classe 'SpatRaster' (pacote terra).


# METADADOS BÁSICOS DE UM RASTER (SpatRaster)

# 1. QUAL É O SISTEMA DE REFERÊNCIA DE COORDENADAS (CRS / PROJEÇÃO)?
crs(
  x = raster_exemplo # Exibe o sistema de coordenadas e datum da matriz raster.
)

# 2. QUAL É A EXTENSÃO GEOGRÁFICA (BOUNDING BOX / LIMITES)?
ext(
  x = raster_exemplo # Exibe a extensão retangular em coordenadas (Xmin, Xmax, Ymin, Ymax).
)

# 3. QUAL É A RESOLUÇÃO ESPACIAL (TAMANHO DO PIXEL)?
res(
  x = raster_exemplo # Exibe o tamanho de cada pixel em X e Y (ex: 30x30 metros ou em graus).
)


#---------------------------------------------------------------------------------------#
# 2.4 EQUIVALÊNCIAS RÁPIDAS DE COMANDOS: sf (Vetores) vs terra (Rasters)
#---------------------------------------------------------------------------------------#
# PROJEÇÃO:   st_crs(vetor)         <--->  crs(raster)
# LIMITES:    st_bbox(vetor)        <--->  ext(raster)
# COLUNAS:    names(vetor) = dados  <--->  names(raster) = camadas/bandas
# TABELA:     st_drop_geometry()    <--->  as.data.frame()
#
# EXCLUSIVOS DE CADA ESTRUTURA:
# - Vetor:  st_geometry_type(vetor) -> Tipo de geometria (Ponto, Linha, Polígono)
# - Raster: res(raster)             -> Tamanho do Pixel / Resolução Espacial


#=======================================================================================#
# 3. PRIMEIRAS VISUALIZAÇÕES CARTOGRÁFICAS
#=======================================================================================#

#---------------------------------------------------------------------------------------#
# 3.1 PLOT NATIVO (R BASE) E CONSTRUÇÃO EM CAMADAS COM GGPLOT2
#---------------------------------------------------------------------------------------#

# Visualização rápida com o gráfico nativo do R (R Base):

plot(niteroi) # ATENÇÃO: Desenha um mapa para CADA coluna presente na tabela de atributos.

plot(
  st_geometry(niteroi) # Extrai e plota APENAS a geometria, evitando múltiplos mapas na tela.
)

plot(
  st_geometry(niteroi),
  col = "purple" # col: define a cor de preenchimento do polígono.
)

plot(
  st_geometry(niteroi),
  col = NA,       # col = NA: torna o preenchimento transparente.
  border = "gray" # border: define a cor da linha de contorno.
)

plot(
  st_geometry(niteroi),
  col = NA,
  border = "black",
  main = "Limite do Município de Niterói" # main: título centralizado no topo.
)


# Visualização com o pacote 'ggplot2' (Padrão moderno em R):
# O ggplot2 constrói gráficos por camadas sobrepostas usando o operador de soma "+".

mapa_limite <- ggplot(
  data = niteroi # data: especifica o objeto espacial da classe sf.
) +
  geom_sf( # geom_sf(): reconhece automaticamente a coluna 'geometry' do objeto sf.
    fill = "#EDEDF4",   # fill: cor de preenchimento do interior (código Hex: lilás claro).
    color = "#881EF9",  # color: cor da linha do contorno (código Hex: roxo/púrpura).
    linewidth = 1      # linewidth: espessura da linha de borda.
  ) +
  labs(
    title = "Município de Niterói",               # title: título do mapa.
    subtitle = "Primeira construção com ggplot2"   # subtitle: subtítulo informativo.
  ) +
  theme_minimal() # theme_minimal(): tema limpo com linhas de grade sutis.

# Exibe o mapa armazenado no objeto 'mapa_limite':
mapa_limite


# TESTANDO VARIAÇÕES DE TEMAS NO GGPLOT2 PARA MAPAS:

# --- Opção A: Totalmente limpo (IDEAL PARA MAPAS CARTOGRÁFICOS) ---
mapa_limite + theme_void() # Remove eixos, coordenadas, linhas de grade e fundo.

# --- Opção B: Escuro e Elegante (Dark Mode) ---
mapa_limite + theme_dark() # Excelente para slides em telas escuras ou mapas neon.

# --- Opção C: Clássico com bordas ---
mapa_limite + theme_bw() # Mantém moldura preta e eixos limpos.

# --- Opção D: Estilo Artigo Científico / Publicação ---
mapa_limite + theme_classic() # Remove linhas de grade e foca totalmente na geometria.


#---------------------------------------------------------------------------------------#
# 3.2 MAPA DE CONTEXTO TERRITORIAL (SOBREPOSIÇÃO DE CAMADAS)
#---------------------------------------------------------------------------------------#

# 1. Importação da camada de todos os municípios do Estado do Rio de Janeiro
municipios_rj <- st_read(
  dsn = arquivo_vetorial,
  layer = "municipios_rj_2024",
  quiet = TRUE
)

# 2. Filtragem dos municípios vizinhos usando a integração do sf com o dplyr
municipios_limitrofes <- municipios_rj |>
  filter(
    name_muni %in% c("São Gonçalo", "Maricá") # %in%: filtra cidades contidas no vetor de nomes.
  )


# 3. CONSTRUÇÃO DO MAPA DE CONTEXTO TERRITORIAL EM CAMADAS
# A Ordem de sobreposição no código define a ordem de desenho no papel (fundo -> frente):
# 1. Oceano/Fundo do Painel -> 2. Todos os municípios do RJ -> 3. Vizinhos -> 4. Niterói

mapa_niteroi_contexto <- ggplot() +
  
  # CAMADA 1 (Fundo/Base): Todos os municípios do Estado do RJ
  geom_sf(
    data = municipios_rj,
    fill = "#ECE9E1", # Preenchimento bege/areia para o continente.
    color = NA        # color = NA: remove as bordas para evitar poluição visual.
  ) +
  
  # CAMADA 2 (Destaque dos Vizinhos): Municípios limítrofes (São Gonçalo e Maricá)
  geom_sf(
    data = municipios_limitrofes,
    fill = NA,         # Mantém o interior transparente.
    color = "#7A817D", # Linha cinza para as divisas vizinhas.
    linewidth = 0.65
  ) +
  
  # CAMADA 3 (Elemento Principal/Foco): Município de Niterói
  geom_sf(
    data = niteroi,
    fill = "#C65D5D",  # Tom terracota/vermelho para atrair o olhar.
    color = "#784343", # Borda terracota escura em harmonia.
    linewidth = 0.8
  ) +
  
  # ENQUADRAMENTO E ZOOM DO MAPA (Bounding Box / Janela de Exibição)
  coord_sf(
    xlim = c(-43.23, -42.80), # xlim: limites de Longitude (Oeste/Leste).
    ylim = c(-23.16, -22.76), # ylim: limites de Latitude (Sul/Norte).
    expand = FALSE            # expand = FALSE: impede o ggplot de adicionar margem extra indesejada.
  ) +
  
  # RÓTULOS E CRÉDITOS
  labs(
    title = "Niterói em seu contexto territorial",
    caption = "Fonte: IBGE; dados preparados para a oficina."
  ) +
  
  # ESTILIZAÇÃO E SIMULAÇÃO VISUAL DE CORPOS D'ÁGUA
  theme_void() +
  theme(
    panel.background = element_rect(
      fill = "#DCEFF5", # Fundo azul claro simulando o Oceano Atlântico e a Baía de Guanabara.
      color = NA
    )
  )

# Exibe o mapa de contexto pronto:
mapa_niteroi_contexto


#=======================================================================================#
# 4. SISTEMAS DE REFERÊNCIA DE COORDENADAS (SRC/CRS) E CÁLCULO DE ÁREA
#=======================================================================================#
#
# REGRA DE OURO DA CARTOGRAFIA: "Localizar não é o mesmo que medir!"
#
# -> EPSG 4674 (SIRGAS 2000 Geográfico): Coordenadas medidas em GRAUS (Latitude/Longitude).
#    Ideal para armazenar e apontar posições no globo, mas NÃO serve para medir áreas/distâncias no plano.
#
# -> EPSG 31983 (SIRGAS 2000 / UTM zona 23S): Coordenadas medidas em METROS.
#    Ideal para CALCULAR ÁREAS (m² ou km²) e fazer medições cartográficas no estado do RJ.
#
# ⚠️ A ZONA UTM MUDA DE ACORDO COM A LOCALIZAÇÃO DO SEU MAPA!
# -> O sistema UTM divide a Terra em 60 zonas/fusos verticais de 6° de longitude.
# -> Niterói e a maior parte do RJ estão localizados na Zona 23S (EPSG:31983).
# -> Sempre verifique qual fuso UTM corresponde à sua área de estudo antes de reprojetar!


# 1. Consulta o CRS atual do objeto
st_crs(
  x = niteroi # Exibe o EPSG atual (está em graus - EPSG 4674).
)


# 2. Reprojeção espacial com st_transform()
# Converte as coordenadas de GRAUS para METROS usando a projeção UTM Zona 23S (EPSG 31983).
niteroi_utm <- niteroi |>
  st_transform(
    crs = 31983 # crs = 31983: código EPSG do SIRGAS 2000 / UTM zona 23S (medido em metros).
  )

municipios_rj_utm <- municipios_rj |>
  st_transform(
    crs = 31983 # Reprojeta a camada do estado inteiro para manter todos no mesmo CRS projetado.
  )


# 3. Cálculo de Área Geográfica com st_area()
# Como a camada está em metros (UTM), st_area() calcula a área das geometrias em m² (metros quadrados).
# Dividimos por 1.000.000 (10^6) para converter de m² para km² (1 km² = 1.000.000 m²).

niteroi_utm$area_km2 <- as.numeric( # as.numeric(): remove o rótulo de unidade [m^2], transformando em número puro.
  st_area(
    x = niteroi_utm
  )
) / 1000000


# 4. Visualização do resultado em tabela alfanumérica limpa
niteroi_utm |>
  st_drop_geometry() |> # Desconecta a geometria e mantém apenas a tabela de atributos.
  select(               # Seleciona apenas as colunas de interesse para exibição.
    any_of(
      c(
        "name_muni",    # Nome do município
        "area_km2"      # Área calculada em quilômetros quadrados
      )
    )
  )


#=======================================================================================#
# 5. MAPAS TEMÁTICOS COM VETORES
#=======================================================================================#

# Antes de desenhar as escolas, vamos importar e preparar a camada de bairros de Niterói.
# Este objeto será reutilizado tanto no mapa de pontos quanto no mapa coropleta de áreas.

bairros_niteroi <- st_read(
  dsn = arquivo_vetorial,
  layer = "bairros_niteroi_2022",
  quiet = TRUE
)

bairros_niteroi_utm <- bairros_niteroi |>
  st_transform(
    crs = 31983 # Reprojeta a camada de bairros para SIRGAS 2000 / UTM zona 23S em metros.
  )


#---------------------------------------------------------------------------------------#
# 5.1 PONTOS + POLÍGONOS (LOCALIZAÇÃO DAS ESCOLAS)
#---------------------------------------------------------------------------------------#
# CONCEITO CARTOGRÁFICO: Sobreposição de Geometrias Diferentes (Multicamadas).
# -> A ordem das camadas geom_sf() no ggplot2 define a pilha visual.
# -> Regra Prática: Desenhe Polígonos de base primeiro e Pontos de detalhe por cima!


# 1. Importação dos dados pontuais de escolas com st_read()
escolas_niteroi <- st_read(
  dsn = arquivo_vetorial,
  layer = "escolas_niteroi_2025",
  quiet = TRUE
)


# 2. Alinhamento de Projeção Espacial (CRUCIAL para sobrepor camadas no mesmo mapa)
escolas_niteroi_utm <- escolas_niteroi |>
  st_transform(
    crs = 31983 # Reprojeta os pontos das escolas para UTM 23S (mesmo CRS dos bairros).
  )


# 3. Construção do mapa multicamadas no ggplot2
mapa_escolas_niteroi <- ggplot() +
  
  # CAMADA 1 (Polígonos de Fundo): Bairros de Niterói
  geom_sf(
    data = bairros_niteroi_utm,
    fill = "#EEF5EF", # Tom verde-claro suave para a massa territorial.
    color = "white",   # Linhas brancas finas para separar os bairros de forma discreta.
    linewidth = 0.2
  ) +
  
  # CAMADA 2 (Polígono de Destaque): Contorno do município de Niterói
  geom_sf(
    data = niteroi_utm,
    fill = NA,         # Preenchimento transparente para permitir ver os bairros desenhados abaixo.
    color = "#4C6255", # Verde-escuro marcante para delimitar a fronteira externa do município.
    linewidth = 0.8
  ) +
  
  # CAMADA 3 (Geometria Pontual no Topo): Localização das Escolas
  geom_sf(
    data = escolas_niteroi_utm,
    color = "#C65D5D", # Tom terracota/vermelho em alto contraste com o fundo verde.
    size = 1.5,        # Diâmetro visual de cada ponto.
    alpha = 0.75       # Transparência (75% opacidade) para evidenciar regiões com acúmulo de pontos.
  ) +
  
  # RÓTULOS E TÍTULOS
  labs(
    title = "Escolas localizadas em Niterói",
    subtitle = "Exemplo de sobreposição entre pontos e polígonos"
  ) +
  
  # ESTILIZAÇÃO VISUAL
  theme_minimal()

# Exibe o mapa multicamadas:
mapa_escolas_niteroi


# ⚠️ CUIDADO NA INTERPRETAÇÃO CARTOGRÁFICA:
# A distribuição de pontos mostra ONDE as escolas estão localizadas, mas NÃO garante:
# - Acesso universal ou facilidade de transporte;
# - Quantidade de vagas disponíveis;
# - Qualidade do ensino prestado.


#---------------------------------------------------------------------------------------#
# 5.2 MAPA COROPLETA (ÁREA DOS BAIRROS)
#---------------------------------------------------------------------------------------#
# CONCEITO CARTOGRÁFICO: Mapa Coropleta (Choropleth Map).
# -> Pinta polígonos usando variações de cores para representar uma VARIÁVEL QUANTITATIVA.
# -> Neste exemplo: quanto maior a área do bairro, mais clara/intensa fica a cor no gradiente.


# 1. Cálculo geométrico da área por bairro em km²
bairros_niteroi_utm$area_km2 <- as.numeric(
  st_area(
    x = bairros_niteroi_utm
  )
) / 1000000


# ---------------------------------------------------------------------------------------
# REGRA DE OURO DO ggplot2:
# -> FORA do aes()  -> Aparência ESTÁTICA/FIXA (ex: color = "white", linewidth = 0.2).
# -> DENTRO do aes() -> Aparência Mapeada a uma VARIÁVEL (ex: fill = area_km2).
# ---------------------------------------------------------------------------------------

# 2. Construção do mapa temático coropleta no ggplot2
mapa_area_bairros <- ggplot() +
  
  # CAMADA 1 (Polígonos Temáticos): Bairros coloridos pela variável de área
  geom_sf(
    data = bairros_niteroi_utm,
    mapping = aes(
      fill = area_km2 # Preenchimento varia proporcionalmente ao tamanho do bairro em km².
    ),
    color = "white",  # Cor fixa branca para as linhas de divisa dos bairros.
    linewidth = 0.2
  ) +
  
  # CAMADA 2 (Polígono de Destaque): Contorno externo do município
  geom_sf(
    data = niteroi_utm,
    fill = NA,         # Mantém o interior transparente.
    color = "#3F5447", # Verde-musgo escuro para contornar todo o município.
    linewidth = 0.8
  ) +
  
  # ESCALA DE CORES CONTÍNUA (Viridis)
  scale_fill_viridis_c(
    option = "C",                 # Option = "C" (Plasma): gradiente do roxo escuro ao amarelo claro.
    name = "Área do bairro\n(km²)" # Título da legenda (o '\n' quebra a linha para organizar).
  ) +
  
  # RÓTULOS E CRÉDITOS
  labs(
    title = "Área dos bairros de Niterói",
    caption = "Nota: A área representa uma medida geométrica e não o total populacional."
  ) +
  
  # ESTILIZAÇÃO VISUAL
  theme_minimal()

# Exibe o mapa temático coropleta:
mapa_area_bairros


# ❓ PERGUNTA PARA A TURMA:
# Um bairro com maior extensão territorial (área maior) é necessariamente o mais populoso?
# -> RESPOSTA: NÃO! O mapa mostra área física geométrica, não densidade ou total de habitantes.


#---------------------------------------------------------------------------------------#
# 5.3 COMPOSIÇÃO CARTOGRÁFICA MULTIESCALA (MAPA DE LOCALIZAÇÃO)
#---------------------------------------------------------------------------------------#
# CONCEITO CARTOGRÁFICO: Mapa de Localização Multiescala (Insets / Mapas de Apoio).
# -> Combina diferentes níveis de escala (Nacional, Estadual e Municipal) em uma única figura.
# -> Utiliza 'ggspatial' para elementos cartográficos e 'patchwork' para montagem dos painéis.


# 1. Importação da camada de estados do Brasil com st_read()
estados_brasil <- st_read(
  dsn = arquivo_vetorial,
  layer = "estados_brasil_2024",
  quiet = TRUE
)


# 2. Filtragem do Estado do Rio de Janeiro com dplyr::filter()
rio_de_janeiro <- estados_brasil |>
  filter(
    abbrev_state == "RJ" # Isola exclusivamente o polígono do Estado do Rio de Janeiro.
  )


# 3. Definição da Paleta de Cores em Variáveis (Padronização e Harmonia Visual)
cor_niteroi  <- "#881EF9" # Púrpura/Roxo: cor do objeto principal de estudo.
cor_contorno <- "#5E16AC" # Roxo escuro: para as bordas de destaque.
cor_terra    <- "#F6F6FA" # Cinza bem claro/Off-white: massa territorial neutra.
cor_limite   <- "#B9B9C7" # Cinza intermediário: para divisas administrativas secundárias.
cor_agua     <- "#E9F1FF" # Azul muito claro: simulação visual de oceanos/corpos d'água.


# 4. Cálculo da Janela de Zoom (Bounding Box com Buffer Espacial)
janela_niteroi <- niteroi_utm |>
  st_buffer(
    dist = 7000 # dist = 7000: cria uma borda de expansão de 7 km no entorno do município.
  ) |>
  st_bbox()     # Extrai o vetor com coordenadas extremas (xmin, ymin, xmax, ymax).


# 5. CONSTRUÇÃO DO MAPA PRINCIPAL (Niterói e Entorno Imediato)
mapa_principal_localizacao <- ggplot() +
  
  # Camada 1: Todos os municípios do RJ (massa territorial de fundo)
  geom_sf(
    data = municipios_rj_utm,
    fill = cor_terra,
    color = cor_limite,
    linewidth = 0.25
  ) +
  
  # Camada 2: Município de Niterói em destaque
  geom_sf(
    data = niteroi_utm,
    fill = cor_niteroi,
    color = cor_contorno,
    linewidth = 0.7
  ) +
  
  # ELEMENTOS CARTOGRÁFICOS (Pacote 'ggspatial')
  annotation_scale(
    location = "bl" # location = "bl" (bottom-left): barra de escala no canto inferior esquerdo.
  ) +
  
  annotation_north_arrow(
    location = "tr",     # location = "tr" (top-right): seta do Norte no canto superior direito.
    which_north = "true" # which_north = "true": aponta para o Norte Geográfico/Verdadeiro.
  ) +
  
  # ENQUADRAMENTO E ZOOM ESPACIAL (coord_sf)
  coord_sf(
    xlim = c(janela_niteroi["xmin"], janela_niteroi["xmax"]),
    ylim = c(janela_niteroi["ymin"], janela_niteroi["ymax"]),
    expand = FALSE # expand = FALSE: impede o ggplot de criar margens automáticas extras.
  ) +
  
  # RÓTULOS DO MAPA PRINCIPAL
  labs(
    title = "Área de estudo",
    subtitle = "Niterói e entorno imediato"
  ) +
  
  # ESTILIZAÇÃO E SIMULAÇÃO DE CORPO D'ÁGUA
  theme_void() +
  theme(
    panel.background = element_rect(
      fill = cor_agua, # Fundo azul simulando a água ao redor do continente.
      color = NA
    )
  )


# 6. CONSTRUÇÃO DO INSET 1 (Contexto Nacional - Brasil)
mapa_inset_brasil <- ggplot() +
  geom_sf(
    data = estados_brasil,
    fill = cor_terra,
    color = cor_limite,
    linewidth = 0.2
  ) +
  geom_sf(
    data = rio_de_janeiro,
    fill = cor_niteroi,
    color = cor_contorno,
    linewidth = 0.45
  ) +
  labs(
    title = "Brasil",
    subtitle = "Rio de Janeiro em destaque"
  ) +
  theme_void()


# 7. CONSTRUÇÃO DO INSET 2 (Contexto Estadual - Rio de Janeiro)
mapa_inset_rj <- ggplot() +
  geom_sf(
    data = municipios_rj,
    fill = cor_terra,
    color = cor_limite,
    linewidth = 0.15
  ) +
  geom_sf(
    data = niteroi,
    fill = cor_niteroi,
    color = cor_contorno,
    linewidth = 0.5
  ) +
  labs(
    title = "Estado do Rio de Janeiro",
    subtitle = "Niterói em destaque"
  ) +
  theme_void()


# 8. COMPOSIÇÃO FINAL DOS PAINÉIS COM O PACOTE 'patchwork'

# Operador '/': empilha os dois mapas de contexto em uma única coluna vertical (Brasil sobre RJ).
coluna_insets <- mapa_inset_brasil / mapa_inset_rj

# Operador '|': posiciona o mapa principal na esquerda e a coluna de insets na direita.
# plot_layout(): controla as proporções visuais da composição final.
mapa_localizacao_niteroi <- (mapa_principal_localizacao | coluna_insets) +
  plot_layout(
    widths = c(2.2, 1) # Define que a coluna principal terá 2.2x a largura da coluna de insets.
  )

# Exibe o mapa de localização multiescala pronto:
mapa_localizacao_niteroi


#=======================================================================================#
# 6. PROCESSAMENTO E VISUALIZAÇÃO DE DADOS RASTER (MATRICIAIS)
#=======================================================================================#
# CONCEITO FUNDAMENTAL: O QUE É UM DADO RASTER?
# -> Um dado Raster (SpatRaster no pacote 'terra') é uma grade retangular de pixels (matriz).
# -> Cada pixel/célula possui uma localização espacial (linha, coluna) e UM VALOR associado.
#
# DISTINÇÃO CRUCIAL: CATEGÓRICO vs. CONTÍNUO
#
# 1. RASTER CATEGÓRICO (Qualitativo / Discreto):
#    - O valor numérico do pixel é apenas um CÓDIGO que representa uma classe/categoria.
#    - Exemplo (MapBiomas): Pixel = 3 (Formação Florestal), Pixel = 24 (Área Urbanizada).
#    - REGRA: Média ou desvio padrão dos pixels NÃO FAZEM SENTIDO (não existe "meia-floresta").
#    - O que analisar: Frequência de pixels e Área total por classe (km²).
#
# 2. RASTER CONTÍNUO (Quantitativo / Numérico):
#    - O valor do pixel representa uma medida ou um índice numérico naquela posição.
#    - Exemplo: Modelo Digital de Elevação (Altitude em metros), NDVI, Temperatura (°C).
#    - REGRA: Média, Mínimo, Máximo e Histogramas SÃO análises válidas.


#---------------------------------------------------------------------------------------#
# 6.1 IMPORTAÇÃO E INSPEÇÃO DO MAPBIOMAS
#---------------------------------------------------------------------------------------#

# rast(): função do pacote 'terra' que lê arquivos matriciais (GeoTIFF)
# e cria um objeto da classe 'SpatRaster'.
mapbiomas_bruto <- rast(
  x = arquivo_mapbiomas
)


# Inspeção de metadados do Raster importado
mapbiomas_bruto # Exibe no console dimensões (linhas, colunas, camadas), resolução e extensão.

crs(
  x = mapbiomas_bruto # Consulta o Sistema de Referência de Coordenadas do raster.
)

res(
  x = mapbiomas_bruto # Exibe o tamanho das células nas unidades do SRC (neste raster, em graus).
)


#---------------------------------------------------------------------------------------#
# 6.2 PREPARAR O LIMITE DE NITERÓI (COMPATIBILIZAÇÃO ESPACIAL)
#---------------------------------------------------------------------------------------#
# Para recortar o raster, colocamos vetor e raster no mesmo SRC.
# Depois convertemos o vetor para SpatVector, a estrutura nativa utilizada pelo 'terra'.

niteroi_mapbiomas <- niteroi |>
  st_transform(
    crs = crs(mapbiomas_bruto) # st_transform(): converte o CRS do 'sf' para o mesmo CRS do raster.
  ) |>
  vect() # vect(): converte o objeto 'sf' para a classe 'SpatVector'.


#---------------------------------------------------------------------------------------#
# 6.3 RECORTAR E MASCARAR O RASTER
#---------------------------------------------------------------------------------------#
# crop(): realiza o corte retangular baseado no envelope (Bounding Box) do vetor.
# mask(): transforma em NA (nulo) todas as células localizadas fora do limite do polígono.

mapbiomas_niteroi <- crop(
  x = mapbiomas_bruto,  # Raster bruto de entrada.
  y = niteroi_mapbiomas # Limite vetorial de Niterói (SpatVector).
) |>
  mask(
    mask = niteroi_mapbiomas # Mantém somente os pixels dentro do contorno real do município.
  )


# Conferir o resultado do recorte no console
mapbiomas_niteroi


#---------------------------------------------------------------------------------------#
# 6.4 FREQUÊNCIA DE CÉLULAS POR CLASSE
#---------------------------------------------------------------------------------------#

# freq(): conta quantas células/pixels existem para cada código numérico no raster recortado.
frequencia_mapbiomas <- freq(
  x = mapbiomas_niteroi # Retorna tabela com as colunas: 'layer', 'value' (código) e 'count' (pixels).
)

frequencia_mapbiomas # Exibe a contagem de células por código de classe.

# NOTA: A coluna 'count' representa a quantidade de células, não a área em km².


#---------------------------------------------------------------------------------------#
# 6.5 FILTRAGEM E ASSOCIAÇÃO DA LEGENDA DO MAPBIOMAS
#---------------------------------------------------------------------------------------#
# Importamos o arquivo CSV de referência da oficina e mantemos APENAS os códigos
# que realmente aparecem dentro do município de Niterói.

legenda_mapbiomas <- read_csv(
  file = arquivo_legenda_mapbiomas,
  show_col_types = FALSE
)

# AJUSTE DO MATERIAL DISTRIBUÍDO:
# O CSV desta oficina veio sem o código 33, presente no raster de Niterói.
# Acrescentamos essa classe caso esteja faltando, sem modificar o arquivo CSV original no disco.
if (!33 %in% legenda_mapbiomas$class_id) {
  legenda_mapbiomas <- add_row(
    legenda_mapbiomas,
    class_id = 33,
    class_name_pt_br = "Rio, Lago e Oceano",
    class_name_en = "River, Lake and Ocean",
    hex_code = "#2532e4"
  )
}

# CHECAGEM PREVENTIVA: Conferir se todos os códigos do raster possuem correspondência na tabela.
# Esperamos a resposta TRUE. Se aparecer FALSE, revise a legenda antes de continuar.
all(frequencia_mapbiomas$value %in% legenda_mapbiomas$class_id)

classes_niteroi <- legenda_mapbiomas |>
  filter(
    class_id %in% frequencia_mapbiomas$value # Mantém apenas as linhas cujos códigos existem em Niterói.
  ) |>
  transmute(
    codigo = class_id,         # Renomeia a coluna do ID numérico.
    classe = class_name_pt_br, # Renomeia o nome da classe em português.
    cor = hex_code             # Renomeia o código Hexadecimal da cor oficial.
  ) |>
  arrange(
    codigo # Ordena a tabela em ordem crescente pelo código numérico.
  )


# Conferir as classes filtradas presentes em Niterói
classes_niteroi


#---------------------------------------------------------------------------------------#
# 6.6 ATRIBUIÇÃO DAS CATEGORIAS AO RASTER
#---------------------------------------------------------------------------------------#

# Criamos uma cópia para preservar o raster recortado original
mapbiomas_niteroi_cat <- mapbiomas_niteroi


# levels(): atribui a tabela de categorias ao raster, associando cada ID ao seu nome.
# Isso transforma a matriz numérica em um SpatRaster Categórico (fator).
levels(mapbiomas_niteroi_cat) <- data.frame(
  id = classes_niteroi$codigo,   # Vetor com os códigos numéricos dos pixels.
  classe = classes_niteroi$classe # Vetor com os nomes textuais das categorias.
)


# Conferir as categorias associadas ao raster
levels(
  mapbiomas_niteroi_cat
)


#---------------------------------------------------------------------------------------#
# 6.7 VISUALIZAÇÃO DO RASTER CATEGÓRICO
#---------------------------------------------------------------------------------------#

# DICA: Se o painel 'Plots' estiver pequeno, amplie-o em 'Zoom' para ler a legenda com clareza.

# 1. Desenha a matriz raster categórica
plot(
  x = mapbiomas_niteroi_cat,
  col = classes_niteroi$cor, # Aplica a paleta Hexadecimal filtrada especificamente para Niterói.
  all_levels = FALSE,        # Oculta da legenda as classes que não existem no raster recortado.
  main = "Uso e Cobertura da Terra em Niterói — 2025",
  plg = list(
    cex = 0.85,              # Ajusta a dimensão da fonte do texto na legenda.
    title = "Uso e cobertura",# Título no topo da caixa da legenda.
    bty = "n"                # Remove a caixa delimitadora da legenda para evitar sobreposição.
  )
)

# 2. Acrescenta o limite vetorial do município por cima do raster
plot(
  x = niteroi_mapbiomas,
  add = TRUE,         # Sobrepõe o vetor na figura já existente sem apagar o raster.
  col = NA,           # Mantém o interior transparente para não cobrir a imagem do raster.
  border = "#2F2F30", # Linha de contorno em cinza-escuro.
  lwd = 1.5           # Espessura do contorno.
)


# ❓ PERGUNTA PARA A TURMA:
# Um mapa de uso e cobertura da terra de apenas um ano (ex: 2025) permite afirmar que
# houve desmatamento ou crescimento urbano recente em Niterói?
# -> RESPOSTA: NÃO. Um mapa estático é apenas um "retrato" do momento.
# -> Para analisar transições temporais, precisamos comparar mapas de dois ou mais anos!


#=======================================================================================#
# 7. RASTER CONTÍNUO — ELEVAÇÃO (MODELO DIGITAL DE ELEVAÇÃO - MDE)
#=======================================================================================#
# CONCEITO CARTOGRÁFICO: Raster Contínuo (Quantitativo).
# -> Os valores dos pixels representam uma MEDIÇÃO FÍSICA REAL e contínua da superfície.
# -> Ao contrário do MapBiomas (cujas médias não fazem sentido), no MDE podemos calcular:
#    Altitude Mínima, Altitude Máxima, Média e Declividade.


#---------------------------------------------------------------------------------------#
# 7.1 IMPORTAÇÃO E INSPEÇÃO DO MDE BRUTO
#---------------------------------------------------------------------------------------#

# rast(): importa a matriz do Modelo Digital de Elevação (SRTM/GeoTIFF).
mde_bruto <- rast(
  x = arquivo_mde # x: caminho do arquivo GeoTIFF do MDE no computador.
)


# Inspeção de metadados do MDE
mde_bruto # Exibe no console dimensões, extensão e intervalo de altitudes.

crs(
  x = mde_bruto # crs(): consulta a projeção geográfica e o datum do MDE.
)

res(
  x = mde_bruto # res(): exibe a resolução espacial (tamanho do pixel).
)


#---------------------------------------------------------------------------------------#
# 7.2 PREPARAR O LIMITE DE NITERÓI (COMPATIBILIZAÇÃO ESPACIAL)
#---------------------------------------------------------------------------------------#
# Reprojeta e converte o limite de Niterói para garantir que o vetor cortador
# esteja exatamente no mesmo SRC e no formato 'SpatVector' do pacote 'terra'.

niteroi_mde_crs <- niteroi |>
  st_transform(
    crs = st_crs(crs(mde_bruto)) # st_transform(): padroniza o CRS com o MDE.
  )

niteroi_mde_vect <- vect(
  x = niteroi_mde_crs # vect(): converte o 'sf' em 'SpatVector'.
)


#---------------------------------------------------------------------------------------#
# 7.3 RECORTAR E MASCARAR O MDE
#---------------------------------------------------------------------------------------#
# crop(): realiza o corte retangular de enquadramento.
# mask(): isola apenas as células contidas dentro do polígono oficial do município.

mde_niteroi <- crop(
  x = mde_bruto,        # Raster MDE de entrada.
  y = niteroi_mde_vect # Limite de Niterói (SpatVector).
) |>
  mask(
    mask = niteroi_mde_vect # Mantém os pixels apenas no interior do contorno.
  )


# Inspeção das estatísticas descritivas do MDE recortado
# Como é um raster contínuo, as funções summary() e minmax() extraem a amplitude altimétrica!
minmax(mde_niteroi) # Exibe a menor (mínima) e a maior (máxima) altitude em metros de Niterói.


#---------------------------------------------------------------------------------------#
# 7.4 VISUALIZAÇÃO DA ELEVAÇÃO
#---------------------------------------------------------------------------------------#

# 1. Desenha a matriz altimétrica contínua
plot(
  x = mde_niteroi,
  col = hcl.colors(      # hcl.colors(): gera um gradiente suave de cores perceptualmente ajustado.
    n = 25,              # n = 25: número de tons no gradiente para um efeito de relevo fluido.
    palette = "Terrain 2"# palette = "Terrain 2": paleta hipsométrica (do verde ao marrom e branco).
  ),
  main = "Elevação em Niterói (Metros)", # Título do mapa.
  plg = list(
    title = "Altitude (m)",              # Título no topo da barra de rampa de cor.
    bty = "n"                            # Remove caixa delimitadora da legenda.
  )
)

# 2. Acrescenta o limite municipal por cima do MDE
plot(
  x = niteroi_mde_vect,
  add = TRUE,         # add = TRUE: sobrepõe o vetor sem apagar a imagem do MDE.
  col = NA,           # Mantém o interior transparente.
  border = "#35483C", # Linha de contorno em verde-escuro hipsométrico.
  lwd = 2             # Espessura da borda.
)


#=======================================================================================#
# 8. DERIVAÇÃO DO RELEVO: DO MDE À DECLIVIDADE (SLOPE)
#=======================================================================================#
# CONCEITO: Produtos Derivados do MDE.
# -> A Declividade (Slope) representa o ângulo de inclinação do terreno em relação ao plano horizontal.
# -> É calculada analisando a diferença de altitude entre um pixel e a sua vizinhança.


# DEMONSTRAÇÃO CONCEITUAL: CÁLCULO DA DECLIVIDADE EM GRAUS
# Fórmula trigonométrica simples: $\text{Ângulo} = \arctan\left(\frac{\text{cateto oposto}}{\text{cateto adjacente}}\right) \times \frac{180}{\pi}$
# Exemplo: subir 10 metros na vertical ao longo de 100 metros na horizontal:

exemplo_declividade_graus <- atan(10 / 100) * 180 / pi
exemplo_declividade_graus # Retorna aproximadamente 5.71 graus de inclinação.


#---------------------------------------------------------------------------------------#
# 8.1 CÁLCULO DA DECLIVIDADE NO RASTER COM A FUNÇÃO terrain()
#---------------------------------------------------------------------------------------#
# terrain(): calcula atributos topográficos (declividade, aspecto, etc.) a partir da vizinhança do pixel.

declividade_niteroi <- terrain(
  x = mde_niteroi,    # Raster de entrada com dados de altitude (MDE).
  v = "slope",        # v = "slope": especifica que o atributo derivado a calcular é a Declividade.
  neighbors = 8,      # neighbors = 8: considera as 8 células vizinhas ao redor de cada pixel (matriz 3x3).
  unit = "degrees"    # unit = "degrees": devolve o valor do ângulo de inclinação em Graus (0° a 90°).
)

# Conferir o raster de declividade gerado
declividade_niteroi


#---------------------------------------------------------------------------------------#
# 8.2 VISUALIZAÇÃO DA DECLIVIDADE
#---------------------------------------------------------------------------------------#

# 1. Desenha a matriz de declividade derivada
plot(
  x = declividade_niteroi,
  col = hcl.colors(
    n = 25, 
    palette = "YlOrRd" # Palette "YlOrRd" (Yellow-Orange-Red): do amarelo (plano) ao vermelho (escarpas).
  ),
  main = "Declividade em Niterói (Graus)",
  plg = list(
    title = "Inclinação (°)",
    bty = "n"
  )
)

# 2. Acrescenta o limite municipal por cima do mapa de declividade
plot(
  x = niteroi_mde_vect,
  add = TRUE,
  col = NA,
  border = "#2F2F30",
  lwd = 1.5
)


#=======================================================================================#
# 9. ÁLGEBRA RASTER — ÍNDICE DE VEGETAÇÃO POR DIFERENÇA NORMALIZADA (NDVI)
#=======================================================================================#
# CONCEITO CARTOGRÁFICO: Álgebra de Mapas e Índices Espectrais.
# -> O NDVI mede a resposta espectral da superfície combinando duas bandas das imagens de satélite:
#    - B04: Vermelho (RED) -> Absorvido pela clorofila da vegetação ativa.
#    - B08: Infravermelho Próximo (NIR) -> Refletido pela estrutura celular interna das folhas.
#
# FÓRMULA MATEMÁTICA DO NDVI:
#
#          NIR - RED
#  NDVI = -----------
#          NIR + RED
#
# O resultado varia estritamente entre -1 e +1:
# -> Valores próximos a +1: Vegetação densa e saudável (alto vigor vegetativo).
# -> Valores próximos a 0: Solo exposto, rocha ou áreas urbanizadas.
# -> Valores negativos (próximos a -1): Corpos d'água (absorvem NIR e refletem visível).


#---------------------------------------------------------------------------------------#
# 9.1 DEMONSTRAÇÃO CONCEITUAL EM UMA CÉLULA
#---------------------------------------------------------------------------------------#

red_exemplo <- 0.12 # Reflectância no Vermelho (12%)
nir_exemplo <- 0.48 # Reflectância no Infravermelho Próximo (48%)

# Aplicação da fórmula normalizada na célula de teste:
ndvi_exemplo <- (nir_exemplo - red_exemplo) / (nir_exemplo + red_exemplo)
ndvi_exemplo # Retorna 0.60 (Indica presença de vegetação moderadamente densa/saudável).


#---------------------------------------------------------------------------------------#
# 9.2 IMPORTAÇÃO DAS BANDAS DO SENTINEL-2
#---------------------------------------------------------------------------------------#

# B04: Banda do Vermelho (Red - 10 metros de resolução espacial)
vermelho_entorno <- rast(
  x = arquivo_b04
)

# B08: Banda do Infravermelho Próximo (NIR - 10 metros de resolução espacial)
nir_entorno <- rast(
  x = arquivo_b08
)


#---------------------------------------------------------------------------------------#
# 9.3 VERIFICAÇÃO DE ALINHAMENTO GEOMÉTRICO DAS BANDAS
#---------------------------------------------------------------------------------------#
# REGRA DA ÁLGEBRA RASTER: Para operar pixels entre duas matrizes, elas precisam ter RIGOROSAMENTE:
# mesmo CRS, mesma resolução, mesma extensão e o mesmo alinhamento de grade!

# compareGeom(): compara a geometria de dois rasters e confirma a compatibilidade.
bandas_alinhadas <- compareGeom(
  x = vermelho_entorno,
  y = nir_entorno,
  stopOnError = FALSE # stopOnError = FALSE: devolve TRUE/FALSE em vez de travar o script com erro.
)

bandas_alinhadas # Esperamos a resposta TRUE para prosseguir com a álgebra de mapas.


#---------------------------------------------------------------------------------------#
# 9.4 PREPARAR O LIMITE DE NITERÓI E RECORTAR AS BANDAS
#---------------------------------------------------------------------------------------#

# 1. Reprojeção e conversão do vetor de Niterói para o CRS das imagens Sentinel-2
niteroi_sentinel_crs <- niteroi |>
  st_transform(
    crs = st_crs(crs(vermelho_entorno))
  )

niteroi_sentinel_vect <- vect(
  x = niteroi_sentinel_crs
)


# 2. Recorte e máscara da Banda 04 (Vermelho) para o município
vermelho_niteroi <- crop(
  x = vermelho_entorno,
  y = niteroi_sentinel_vect
) |>
  mask(
    mask = niteroi_sentinel_vect
  )


# 3. Recorte e máscara da Banda 08 (NIR) para o município
nir_niteroi <- crop(
  x = nir_entorno,
  y = niteroi_sentinel_vect
) |>
  mask(
    mask = niteroi_sentinel_vect
  )


# Re-conferir alinhamento das bandas após o recorte municipal
compareGeom(
  x = vermelho_niteroi,
  y = nir_niteroi,
  stopOnError = FALSE
)


#---------------------------------------------------------------------------------------#
# 9.5 ÁLGEBRA RASTER PASSO A PASSO
#---------------------------------------------------------------------------------------#

# 1. Numerador: Diferença entre NIR e RED
diferenca_nir_red <- nir_niteroi - vermelho_niteroi

# 2. Denominador: Soma entre NIR e RED
soma_nir_red <- nir_niteroi + vermelho_niteroi

# 3. Divisão Normalizada com tratamento de exceção (Divisão por Zero)
# ifel(): função condicional vetorizada do 'terra' (equivalente ao ifelse do R base).
# Se a soma for igual a 0, atribui NA (valor nulo); caso contrário, realiza a divisão.
ndvi_niteroi <- ifel(
  test = soma_nir_red == 0,
  yes = NA,
  no = diferenca_nir_red / soma_nir_red
)


#---------------------------------------------------------------------------------------#
# 9.6 VISUALIZAÇÃO E PALETA TEMÁTICA DO NDVI (OPÇÃO 1 - PADRÃO CARTOGRÁFICO)
#---------------------------------------------------------------------------------------#

paleta_ndvi <- colorRampPalette(
  colors = c(
    "#000080", # Azul marinho: Corpos d'água (NDVI negativo)
    "#D2B48C", # Bege/Castanho: Solo exposto e áreas urbanas (NDVI próximo de 0)
    "#FFFF00", # Amarelo: Vegetação rasteira/esparsa ou estressada (NDVI baixo/médio)
    "#00FF00", # Verde claro: Vegetação em crescimento / Gramados (NDVI médio)
    "#006400"  # Verde escuro: Floresta densa / Mata Atlântica (NDVI elevado)
  )
)

# Plota com a nova rampa:
plot(
  x = ndvi_niteroi,
  col = paleta_ndvi(100), # Rampa com 100 variações suaves
  range = c(-1, 1),       # Escala teórica do NDVI [-1, +1]
  main = "Índice de Vegetação (NDVI) em Niterói — Sentinel-2",
  plg = list(
    title = "NDVI",
    bty = "n"
  )
)

# Borda do município por cima:
plot(
  x = niteroi_sentinel_vect,
  add = TRUE,
  col = NA,
  border = "#2F2F30",
  lwd = 1.3
)

#---------------------------------------------------------------------------------------#
# RECAPITULAÇÃO FINAL DOS PRODUTOS RASTER PROCESSADOS:
#
# 1. MAPBIOMAS   -> Raster Categórico (Códigos numéricos = etiquetas de uso do solo).
# 2. ELEVAÇÃO    -> Raster Contínuo (Medição direta de altitude em metros).
# 3. DECLIVIDADE -> Raster Contínuo Derivado (Cálculo de inclinação do relevo a partir do MDE).
# 4. NDVI        -> Raster Contínuo Produzido (Combinação matemática/álgebra de 2 bandas).
#---------------------------------------------------------------------------------------#


#=======================================================================================#
# 10. FECHAMENTO E DIRETRIZES DE ANÁLISE CRÍTICA
#=======================================================================================#

# Antes de interpretar ou tomar decisões com qualquer dado raster, verifique:
#
# 1. O que cada célula/pixel representa conceitualmente?
# 2. Qual é o Sistema de Referência de Coordenadas (SRC/CRS) e se está em metros ou graus?
# 3. Qual é a resolução espacial (tamanho da célula)?
# 4. O dado é CATEGÓRICO (discreto) ou CONTÍNUO (numérico)?
# 5. Qual estatística espacial faz sentido aplicar (frequência/área vs. média/amplitude)?
# 6. Qual é a fonte primária do dado e a data de aquisição?
# 7. Quais são as limitações metodológicas e de escala da representação?


#=======================================================================================#
# DESAFIO DE CONSOLIDAÇÃO (PARA COMPLETAR EM AULA OU DEPOIS)
#=======================================================================================#
#
# Escolha UM dos 6 produtos desenvolvidos durante a oficina:
# - mapa_area_bairros
# - mapa_escolas_niteroi
# - mapbiomas_niteroi_cat
# - mde_niteroi
# - declividade_niteroi
# - ndvi_niteroi
#
# E responda no seu caderno ou script:
#
# 1. O que esse produto representa geometricamente e tematicamente?
# _______________________________________________________________________________________
#
# 2. Que tipo de conclusão ele NÃO permite fazer isoladamente?
# _______________________________________________________________________________________
#
# 3. Que alteração de paleta, borda ou escala visual você faria para um público leigo?
# _______________________________________________________________________________________
#
# 4. Que nova pergunta ou hipótese espacial você formularia a partir dele?
# _______________________________________________________________________________________


#=======================================================================================#
# QUERO MAIS! — PRÓXIMOS PASSOS NO R
#=======================================================================================#
#
# Parabéns! Você concluiu a estrutura completa de processamento vetorial e matricial.
# Este script foi pensado como um "guia de consulta / cheat sheet" para os seus projetos.
# Continue praticando com novos municípios e produtos da comunidade R-Ladies!
#
#=======================================================================================#
# FIM DO SCRIPT
#=======================================================================================#

