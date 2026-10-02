# ============================================================
# BÔNUS — MAPA DE LOCALIZAÇÃO PARA TRABALHOS FUTUROS
# Minicurso: Trabalhando com dados geoespaciais no R
# MATERIAL COMPLEMENTAR PARA AS PARTICIPANTES
#
# Autoria: Cássia Fernanda Martins da Silva
# Ecóloga e analista de dados geoespaciais
# Ciência aberta | R | QGIS | fluxos reprodutíveis
# R-Ladies Niterói | 2026
# ============================================================

# Este material foi elaborado com muito carinho para as alunas e
# participantes do R-Ladies Niterói <3
#
# A ideia é que vocês tenham um MODELO COMPLETO de mapa de localização
# para adaptar depois em trabalhos acadêmicos, relatórios, TCCs,
# dissertações, teses, artigos, apresentações e projetos profissionais.
#
# ESTE SCRIPT É MATERIAL COMPLEMENTAR.
# Ele NÃO é necessário para acompanhar o minicurso.
#
# Durante a aula construímos a lógica essencial do mapa. Aqui vamos um
# passo além e trabalhamos também com:
#
# - download e preparação das malhas do IBGE;
# - controle fino da extensão espacial (bbox);
# - projeções diferentes para escalas diferentes;
# - rótulos e elementos cartográficos;
# - mapa principal + mapas localizadores;
# - painel de legenda, fonte e autoria;
# - composição editorial com cowplot;
# - exportação em alta resolução.
#
# O objetivo não é decorar este script. É rodá-lo com calma, entender
# a lógica e reutilizar sua estrutura em trabalhos futuros.
#
# DADOS: IBGE — Malhas Territoriais 2022
# MAPA PRINCIPAL/RJ: SIRGAS 2000 / UTM 23S — EPSG:31983
# BRASIL: SIRGAS 2000 / Brazil Polyconic — EPSG:5880
# ======================================================================


# ======================================================================
# ETAPA 0 - PACOTES
# ======================================================================

# sf        -> operações vetoriais e sistemas de referência
# dplyr     -> filtros e organização de atributos
# ggplot2   -> construção dos mapas
# ggspatial -> escala gráfica
# cowplot   -> composição final dos painéis
# grid      -> unidades gráficas, setas e objetos auxiliares

pacotes <- c(
  "sf",
  "dplyr",
  "ggplot2",
  "ggspatial",
  "cowplot",
  "grid"
)

# Identificar somente os pacotes que ainda não estão instalados.
instalar <- pacotes[!pacotes %in% rownames(installed.packages())]

# length() informa quantos elementos existem no objeto.
# Se houver pelo menos um pacote faltando, instalamos apenas esses.
if (length(instalar) > 0) {
  install.packages(instalar)
}

# lapply() aplica library() a cada nome guardado no vetor pacotes.
# character.only = TRUE indica que os nomes estão armazenados como texto.
invisible(
  lapply(
    pacotes,
    library,
    character.only = TRUE
  )
)


# ======================================================================
# ETAPA 1 - PASTAS
# ======================================================================

# dir.create() cria pastas.
# recursive = TRUE permite criar também pastas anteriores do caminho.
# showWarnings = FALSE evita avisos caso a pasta já exista.

dir.create(
  "dados/brutos/ibge_2022",
  recursive = TRUE,
  showWarnings = FALSE
)

dir.create(
  "figuras",
  recursive = TRUE,
  showWarnings = FALSE
)


# ======================================================================
# ETAPA 2 - PALETA E TIPOGRAFIA
# ======================================================================

# A paleta abaixo foi baseada na identidade visual RLadies+.
# Em outro projeto, esta é uma das partes mais fáceis de adaptar.

cor_fundo       <- "#EDEDF4"
cor_titulo      <- "#2F2F30"
cor_subtitulo   <- "#2F2F30"
cor_texto       <- "#2F2F30"

cor_barra       <- "#881EF9"
cor_barra_txt   <- "#EDEDF4"

cor_terra       <- "#F6F6FA"
cor_terra2      <- "#EFEFF6"
cor_agua        <- "#E9F1FF"

cor_niteroi     <- "#881EF9"
cor_niteroi_brd <- "#5E16AC"

cor_limite      <- "#B9B9C7"
cor_limite2     <- "#8C8C97"
cor_borda       <- "#B6B6C2"

cor_agua_rotulo <- "#146AF9"
cor_divisoria   <- "#FF5B92"

# Arial foi mantida por portabilidade.
# Se Poppins estiver instalada, você pode testar fonte_mapa <- "Poppins".
fonte_mapa <- "Arial"


