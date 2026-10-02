# Builds imgs/gifs/sampleDistNormal-1.gif (fig-3samplingmean) and its final-frame still.
# Four panels, n = 10, 50, 100, 1000, from a standard normal population (orange curve).
# Each frame draws one new sample: grey bars are the sample, the lime-green dotted line
# is its mean (x-bar, as in Chapters 4 and 5), the green histogram is 1000 sample means
# of that size, and the dark green line is the mean of those sample means.
# Run from the project root: Rscript imgs/gifs/ch3_sampling_mean_gif.R
suppressMessages({library(ggplot2); library(gganimate); library(magick)})
theme_set(theme_classic(base_size = 14))
set.seed(538)

ns <- c(10, 50, 100, 1000)
# One set of 0.2-wide bins for every panel, so a narrow sampling distribution piles into a
# few tall bars instead of disappearing into slivers.
breaks <- seq(-3, 3, by = 0.2)
bin_heights <- function(x, top) {
  h <- hist(pmin(pmax(x, -3), 3), breaks = breaks, plot = FALSE)
  keep <- h$counts > 0
  data.frame(xmin = head(breaks, -1), xmax = tail(breaks, -1), h = h$density / max(h$density) * top)[keep, ]
}

samples <- means <- marks <- list()
for (sim in 1:10) for (n in ns) {
  one   <- rnorm(n)
  xbars <- replicate(1000, mean(rnorm(n)))
  samples[[length(samples) + 1]] <- cbind(bin_heights(one, 0.6), sims = sim, sample_size = n)
  means[[length(means) + 1]]     <- cbind(bin_heights(xbars, 1), sims = sim, sample_size = n)
  marks[[length(marks) + 1]]     <- data.frame(sims = sim, sample_size = n,
                                               xbar = mean(one), center = mean(xbars))
}
samples <- do.call(rbind, samples); means <- do.call(rbind, means); marks <- do.call(rbind, marks)
pop <- data.frame(x = seq(-3, 3, by = 0.02)); pop$d <- dnorm(pop$x)

p <- ggplot() +
  geom_rect(data = samples, aes(xmin = xmin, xmax = xmax, ymin = 0, ymax = h),
            fill = "grey65", colour = "white") +
  geom_rect(data = means, aes(xmin = xmin, xmax = xmax, ymin = 0, ymax = h),
            fill = "darkgreen", colour = "white", alpha = 0.5) +
  geom_line(data = pop, aes(x, d), colour = "orange", linewidth = 0.9) +
  geom_vline(data = marks, aes(xintercept = center), colour = "darkgreen", linewidth = 0.9) +
  geom_vline(data = marks, aes(xintercept = xbar), colour = "limegreen",
             linetype = "dotted", linewidth = 1.6) +
  facet_wrap(~sample_size) +
  coord_cartesian(xlim = c(-3, 3), ylim = c(0, 1.05)) +
  labs(x = "value", y = "Rough likelihoods") +
  transition_states(sims, transition_length = 2, state_length = 1) +
  enter_fade() + exit_shrink() + ease_aes("sine-in-out")

gif <- animate(p, nframes = 80, fps = 10, width = 750, height = 582, renderer = gifski_renderer())
anim_save("imgs/gifs/sampleDistNormal-1.gif", gif)
frames <- image_read("imgs/gifs/sampleDistNormal-1.gif")
image_write(frames[length(frames)], "imgs/gifs/stills/sampleDistNormal-1.png")
