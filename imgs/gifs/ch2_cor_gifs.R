# Builds the three Chapter 2 correlation GIFs and their final-frame stills:
#   corUnifn10-1.gif     (fig-2randcor10gif)  random X and Y, n = 10
#   corUnifFourNs-1.gif  (fig-2corRandfour)   random X and Y, n = 10, 50, 100, 1000
#   corRealgif-1.gif     (fig-2realcorFour)   a real positive relationship, same four n
# Black points and a sky-blue fitted line, matching the static Chapter 2 figures.
# Run from the project root: Rscript imgs/gifs/ch2_cor_gifs.R
suppressMessages({library(ggplot2); library(gganimate); library(magick)})
theme_set(theme_classic(base_size = 14))
set.seed(538)

line_col <- "#008cff"

save_gif <- function(anim, name) {
  gif <- animate(anim, nframes = 80, fps = 10, width = 480, height = 480,
                 renderer = gifski_renderer())
  anim_save(file.path("imgs/gifs", name), gif)
  frames <- image_read(file.path("imgs/gifs", name))
  image_write(frames[length(frames)], file.path("imgs/gifs/stills", sub("\\.gif$", ".png", name)))
}

animate_sims <- function(p) p +
  transition_states(simulation, transition_length = 2, state_length = 1) +
  enter_fade() + exit_shrink() + ease_aes("sine-in-out")

# 1. random X and Y, n = 10
one_n <- do.call(rbind, lapply(1:10, function(sim)
  data.frame(simulation = sim,
             North_pole = sample(1:10, 10, replace = TRUE),
             South_pole = sample(1:10, 10, replace = TRUE))))
save_gif(animate_sims(
  ggplot(one_n, aes(North_pole, South_pole)) +
    geom_point(colour = "black", size = 2) +
    geom_smooth(method = lm, se = FALSE, colour = line_col, linewidth = 1.2, formula = y ~ x) +
    labs(x = "North Pole ball", y = "South Pole ball")),
  "corUnifn10-1.gif")

# 2 and 3. four sample sizes, with and without a real relationship
four_ns <- function(make_y) do.call(rbind, lapply(1:10, function(sim)
  do.call(rbind, lapply(c(10, 50, 100, 1000), function(n) {
    x <- runif(n, 1, 10)
    data.frame(nsize = n, simulation = sim, North_pole = x, South_pole = make_y(x))
  }))))
four_plot <- function(d, xlab, ylab) animate_sims(
  ggplot(d, aes(North_pole, South_pole)) +
    geom_point(colour = "black", size = 1) +
    geom_smooth(method = lm, se = FALSE, colour = line_col, linewidth = 1.2, formula = y ~ x) +
    facet_wrap(~nsize, labeller = labeller(nsize = function(n) paste("n =", n))) +
    labs(x = xlab, y = ylab))

save_gif(four_plot(four_ns(function(x) runif(length(x), 1, 10)), "X (random)", "Y (random)"), "corUnifFourNs-1.gif")
save_gif(four_plot(four_ns(function(x) 0.5 * x + rnorm(length(x), 2.5, 3.5)), "X", "Y"), "corRealgif-1.gif")
