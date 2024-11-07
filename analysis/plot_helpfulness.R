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

# Plot 1 (Helpfulness ratings): ================================================

likert <- data %>%
  dplyr::select(matches("^Q(100|[1-9][0-9]?)_(SN|Alt)$")) %>%
  pivot_longer(cols = everything(), 
               names_to = "question", 
               values_to = "value") %>%
  filter(!is.na(value) & value != "") %>%
  mutate(type = ifelse(grepl("_SN$", question), "SN", "Alt")) %>%
  dplyr::select(value, type) %>%
  
  mutate(type = case_when(
    type == 'SN' ~ 'Supernote',
    type == 'Alt' ~ 'Best existing note',
    TRUE ~ type
  )) %>%
  
  mutate(value = case_when(
    value == '1' ~ 'Not helpful',
    value == '2' ~ 'Somewhat helpful',
    value == '3' ~ 'Helpful',
    TRUE ~ value
  ))

levels_helpfulness <- c("Not helpful", "Somewhat helpful", "Helpful")
likert$value <- factor(likert$value, levels = levels_helpfulness)
likert  <- likert  %>% 
  rename("Is this note helpful?" = value) # rename col for plot
likert$type <- factor(likert$type)
likert <- as.data.frame(likert) # likert package needs a df


likert_plot <- plot(likert(likert[,1, drop=FALSE], grouping = likert[,2]), plot.percent.low = FALSE, plot.percent.high = FALSE, 
                    plot.percent.neutral = FALSE, include.center=TRUE, legend.position = "bottom", center=2) +
  scale_fill_manual(values = c("Not helpful" = "#8E1322", "Somewhat helpful" = "#f0f0f0", "Helpful" = "#1C5A7E")) +
  guides(fill = guide_legend(title = "", reverse = TRUE)) +
  theme(text = element_text(size = 56, face='bold'), 
        axis.text.y = element_text(size = 56, face='plain'),
        axis.text.x = element_text(size = 56, face='plain'),
        plot.title = element_text(color = "white", face='plain'),
        panel.border = element_blank(),
        panel.grid.major = element_line(color = "lightgray", linetype='dashed', size = 0.25))+
  ylab("% of response") +
  xlab("") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "black", size = 0.5) +
  ylim(-80,80) 

new_df <- data %>%
  dplyr::select(matches("^Q(100|[1-9][0-9]?)_(SN|Alt)$")) %>%
  pivot_longer(cols = everything(), 
               names_to = "QID", 
               values_to = "value") %>%
  
  filter(!is.na(value) & value != "") %>%
  
  mutate(value = case_when(
    value == 1 ~ 0,
    value == 2 ~ 0.5,
    value == 3 ~ 1
  ),
  
  type = case_when(
    grepl("_SN$", QID) ~ "Supernote",
    grepl("_Alt$", QID) ~ "Best existing note"
  )) %>%
  
  group_by(QID, type) %>%
  summarise(helpfulness = mean(value, na.rm = TRUE)) %>%
  ungroup()

means_ci <- new_df %>%
  group_by(type) %>%
  summarise(mean_helpfulness = mean(helpfulness),
            ci_data = list(gaussian_mean_95_ci(helpfulness))) %>%
  unnest(ci_data)

means_ci$type <- factor(means_ci$type, levels = c("Best existing note", "Supernote"))

helpfulness_plot <- ggplot(means_ci, aes(x = mean_helpfulness, y = type, color = type)) +
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
  scale_x_continuous(breaks = c(0, 0.25, 0.5, 0.75, 1), labels = c("0 \n Not helpful", "" , "0.5 \n Somewhat helpful", "", "1 \n Helpful"), limits = c(0, 1)) +
  geom_vline(xintercept = 0.5, linetype = "dashed") +
  ylab("") +
  xlab("Helpfulness score")

combined_plot <- plot_grid(likert_plot, helpfulness_plot, ncol = 1, align = "v", rel_heights = c(1.4, 1), labels=c("A", "B"))
combined_plot
ggsave(filename = "generated_plots/results_helpfulness.eps", plot = combined_plot, device = "eps", width = 33, height = 14, units = "in")
