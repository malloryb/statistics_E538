# Builds imgs/gifs/ch5_recap.gif for Chapter 5: the two sampling distributions from Chapter 4,
# the distance between them deciding the test. Ends where the Type I figure starts; the truth is added there.
# Run from the project root: Rscript imgs/gifs/ch5_recap_gif.R
suppressMessages({library(ggplot2); library(gifski)})
se <- 0.4; sigma <- 0.8; mu0 <- 0; crit <- 1.96 * se; xlim <- c(-1.8, 2.8)
xs <- seq(xlim[1], xlim[2], by = 0.005)
h0 <- data.frame(x = xs, y = dnorm(xs, mu0, se))

frame <- function(title, xbar = NULL, truth = FALSE, verdict = NULL) {
  p <- ggplot() +
    geom_area(data = subset(h0, x <= mu0 - crit), aes(x, y), fill = "red", alpha = 0.18) +
    geom_area(data = subset(h0, x >= mu0 + crit), aes(x, y), fill = "red", alpha = 0.18)
  if (truth) p <- p + geom_line(aes(xs, dnorm(xs, mu0, sigma)), colour = "orange", linewidth = 1.2)
  p <- p + geom_line(data = h0, aes(x, y), colour = "blue", linetype = "dotdash", linewidth = 1.2) +
    annotate("segment", x = mu0 + c(-crit, crit), xend = mu0 + c(-crit, crit), y = 0,
             yend = dnorm(crit, 0, se), colour = "red", linewidth = 0.8)
  if (!is.null(xbar)) p <- p +
    geom_line(aes(xs, dnorm(xs, xbar, se)), colour = "darkgreen", linetype = "dotdash", linewidth = 1.2) +
    annotate("segment", x = xbar - crit, xend = xbar + crit, y = -0.04, yend = -0.04, colour = "darkgreen", linewidth = 3)
  if (truth) p <- p + annotate("segment", x = mu0, xend = mu0, y = -0.04, yend = 1.22, colour = "orange", linewidth = 0.9)
  p <- p + annotate("segment", x = mu0, xend = mu0, y = -0.04, yend = 1.22, colour = "magenta", linetype = "dashed", linewidth = 1) +
    annotate("text", x = mu0 - 0.08, y = 1.3, label = "mu[0]", parse = TRUE, hjust = 1, colour = "magenta", size = 5)
  if (truth) p <- p + annotate("text", x = mu0 + 0.08, y = 1.3, label = "mu", parse = TRUE, hjust = 0, colour = "orange", size = 5)
  if (!is.null(xbar)) {
    z <- (xbar - mu0) / se
    p <- p +
      annotate("segment", x = xbar, xend = xbar, y = -0.04, yend = 1.22, colour = "limegreen", linetype = "dotted", linewidth = 1.6) +
      annotate("text", x = xbar + 0.08, y = 1.3, label = "bar(x)", parse = TRUE, hjust = 0, colour = "#1E9E1E", fontface = "bold", size = 5.5) +
      annotate("segment", x = mu0, xend = xbar, y = 1.08, yend = 1.08, colour = "grey30", linewidth = 0.6,
               arrow = arrow(length = unit(0.15, "cm"), ends = "both")) +
      annotate("text", x = xbar + 0.12, y = 1.08, label = sprintf("%.1f SE", z), hjust = 0, colour = "grey20", size = 4.3)
  }
  p <- p +
    annotate("text", x = xlim[1] + 0.05, y = 1.12, label = "'Under '*H[0]", parse = TRUE, hjust = 0, colour = "blue", size = 4.5)
  if (!is.null(xbar)) p <- p + annotate("text", x = xlim[1] + 0.05, y = 1.02, label = "From the sample", hjust = 0, colour = "darkgreen", size = 4.5)
  if (truth) p <- p + annotate("text", x = xlim[1] + 0.05, y = 0.92, label = "The truth", hjust = 0, colour = "orange", size = 4.5)
  if (!is.null(verdict)) {
    vcol <- if (verdict == "Reject") "red3" else "grey25"
    p <- p + annotate("label", x = xlim[2] - 0.1, y = 0.75, label = verdict, hjust = 1, size = 7,
                      fontface = "bold", colour = vcol, fill = "white", label.size = 0.9,
                      label.padding = unit(0.35, "lines"))
  }
  p + coord_cartesian(xlim = xlim, ylim = c(-0.08, 1.38)) + labs(x = NULL, y = NULL, title = parse(text = title)) +
    theme_classic(base_size = 13) +
    theme(axis.text = element_blank(), axis.ticks = element_blank(),
          plot.title = element_text(size = 13, colour = "grey35", face = "italic"))
}

dir <- file.path(tempdir(), "ch5_recap_frames"); dir.create(dir, showWarnings = FALSE); unlink(file.path(dir, "*"))
files <- c(); i <- 0
add <- function(p, n) for (r in seq_len(n)) { i <<- i + 1; f <- file.path(dir, sprintf("f%03d.png", i))
  if (r == 1) ggsave(f, p, width = 8, height = 5, dpi = 90, bg = "white") else file.copy(files[length(files)], f)
  files <<- c(files, f) }
verdict_of <- function(z) if (abs(z) >= 1.96) "Reject" else "Fail to reject"

# delay 0.25 s per frame: 16 frames = 4 s
add(frame("'Under '*H[0]*': where the sample mean would land if '*H[0]*' were true'"), 16)
add(frame("'From the sample: the sample mean and its sampling distribution'", xbar = 0.8 * se,
          verdict = verdict_of(0.8)), 16)
for (z in seq(0.8, 2.4, by = 0.2)) add(frame("'The distance between them decides the test'", xbar = z * se,
                                             verdict = verdict_of(z)), if (abs(z - 2.0) < 1e-9) 3 else 2)
add(frame("'The distance between them decides the test'", xbar = 2.4 * se, verdict = "Reject"), 24)
gifski(files, gif_file = "imgs/gifs/ch5_recap.gif", width = 720, height = 450, delay = 0.25)
