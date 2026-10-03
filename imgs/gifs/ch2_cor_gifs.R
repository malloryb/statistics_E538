# Builds the three Chapter 2 correlation GIFs and their final-frame stills:
#   corUnifn10-1.gif     (fig-2randcor10gif)  random X and Y, n = 10
#   corUnifFourNs-1.gif  (fig-2corRandfour)   random X and Y, n = 10, 50, 100, 1000
#   corRealgif-1.gif     (fig-2realcorFour)   true correlation true_r, same four n
# Black points and a cobalt fitted line.
# true_r is set in imgs/gifs/ch2_cor_true_r.R, which 02-Correlation.qmd also reads.
# Run from the project root: Rscript imgs/gifs/ch2_cor_gifs.R
suppressMessages({library(ggplot2); library(gganimate); library(magick)})
theme_set(theme_classic(base_size = 14))
source("imgs/gifs/ch2_cor_true_r.R")
set.seed(538)

line_col <- "#10377f"

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

# 2. four sample sizes, no relationship (four_ns and four_plot are reused for 3)
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
# 3. X and Y with population correlation exactly true_r: standard normal x,
# y = true_r * x + sqrt(1 - true_r^2) * noise, then both rescaled to mean 5.5, SD 2.
real_ns <- do.call(rbind, lapply(1:10, function(sim)
  do.call(rbind, lapply(c(10, 50, 100, 1000), function(n) {
    x <- rnorm(n)
    y <- true_r * x + sqrt(1 - true_r^2) * rnorm(n)
    data.frame(nsize = n, simulation = sim, North_pole = 5.5 + 2 * x, South_pole = 5.5 + 2 * y)
  }))))
r_by_frame <- sapply(split(real_ns, list(real_ns$nsize, real_ns$simulation)),
                     function(d) cor(d$North_pole, d$South_pole))
print(round(matrix(r_by_frame, nrow = 4, dimnames = list(c(10, 50, 100, 1000), 1:10)), 2))
save_gif(four_plot(real_ns, "X", "Y"), "corRealgif-1.gif")
