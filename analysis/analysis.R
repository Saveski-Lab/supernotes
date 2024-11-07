library(dplyr)
library(ggplot2)
library(likert)
library(lme4)
library(coin)
source("utils.R", echo=F)

# Load the data

data <- readRDS("data/combined_finalsurvey.rds")
duration_minutes <- as.numeric(data$`Duration..in.seconds.`) / 60
mean(duration_minutes) # 30.73
median(duration_minutes) # 25.55

# Section 4.2 (Helpfulness Ratings)

likert_num <- data %>%
  dplyr::select(ResponseId, matches("^Q(100|[1-9][0-9]?)_(SN|Alt)$")) %>%
  pivot_longer(cols = -ResponseId,
               names_to = c("Question", "type"),
               names_pattern = "(Q[0-9]+)_(SN|Alt)",
               values_to = "value") %>%
  pivot_wider(names_from = type, values_from = value) %>%
  dplyr::select(ResponseId, Question, SN, Alt) %>%
  filter(SN != "" & Alt != "") %>%
  mutate(SN = as.numeric(SN),
         Alt = as.numeric(Alt))

wilcox_test <- wilcoxsign_test(SN ~ Alt, data = likert_num,  zero.method = "Pratt")
print(wilcox_test) # p < 0.001

long_df <- data %>%
  dplyr::select(ResponseId, matches("^Q(100|[1-9][0-9]?)_(SN|Alt)$")) %>%
  pivot_longer(cols = -ResponseId,
               names_to = c("tweetId", "type"),
               names_pattern = "Q(\\d+)_(SN|Alt)",
               values_to = "rating") %>% 
  
  rename(userId = ResponseId) %>%
  mutate(userId = as.integer(factor(userId))) %>%
  mutate(type = ifelse(type == "SN", 1, 0)) %>%
  mutate(rating = case_when(
    rating == 1 ~ 0,
    rating == 2 ~ 0.5,
    rating == 3 ~ 1.0
  )) %>%
  
  mutate(tweetId = as.integer(tweetId)) %>%
  filter(!is.na(rating) & rating != "")

long_df$type = factor(long_df$type)

model <- lmer(rating ~ type + (1 | userId) + (1 | tweetId), data = long_df)

res = residuals(model)
summary(model)

group1 <- long_df[long_df$type == 1, ]$rating 
group2 <- long_df[long_df$type == 0, ]$rating

t_test_result <- t.test(group1, group2, paired=TRUE)
print(t_test_result) # p < 0.001

# Section 4.2 (Helpfulness Win Rates)

win_df <- data %>%
  dplyr::select(ResponseId, matches("^Q(100|[1-9][0-9]?)_Win$")) %>%
  pivot_longer(cols = -ResponseId,
               names_to = c("tweetId"),
               names_pattern = "Q(\\d+)_Win",
               values_to = "rating") %>%
  
  rename(userId = ResponseId) %>%
  mutate(userId = as.integer(factor(userId))) %>%
  mutate(rating = case_when(
    rating == "1" ~ 1,
    rating == "2" ~ 0,
    rating == "3" ~ 0.5,
    TRUE ~ NA_real_ 
  )) %>%
  
  mutate(tweetId = as.integer(tweetId)) %>%
  filter(!is.na(rating))

lm <- lm(rating ~ 1, data=win_df)
lmer <- lmer(rating ~ 1 + (1 | userId) + (1 | tweetId), data=win_df)
summary(lmer)

# Section 4.2 (Community Notes Helpfulness Score)

cn_scores <- read.csv("data/survey_notes_with_scores.csv")
cn_data <- cn_scores %>% filter(type == 1)
alt_data <- cn_scores %>% filter(type == 0)

group_1 <- cn_data$internalNoteIntercept
group_2 <- alt_data$internalNoteIntercept
t_test_result <- t.test(group_1, group_2, paired=TRUE)
print(t_test_result) # p < 0.001

# Section 4.2 (Note Characteristics)

tag_num <- data %>%
  dplyr::select(ResponseId, matches("^Q(100|[1-9][0-9]?)_(SN|Alt)_tags_[1-5]$")) %>%
  pivot_longer(
    cols = -ResponseId,
    names_to = c("Question", "type", "tagId"),
    names_pattern = "(Q[0-9]+)_(SN|Alt)_tags_([1-5])",
    values_to = "value"
  ) %>%
  pivot_wider(names_from = type, values_from = value) %>%
  dplyr::select(ResponseId, Question, tagId, SN, Alt) %>%
  filter(SN != "" & Alt != "") %>%
  mutate(
    SN = as.numeric(SN),
    Alt = as.numeric(Alt),
    tagId = as.numeric(tagId)
  )

wilcox_test <- wilcoxsign_test(SN ~ Alt, data = tag_num,  zero.method = "Pratt")
print(wilcox_test) # p < 0.001


# Section 4.3 (Ablation)

data <- readRDS("data/combined_finalablation_analysis.rds")
lmer_fc <- lmer(Response ~ 1 + (1 | QID) + (1 | ResponseId), data=data)
summary(lmer_fc, ci.force = T)

