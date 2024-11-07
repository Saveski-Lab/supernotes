library(ggplot2)
library(dplyr)
source("utils.R", echo=F)

data <- read.csv("data/survey_notes_with_scores.csv")
cn_data <- data %>% filter(type == 1)
alt_data <- data %>% filter(type == 0)

response_1 <- cn_data$internalNoteIntercept
response_2 <- alt_data$internalNoteIntercept
response_1_desc_stats <- gaussian_mean_95_ci(response_1)
response_2_desc_stats <- gaussian_mean_95_ci(response_2)

means_ci <- data.frame(
  type = c("Supernote", "Best existing note"),
  mean_helpfulness = c(response_1_desc_stats$mean, response_2_desc_stats$mean),
  lower_ci = c(response_1_desc_stats$lower_ci, response_2_desc_stats$lower_ci),
  upper_ci = c(response_1_desc_stats$upper_ci, response_2_desc_stats$upper_ci)
)

cnscores_plot <- ggplot(means_ci, aes(x = mean_helpfulness, y = type, color = type)) +
  geom_errorbarh(aes(xmin = lower_ci, xmax = upper_ci), height = 0.0, size = 6, lineend = "round", color = "grey") +
  geom_point(size = 15) +
  scale_color_manual(values = c("Supernote" = "black", "Best existing note" = "black")) +
  theme(
    legend.position = "none",
    plot.title = element_text(size = 56, face='bold'),
    axis.text.y = element_text(size = 56),
    axis.text.x = element_text(size = 56),
    axis.title.x = element_text(size = 56, face='bold'),
    panel.background = element_rect(fill = "white"),  # White background
    panel.grid.major = element_line(color = "lightgray", linetype='dashed'),  # Major grid lines
    panel.border = element_rect(color = "gray", fill = NA, size = 1)  # Border around the plot
    
  ) +
  scale_x_continuous(
    breaks = c(0.0, 0.1, 0.2, 0.3),
    labels = c("0.0","0.1", "0.2", "0.3"),
    limits = c(0, 0.4)
  ) +
  #geom_vline(xintercept = 0.4, linetype = "dashed") +
  ylab("") +
  xlab("Community Notes Helpfulness Score")

cnscores_plot
ggsave(filename = "generated_plots/results_cnscores.eps", plot = cnscores_plot, device = "eps", width = 33, height = 14, units = "in")