# ======================================================================
# ETAPA 3 - ENDEREÇOS DOS DADOS DO IBGE
# ======================================================================

# Este bônus é independente do fluxo principal da aula e, por isso,
# registra também uma forma completa de aquisição dos dados.

protocolo <- "https://"
servidor  <- "geoftp.ibge.gov.br"

caminho_ibge <- paste0(
  "/organizacao_do_territorio/",
  "malhas_territoriais/",
  "malhas_municipais/",
  "municipio_2022/"
)

url_base <- paste0(
  protocolo,
  servidor,
  caminho_ibge
)

url_rj_municipios <- paste0(
  url_base,
  "UFs/RJ/",
  "RJ_Municipios_2022.zip"
)

url_br_uf <- paste0(
  url_base,
  "Brasil/BR/",
  "BR_UF_2022.zip"
)


# ======================================================================
# ETAPA 4 - FUNÇÃO PARA DOWNLOAD E LEITURA
# ======================================================================

# Esta função evita repetir a mesma sequência para cada base:
# criar pasta -> baixar ZIP -> descompactar -> localizar .shp -> st_read().

baixar_ibge <- function(url, pasta, nome_zip) {

  dir.create(
    pasta,
    recursive = TRUE,
    showWarnings = FALSE
  )

  # file.path() monta um caminho de arquivo respeitando o sistema.
  arquivo_zip <- file.path(
    pasta,
    nome_zip
  )

  # Se o ZIP ainda não existe, fazemos o download.
  if (!file.exists(arquivo_zip)) {

    message("Baixando: ", nome_zip)

    # mode = "wb" -> modo binário, apropriado para ZIP.
    download.file(
      url = url,
      destfile = arquivo_zip,
      mode = "wb",
      quiet = FALSE
    )

  } else {

    message("Arquivo já existente: ", nome_zip)

  }

  # Procurar Shapefiles já existentes na pasta.
  shp <- list.files(
    pasta,
    pattern = "\\.shp$",
    full.names = TRUE,
    recursive = TRUE
  )

  # Se não encontramos .shp, descompactamos o ZIP.
  if (length(shp) == 0) {

    unzip(
      arquivo_zip,
      exdir = pasta
    )

    shp <- list.files(
      pasta,
      pattern = "\\.shp$",
      full.names = TRUE,
      recursive = TRUE
    )
  }

  # stop() encerra a execução com uma mensagem clara.
  if (length(shp) == 0) {
    stop("Nenhum shapefile encontrado em: ", pasta)
  }

  # A última expressão da função será devolvida como resultado.
  sf::st_read(
    shp[1],
    quiet = TRUE
  )
}


# ======================================================================
# ETAPA 5 - DOWNLOAD DAS MALHAS
# ======================================================================

rj_municipios <- baixar_ibge(
  url = url_rj_municipios,
  pasta = "dados/brutos/ibge_2022/rj_municipios",
  nome_zip = "RJ_Municipios_2022.zip"
)

br_uf <- baixar_ibge(
  url = url_br_uf,
  pasta = "dados/brutos/ibge_2022/br_uf",
  nome_zip = "BR_UF_2022.zip"
)


# ======================================================================
# ETAPA 6 - VALIDAÇÃO E PREPARO
# ======================================================================

# st_make_valid() tenta corrigir geometrias inválidas antes de operações
# como interseção, recorte e união.

rj_municipios <- rj_municipios |>
  sf::st_make_valid()

br_uf <- br_uf |>
  sf::st_make_valid()

# Selecionar Niterói pelo código IBGE.
niteroi <- rj_municipios |>
  dplyr::filter(
    CD_MUN == "3303302"
  )

if (nrow(niteroi) == 0) {
  stop("Niterói não encontrado na malha do IBGE.")
}

# Definir sistemas de referência.
crs_rj     <- 31983
crs_brasil <- 5880

# st_transform() transforma as coordenadas para outro SRC.
# UTM é usada nos mapas local/regional; Brazil Polyconic no mapa nacional.
rj_utm <- rj_municipios |>
  sf::st_transform(crs_rj)

niteroi_utm <- niteroi |>
  sf::st_transform(crs_rj)

br_utm <- br_uf |>
  sf::st_transform(crs_rj)

br_poly <- br_uf |>
  sf::st_transform(crs_brasil)


# ======================================================================
# ETAPA 7 - FUNÇÕES DE APOIO PARA BBOX
# ======================================================================

# st_bbox() devolve xmin, ymin, xmax e ymax.
# Para uma figura editorial, precisamos controlar esses valores com mais
# cuidado do que em um mapa exploratório simples.

