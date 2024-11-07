bootstrap_winrate <- function(data, num_bootstrap = 10000) {
  win_rates <- numeric(num_bootstrap)
  for (i in 1:num_bootstrap) {
    sample_data <- sample(data, replace = TRUE)
    freq_1 <- sum(sample_data == "1")
    total <- length(sample_data)
    win_rates[i] <- freq_1 / total
  }
  
  ci_lower <- quantile(win_rates, 0.025)
  ci_upper <- quantile(win_rates, 0.975)
  return(c(ci_lower, ci_upper))
}

gaussian_mean_95_ci <- function(sample) {
  n <- length(sample)
  sample_std <- sd(sample)
  ci_width <- 1.96 * sample_std / sqrt(n)
  mean_sample <- mean(sample)
  data.frame(mean = mean_sample, lower_ci = mean_sample - ci_width, upper_ci = mean_sample + ci_width)
}

binomial_95_ci <- function(p, n) {
  ci_width <- 1.96 * sqrt(p * (1 - p) / n)
  data.frame(mean = p, lower_ci = p - ci_width, upper_ci = p + ci_width)
}