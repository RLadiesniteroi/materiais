# Instalação e carregamento dos pacotes
if(!require(pacman)){install.packages("pacman")}
pacman::p_load(ggplot2, dplyr, tidyr, stringr, readxl)


# Leitura da base de dados
dados <- readxl::read_excel("dados_agatha.xlsx")


# Entendendo a lógica das camadas do ggplot2 ----------------------------------


## Os três principais argumentos: dados (data), estética (aes) e geom

ggplot(data = dados, aes(x = nota_amazon, y = nota_goodreads)) +
  geom_point()


## O aes e o data podem ser definidos na camada ggplot ou na geom_

ggplot() +
  geom_point(data = dados, aes(x = nota_amazon, y = nota_goodreads))



## Possibilidades de camadas de geom_: https://ggplot2.tidyverse.org/reference/

### Histograma (Votos Amazon)

ggplot(data = dados, aes(x = votos_amazon)) +
  geom_histogram()


### Gráfico de barras (Quantidade de livros por detetive)

ggplot(data = dados, aes(x = detetive)) +
  geom_bar()


### Boxplot (Avaliação por detetive)

ggplot(data = dados, aes(y = nota_amazon, x = detetive)) +
  geom_boxplot(outlier.shape = 1)


### Linhas (Quantidade de livros por ano até 1976)

# Ctrl + Shift + M: %>% ou |>

ggplot(data = dados |> filter(ano <= 1976),
       aes(x = ano, group = 1)) +
  geom_line(stat = "count")



dados_graf_linha <- dados |> 
  mutate(ano = factor(ano, levels = 1920:1976)) |> 
  count(ano, .drop = FALSE)

ggplot(data = dados_graf_linha,
       aes(x = as.numeric(as.character(ano)),
           y = n, group = 1)) +
  geom_line()



## Modificando argumentos dentro do geom (color, shape, size) -----------------
## E a diferença entre usá-los dentro ou fora do aes

### Color

#### Fora do aes

ggplot(data = dados, aes(x = nota_amazon, y = nota_goodreads)) +
  geom_point(color = "red")


#### Dentro do aes

ggplot(data = dados,
       aes(x = nota_amazon, y = nota_goodreads,
           color = tipo)) +
  geom_point()


ggplot(data = dados) +
  geom_point(aes(x = nota_amazon, y = nota_goodreads,
                 color = tipo))


#### E se eu definir os dois?

ggplot(data = dados,
       aes(x = nota_amazon, y = nota_goodreads,
           color = tipo)) +
  geom_point(color = "red")


### Shape

#### Fora do aes

ggplot(data = dados, aes(x = nota_amazon, y = nota_goodreads)) +
  geom_point(shape = 2)


#### Dentro do aes

ggplot(data = dados,
       aes(x = nota_amazon, y = nota_goodreads,
           shape = tipo)) +
  geom_point()


### Opções de shape e color

ggplot(data = dados, aes(x = nota_amazon, y = nota_goodreads)) +
  geom_point(color = "darkmagenta")
# Cores pré-definidas no R: https://drive.google.com/file/d/1WAdKbgHvMtNEP6GhScH9zMXmgW59_GdE/view?usp=sharing
# Publicado originalmente em: http://www.stat.columbia.edu/~tzheng/files/Rcolor.pdf



ggplot(data = dados, aes(x = nota_amazon, y = nota_goodreads)) +
  geom_point(color = "#77AF9C")
# Site gerador de paletas: https://coolors.co/



ggplot(data = dados, aes(x = nota_amazon, y = nota_goodreads)) +
  geom_point(color = "#77AF9C", shape = 18)
# Shapes possíveis: https://www.sthda.com/sthda/RDoc/images/points-symbols.png



#### Color x fill

ggplot(data = dados, aes(x = nota_amazon, y = nota_goodreads)) +
  geom_point(fill = "#77AF9C", shape = 23, color = "black")
# Shape que permite color e fill



### Size e alpha