bbox_seguro <- function(xmin, ymin, xmax, ymax, crs_obj) {

  valores <- c(
    xmin = as.numeric(xmin),
    ymin = as.numeric(ymin),
    xmax = as.numeric(xmax),
    ymax = as.numeric(ymax)
  )

  # is.finite() identifica valores válidos; any() verifica se há algum erro.
  if (any(!is.finite(valores))) {
    stop(
      paste0(
        "Não foi possível construir a extensão cartográfica: ",
        "há coordenadas NA/NaN/Inf no bbox."
      )
    )
  }

  sf::st_bbox(
    valores,
    crs = crs_obj
  )
}


# ajustar_bbox() controla a razão largura/altura da janela do mapa.
# Isso ajuda a evitar painéis espremidos ou com áreas vazias excessivas.
ajustar_bbox <- function(
  bbox,
  ratio = 1.55,
  crs_obj = sf::st_crs(crs_rj)
) {

  xmin <- as.numeric(bbox["xmin"])
  xmax <- as.numeric(bbox["xmax"])
  ymin <- as.numeric(bbox["ymin"])
  ymax <- as.numeric(bbox["ymax"])

  valores_bbox <- c(xmin, ymin, xmax, ymax)

  if (any(!is.finite(valores_bbox))) {
    stop(
      paste0(
        "O bbox recebido por ajustar_bbox() contém valores ausentes. ",
        "Verifique a construção da extensão espacial."
      )
    )
  }

  largura <- xmax - xmin
  altura  <- ymax - ymin

  if (!is.finite(ratio) || ratio <= 0) {
    stop("O argumento 'ratio' deve ser um número positivo.")
  }

  if (largura <= 0 || altura <= 0) {
    stop("A extensão do bbox é inválida: largura ou altura <= 0.")
  }

  centro_x <- (xmin + xmax) / 2
  centro_y <- (ymin + ymax) / 2

  ratio_atual <- largura / altura

  # Se a janela estiver estreita demais, aumentamos a largura.
  if (ratio_atual < ratio) {

    nova_largura <- altura * ratio
    xmin <- centro_x - nova_largura / 2
    xmax <- centro_x + nova_largura / 2

  } else {

    # Caso contrário, aumentamos a altura.
    nova_altura <- largura / ratio
    ymin <- centro_y - nova_altura / 2
    ymax <- centro_y + nova_altura / 2

  }

  bbox_seguro(
    xmin = xmin,
    ymin = ymin,
    xmax = xmax,
    ymax = ymax,
    crs_obj = crs_obj
  )
}


# ======================================================================
# ETAPA 8 - EXTENSÃO DO MAPA PRINCIPAL
# ======================================================================

bb_nit <- sf::st_bbox(niteroi_utm)

# Ampliamos Niterói de forma assimétrica para mostrar o contexto desejado.
# Esses números são decisões cartográficas/editoriais e podem ser ajustados.
bbox_main <- bbox_seguro(
  xmin = bb_nit["xmin"] - 14000,
  ymin = bb_nit["ymin"] - 5500,
  xmax = bb_nit["xmax"] + 13000,
  ymax = bb_nit["ymax"] + 12500,
  crs_obj = sf::st_crs(crs_rj)
)

bbox_main <- ajustar_bbox(
  bbox_main,
  ratio = 1.23,
  crs_obj = sf::st_crs(crs_rj)
)

# st_crop() limita a geometria à janela que será mostrada.
rj_main <- sf::st_crop(
  rj_utm,
  bbox_main
)

# Coordenadas do indicador norte minimalista.
north_x  <- as.numeric(bbox_main["xmax"]) - 2300
north_y1 <- as.numeric(bbox_main["ymax"]) - 2700
north_y0 <- north_y1 - 1700
north_yn <- north_y1 + 850


# ======================================================================
# ETAPA 9 - RÓTULOS
# ======================================================================

municipios_rotulo <- c(
  "Rio de Janeiro",
  "São Gonçalo",
  "Itaboraí",
  "Maricá"
)

# Converter bbox para geometria para usá-lo em st_intersection().
bbox_main_sf <- sf::st_as_sfc(
  bbox_main
)

# Filtrar municípios, limitar ao recorte visível e encontrar posições
# adequadas para os rótulos.
rotulos_vizinhos <- rj_utm |>
  dplyr::filter(
    NM_MUN %in% municipios_rotulo
  ) |>
  sf::st_intersection(
    bbox_main_sf
  ) |>
  dplyr::group_by(
    NM_MUN
  ) |>
  dplyr::summarise(
    geometry = sf::st_union(geometry),
    .groups = "drop"
  ) |>
  sf::st_point_on_surface()

