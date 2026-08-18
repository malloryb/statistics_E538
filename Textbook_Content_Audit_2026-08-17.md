# E-538 textbook content audit
Date: 2026-08-17. **Status: all items below have been fixed unless marked OPEN.** Clean full render after fixes: exit 0, no errors, no warnings, no broken cross-references, no duplicate labels. Scope: all 11 chapters, substantive pass for mathematical correctness, R correctness, and internal consistency. Distinct from the completed style/voice pass.

Method: clean full render from an emptied `_freeze`, cross-reference and label integrity checks, independent recomputation in R of every hardcoded number, and a read of each chapter.

## Summary

The book is in good shape mathematically. Every worked arithmetic example I recomputed was correct, and the render is clean. The real problems are a small number of specific bugs, plus a recurring pattern where a figure's caption or the prose around it no longer matches the code that draws it.

### Book-wide checks, all passing
- Clean render from an emptied `_freeze` cache: exit 0, no R errors, no warnings.
- No duplicate chunk labels anywhere in the book.
- No broken `@fig-` / `@tbl-` cross-references.
- Every "Chapter N" reference in prose matches the actual chapter order in `_quarto.yml`.
- Verified correct by recomputation: Ch1 weighted mean, variance/SD, ozone mode/median/mean, Simpson's paradox CFRs; Ch3 all three sd-bias examples, the n=2 expectation, the 70% CI constant; Ch5 the power simulation and power-curve values; Ch6 all three t-test worked examples and the reported CIs; Ch7 the chi-square contributions, E[U], Var(U) and the MWW normal approximation; Ch8 the full SS/MS/F walkthrough and eta-squared; Ch10 the factorial SS partition and all three effect sizes.

---

## Fix these (real errors)

### 1. Ch2, slope worked example: wrong number in the printed fraction
`02-Correlation.qmd` ~L500. The slope line prints the denominator as `7*275-34^2`. For this data `sum(x^2) = 200`, and the intercept line directly above correctly uses `7*200`. As printed the fraction evaluates to **0.378**, not the stated 1.19. Change `7*275` to `7*200`.

### 2. Ch2, chunk `3morcov`: slope and intercept are assigned to each other
The variable named `slope` holds the intercept formula and the variable named `intercept` holds the slope formula. Neither is printed, so the render is unaffected, but the source is wrong for any student reading or copying it.

### 3. Ch4, `fig-5simdecision` caption is backwards and names a colour that isn't there
`04-Foundation_Inference.qmd` L474. Caption reads: "Green marks differences chance never produced...; red marks the range chance did produce; grey marks a zone chance produced only rarely."

The code draws grey as the chance window, gold as the rare edge bands, and brick red as the region outside the window. The body prose says the opposite of the caption: "The red zones on either side are the ones chance never reached." There is no green in the figure at all. This currently ships in `docs/04-Foundation_Inference.html`.

Worth noting: this supersedes the "inverted colour semantics" item in your notes. The figure and the prose were fixed at some point; the caption was not.

### 4. Ch1, malformed summation subscript
`01-Data_Description.qmd` ~L930: `\sum_{i=1}^{n}x_{{i}-a} = 0`. The braces put `-a` inside the subscript, so it renders as $x_{i-a}$. Should be $\sum(x_i - a)$.

### 5. Ch1, Anscombe's Quartet: the printed table contradicts the prose
The text says all four datasets have "the exact same descriptive statistics," but the kable prints `var_y` as 4.127269 / 4.127629 / 4.122620 / 4.123249, visibly different in the third decimal. The bullet list also claims "same correlation," which is not in the table at all. Either round the table to 2 decimals, or soften to "identical to two decimal places" and add the correlation column.

### 6. Ch2, two caption/prose colour mismatches
- "Notice the blue lines in these panels" describes `fig-3regression`, which draws its fit line in `#b22222` (brick red).
- `fig-3corwithLine`'s caption says "with confidence bands," but the code has `se = FALSE`. There are no bands.

### 7. Ch4, `fig-5randtest` colour mismatch
Prose says "The light green and red dots are the individual readings"; the caption says "blue and red dots track how individual scores move."

