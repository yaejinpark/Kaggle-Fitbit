install.packages('tidyverse')
# install.packages('skimr')
# install.packages('janitor')

library(tidyverse)
library(ggplot2)

# Read the CSV created from BigQuery
weightdiff_predicted_actual <- read.csv("data/created/weightdiff_pred_actual_merged.csv")

# Change the Id column to string so that it's not shown in scientific notation
weightdiff_predicted_actual$Id <- as.character(weightdiff_predicted_actual$Id)

# Creating a list to add manual legend
data_colors <- c('Predicted'='#ff05dd', 'Actual'='#34aaff')

# Create a scatter plot with users' predicted and actual weight differences
ggplot(weightdiff_predicted_actual, aes(x=Id)) +
  geom_segment(aes(x=Id, xend=Id, y=weightloss_pred_lb, yend=weight_diff_lb)) +
  geom_point(aes(y=weightloss_pred_lb, color='Predicted'),size=5) + 
  geom_point(aes(y=weight_diff_lb, color = 'Actual'),size=5) +
  geom_hline(yintercept=0, linetype="dashed", color = "red") +
  ggtitle("Predicted Weight Change and Actual Weight Change of Users") + 
  theme(plot.title=element_text(hjust=0.5)) +
  labs(x="User Id", y="Weight (lb)", color="Data Type") + 
  scale_color_manual(values=data_colors)

# Save the scatter plot
ggsave("img/Users' Predicted vs Actual Weight Change.jpg")

# Show how much healthy hours of sleep users are getting
sleep <- read.csv("data/created/users_sleep_healthy.csv")

# Clean the sleep data so that rows with 0 are omitted
cleaned_sleep <- filter(sleep, 
                        avg_asleep_minutes != 0, 
                        avg_time_in_bed != 0,
                        avg_time_in_bed_awake != 0)

# Change User Id type from integer to string
cleaned_sleep$Id <- as.character(cleaned_sleep$Id)

# Create a bar plot that shows % of healthy sleep each user got
cleaned_sleep %>%
  ggplot2::ggplot(aes(x=Id,y=percent_healthy_sleep,fill=percent_healthy_sleep >= 75)) + 
    geom_bar(stat='identity') +
    geom_hline(yintercept=75, linetype="dashed", color = "red") +
    theme(axis.text.x=element_text(angle=60,vjust=0.5)) +
    scale_fill_manual(values = c('#34aaff','#ff05dd'), labels=c('T'='>=75','F'='<75')) + 
    scale_y_continuous(expand=c(0,0), limits=c(0,90)) +
    ggtitle("% Healthy Sleep of All Sleep Records for Each User") +
    theme(plot.title = element_text(hjust=0.5)) + 
    labs(x="User Id", y="% Healthy Sleep",fill='Healthy Sleep >= 75%')

# Save the bar plot
ggsave("img/Healthy Sleep Percentage for Each User.jpg")

# Average time in bed awake vs percent healthy sleep?
ggplot(data=sleep,aes(x=percent_healthy_sleep,y=avg_time_in_bed_awake)) + 
  geom_point(size=3) +
  scale_y_continuous(expand=c(0,0), limits=c(0,330)) +
  ggtitle("Average Time in Bed Awake vs. % Healthy Sleep (Pre-Cleaning)") +
  theme(plot.title = element_text(hjust=0.5)) + 
  labs(x="Minutes",y="% Healthy Sleep")

# Save the scatter plot
ggsave("img/Avg Time Awake in Bed and Healthy Sleep Percentage.jpg")

# Average time asleep vs percent healthy sleep?
ggplot(data=sleep,aes(x=avg_asleep_minutes,y=percent_healthy_sleep)) + 
  geom_point(size=3) +
  scale_y_continuous(expand=c(0,0), limits=c(0,100)) +
  ggtitle("Average Time Asleep vs. % Healthy Sleep (Pre-Cleaning)") +
  theme(plot.title = element_text(hjust=0.5)) + 
  labs(x="Minutes",y="% Healthy Sleep")

# Save the scatter plot
ggsave("img/Avg Time Asleep and Healthy Sleep Percentage.jpg")

# TODO: Create two scatter plots from above without outliers