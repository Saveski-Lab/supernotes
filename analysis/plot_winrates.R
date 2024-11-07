library(dplyr)
library(tidyr)
library(ggplot2)
library(likert)
library(RColorBrewer)
library(cowplot)
source("utils.R", echo=F)

# Load the data
data <- readRDS("data/combined_finalsurvey.rds")
duration_minutes <- as.numeric(data$`Duration..in.seconds.`) / 60
mean(duration_minutes) # 30.73
median(duration_minutes) # 25.55

# Plot 2 (Win rates): ================================================
long_data <- data %>%
  dplyr::select(ResponseId, matches("^Q(100|[1-9][0-9]?)_(Win|SN|Alt)$")) %>%
  pivot_longer(cols = -ResponseId,
               names_to = c("QID", "type"),
               names_sep = "_",
               values_to = "Response") %>%
  filter(!is.na(Response) & Response != "")

final_df <- long_data %>%
  pivot_wider(names_from = type, values_from = Response) %>%
  dplyr::rename(Win = Win, SN = SN, Alt = Alt) %>%
  dplyr::select(ResponseId, QID, Win, SN, Alt)

## both helpful
both_helpful_df <- final_df %>%
  filter(SN == "3" & Alt == "3")

overall_frequency <- both_helpful_df %>%
  group_by(Win) %>%
  summarise(Frequency = n())

freq_of_1 <- overall_frequency %>%
  filter(Win == "1") %>%
  pull(Frequency)

freq_of_2 <- overall_frequency %>%
  filter(Win == "2") %>%
  pull(Frequency)

total_responses <- freq_of_1 + freq_of_2
bh_win_rate <- freq_of_1 / total_responses

bh_responses <- both_helpful_df$Win
bh_ci <- bootstrap_winrate(bh_responses)
bh_lower_bound <- as.numeric(bh_ci["2.5%"])
bh_upper_bound <- as.numeric(bh_ci["97.5%"])

## overall
overall_frequency <- final_df %>%
  group_by(Win) %>%
  summarise(Frequency = n())

freq_of_1 <- overall_frequency %>%
  filter(Win == "1") %>%
  pull(Frequency)

freq_of_2 <- overall_frequency %>%
  filter(Win == "2") %>%
  pull(Frequency)

total_responses <- freq_of_1 + freq_of_2
all_win_rate <- freq_of_1 / total_responses

all_responses <- final_df$Win
all_ci <- bootstrap_winrate(all_responses)
all_lower_bound <- as.numeric(all_ci["2.5%"])
all_upper_bound <- as.numeric(all_ci["97.5%"])

means_ci <- data.frame(
  type = c("Overall", "Same \n helpfulness score"),
  mean_helpfulness = c(all_win_rate, bh_win_rate),
  lower_ci = c(all_lower_bound, bh_lower_bound),
  upper_ci = c(all_upper_bound, bh_upper_bound)
)

means_ci$type <- factor(means_ci$type, levels = c("Same \n helpfulness score", "Overall"))

winrates_plot <- ggplot(means_ci, aes(x = mean_helpfulness, y = type, color = type)) +
  geom_errorbarh(aes(xmin = lower_ci, xmax = upper_ci), height = 0.0, size = 6, lineend = "round", color = "grey") +
  geom_point(size = 15) +
  scale_color_manual(values = c("Overall" = "black", "Same \n helpfulness score" = "black")) +
  theme(
    legend.position = "none",
    plot.title = element_text(size = 56, face='bold'),
    axis.text.y = element_text(size = 56),
    axis.text.x = element_text(size = 56),
    axis.title.x = element_text(size = 56, face='bold'),
    panel.background = element_rect(fill = "white"), 
    panel.grid.major = element_line(color = "lightgray", linetype='dashed'),  
    panel.border = element_rect(color = "gray", fill = NA, size = 1) 
    
  ) +
  scale_x_continuous(
    breaks = c(0, 0.25, 0.5,0.75, 1),
    labels = c("0%", "", "50% \n(Tie)", "", "100%"),
    limits = c(0, 1)
  ) +
  geom_vline(xintercept = 0.5, linetype = "dashed") +
  ylab("") +
  xlab("%(supernote rated more helpful than best existing note)")

winrates_plot
ggsave(filename = "generated_plots/results_winrates.eps", plot = winrates_plot, device = "eps", width = 28, height = 5.5, units = "in")