---

## Worth fixing (correctness-adjacent)

### 8. `round(runif(n, 1, 10))` is used to mean "uniform on the integers 1 to 10"
This appears in Ch2 (`3northsouth`), Ch3 (`fig-4unifmany`), and Ch4 (`fig-5manysamples`, `fig-5whichone`). It is not uniform: 1 and 10 each get half the probability of the other values, because they only catch half a rounding interval.

This matters most in **Ch4**, which is internally inconsistent about it: `fig-5unifsamp100`, `fig-5unifsamp1000` and `fig-5sampunifALOT` use the correct `sample(1:10, ..., replace = TRUE)`, while the earlier figures in the same chapter use `round(runif(...))`. Ch3 is worse in a different way: `fig-4Unif` explicitly draws a flat line at P = 0.1 for each of the ten values, and the very next figure samples from a distribution that isn't that. Fix: `sample(1:10, n, replace = TRUE)` everywhere.

### 9. Ch3, the bias simulation samples a different population than the one described
The narrative sets up "every even number from 80 to 120" (sigma = 12.11, correctly computed), then says the simulation checks "that directly" but actually runs `rnorm(n, 100, 12.11)`. Same sigma, different distribution. Either sample the 21 even numbers, or reword.

### 10. Ch5, the power-curve SE formula is written wrong and only works by coincidence
`fig-5.5powercurve` and `fig-5.5powercurveN` compute `se <- sqrt(sd_AB/n + sd_AB/n)` where `sd_AB` is a standard deviation. It should be `sd_AB^2/n`. It gives the right answer only because `sd_AB <- 1`, so the variance equals the SD. Any future edit that changes the SD silently breaks both curves.

Related, smaller: both curves are computed with `qnorm`/`pnorm` but captioned as power for a **t**-test. At n = 10 the z-approximation gives 0.20 where the exact t-based power is 0.18, and the "about 380 per group" for d = 0.2 is 394 by the exact calculation.

### 11. Ch2/Ch1, covariance is defined with /N but R uses n-1
Ch2 defines $cov(X,Y)$ dividing by N, and Pearson's r as $cov/(\sigma_X\sigma_Y)$ with population SDs. Ch1 has already established that "the sample standard deviation" means the n-1 version and that this is what R returns. A student who runs `cov()` on the chocolate/happiness table will not reproduce the book's number. One sentence noting the convention would close this.

### 12. Ch3, CLT fact 1 attributed to the wrong theorem
"The first fact, that sample means converge to the population mean, comes from the law of large numbers." Fact 1 of the CLT as stated is that the sampling distribution is *centered* on mu, which is unbiasedness and holds at every n. LLN is about convergence as n grows. Two different claims.

Related: the careful sentence noting that $s_{n-1}$ is *still slightly biased* for sigma (which most textbooks get wrong, and which yours gets right) is contradicted a few paragraphs later by the flat "Key points" bullet, "Dividing by n-1 instead corrects this bias."

### 13. Ch1, dangling forward reference to the weighted mean
L683: "Unequal group sizes come back when we reach ANOVA in Chapter 8, where each group mean is weighted by its own n." Ch8 uses equal group sizes throughout and never weights anything. This is the known open item; it is still open.

### 14. Ch6, five figures use base-R `hist()` and bypass the whole design system
`fig-7nullt`, `fig-7flatp`, `fig-7simts1000`, `fig-7simps1000`, `fig-7simtrueps` are `hist(save_ts)` / `hist(save_ps)`. They render in default base graphics, ignore the palette and `theme_classic`, and are axis-labelled "save_ts" and "save_ps". These are the only base-graphics figures in the book.

### 15. Ch6, raw `t.test()` console output still present
The independent-samples "by hand" chunk prints both bare `t` and full `t.test(a, b, paired = FALSE, var.equal = TRUE)` console output with `echo = TRUE`. This is the known house-style exception; still there.

### 16. Ch5, the power comparison chunks hide their own code
The n = 10 baseline simulation is `echo = TRUE`, but the "Larger n" and "Smaller alpha" follow-ups are plain `{r}` chunks, so with the global `echo: false` the reader sees a bare number appear with no code and no label explaining what changed.