ggplot(data = dados, aes(x = nota_amazon, y = nota_goodreads)) +
  geom_point(fill = "#77AF9C", shape = 23, color = "black",
             size = 2, alpha = 0.5)



# Combinando geoms ----------------------------------------------------------

### geom_point + geom_line

ggplot(data = dados, aes(x = nota_amazon, y = nota_goodreads)) +
  geom_point(color = "#77AF9C") +
  geom_line(stat = "smooth", method = "lm")


### geom_line x geom_smooth

ggplot(data = dados, aes(x = nota_amazon, y = nota_goodreads)) +
  geom_point(color = "#77AF9C") +
  geom_line(stat = "smooth", method = "lm")

ggplot(data = dados, aes(x = nota_amazon, y = nota_goodreads)) +
  geom_point(color = "#77AF9C") +
  geom_smooth(method = "lm", se = F, color = "black",
              linewidth = 0.5)



## Modificando a ordem das camadas (a ordem dos geoms importa!)

ggplot(data = dados, aes(x = nota_amazon, y = nota_goodreads)) +
  geom_point(color = "#77AF9C") +
  geom_line(stat = "smooth", method = "lm")


ggplot(data = dados, aes(x = nota_amazon, y = nota_goodreads)) +
  geom_line(stat = "smooth", method = "lm") +
  geom_point(color = "#77AF9C")



## Os geoms smooth e line trazem duas novas estéticas: linetype e linewidth

ggplot(data = dados, aes(x = nota_amazon, y = nota_goodreads)) +
  geom_point(color = "#77AF9C") +
  geom_line(stat = "smooth", method = "lm",
            linewidth = 0.5, linetype = "dashed")


ggplot(data = dados, aes(x = nota_amazon, y = nota_goodreads,
                         linetype = tipo)) +
  geom_point(color = "#77AF9C") +
  geom_line(stat = "smooth", method = "lm",
            linewidth = 0.5)



## Usando o filtro (dplyr) para selecionar dados para o gráfico

ggplot(data = dados |> 
         filter(detetive %in% c("Hercule Poirot", "Miss Marple")),
       aes(x = nota_amazon, y = nota_goodreads,
           linetype = detetive)) +
  geom_point(color = "#77AF9C") +
  geom_line(stat = "smooth", method = "lm")



# Entendendo o argumento "stat" -----------------------------------------------


ggplot(data = dados, aes(x = detetive)) +
  geom_bar()


ggplot(data = dados, aes(x = detetive)) +
  geom_bar(stat = "count")


ggplot(data = dados, aes(x = detetive, y = nota_amazon)) +
  geom_bar(stat = "summary", fun = "mean")


ggplot(data = dados, aes(x = detetive, y = nota_amazon)) +
  geom_bar(stat = "summary", fun = "median")


ggplot(data = dados, aes(x = detetive, y = votos_amazon)) +
  geom_bar(stat = "summary", fun = "sum")



## Com proporção

dados |> 
  count(detetive) |> 
  mutate(prop = n/sum(n)) |> 
  ggplot(aes(x = detetive, y = prop)) +
  geom_bar(stat = "identity")



## (stat = summary) x stat_summary()

ggplot(data = dados, aes(x = detetive, y = votos_amazon)) +
  geom_point(stat = "summary", fun = "mean")


ggplot(data = dados, aes(x = detetive, y = votos_amazon)) +
  stat_summary(geom = "point", fun = "mean")



## O summary para barras de erros
### fun.data = calcula y, ymin e ymax

ggplot(data = dados, aes(x = detetive, y = votos_amazon)) +
  geom_point(stat = "summary", fun = "mean") +
  geom_errorbar(stat = "summary", fun.data = "mean_se", width = 0.4)


ggplot(data = dados, aes(x = detetive, y = votos_amazon)) +
  geom_point(stat = "summary", fun = "mean") +
  geom_errorbar(stat = "summary", fun.data = "mean_cl_normal", width = 0.4)



## Barras de erro com IC 95% e desvio-padrão (pacote ggpubr)

pacman::p_load(ggpubr)

