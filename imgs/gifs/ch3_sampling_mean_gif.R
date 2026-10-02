# Builds imgs/gifs/sampleDistNormal-1.gif (fig-3samplingmean) and its final-frame still.
# Four sample sizes (n = 2, 8, 32, 128; each step multiplies n by 4, which halves the SE) from a normal
# population with mu = 0, sigma = 1. Each frame draws one new sample per panel.
# Top row: that sample's values (grey points), its s, and its mean (lime-green dotted line).
# Bottom row: every sample mean so far as a dot pile, newest in lime green, with SE = sigma/sqrt(n).
# Three things to see: the values' spread stays near sigma, the means' spread shrinks (SE),
# and one sample's mean settles near mu (law of large numbers).
# The first frames are held longer so the reader can follow one sample before it speeds up.
# Run from the project root: Rscript imgs/gifs/ch3_sampling_mean_gif.R
suppressMessages({library(ggplot2); library(gganimate); library(gifski)})
theme_set(theme_classic(base_size = 14))
set.seed(538)
ns <- c(2, 8, 32, 128); K <- 40; bw <- 0.1
rows <- c("One sample: its values", "Sample means so far")
lab_n <- function(n) paste("n =", n)
samp <- list(); xb <- list()
for (n in ns) { m <- s <- numeric(K)
  for (k in 1:K) { x <- rnorm(n); m[k] <- mean(x); s[k] <- if (n > 1) sd(x) else NA
    samp[[length(samp)+1]] <- data.frame(n = n, f = k, x = x, y = runif(n, 0.03, 0.13)) }
  xb[[length(xb)+1]] <- data.frame(n = n, k = 1:K, m = m, s = s) }
samp <- do.call(rbind, samp); xb <- do.call(rbind, xb)
pile <- do.call(rbind, lapply(1:K, function(f) do.call(rbind, lapply(ns, function(n) {
  d <- xb[xb$n == n & xb$k <= f, ]; d$bin <- round(d$m / bw) * bw
  d$h <- ave(d$k, d$bin, FUN = seq_along); d$f <- f; d$now <- d$k == f; d }))))
top <- function(d) { d$part <- factor(rows[1], rows); d }; bot <- function(d) { d$part <- factor(rows[2], rows); d }
pile <- bot(pile); samp <- top(samp)
cur <- xb; cur$f <- cur$k
pop <- top(expand.grid(x = seq(-3, 3, by = .02), n = ns)); pop$d <- dnorm(pop$x)
s_lab  <- top(transform(cur, lab = sprintf("s = %.2f", s)))
se_lab <- bot(data.frame(n = ns, lab = sprintf("SE = %.2f", 1 / sqrt(ns))))
p <- ggplot() +
  geom_line(data = pop, aes(x, d), colour = "orange", linewidth = 0.9) +
  geom_point(data = samp, aes(x, y), colour = "grey35", alpha = 0.6, size = 1.6) +
  geom_segment(data = top(cur), aes(x = m, xend = m, y = 0, yend = 0.42), colour = "limegreen", linetype = "dotted", linewidth = 1.6) +
  geom_label(data = s_lab, aes(x = -2.45, y = 0.4, label = lab), hjust = 0, size = 4.2, colour = "grey25", fill = "white", label.size = 0) +
  geom_point(data = pile, aes(bin, h, colour = now), size = 1.9) +
  geom_text(data = se_lab, aes(x = -2.45, y = 22, label = lab), hjust = 0, size = 4.2, colour = "darkgreen") +
  scale_colour_manual(values = c(`FALSE` = "darkgreen", `TRUE` = "limegreen"), guide = "none") +
  geom_vline(xintercept = 0, colour = "grey60", linewidth = 0.4) +
  facet_grid(part ~ n, scales = "free_y", labeller = labeller(n = lab_n, part = label_wrap_gen(14))) +
  coord_cartesian(xlim = c(-2.5, 2.5)) +
  labs(x = "value (population: \u03bc = 0, \u03c3 = 1)", y = NULL) +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank(), strip.text.y = element_text(size = 11)) +
  transition_manual(f)
dir <- file.path(tempdir(), "ch3_sampling_mean_frames"); unlink(dir, recursive = TRUE); dir.create(dir)
animate(p, nframes = K, fps = 4, width = 860, height = 580, renderer = file_renderer(dir, prefix = "f", overwrite = TRUE))
files <- sort(list.files(dir, full.names = TRUE))
# slow start: frames 1-3 held 2.5 s, 4-8 held 1 s, then 0.25 s each; final frame held 4 s
reps <- c(rep(10, 3), rep(4, 5), rep(1, K - 9), 16)
gifski(rep(files, reps), "imgs/gifs/sampleDistNormal-1.gif", width = 860, height = 580, delay = 0.25)
invisible(file.copy(files[K], "imgs/gifs/stills/sampleDistNormal-1.png", overwrite = TRUE))