### 17. Ch8 and Ch10 give the same formula two different names
Ch8 computes eta-squared as `ss_between / (ss_between + ss_within)`. Numerically correct for a one-way ANOVA. But Ch10 then introduces *partial* eta-squared as $SS_\text{Effect}/(SS_\text{Effect}+SS_\text{Error})$, which is the identical expression. A student flipping back will see one formula with two names. Ch8 would read more cleanly as `ss_between / ss_total`, which is also how Ch10 describes what Ch8 did.

---

## Minor / cosmetic

- Ch6: the comment `# Welch one-sample t` on `t.test(scores, mu = 50)`. There is no such thing; Welch is the two-sample unequal-variance correction.
- Ch2: the lottery-ball narrative says draws are "with replacement" from balls 1-10, but `fig-3anotherthousand` drops the rounding entirely and draws continuous `runif`.
- Ch2: the chocolate/happiness covariance table is built up in detail but Pearson's r is never actually computed for that running example.
- Ch4: the NO2 data are laid out wide (20 rows, `near_ppb` / `far_ppb` columns, "site" 1-20), which reads as a paired design, but the analysis is an independent-groups randomization test. Worth restructuring given Ch6 makes paired-vs-independent load-bearing.
- Ch4: `fig-5whichoneB` uses `round(rnorm(20, 5, 2.5))`, which produces values outside 1-10, so the shared facet bins no longer line up with the 1-10 axis breaks.
- Ch3: `fig-4normalSDspercents` prints a label reading "0" for the 3-to-4 SD band. `fig-4samplemeanunif` draws the "flat parent distribution" as a bare `geom_hline` at y = 0.1, and `fig-4samplemeanExp` overlays `dexp` (max height 2) on a histogram normalized to max 1. Neither red reference curve is on the same scale as the bars beneath it.
- Ch1: `element_rect(size = 1)` in `fig-age-distributions` is the deprecated ggplot2 argument; should be `linewidth`.
- Teaching code hygiene, mostly Ch2-Ch3: `simulated_sums <- length(0)` and `save_means <- length(iter)` used as vector preallocation (7+ places); `sample <- rnorm(...)` and `c <- ggplot(...)` shadowing base R functions; a dead `sample` column built and never used in three CLT chunks.
- ~30 figures are defined but never referenced from prose, so Quarto numbers them but nothing points at them. The largest cluster is the five `fig-10outbreak*` figures in Ch9 (Regression).
- Colour literals outside the palette are down to 42, concentrated in Ch1 (29), Ch10 (8), Ch6 (3), Ch9 (2). Ch5 uses named colours only and is excluded by your standing instruction.

---

## Confirmed resolved since your last notes
- Ch8 now has eta-squared. The "ANOVA has zero effect-size content" gap is closed.
- `fig-5simdecision`'s figure and prose now use red for the rejection region, consistent with the rest of the book. Only the caption is stale (item 3 above).
- Ch9/Ch10/Ch11 hardcode no arithmetic at all: every reported number is computed inline from the data. That is the pattern that makes the earlier chapters' stale-number risk avoidable.

## Not checked
- Rendered PNG inspection for binning/aliasing artifacts. One candidate: `fig-4unifmany` in Ch3 histograms the means of 20 discrete values (which step by exactly 0.05) using the default 30 bins, the same aliasing pattern you have hit before.
- Ch5's figures and colours, per your standing instruction not to touch them.
- The three `outofbook-*` chapters and `Gifs.qmd`, which are not in the book's chapter list.


---

# Post-fix status (2026-08-17)

## Fixed

**Ch1** malformed `\sum x_{{i}-a}` subscript; Anscombe table now rounds to 2 dp and carries a `cor_xy` column, with prose reworded to "rounded to two decimals" plus a note on why they differ beyond that; deprecated `element_rect(size=)` to `linewidth`; weighted-mean forward reference to Ch8 removed and replaced with a general "average of averages" closing (per your call, Ch8 unchanged).