rotulos_vizinhos_df <- cbind(
  sf::st_drop_geometry(rotulos_vizinhos),
  sf::st_coordinates(rotulos_vizinhos)
)

# Posição do texto de Niterói.
rotulo_niteroi <- niteroi_utm |>
  sf::st_union() |>
  sf::st_point_on_surface()

xy_niteroi <- sf::st_coordinates(rotulo_niteroi)

# Rótulos de água definidos manualmente.
rotulos_agua <- data.frame(
  nome = c(
    "Baía de\nGuanabara",
    "Oceano Atlântico"
  ),
  lon = c(
    -43.175,
    -43.015
  ),
  lat = c(
    -22.812,
    -22.995
  )
)

rotulos_agua_sf <- rotulos_agua |>
  sf::st_as_sf(
    coords = c("lon", "lat"),
    crs = 4674
  ) |>
  sf::st_transform(crs_rj)

rotulos_agua_df <- cbind(
  rotulos_agua,
  sf::st_coordinates(rotulos_agua_sf)
)


# ======================================================================
# ETAPA 10 - TEMAS DOS MAPAS
# ======================================================================

# theme_void() remove eixos e grades, criando uma base limpa.
tema_mapa_principal <- ggplot2::theme_void(
  base_family = fonte_mapa
) +
  ggplot2::theme(
    plot.background = ggplot2::element_rect(
      fill = "white",
      colour = NA
    ),
    panel.background = ggplot2::element_rect(
      fill = cor_agua,
      colour = cor_borda,
      linewidth = 0.30
    ),
    panel.border = ggplot2::element_rect(
      fill = NA,
      colour = cor_borda,
      linewidth = 0.30
    ),
    plot.margin = ggplot2::margin(0, 0, 0, 0),
    legend.position = "none"
  )

# Nos localizadores retiramos a moldura interna para evitar um quadro
# visualmente pesado dentro do card externo.
tema_mapa_inset <- ggplot2::theme_void(
  base_family = fonte_mapa
) +
  ggplot2::theme(
    plot.background = ggplot2::element_rect(
      fill = "white",
      colour = NA
    ),
    panel.background = ggplot2::element_rect(
      fill = cor_agua,
      colour = NA
    ),
    panel.border = ggplot2::element_blank(),
    plot.margin = ggplot2::margin(0, 0, 0, 0),
    legend.position = "none"
  )


# ======================================================================
# ETAPA 11 - MAPA PRINCIPAL
# ======================================================================

mapa_principal <- ggplot2::ggplot() +

  # Municípios do entorno.
  ggplot2::geom_sf(
    data = rj_main,
    fill = cor_terra,
    colour = cor_limite,
    linewidth = 0.35
  ) +

  # Área de estudo.
  ggplot2::geom_sf(
    data = niteroi_utm,
    fill = cor_niteroi,
    colour = cor_niteroi_brd,
    linewidth = 0.75
  ) +

  # Rótulos dos municípios vizinhos.
  ggplot2::geom_text(
    data = rotulos_vizinhos_df,
    ggplot2::aes(
      x = X,
      y = Y,
      label = NM_MUN
    ),
    family = fonte_mapa,
    colour = cor_texto,
    size = 2.60
  ) +

  # Nome de Niterói.
  ggplot2::annotate(
    "text",
    x = xy_niteroi[1, 1],
    y = xy_niteroi[1, 2],
    label = "Niterói",
    family = fonte_mapa,
    fontface = "bold",
    colour = "white",
    size = 3.40
  ) +

  # Rótulos da água.
  ggplot2::geom_text(
    data = rotulos_agua_df,
    ggplot2::aes(
      x = X,
      y = Y,
      label = nome
    ),
    family = fonte_mapa,
    fontface = "italic",
    colour = cor_agua_rotulo,
    size = 2.70,
    lineheight = 0.95
  ) +

  # Escala gráfica.
  ggspatial::annotation_scale(
    location = "bl",
    width_hint = 0.18,
    text_cex = 0.52,
    line_width = 0.42,
    pad_x = grid::unit(0.24, "cm"),
    pad_y = grid::unit(0.22, "cm")
  ) +

  # Indicador norte minimalista desenhado manualmente.
  ggplot2::annotate(
    "segment",
    x = north_x,
    xend = north_x,
    y = north_y0,
    yend = north_y1,
    colour = cor_texto,
    linewidth = 0.38,
    arrow = grid::arrow(
      length = grid::unit(0.10, "cm"),
      type = "closed"
    )
  ) +

  ggplot2::annotate(
    "text",
    x = north_x,
    y = north_yn,
    label = "N",
    family = fonte_mapa,
    colour = cor_texto,
    size = 2.2
  ) +

  # coord_sf() controla projeção e janela visível.
  ggplot2::coord_sf(
    crs = sf::st_crs(crs_rj),
    datum = NA,
    xlim = c(bbox_main["xmin"], bbox_main["xmax"]),
    ylim = c(bbox_main["ymin"], bbox_main["ymax"]),
    expand = FALSE
  ) +

  tema_mapa_principal


