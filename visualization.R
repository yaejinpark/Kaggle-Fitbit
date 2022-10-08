install.packages('tidyverse')
install.packages('gridExtra')

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

# Average time in bed awake vs % healthy sleep as a scatter plot
ggplot(data=sleep,aes(x=percent_healthy_sleep,y=avg_time_in_bed_awake)) + 
  geom_point(size=3) +
  scale_y_continuous(expand=c(0,0), limits=c(0,330)) +
  ggtitle("Average Time in Bed Awake vs. % Healthy Sleep (Pre-Cleaning)") +
  theme(plot.title = element_text(hjust=0.5)) + 
  labs(x="% Healthy Sleep",y="Minutes")

# Remove the outliers seen in the plot
awake_phs_clean <- sleep[sleep$avg_time_in_bed_awake < 100,]

# Function for getting a trendline's equation
lm_eqn <- function(x,y){
  m <- lm(y ~ x);
  eq <- substitute(italic(y) == a + b %.% italic(x)*","~~italic(r)^2~"="~r2, 
                   list(a = format(unname(coef(m)[1]), digits = 2),
                        b = format(unname(coef(m)[2]), digits = 2),
                        r2 = format(summary(m)$r.squared, digits = 3)))
  as.character(as.expression(eq));
}

# % healthy sleep vs Average time in bed awake after cleaning
ggplot(data=awake_phs_clean,aes(x=percent_healthy_sleep,y=avg_time_in_bed_awake)) + 
  geom_point(size=3) +
  scale_y_continuous(expand=c(0,0), limits=c(0,60)) +
  ggtitle("Average Time in Bed Awake vs. % Healthy Sleep") +
  theme(plot.title = element_text(hjust=0.5)) + 
  labs(x="% Healthy Sleep",y="Minutes") +
  geom_smooth(method=lm, formula=y~x) + 
  geom_text(x=40, 
            y=55, 
            label=lm_eqn(awake_phs_clean$percent_healthy_sleep,
                         awake_phs_clean$avg_time_in_bed_awake), parse=TRUE)

# Save the scatter plot
ggsave("img/Avg Time Awake in Bed and Healthy Sleep Percentage.jpg")

# Average time asleep vs % healthy sleep 
ggplot(data=sleep,aes(x=avg_asleep_minutes,y=percent_healthy_sleep)) + 
  geom_point(size=3) +
  scale_y_continuous(expand=c(0,0), limits=c(0,100)) +
  ggtitle("Average Time Asleep vs. % Healthy Sleep (Pre-Cleaning)") +
  theme(plot.title = element_text(hjust=0.5)) + 
  labs(x="% Healthy Sleep",y="Minutes")

# Average time asleep vs % healthy sleep after cleaning
ggplot(data=awake_phs_clean,aes(x=avg_asleep_minutes,y=percent_healthy_sleep)) + 
  geom_point(size=3) +
  coord_cartesian(ylim=c(0,100)) +
  #scale_y_continuous(expand=c(0,0),limits=c(0,100)) + # Rows are omitted, use coord_cartesian instead
  ggtitle("Average Time Asleep vs. % Healthy Sleep") +
  theme(plot.title = element_text(hjust=0.5)) + 
  labs(x="Minutes",y="% Healthy Sleep") +
  geom_smooth(method=lm, formula=y~x) + 
  geom_text(x=300, 
            y=90, 
            label=lm_eqn(awake_phs_clean$avg_asleep_minutes,
                         awake_phs_clean$percent_healthy_sleep), parse=TRUE)

# Save the scatter plot
ggsave("img/Avg Time Asleep and Healthy Sleep Percentage.jpg")

# Scatter plot for Sedentary Minutes vs. Asleep Minutes
sedentary_asleep <- read.csv("data/created/sedentary_vs_asleep.csv")
ggplot(data=sedentary_asleep,aes(x=asleep_minutes,y=sedentary_minutes)) +
  geom_point(size=3) + 
  scale_y_continuous(expand=c(0,0),limit=c(500,1400)) +
  ggtitle("Avg. Asleep Minutes vs. Avg. Sedentary Minutes (Per User)") +
  theme(plot.title = element_text(hjust=0.5)) +
  labs(x="Minutes (Asleep)",y="Minutes (Sedentary)") +
  geom_smooth(method=lm, formula=y~x) + 
  geom_text(x=150,
            y=625,
            label=lm_eqn(sedentary_asleep$asleep_minutes,
                         sedentary_asleep$sedentary_minutes), parse=TRUE)

# Save the scatter plot
ggsave("img/Avg Time Asleep and Avg Time Sedentary.jpg")

######################## Combining Plots into One Image (Sleep Analysis)
library(gridExtra)

sleep_p1 <- ggplot(data=sleep,aes(x=percent_healthy_sleep,y=avg_time_in_bed_awake)) + 
  geom_point(size=3) +
  scale_y_continuous(expand=c(0,0), limits=c(0,330)) +
  ggtitle("Average Time in Bed Awake vs. % Healthy Sleep (Pre-Cleaning)") +
  labs(x="% Healthy Sleep",y="Minutes")

sleep_p2 <- ggplot(data=awake_phs_clean,aes(x=percent_healthy_sleep,y=avg_time_in_bed_awake)) + 
  geom_point(size=3) +
  scale_y_continuous(expand=c(0,0), limits=c(0,60)) +
  ggtitle("Average Time in Bed Awake vs. % Healthy Sleep") +
  labs(x="% Healthy Sleep",y="Minutes") +
  geom_smooth(method=lm, formula=y~x) + 
  geom_text(x=40, 
            y=55, 
            label=lm_eqn(awake_phs_clean$percent_healthy_sleep,
                         awake_phs_clean$avg_time_in_bed_awake), parse=TRUE)

sleep_p3 <- ggplot(data=sleep,aes(x=avg_asleep_minutes,y=percent_healthy_sleep)) + 
  geom_point(size=3) +
  scale_y_continuous(expand=c(0,0), limits=c(0,100)) +
  ggtitle("Average Time Asleep vs. % Healthy Sleep (Pre-Cleaning)") +
  labs(x="% Healthy Sleep",y="Minutes")

sleep_p4 <- ggplot(data=awake_phs_clean,aes(x=avg_asleep_minutes,y=percent_healthy_sleep)) + 
  geom_point(size=3) +
  coord_cartesian(ylim=c(0,100)) +
  ggtitle("Average Time Asleep vs. % Healthy Sleep") +
  labs(x="Minutes",y="% Healthy Sleep") +
  geom_smooth(method=lm, formula=y~x) + 
  geom_text(x=300, 
            y=90, 
            label=lm_eqn(awake_phs_clean$avg_asleep_minutes,
                         awake_phs_clean$percent_healthy_sleep), parse=TRUE)

sleep_p5 <- ggplot(data=sedentary_asleep,aes(x=asleep_minutes,y=sedentary_minutes)) +
  geom_point(size=3) + 
  scale_y_continuous(expand=c(0,0),limit=c(500,1400)) +
  ggtitle("Avg. Asleep Minutes vs. Avg. Sedentary Minutes (Per User)") +
  labs(x="Minutes (Asleep)",y="Minutes (Sedentary)") +
  geom_smooth(method=lm, formula=y~x) + 
  geom_text(x=150,
            y=625,
            label=lm_eqn(sedentary_asleep$asleep_minutes,
                         sedentary_asleep$sedentary_minutes), parse=TRUE)

grid.arrange(sleep_p1,sleep_p2,sleep_p3,sleep_p4,nrow=2)
grid.arrange(sleep_p2,sleep_p4,sleep_p5,nrow=3)