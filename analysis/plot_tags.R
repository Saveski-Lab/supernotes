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

# Plot 4 (Tags): ================================================

new_tag_df <- data %>%
  pivot_longer(
    cols = matches("^Q(100|[1-9][0-9]?)_(SN|Alt)_tags_[1-5]$"), 
    names_to = c("Q", "type", "tag"), 
    names_pattern = "Q([0-9]+)_(SN|Alt)_tags_([1-5])", 
    values_to = "value"  
  ) %>%
  mutate(
    type = case_when(
      type == "SN" ~ "Supernote",
      type == "Alt" ~ "Existing note"
    ),
    tag = as.integer(tag)  
  ) %>%
  
  pivot_wider(
    names_from = tag,  
    values_from = value,  
    names_prefix = "tag"  
  ) %>%
  
  filter(!is.na(tag1) | !is.na(tag2) | !is.na(tag3) | !is.na(tag4) | !is.na(tag5)) 

new_tag_df <- new_tag_df %>%
  mutate(across(c(tag1, tag2, tag3, tag4, tag5), ~ na_if(trimws(.), "")))

subset_tag_df <- new_tag_df %>%
  dplyr::select(type, tag1, tag2, tag3, tag4, tag5) %>%
  filter(if_any(c(tag1, tag2, tag3, tag4, tag5), ~ !is.na(.)))

tag_mapping <- c(
  '6' = 'Strongly disagree',
  '7' = 'Disagree',
  '8' = 'Neutral',
  '9' = 'Agree',
  '10' = 'Strongly agree'
)
mapped_df <- subset_tag_df %>%
  mutate(
    quality = case_when(
      tag1 == '6' ~ 'Strongly disagree',
      tag1 == '7' ~ 'Disagree',
      tag1 == '8' ~ 'Neutral',
      tag1 == '9' ~ 'Agree',
      tag1 == '10' ~ 'Strongly agree'
    ),
    clarity = case_when(
      tag2 == '6' ~ 'Strongly disagree',
      tag2 == '7' ~ 'Disagree',
      tag2 == '8' ~ 'Neutral',
      tag2 == '9' ~ 'Agree',
      tag2 == '10' ~ 'Strongly agree'
    ),
    key = case_when(
      tag3 == '6' ~ 'Strongly disagree',
      tag3 == '7' ~ 'Disagree',
      tag3 == '8' ~ 'Neutral',
      tag3 == '9' ~ 'Agree',
      tag3 == '10' ~ 'Strongly agree'
    ),
    context = case_when(
      tag4 == '6' ~ 'Strongly disagree',
      tag4 == '7' ~ 'Disagree',
      tag4 == '8' ~ 'Neutral',
      tag4 == '9' ~ 'Agree',
      tag4 == '10' ~ 'Strongly agree'
    ),
    argumentative = case_when(
      tag5 == '6' ~ 'Strongly disagree',
      tag5 == '7' ~ 'Disagree',
      tag5 == '8' ~ 'Neutral',
      tag5 == '9' ~ 'Agree',
      tag5 == '10' ~ 'Strongly agree'
    )
  ) 

df <- mapped_df

df$quality <- factor(df$quality, levels = c("Strongly disagree", "Disagree", "Neutral", "Agree", "Strongly agree"))
df$clarity <- factor(df$clarity, levels = c("Strongly disagree", "Disagree", "Neutral", "Agree", "Strongly agree"))
df$key <- factor(df$key, levels = c("Strongly disagree", "Disagree", "Neutral", "Agree", "Strongly agree"))
df$context <- factor(df$context, levels = c("Strongly disagree", "Disagree", "Neutral", "Agree", "Strongly agree"))
df$argumentative <- factor(df$argumentative, levels = c("Strongly disagree", "Disagree", "Neutral", "Agree", "Strongly agree"))

df$type <- factor(ifelse(df$type == "Existing note", "Best existing note", df$type),
                  levels = c("Supernote", "Best existing note"))

df  <- df  %>% 
  rename("Sources on note are high-quality and relevant" = quality,
         "Note is written in clear language" = clarity,
         "Note addresses all key claims in the post" = key,
         "Note provides important context" = context,
         "Note is argumentative, speculative or biased" = argumentative,)

df <- as.data.frame(df) 

tag_plot <- plot(likert(df[,c(7:11)], grouping = df[,1]), plot.percent.low = FALSE, plot.percent.high = FALSE, plot.percent.neutral = FALSE, legend.position="bottom") +
  scale_fill_manual(values = brewer.pal(n=5,"RdBu"), breaks = c("Strongly disagree", "Disagree", "Neutral", "Agree", "Strongly agree")) +
  guides(fill = guide_legend(title="",reverse = FALSE)) +
  theme(text = element_text(size = 56, face='bold'),
        axis.text.y = element_text(size = 56, face='plain'),
        axis.text.x = element_text(size = 56, face='plain'),
        panel.border = element_blank(),
        panel.grid.major = element_line(color = "lightgray", linetype='dashed', size = 0.25))+
  ylab("") +
  xlab("") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "black", size = 0.5)

tag_plot
ggsave(filename = "~/Desktop/results_tags.eps", plot = tag_plot, device = "eps", width = 28, height = 18, units = "in")