# ======================================================================
# ETAPA 12 - MAPA DO BRASIL
# ======================================================================

rj_brasil <- br_poly |>
  dplyr::filter(
    SIGLA_UF == "RJ"
  )

bb_br <- sf::st_bbox(br_poly)

largura_br <- bb_br["xmax"] - bb_br["xmin"]
altura_br  <- bb_br["ymax"] - bb_br["ymin"]

bbox_br <- bbox_seguro(
  xmin = bb_br["xmin"] - largura_br * 0.12,
  ymin = bb_br["ymin"] - altura_br * 0.03,
  xmax = bb_br["xmax"] + largura_br * 0.10,
  ymax = bb_br["ymax"] + altura_br * 0.03,
  crs_obj = sf::st_crs(crs_brasil)
)

mapa_brasil <- ggplot2::ggplot() +
  ggplot2::geom_sf(
    data = br_poly,
    fill = cor_terra2,
    colour = cor_limite,
    linewidth = 0.30
  ) +
  ggplot2::geom_sf(
    data = rj_brasil,
    fill = cor_niteroi,
    colour = cor_niteroi_brd,
    linewidth = 0.50
  ) +
  ggplot2::coord_sf(
    crs = sf::st_crs(crs_brasil),
    datum = NA,
    xlim = c(bbox_br["xmin"], bbox_br["xmax"]),
    ylim = c(bbox_br["ymin"], bbox_br["ymax"]),
    expand = FALSE
  ) +
  tema_mapa_inset


# ======================================================================
# ETAPA 13 - MAPA DO ESTADO DO RIO DE JANEIRO
# ======================================================================

estado_rj <- br_utm |>
  dplyr::filter(
    SIGLA_UF == "RJ"
  )

bb_rj <- sf::st_bbox(estado_rj)

bbox_rj <- bbox_seguro(
  xmin = bb_rj["xmin"] - 45000,
  ymin = bb_rj["ymin"] - 18000,
  xmax = bb_rj["xmax"] + 28000,
  ymax = bb_rj["ymax"] + 22000,
  crs_obj = sf::st_crs(crs_rj)
)

bbox_rj <- ajustar_bbox(
  bbox_rj,
  ratio = 1.35,
  crs_obj = sf::st_crs(crs_rj)
)

estados_contexto <- sf::st_crop(
  br_utm,
  bbox_rj
)

mapa_rj <- ggplot2::ggplot() +
  ggplot2::geom_sf(
    data = estados_contexto,
    fill = cor_terra,
    colour = cor_limite,
    linewidth = 0.35
  ) +
  ggplot2::geom_sf(
    data = rj_utm,
    fill = cor_terra2,
    colour = cor_limite,
    linewidth = 0.18
  ) +
  ggplot2::geom_sf(
    data = niteroi_utm,
    fill = cor_niteroi,
    colour = cor_niteroi_brd,
    linewidth = 0.55
  ) +
  ggplot2::coord_sf(
    crs = sf::st_crs(crs_rj),
    datum = NA,
    xlim = c(bbox_rj["xmin"], bbox_rj["xmax"]),
    ylim = c(bbox_rj["ymin"], bbox_rj["ymax"]),
    expand = FALSE
  ) +
  tema_mapa_inset


# ======================================================================
# ETAPA 14 - PAINEL DE LEGENDA, FONTE E AUTORIA
# ======================================================================

# Em vez de usar uma legenda automática, construímos um painel editorial
# com coordenadas de 0 a 100. Isso dá controle total do layout.

