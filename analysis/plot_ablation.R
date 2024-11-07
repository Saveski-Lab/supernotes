library(ggplot2)
library(dplyr)
library(tidyr)
library(tidyverse)
source("utils.R", echo=F)

data <- readRDS("data/combined_finalablation.rds")

same_set <- c(18,22,26,27,29,30,31,33,36,37,40)
diff_set <- c(1,2,3,4,6,7,9,10,12,13,14,15,17,20,23,25,32,35,39,5,8,11,16,19,21,24,28,34,38)

## same-set

question_columns <- paste0("Q", same_set, "_Win") # all Qs:1:40
question_columns <- append(question_columns,'ResponseId')

response_data_r <- data_r[, question_columns]
response_data_r <- response_data_r[-c(1, 2), ] # remove first 2 rows (metadata)

response_data_l <- data_l[, question_columns]
response_data_l <- response_data_l[-c(1, 2), ] # remove first 2 rows (metadata)

response_data <- rbind(response_data_l, response_data_r)

long_data <- response_data %>%
  gather(key = "Question", value = "Response",-ResponseId) %>%
  filter(Response != "") %>%
  na.omit()

overall_frequency <- long_data %>%
  group_by(Response) %>%
  summarise(Frequency = n())

question_frequency <- long_data %>%
  group_by(Question, Response) %>%
  summarise(Frequency = n()) %>%
  spread(key = "Response", value = "Frequency", fill = 0)

freq_of_1 <- overall_frequency %>%
  filter(Response == "1") %>%
  pull(Frequency)

freq_of_2 <- overall_frequency %>%
  filter(Response == "2") %>%
  pull(Frequency)

total_responses <- freq_of_1 + freq_of_2
ss_win_rate <- freq_of_1 / total_responses

responses <- long_data$Response
ss_ci <- bootstrap_winrate(responses)

ss_lower_bound <- as.numeric(ss_ci["2.5%"])
ss_upper_bound <- as.numeric(ss_ci["97.5%"])

## diff-set

question_columns <- paste0("Q", diff_set, "_Win") # all Qs:1:40
question_columns <- append(question_columns,'ResponseId')

response_data_r <- data_r[, question_columns]
response_data_r <- response_data_r[-c(1, 2), ] # remove first 2 rows (metadata)

response_data_l <- data_l[, question_columns]
response_data_l <- response_data_l[-c(1, 2), ] # remove first 2 rows (metadata)

response_data <- rbind(response_data_l, response_data_r)

long_data <- response_data %>%
  gather(key = "Question", value = "Response",-ResponseId) %>%
  filter(Response != "") %>%
  na.omit()

overall_frequency <- long_data %>%
  group_by(Response) %>%
  summarise(Frequency = n())

question_frequency <- long_data %>%
  group_by(Question, Response) %>%
  summarise(Frequency = n()) %>%
  spread(key = "Response", value = "Frequency", fill = 0)

freq_of_1 <- overall_frequency %>%
  filter(Response == "1") %>%
  pull(Frequency)

freq_of_2 <- overall_frequency %>%
  filter(Response == "2") %>%
  pull(Frequency)

total_responses <- freq_of_1 + freq_of_2
ds_win_rate <- freq_of_1 / total_responses

responses <- long_data$Response
ds_ci <- bootstrap_winrate(responses)

ds_lower_bound <- as.numeric(ds_ci["2.5%"])
ds_upper_bound <- as.numeric(ds_ci["97.5%"])

## overall

question_columns <- paste0("Q", 1:40, "_Win") # all Qs:1:40
question_columns <- append(question_columns,'ResponseId')

response_data_r <- data_r[, question_columns]
response_data_r <- response_data_r[-c(1, 2), ] # remove first 2 rows (metadata)

response_data_l <- data_l[, question_columns]
response_data_l <- response_data_l[-c(1, 2), ] # remove first 2 rows (metadata)

response_data <- rbind(response_data_l, response_data_r)

long_data <- response_data %>%
  gather(key = "Question", value = "Response",-ResponseId) %>%
  filter(Response != "") %>%
  na.omit()

overall_frequency <- long_data %>%
  group_by(Response) %>%
  summarise(Frequency = n())

question_frequency <- long_data %>%
  group_by(Question, Response) %>%
  summarise(Frequency = n()) %>%
  spread(key = "Response", value = "Frequency", fill = 0)

freq_of_1 <- overall_frequency %>%
  filter(Response == "1") %>%
  pull(Frequency)

freq_of_2 <- overall_frequency %>%
  filter(Response == "2") %>%
  pull(Frequency)

total_responses <- freq_of_1 + freq_of_2
all_win_rate <- freq_of_1 / total_responses

responses <- long_data$Response
all_ci <- bootstrap_winrate(responses)

all_lower_bound <- as.numeric(all_ci["2.5%"])
all_upper_bound <- as.numeric(all_ci["97.5%"])

abl_means_ci <- data.frame(
  type = c("Overall", "Different Set", "Same Set"),
  mean_helpfulness = c(all_win_rate, ds_win_rate, ss_win_rate),
  lower_ci = c(all_lower_bound, ds_lower_bound, ss_lower_bound),
  upper_ci = c(all_upper_bound, ds_upper_bound, ss_upper_bound)
)

abl_means_ci$type <- factor(abl_means_ci$type, levels = c( "Different Set", "Same Set","Overall"))

# Plot
abl_winrates_plot <- ggplot(abl_means_ci, aes(x = mean_helpfulness, y = type, color = type)) +
  geom_errorbarh(aes(xmin = lower_ci, xmax = upper_ci), height = 0.0, size = 6, lineend = "round", color = "lightgray") +
  geom_point(size = 15) +
  scale_color_manual(values = c("Overall" = "black", "Different Count" = "black", "Different Set" = "black", "Same Set" = "black")) +
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
    breaks = c(0, 0.25, 0.5, 0.75),
    labels = c("0%","25%", "50% \n (Tie)", "75%"),
    limits = c(0, 0.75)
  ) +
  geom_vline(xintercept = 0.5, linetype = "dashed") +
  ylab("") +
  xlab("%(supernote rated more helpful than an LLM summary)")

abl_winrates_plot
ggsave(filename = "generated_plots/results_ablation.eps", plot = abl_winrates_plot, device = "eps", width = 28, height = 6.75, units = "in")