**Ch2** slope denominator `7*275` corrected to `7*200`; `slope`/`intercept` assignments in chunk `3morcov` un-swapped; "blue lines" corrected to red; `fig-3corwithLine`'s "with confidence bands" removed; lottery draws changed from `round(runif())` to `sample(1:10, replace=TRUE)` in all three places; new paragraph explaining the /N vs n-1 convention and that the factor cancels in Pearson's r.

**Ch3** rules-of-probability table cut; replaced with a "Two rules that matter later" section covering conditional probability and independence in prose, with the multiplication rule kept in words rather than set notation; summary bullet updated to match; CLT "fact 1" re-attributed from LLN to unbiasedness; the "Key points" n-1 bullet reconciled with the careful statement above it; `round(runif())` to `sample()`; the sd-bias simulation's population mismatch fixed in the prose (see note below).

**Ch4** the backwards `fig-5simdecision` caption rewritten to match the figure and the body prose, with the nonexistent "green" removed; `fig-5randtest` caption reconciled with the prose on dot colours; three `round(runif())` calls converted to `sample()`, making the chapter internally consistent; `fig-5whichoneB`/`C`'s normal panel clamped to 1-10 so the shared facet bins line up with the axis breaks.

**Ch5** power-curve SE corrected from `sqrt(sd_AB/n + sd_AB/n)` to `sd_AB^2/n` in both curves; the "Larger n" and "Smaller alpha" chunks now `echo=TRUE` so the reader can see what changed rather than watching a bare number appear.

**Ch6** all seven base-R `hist()` calls converted to two ggplot helpers (`hist_t`, `hist_p`) so the five simulation figures match the book's look and carry real axis labels; the p-value helper uses breaks of 0.05, which makes the "0-.05 is as likely as .90-.95" claim directly readable off the figure; the bogus `# Welch one-sample t` comment removed; raw `t.test()` output kept (per your call) with a sentence framing it as the deliberate exception and the comments rewritten to point at the comparison.

**Ch8/Ch10** Ch8's eta-squared now computed as `ss_between / ss_total`, and Ch10 gained a short paragraph explaining that in a one-way ANOVA there are no other factors to set aside, so eta-squared and partial eta-squared coincide, and they only diverge once a design has more than one factor. That closes the "same formula, two names" collision.

## A judgment call worth knowing about

I first fixed Ch3's sd-bias simulation by making it sample the actual 21-even-number population the narrative describes. It was correct and the pedagogical pattern held, but the n=3 panels came out comb-like, because sample SDs from a 21-value discrete population take a limited set of values and alias against the bins. That artifact distracted from the point of the figure. I reverted to the normal-population simulation and fixed the **prose** instead: it now says plainly that the simulation draws from a normal population with the same mu and sigma so the histograms read cleanly, and that the bias is a general property rather than a quirk of one population.

## OPEN (deliberately not done)

- **Non-palette colour literals**: now 42, down from ~50. Ch1 (29), Ch10 (8), Ch6 (3), Ch9 (2). Still deferred per your standing instruction; Ch5 excluded entirely.
- **~30 figures defined but never `@fig-` referenced**, largest cluster the five `fig-10outbreak*` in Ch9. On a closer read these are lower priority than I first rated them: the prose flows into each figure naturally ("the residuals-versus-fitted plot tells a different story") and the figure sits right there. Converting them to explicit cross-references would tighten discipline but means touching prose you have already style-passed.
- **Teaching-code hygiene**: `x <- length(0)` used as vector preallocation (7+ places, Ch2-Ch3-Ch6), and `sample <- rnorm(...)` / `c <- ggplot(...)` shadowing base R functions in Ch3. All harmless at runtime, all bad habits to model in code students copy.
- **Ch4's NO2 data are laid out wide** (20 rows, near/far columns), which reads as paired, while the analysis is an independent-groups randomization test. Restructuring means rewriting the table and three chunks around it.
- **Ch5 power curves are computed with `qnorm`/`pnorm` but captioned as t-test power.** The SE bug is fixed; this remains. At n=10 the z-approximation gives 0.20 where exact t-based power is 0.18, and "about 380 per group" is 394 exactly. Small, but the captions do say t-test.