painel_info <- ggplot2::ggplot() +
  ggplot2::coord_cartesian(
    xlim = c(0, 100),
    ylim = c(0, 100),
    clip = "on"
  ) +

  # Fundo/moldura.
  ggplot2::annotate(
    "rect",
    xmin = 0, xmax = 100,
    ymin = 0, ymax = 100,
    fill = "white",
    colour = cor_borda,
    linewidth = 0.42
  ) +

  # Título.
  ggplot2::annotate(
    "text",
    x = 8, y = 91,
    label = "Legenda",
    hjust = 0,
    family = fonte_mapa,
    fontface = "bold",
    colour = "#1D2D35",
    size = 3.35
  ) +

  # Niterói.
  ggplot2::annotate(
    "rect",
    xmin = 8, xmax = 13,
    ymin = 79, ymax = 85,
    fill = cor_niteroi,
    colour = cor_niteroi_brd,
    linewidth = 0.32
  ) +
  ggplot2::annotate(
    "text",
    x = 17, y = 82,
    label = "Município de Niterói",
    hjust = 0,
    family = fonte_mapa,
    colour = cor_texto,
    size = 2.45
  ) +

  # Municípios do entorno.
  ggplot2::annotate(
    "rect",
    xmin = 8, xmax = 13,
    ymin = 68, ymax = 74,
    fill = cor_terra,
    colour = cor_limite,
    linewidth = 0.32
  ) +
  ggplot2::annotate(
    "text",
    x = 17, y = 71,
    label = "Municípios do entorno",
    hjust = 0,
    family = fonte_mapa,
    colour = cor_texto,
    size = 2.45
  ) +

  # Água.
  ggplot2::annotate(
    "rect",
    xmin = 8, xmax = 13,
    ymin = 57, ymax = 63,
    fill = cor_agua,
    colour = "#B6D5DF",
    linewidth = 0.32
  ) +
  ggplot2::annotate(
    "text",
    x = 17, y = 60,
    label = "Superfície aquática",
    hjust = 0,
    family = fonte_mapa,
    colour = cor_texto,
    size = 2.45
  ) +

  # Limites municipais.
  ggplot2::annotate(
    "segment",
    x = 8, xend = 13,
    y = 49, yend = 49,
    colour = cor_limite2,
    linewidth = 0.62
  ) +
  ggplot2::annotate(
    "text",
    x = 17, y = 49,
    label = "Limites municipais",
    hjust = 0,
    family = fonte_mapa,
    colour = cor_texto,
    size = 2.45
  ) +

  # Fonte de dados.
  ggplot2::annotate(
    "text",
    x = 8, y = 35,
    label = "Fonte de dados",
    hjust = 0,
    family = fonte_mapa,
    fontface = "bold",
    colour = "#1D2D35",
    size = 2.95
  ) +
  ggplot2::annotate(
    "text",
    x = 8, y = 29,
    label = paste0(
      "Limites municipais e estaduais: IBGE (2022)\n",
      "Datum: SIRGAS 2000"
    ),
    hjust = 0,
    vjust = 1,
    family = fonte_mapa,
    colour = cor_texto,
    size = 2.20,
    lineheight = 1.28
  ) +

  # Divisória.
  ggplot2::annotate(
    "segment",
    x = 8, xend = 92,
    y = 12, yend = 12,
    colour = cor_divisoria,
    linewidth = 0.42
  ) +

  # Autoria — adapte para seu trabalho.
  ggplot2::annotate(
    "text",
    x = 8, y = 6,
    label = "Autoria: Silva, 2026 · R-Ladies Niterói",
    hjust = 0,
    vjust = 0.5,
    family = fonte_mapa,
    colour = cor_texto,
    size = 2.15
  ) +

  ggplot2::theme_void() +
  ggplot2::theme(
    plot.background = ggplot2::element_rect(
      fill = "white",
      colour = NA
    ),
    plot.margin = ggplot2::margin(0, 0, 0, 0)
  )


# ======================================================================
# ETAPA 15 - FUNÇÕES AUXILIARES PARA A COMPOSIÇÃO
# ======================================================================

# card_fundo() cria o fundo/moldura dos cards.
card_fundo <- function(fill = "white", border = cor_borda, lwd = 0.8) {
  grid::rectGrob(
    gp = grid::gpar(
      fill = fill,
      col = border,
      lwd = lwd
    )
  )
}

# barra_titulo_grob() cria as barras roxas dos cabeçalhos.
barra_titulo_grob <- function(fill = cor_barra, border = cor_barra) {
  grid::rectGrob(
    gp = grid::gpar(
      fill = fill,
      col = border,
      lwd = 0.8
    )
  )
}


# ======================================================================
# ETAPA 16 - RÉGUA GEOMÉTRICA DA PÁGINA
# ======================================================================

# cowplot trabalha com coordenadas normalizadas de 0 a 1.
# x/y controlam posição; width/height controlam tamanho.

x_principal <- 0.020
w_principal <- 0.635

x_direita <- 0.680
w_direita <- 0.270

y_base <- 0.045
y_topo <- 0.955