ggplot(data = dados, aes(x = detetive, y = votos_amazon)) +
  geom_point(stat = "summary", fun = "mean") +
  geom_errorbar(stat = "summary", fun.data = "mean_sd", width = 0.4)


ggplot(data = dados, aes(x = detetive, y = nota_amazon)) +
  ggbeeswarm::geom_beeswarm(color = "cadetblue") +
  geom_point(stat = "summary", fun = "mean") +
  geom_errorbar(stat = "summary", fun.data = "mean_sd", width = 0.4)



# Incluindo mais uma variável categórica ao gráfico ---------------------------

## Entendendo o argumento "position"

dados_filt <- dados |> 
  filter(detetive %in% c("Hercule Poirot", "Miss Marple"))

### Gráfico de barras (fill x color)

#### Position stack

ggplot(data = dados_filt,
       aes(x = detetive, fill = tipo)) +
  geom_bar()


ggplot(data = dados_filt,
       aes(x = detetive, fill = tipo)) +
  geom_bar(position = position_stack())


#### Position fill

ggplot(data = dados_filt,
       aes(x = detetive, fill = tipo)) +
  geom_bar(position = position_fill())


#### Position dodge (e os argumentos width e preserve)

ggplot(data = dados_filt,
       aes(x = detetive, fill = tipo)) +
  geom_bar(position = position_dodge())


ggplot(data = dados_filt,
       aes(x = detetive, fill = tipo)) +
  geom_bar(position = position_dodge(preserve = "single"))



### Gráfico de pontos + barras de erro

ggplot(data = dados_filt,
       aes(x = detetive, y = nota_amazon, color = tipo)) +
  geom_point(stat = "summary", fun = "mean",
             position = position_dodge(width = 0.4)) +
  geom_errorbar(stat = "summary", fun.data = "mean_sd",
                width = 0.4,
                position = position_dodge(width = 0.4))




# Salvando os gráficos em objetos ------------------------------------------------

graf_medias <- ggplot(data = dados_filt,
                      aes(x = detetive, y = nota_amazon, color = tipo)) +
  geom_point(stat = "summary", fun = "mean",
             position = position_dodge(width = 0.4)) +
  geom_errorbar(stat = "summary", fun.data = "mean_sd",
                width = 0.4,
                position = position_dodge(width = 0.4))


graf_barras <- ggplot(data = dados_filt,
                      aes(x = detetive, fill = tipo)) +
  geom_bar(position = position_dodge())


graf_dispersao <- ggplot(data = dados,
                         aes(x = nota_amazon, y = nota_goodreads)) +
  geom_point(color = "cadetblue", alpha = 0.5)


graf_porc <- dados |> 
  count(detetive) |> 
  mutate(prop = n/sum(n)) |> 
  ggplot(aes(x = detetive, y = prop)) +
  geom_bar(stat = "identity")


# Renomeando os eixos e legenda -------------------------------------------

graf_medias +
  labs(y = "Notas na Amazon", x = "Detetive",
       color = "Tipo de livro")


## Removendo títulos com NULL e ""

graf_medias +
  labs(y = "Notas na Amazon", x = "",
       color = "Tipo de livro")


graf_medias +
  labs(y = "Notas na Amazon", x = NULL,
       color = "Tipo de livro")



## Adicionando título, subtítulo e legenda

graf_medias +
  labs(y = "Notas na Amazon", x = "",
       color = "Tipo de livro",
       title = "Avaliações (1 a 5) dos livros da Agatha Christie",
       subtitle = "Dados expressos como média e desvio-padrão",
       caption = "Fonte: Amazon, busca pelo título em português")


## Quebra de texto manual

graf_medias +
  labs(y = "Notas na Amazon", x = "",
       color = "Tipo de livro",
       title = "Avaliações (1 a 5) dos livros\nda Agatha Christie",
       subtitle = "Dados expressos como média e desvio-padrão",
       caption = "Fonte: Amazon, busca pelo título em português")


## Quebra de texto automática (stringr::str_wrap)

