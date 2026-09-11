# Builds imgs/gifs/ch4_step4.gif for Chapter 4, build-up step 4: from individual readings to
# sample means, then the population turns right-skewed while the sampling distribution of the
# sample mean keeps its normal shape and spread.
# Run from the project root: Rscript imgs/gifs/ch4_step4_gif.R
suppressMessages({library(ggplot2); library(gifski)})
xbar <- -1.3; SE <- 0.4
xs <- seq(-4.5, 4.5, by = 0.01)
# right-skewed population with the same mean (xbar) and SD (1): shifted gamma, shape k
skewpop <- function(k) { sc <- 1 / sqrt(k); dgamma(xs - (xbar - k * sc), shape = k, scale = sc) }

base <- function(title) ggplot() + coord_cartesian(xlim = c(-4.5, 4.5), ylim = c(0, 1.38)) + theme_classic(base_size = 13) +
  labs(x = NULL, y = NULL, title = title) +
  theme(axis.text = element_blank(), axis.ticks = element_blank(), plot.title = element_text(size = 13, face = "italic", colour = "grey35")) +
  annotate("segment", x = xbar, xend = xbar, y = 0, yend = 1.22, linetype = "dotted", linewidth = 1) +
  annotate("text", x = xbar + 0.12, y = 1.3, label = "bar(x)", parse = TRUE, hjust = 0, size = 5)
pop  <- function(p, y, a = 1) p + geom_line(aes(x = xs, y = !!y), colour = "green3", linetype = "dashed", linewidth = 1.3, alpha = a)
samp <- function(p, a = 1) p + geom_line(aes(x = xs, y = dnorm(xs, xbar, SE)), colour = "darkgreen", linetype = "dotdash", linewidth = 1.2, alpha = a)
lab  <- function(p, y, l1, l2, col) p +
  annotate("text", x = 4.45, y = y, label = l1, parse = TRUE, hjust = 1, colour = col, size = 4.6) +
  annotate("text", x = 4.45, y = y - 0.085, label = l2, parse = TRUE, hjust = 1, colour = col, size = 4.1)

frame_dir <- file.path(tempdir(), "ch4_step4_frames"); dir.create(frame_dir, showWarnings = FALSE); unlink(file.path(frame_dir, "*"))
files <- c(); i <- 0
add_png <- function(p, secs) { for (r in seq_len(secs)) { i <<- i + 1; f <- file.path(frame_dir, sprintf("f%03d.png", i)); ggsave(f, p, width = 8, height = 5, dpi = 90, bg = "white"); files <<- c(files, f) } }

normal_pop <- dnorm(xs, xbar, 1)
# 1. the sample's picture of the population
add_png(lab(pop(base("The sample: its mean and standard deviation"), normal_pop), 0.62,
            "'Estimated population distribution'", "'center '*bar(x)*', spread '*s", "green4"), 4)
# 2. the sampling distribution of the sample mean
p2 <- samp(pop(base("Divide the spread by the square root of n"), normal_pop, a = 0.45))
p2 <- lab(p2, 1.2, "'Sampling distribution of the sample mean'", "N*'('*bar(x)*', '*SE[bar(x)]^2*'):  same center, spread '*SE[bar(x)] == s/sqrt(n)", "darkgreen")
add_png(p2, 5)
# 3. the population turns right-skewed; the dot-dash curve does not move
for (k in c(40, 12, 6, 3.5, 2)) add_png(samp(pop(base("Now make the population right-skewed"), skewpop(k))), 1)
p4 <- samp(pop(base("Now make the population right-skewed"), skewpop(2)))
p4 <- lab(p4, 1.2, "'Same sampling distribution of the sample mean'", "N*'('*bar(x)*', '*SE[bar(x)]^2*'),  once n is large enough'", "darkgreen")
add_png(p4, 8)
gifski(files, gif_file = "imgs/gifs/ch4_step4.gif", width = 720, height = 450, delay = 1)