gap_vertical <- 0.018

# A legenda recebe mais altura para acomodar fonte e autoria.
h_legenda <- 0.340

# Brasil e RJ terão a mesma altura.
h_mapa_lateral <- (
  (y_topo - y_base) -
  h_legenda -
  (2 * gap_vertical)
) / 2

y_legenda <- y_base

y_rj <- y_legenda +
  h_legenda +
  gap_vertical

y_brasil <- y_rj +
  h_mapa_lateral +
  gap_vertical

h_cabecalho_principal <- 0.080
h_cabecalho_lateral   <- 0.072


# ======================================================================
# 17. MONTAGEM FINAL COM cowplot
# ======================================================================

# ggdraw() cria a prancheta.
# draw_grob() adiciona objetos grid.
# draw_plot() adiciona gráficos.
# draw_label() adiciona textos.
#
# IMPORTANTE: em draw_label(), a família tipográfica é fontfamily.

mapa_final <- cowplot::ggdraw() +

  # Fundo geral.
  cowplot::draw_grob(
    grid::rectGrob(
      gp = grid::gpar(
        fill = cor_fundo,
        col = NA
      )
    ),
    x = 0,
    y = 0,
    width = 1,
    height = 1
  ) +

  # --------------------------------------------------------------------
  # PAINEL PRINCIPAL
  # --------------------------------------------------------------------

  cowplot::draw_grob(
    card_fundo(
      fill = "white",
      border = cor_borda,
      lwd = 0.58
    ),
    x = x_principal,
    y = y_base,
    width = w_principal,
    height = y_topo - y_base
  ) +

  cowplot::draw_grob(
    barra_titulo_grob(),
    x = x_principal,
    y = y_topo - h_cabecalho_principal,
    width = w_principal,
    height = h_cabecalho_principal
  ) +

  cowplot::draw_label(
    "LOCALIZAÇÃO DA ÁREA DE ESTUDO",
    x = x_principal + 0.015,
    y = y_topo - 0.034,
    hjust = 0,
    fontfamily = fonte_mapa,
    fontface = "bold",
    colour = cor_barra_txt,
    size = 11.2
  ) +

  cowplot::draw_label(
    "Município de Niterói, estado do Rio de Janeiro, Brasil",
    x = x_principal + 0.015,
    y = y_topo - 0.061,
    hjust = 0,
    fontfamily = fonte_mapa,
    colour = cor_barra_txt,
    size = 7.4
  ) +

  cowplot::draw_plot(
    mapa_principal,
    x = x_principal + 0.005,
    y = y_base + 0.005,
    width = w_principal - 0.010,
    height = (y_topo - y_base) -
      h_cabecalho_principal -
      0.012
  ) +

  # --------------------------------------------------------------------
  # BRASIL
  # --------------------------------------------------------------------

  cowplot::draw_grob(
    card_fundo(
      fill = "white",
      border = cor_borda,
      lwd = 0.58
    ),
    x = x_direita,
    y = y_brasil,
    width = w_direita,
    height = h_mapa_lateral
  ) +

  cowplot::draw_grob(
    barra_titulo_grob(),
    x = x_direita,
    y = y_brasil + h_mapa_lateral - h_cabecalho_lateral,
    width = w_direita,
    height = h_cabecalho_lateral
  ) +

  cowplot::draw_label(
    "BRASIL",
    x = x_direita + 0.014,
    y = y_brasil + h_mapa_lateral - 0.030,
    hjust = 0,
    fontfamily = fonte_mapa,
    fontface = "bold",
    colour = cor_barra_txt,
    size = 8.4
  ) +

  cowplot::draw_label(
    "Estado do Rio de Janeiro em destaque",
    x = x_direita + 0.014,
    y = y_brasil + h_mapa_lateral - 0.054,
    hjust = 0,
    fontfamily = fonte_mapa,
    colour = cor_barra_txt,
    size = 6.0
  ) +

  cowplot::draw_plot(
    mapa_brasil,
    x = x_direita + 0.018,
    y = y_brasil + 0.012,
    width = w_direita - 0.036,
    height = h_mapa_lateral - h_cabecalho_lateral - 0.020
  ) +

  # --------------------------------------------------------------------
  # ESTADO DO RIO DE JANEIRO
  # --------------------------------------------------------------------

  cowplot::draw_grob(
    card_fundo(
      fill = "white",
      border = cor_borda,
      lwd = 0.58
    ),
    x = x_direita,
    y = y_rj,
    width = w_direita,
    height = h_mapa_lateral
  ) +

  cowplot::draw_grob(
    barra_titulo_grob(),
    x = x_direita,
    y = y_rj + h_mapa_lateral - h_cabecalho_lateral,
    width = w_direita,
    height = h_cabecalho_lateral
  ) +

  cowplot::draw_label(
    "ESTADO DO RIO DE JANEIRO",
    x = x_direita + 0.014,
    y = y_rj + h_mapa_lateral - 0.030,
    hjust = 0,
    fontfamily = fonte_mapa,
    fontface = "bold",
    colour = cor_barra_txt,
    size = 8.4
  ) +

  cowplot::draw_label(
    "Município de Niterói em destaque",
    x = x_direita + 0.014,
    y = y_rj + h_mapa_lateral - 0.054,
    hjust = 0,
    fontfamily = fonte_mapa,
    colour = cor_barra_txt,
    size = 6.0
  ) +

  cowplot::draw_plot(
    mapa_rj,
    x = x_direita + 0.018,
    y = y_rj + 0.012,
    width = w_direita - 0.036,
    height = h_mapa_lateral - h_cabecalho_lateral - 0.020
  ) +

  # --------------------------------------------------------------------
  # LEGENDA / FONTE / AUTORIA
  # --------------------------------------------------------------------

  cowplot::draw_plot(
    painel_info,
    x = x_direita,
    y = y_legenda,
    width = w_direita,
    height = h_legenda
  )


