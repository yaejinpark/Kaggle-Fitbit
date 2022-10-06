install.packages('tidyverse')
install.packages('reshape2')
# install.packages('skimr')
# install.packages('janitor')

library(tidyverse)
library(ggplot2)
library(reshape2)

# Read the CSV created from BigQuery
weightdiff_predicted_actual <- read.csv("data/created/weightdiff_pred_actual_merged.csv")

# Change the Id column to string so that it's not shown in scientific notation
weightdiff_predicted_actual$Id <- as.character(weightdiff_predicted_actual$Id)

# Creating a list to add manual legend
data_colors <- c('Predicted'='#ff05dd', 'Actual'='#34aaff')

# Create a scatter plot with users' predicted and actual weight differences
ggplot(weightdiff_predicted_actual, aes(x=Id)) +
  geom_segment(aes(x=Id, xend=Id, y = weightloss_pred_lb, yend = weight_diff_lb)) +
  geom_point(aes(y=weightloss_pred_lb, color='Predicted'),size=5) + 
  geom_point(aes(y=weight_diff_lb, color = 'Actual'),size=5) +
  geom_hline(yintercept=0, linetype="dashed", color = "red") +
  ggtitle("Predicted Weight Change and Actual Weight Change of Users") + 
  theme(plot.title = element_text(hjust = 0.5)) +
  labs(x = "User Id", y="Weight (lb)", color="Data Type") + 
  scale_color_manual(values=data_colors)

# Save the scatter plot
ggsave("Users' Predicted vs Actual Weight Change.jpg")

# Show how much healthy hours of sleep users are getting
sleep <- read.csv("data/created/users_sleep_healthy.csv")

# Clean the sleep data so that rows with 0 are omitted
cleaned_sleep <- filter(sleep, 
                        avg_asleep_minutes != 0, 
                        avg_time_in_bed != 0,
                        avg_time_in_bed_awake != 0,
                        percent_healthy_sleep != 0)
ggplot(data=cleaned_sleep, aes(x=Id,y=percent_healthy_sleep)) + geom_bar(stat='identity',fill='green')