graf_medias +
  labs(y = "Notas na Amazon", x = "",
       color = "Tipo de livro",
       title = stringr::str_wrap("Avaliações (1 a 5) dos livros da Agatha Christie",
                                 width = 30),
       subtitle = "Dados expressos como média e desvio-padrão",
       caption = "Fonte: Amazon, busca pelo título em português")


# Temas ----------------------------------------------------------------------------


### Escolhendo outro tema padrão

graf_medias +
  theme_classic()
# https://www.r-bloggers.com/2016/08/ggplot2-themes-examples/


graf_medias +
  theme_bw()


graf_medias +
  theme_minimal()



## Modificando elementos do tema (os elements)

### Tamanho, estilo e tipo da fonte

graf_medias +
  theme_classic() +
  theme(axis.title = element_text(size = 13, face = "bold", color = "darkred"),
        axis.text = element_text(size = 11, family = "Courier"))
# Opções: axis.title.y, axis.title.x, axis.text.y, axis.text.x
# Outras modificações possíveis: plot.title, plot.subtitle, plot.caption
# Fontes: Times, Helvetica, Courier



### Usando uma fonte personalizada

pacman::p_load(extrafont)
font_import()
loadfonts()

graf_medias +
  theme_classic() +
  theme(axis.title = element_text(size = 13, face = "bold",
                                  color = "darkred", family = "Montserrat"),
        axis.text = element_text(size = 11, family = "Nunito"))


### Removendo elementos do gráfico com element_blank


graf_medias +
  theme_classic() +
  theme(axis.ticks.x = element_blank())


graf_medias +
  theme_classic() +
  theme(axis.ticks.x = element_blank(),
        axis.text.y = element_blank())




# Modificando os eixos numéricos -------------------------------------------
  

### Limites
### coord_cartesian x scale_continuous

graf_medias +
  coord_cartesian(ylim = c(4, 4.7))

graf_medias +
  scale_y_continuous(limits = c(4, 4.7))
### EXCLUI DO GRÁFICO VALORES FORA DOS LIMITES!


#### Outras coords


graf_dispersao + coord_cartesian()


graf_dispersao + coord_equal()


graf_dispersao + coord_flip()



#### Cuidado ao nomear os eixos após coord_flip!
graf_dispersao + coord_flip() +
  labs(y = "eixo y", x = "eixo x")



### Expansões

graf_barras +
  theme_classic() +
  scale_y_continuous(expand = expansion(add = c(0, 5)))

graf_barras +
  theme_classic() +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05)))



### Rótulos

graf_medias +
  scale_y_continuous(labels =
                       scales::number_format(decimal.mark = ",",
                                             accuracy = 0.1,
                                             big.mark = ".")) +
  theme_classic()


#### Porcentagem

graf_porc +
  scale_y_continuous(labels = scales::percent_format()) +
  theme_classic()


### Estabelecendo as quebras

graf_barras +
  scale_y_continuous(breaks = c(0, 5, 10, 30))


graf_barras +
  scale_y_continuous(breaks = seq(0, 40, by = 3))


graf_barras +
  scale_y_continuous(n.breaks = 7)


# Modificando os eixos categóricos --------------------------------------------

### Rótulos

graf_porc +
  scale_x_discrete(labels = c("Poirot", "Marple", "Outros",
                              "Beresford", "Múltiplos"))

graf_porc +
  scale_x_discrete(labels = \(x) stringr::str_wrap(x, width = 10))



### Limits

graf_porc +
  scale_x_discrete(limits = c("Tommy e Tuppence", "Vários",
                              "Miss Marple", "Outros",
                              "Hercule Poirot"),
                   labels = c("Beresford", "Vários",
                              "Marple", "Outros",
                              "Poirot"))



dados |> 
  count(detetive) |> 
  mutate(prop = n/sum(n)) |> 
  ggplot(aes(x = forcats::fct_reorder(detetive, prop),
             y = prop)) +
  geom_bar(stat = "identity")


dados |> 
  count(detetive) |> 
  mutate(prop = n/sum(n)) |> 
  ggplot(aes(x = forcats::fct_reorder(detetive, -prop),
             y = prop)) +
  geom_bar(stat = "identity")



