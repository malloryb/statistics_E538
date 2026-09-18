# Builds imgs/gifs/ch4_players.gif for Chapter 4 (the players appearing one at a time, ending on the crowded all-together frame).
# Run from the project root: Rscript imgs/gifs/ch4_players_gif.R
suppressMessages({library(ggplot2); library(gifski)})
mu0 <- -1.2; xbar <- 0.6; true_m <- 0.9; SE <- 0.4
xs <- seq(-4.5, 4.5, by = 0.01)
curves <- list(
  nullpop = list(y = dnorm(xs, mu0, 1),    col = "blue",      lt = "solid",   lw = 1.3),
  sampH0  = list(y = dnorm(xs, mu0, SE),   col = "blue",      lt = "dotdash", lw = 1.1),
  estpop  = list(y = dnorm(xs, xbar, 1),   col = "green3",    lt = "dashed",  lw = 1.3),
  samp    = list(y = dnorm(xs, xbar, SE),  col = "darkgreen", lt = "dotdash", lw = 1.1),
  truepop = list(y = dnorm(xs, true_m, 1), col = "orange",    lt = "solid",   lw = 1.3)
)
L <- function(x, y, l1, l2, col, hj) list(x = x, y = y, l1 = l1, l2 = l2, col = col, hj = hj)
steps <- list(
  list(add = "mu0",     title = "italic('If ')*italic(H[0])*italic(' were true')",
       lab = L(-4.4, 1.3, "mu[0]*': the population mean if '*H[0]*' were true'", NULL, "magenta", 0)),
  list(add = "nullpop", title = "italic('If ')*italic(H[0])*italic(' were true')",
       lab = L(-4.4, 0.56, "'Null population distribution'", "'center '*mu[0]*', spread '*sigma*''", "blue", 0)),
  list(add = "sampH0",  title = "italic('If ')*italic(H[0])*italic(' were true')",
       lab = L(-4.4, 1.2, "'Sampling distribution of the sample mean under '*H[0]", "N*'('*mu[0]*', '*SE[bar(x)]^2*')'", "blue", 0)),
  list(add = "xbar",    title = "italic('From the sample')",
       lab = L(xbar + 0.15, 1.3, "bar(x)*': the sample mean'", NULL, "#1E9E1E", 0)),
  list(add = "estpop",  title = "italic('From the sample')",
       lab = L(4.45, 0.68, "'Estimated population distribution'", "'center '*bar(x)*', spread '*s*''", "green4", 1)),
  list(add = "samp",    title = "italic('From the sample')",
       lab = L(4.45, 1.2, "'Sampling distribution of the sample mean'", "N*'('*bar(x)*', '*SE[bar(x)]^2*')'", "darkgreen", 1)),
  list(add = "truepop", title = "italic('The truth')",
       lab = L(4.45, 0.68, "'True population distribution'", "'center '*mu*', spread '*sigma*': never known'", "darkorange", 1))
)
base <- function(title) ggplot() + coord_cartesian(xlim = c(-4.5, 4.5), ylim = c(0, 1.38)) + theme_classic(base_size = 13) +
  labs(x = NULL, y = NULL, title = parse(text = title)) +
  theme(axis.text = element_blank(), axis.ticks = element_blank(), plot.title = element_text(size = 13, colour = "grey35"))
vline <- function(p, x, col, lt, a, lw = 1) p + annotate("segment", x = x, xend = x, y = 0, yend = 1.22, colour = col, linetype = lt, linewidth = lw, alpha = a)
draw <- function(p, keys, newest = NULL, fade = TRUE) {
  for (nm in intersect(names(curves), keys)) {
    cv <- curves[[nm]]; a <- if (!fade || identical(nm, newest)) 1 else 0.4
    p <- p + geom_line(aes(x = xs, y = !!cv$y), colour = cv$col, linetype = cv$lt, linewidth = cv$lw, alpha = a)
  }
  if ("mu0" %in% keys)  p <- vline(p, mu0,  "magenta", "dashed", if (!fade || identical(newest, "mu0")) 1 else 0.4)
  if ("xbar" %in% keys) p <- vline(p, xbar, "limegreen", "dotted", if (!fade || identical(newest, "xbar")) 1 else 0.4, lw = 1.6)
  p
}
label <- function(p, lab) {
  p <- p + annotate("text", x = lab$x, y = lab$y, label = lab$l1, parse = TRUE, hjust = lab$hj, colour = lab$col, size = 4.6)
  if (!is.null(lab$l2)) p <- p + annotate("text", x = lab$x, y = lab$y - 0.085, label = lab$l2, parse = TRUE, hjust = lab$hj, colour = lab$col, size = 4.1)
  p
}
frame_dir <- file.path(tempdir(), "ch4_players_frames"); dir.create(frame_dir, showWarnings = FALSE); unlink(file.path(frame_dir, "*"))
files <- c(); i <- 0
add_png <- function(p, secs) { for (r in seq_len(secs)) { i <<- i + 1; f <- file.path(frame_dir, sprintf("f%03d.png", i)); ggsave(f, p, width = 8, height = 5, dpi = 90, bg = "white"); files <<- c(files, f) } }
for (k in seq_along(steps)) {
  keys <- sapply(steps[seq_len(k)], `[[`, "add")
  add_png(label(draw(base(steps[[k]]$title), keys, newest = steps[[k]]$add), steps[[k]]$lab), 4)
}
all_keys <- sapply(steps, `[[`, "add")
p_all <- draw(base("italic('All together: crowded fast')"), all_keys, fade = FALSE) +
  annotate("text", x = mu0 - 0.1, y = 1.3, label = "mu[0]", parse = TRUE, hjust = 1, colour = "magenta", size = 5) +
  annotate("text", x = xbar + 0.1, y = 1.3, label = "bar(x)", parse = TRUE, hjust = 0, colour = "#1E9E1E", fontface = "bold", size = 5)
add_png(p_all, 10)
gifski(files, gif_file = "imgs/gifs/ch4_players.gif", width = 720, height = 450, delay = 1)