# ======================================================================
# ETAPA 18 - VISUALIZAR
# ======================================================================

mapa_final


# ======================================================================
# ETAPA 19 - EXPORTAR
# ======================================================================

# PNG em alta resolução.
ggplot2::ggsave(
  filename = "figuras/BONUS_mapa_localizacao_niteroi.png",
  plot = mapa_final,
  width = 200,
  height = 130,
  units = "mm",
  dpi = 400,
  bg = cor_fundo
)

# PDF vetorial.
ggplot2::ggsave(
  filename = "figuras/BONUS_mapa_localizacao_niteroi.pdf",
  plot = mapa_final,
  width = 200,
  height = 130,
  units = "mm",
  device = grDevices::cairo_pdf,
  bg = cor_fundo
)


# ======================================================================
# ETAPA 20 - COMO ADAPTAR ESTE MODELO PARA OUTRA ÁREA?
# ======================================================================

# Ao reutilizar este script, procure principalmente estas partes:
#
# 1. DADOS
#    -> troque a base territorial;
#
# 2. ÁREA DE ESTUDO
#    -> altere o filtro que seleciona Niterói;
#
# 3. SRC
#    -> escolha uma projeção adequada à sua região;
#
# 4. BBOX
#    -> ajuste a janela do mapa principal;
#
# 5. RÓTULOS
#    -> atualize nomes e posições;
#
# 6. PALETA
#    -> escolha cores adequadas ao seu trabalho;
#
# 7. TÍTULOS
#    -> substitua os textos da composição;
#
# 8. FONTE E AUTORIA
#    -> atualize o painel de informações;
#
# 9. TAMANHO DA FIGURA
#    -> adapte width e height no ggsave().
#
# DICA:
# Não tente mudar tudo ao mesmo tempo.
# Altere uma etapa, execute, observe e só então avance.


# ======================================================================
# ETAPA 21 - CHECKLIST CARTOGRÁFICO
# ======================================================================

# [ ] a área de estudo está claramente destacada?
# [ ] o contexto espacial é suficiente?
# [ ] o mapa principal tem maior protagonismo que os localizadores?
# [ ] o SRC escolhido é adequado?
# [ ] escala e norte estão legíveis e sem sobreposição?
# [ ] os rótulos estão legíveis?
# [ ] a paleta possui contraste suficiente?
# [ ] a fonte dos dados está informada?
# [ ] o ano da base está informado?
# [ ] a autoria está correta?
# [ ] o arquivo foi exportado em resolução adequada?


# ======================================================================
# MENSAGEM FINAL
# ======================================================================
#
# Este material foi elaborado com muito carinho para as alunas e
# participantes do R-Ladies Niterói.
#
# Espero que ele não seja apenas um script que vocês executem uma vez,
# mas um modelo que possa acompanhar vocês em muitos trabalhos futuros.
#
# Copiem, testem, desmontem, mudem cores, troquem a área de estudo,
# façam versões simples e versões mais elaboradas.
#
# Um bom mapa não nasce de um único comando: ele é construído por uma
# sequência de decisões espaciais, analíticas, cartográficas e visuais.
#
# Com carinho,
# Cássia
#
# ======================================================================

# Registrar informações da sessão para reprodutibilidade.
sessionInfo()