# Facets -------------------------------------------------------------------

### Wrap

ggplot(data = dados, aes(x = nota_amazon, y = nota_goodreads)) +
  geom_point(color = "#77AF9C") +
  geom_line(stat = "smooth", method = "lm") +
  facet_wrap(~ detetive, ncol = 2, scales = "free")


#### strip.position

ggplot(data = dados, aes(x = nota_amazon, y = nota_goodreads)) +
  geom_point(color = "#77AF9C") +
  geom_line(stat = "smooth", method = "lm") +
  facet_wrap(~ detetive, ncol = 2, scales = "free",
             strip.position = "right")


### Grid

ggplot(data = dados, aes(x = nota_amazon, y = nota_goodreads)) +
  geom_point(color = "#77AF9C") +
  geom_line(stat = "smooth", method = "lm") +
  facet_grid(tipo ~ detetive, scales = "free")



# Outras alterações estéticas -----------------------------------------------


### Adicionar angulação aos textos dos eixos (mas evite!)

graf_medias +
  theme_classic() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1))
# https://qastack.com.br/programming/7263849/what-do-hjust-and-vjust-do-when-making-a-plot-using-ggplot


### Remover grades

graf_medias +
  theme_bw() +
  theme(panel.grid = element_blank())
# Opções: panel.grid.major, panel.grid.minor


## Modificando a legenda
### https://www.r-graph-gallery.com/239-custom-layout-legend-ggplot2.html

### Direção da legenda

graf_medias + theme_classic() +
  theme(legend.direction = "horizontal")

### Posição da legenda

graf_medias + theme_classic() +
  theme(legend.position = "bottom")
# Opções: bottom, top, left, right


graf_medias + theme_classic() +
  theme(legend.position = "bottom") +
  guides(color = guide_legend(title.position = "top", title.hjust = 0.5))


### Excluindo um dos elementos (geoms) da legenda
#### show.legend = FALSE

ggplot(data = dados_filt,
       aes(x = detetive, y = nota_amazon, color = tipo)) +
  geom_point(stat = "summary", fun = "mean",
             position = position_dodge(width = 0.4)) +
  geom_errorbar(stat = "summary", fun.data = "mean_sd",
                position = position_dodge(width = 0.4),
                width = 0.3, show.legend = F) +
  theme_classic()



# Unindo gráficos -----------------------------------------------------------

graf_barras <- graf_barras +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
  labs(y = "Quantidade de livros", x = "Detetive", fill = "Tipo") +
  theme_classic()

graf_medias <- graf_medias +
  scale_y_continuous(labels = scales::number_format(decimal.mark = ",")) +
  labs(y = "Nota na Amazon", x = "Detetive", fill = "Tipo") +
  theme_classic()

graf_dispersao <- graf_dispersao +
  scale_y_continuous(labels = scales::number_format(decimal.mark = ",")) +
  scale_x_continuous(labels = scales::number_format(decimal.mark = ",")) +
  labs(y = "Nota no Goodreads", x = "Nota na Amazon") +
  theme_classic()


pacman::p_load(patchwork)

graf_medias + graf_dispersao + graf_barras +
  plot_layout(ncol = 2) +
  plot_annotation(tag_levels = "a", tag_suffix = ".",
                  title = "Livros da Agatha Christie") &
  theme(plot.tag = element_text(size = 10))


graf_dispersao / (graf_barras + graf_medias)

# https://patchwork.data-imaginist.com/articles/guides/layout.html



## Salvando os gráficos em alta resolução -------------------------------------

### ggsave - por padrão, salva o último gráfico rodado

ggsave("Graficos_patchwork.png", height = 5, width = 8,
       units = "in", dpi = 600)
# Formatos aceitos: tiff, png, pdf, jpeg, eps, svg...
# Unidades aceitas: in, cm, mm, px

ggsave(plot = graf_medias,
       filename = "Grafico_medias.tiff",
       height = 4.5, width = 6,
       units = "in", dpi = 600)


