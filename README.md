# Kaggle Fitbit Data - Calories and Sleep Analysis for Bellabeat
Author: Jin Park\
Last Revised: November 14th, 2022

## Introduction
Health has been and still is one of civilization's biggest interest and concern as healthy people are the building blocks of a strong society. As such, many companies are formed to utilize modern technology to assist people with bettering themselves physically, and one of them is Fitbit. With [health data collected from 30+ users and published in Kaggle](https://www.kaggle.com/arashnic/fitbit), data analysts are provided a great opportunity to see how certain aspects of said health data (sleep, calories burnt, and much more) are related to each other or how the users' health habits are affecting them. 

This dataset can also provide an opportunity for health-related startups to explore potential opportunities that will allow them to create and design a product for their customers. In this case, a high-tech health startup focused on women's health known as [Bellabeat](https://bellabeat.com/) would like to know how it can help its customers by analyzing this data.

(Add Table of Contents here)

## Questions and Assumptions
This case study is broadly divided into two parts: Users' calories/weight change and users' sleep quality. 

### Questions Aimed to be Answered
1. Is there a trend between users' weight and the calories they are burning each day?
2. What is the relationship between users' time in bed and their sleep qualities?

### Hypotheses and Assumptions
#### Calories and Weight
* All users are women over 18 years old (though not noted in the dataset) since they are old enough to consent sharing of any personal data
* Weightloss happens based strictly on Calories In, Calories Out - that is, users are assumed to lose weight if they burn more calories than they consume. Age, medical history and etc. are not counted for simplicity's sake and due to limitations in the provided dataset
* Active users need to consume 2200 calories per day, moderately active ones 2000,sedantary users 1800 calories per day based on [Estimated Calorie Requirements](https://www.webmd.com/diet/features/estimated-calorie-requirement)
* If user walks more than 1.5-3 miles per day, they are moderately active. More than 3, they are active.

#### Sleep Quality
* [7-9 hours of sleep is considered healthy sleep](https://www.hopkinsmedicine.org/health/wellness-and-prevention/oversleeping-bad-for-your-health#:~:text=Sleep%20needs%20can%20vary%20from,an%20underlying%20problem%2C%20Polotsky%20says).

## Overview of Original Data Cleaned and Analyzed
There is an abundance of health data from the users uploaded in Kaggle, but there were several datasets that can be focused on and can play a key role in creating more datasets for further analysis. Here is the list of files used for this case study and their brief description:

* *dailyActivity_merged*: Actiity intensity information (sedentary, lightly active, fairly active, very active) and number of steps along with distance traveled by user on foot for each day
* *dailyCalories_merged*: Subset of *dailyActivity_merged*. Calculation of calories burnt by users on each day the users were wearing their Fitbit devices
* *dailyIntensities_merged*: Subset of *dailyActivity_merged*. Number of minutes for activity intensities and distance traveled for the same intensities for each users on each day
* *minuteSleep_merged*: Long table of data for users' sleep status every minute on each day
* *sleepDay_merged*: Number of sleep sessions each user had each day with total time users were in bed (not necessarily asleep) and their total time asleep
* *weightLogInfo_merged*: Weight information of users - either logged manually or automatically with smart scales

## Data Cleaning
Technologies utilized for data cleaning and analysis:
* Google Sheets
* BigQuery

### Cleaning - Google Sheets
**weightLogInfo_merged**
* Added a column of calculated users' heights in meters based on their weights (kg) and BMI
* Added a column of users' height in inches, converted from users' height in meters
* Changed Date column from AM/PM format to 24 hour format for the time portion

**sleepDay_merged**
* Changed the SleepDay column to show time in a 24 hour format since AM and PM for time notation causes isues when importing to BigQuery
* Added a column for time (minutes) users were awake in bed
* Added a column for time asleep conversion from minutes to hours
* Added a boolean column for healthy sleep for each row (7 to 9 hours) based on time asleep in hours

**minuteSleep_merged**
* Added a column for sleep state translated from values (1 = Asleep, 2 = Restless, 3 = Awake)
* Deleted logId column as it is not being used in this analysis
* Changed the date column so that time is shown in 24 hr format (for importing to BigQuery)

**dailyIntensities_merged**
* Added Total Distance calculation and Total Distance (miles) conversion

**calorieIntake_activeLevel (Manually Created)**
*I only realized that I spelled sedentary incorrectly after I was done with the visualizing process of this case study. Apologies.*

| ActiveLevel      | Calorie Intake |
| ----------- | ----------- |
| Sedantary      | 1800       |
| Moderate   | 2000        |
| Active      | 2200       |
Calorie intake assumptions were made based on [Estimated Calorie Requirements](https://www.webmd.com/diet/features/estimated-calorie-requirement)


### Cleaning - BigQuery: Calorie Data
*Please note that if you are to attempt in recreating my work, my queries' syntax may not work 100% for DBMS and may require minor adjustments. The queries are strictly for the BigQuery setup I have, as shown in the user_activities table in the image below.*

![BigQuery Settings](/img/bigquery-setup.png)

**active_levels**
The user's active status were found by finding the average of distance they traveled/were active for and grouped by userID

```SQL
SELECT Id,
  AVG(TotalDistanceMiles) as avg_distance,
  CASE 
    WHEN AVG(TotalDistanceMiles) < 1.5 THEN 'Sedantary'
    WHEN AVG(TotalDistanceMiles) >= 1.5 AND AVG(TotalDistanceMiles) < 3 THEN 'Moderate'
    ELSE 'Active'
  END AS ActiveLevel
FROM user_activities.daily_intensities
GROUP BY Id;
```
**user_weightdiff_prediction**
Based on the users' active levels, I assumed their calorie intakes will be one of the three depending on their activeness: 1800, 2000, or 2200. Sedentary users will consume the least (1800), and active users will consume the most (2200). I merged the *active_levels* table with *calorieIntake_activeLevel*.

```SQL
SELECT al.*, ci.CalorieIntake
FROM user_activities.active_levels as al
JOIN user_activities.calorie_intake as ci on al.ActiveLevel = ci.ActiveLevel
ORDER BY al.Id;
```
The resulting table (not the final user_weightdiff_prediction, but in process of getting said table) had the following schema:

| Id      | avg_distance |ActiveLevel|CalorieIntake|
| ----------- | ----------- | ----------- | ---------- |
| INTEGER      | FLOAT       | STRING | INTEGER
| 1503960366   | 4.8501013330322582 |Active | 2200|
| ... | ... | ... | ... |

With the *dailyCalories_merged* (part of given dataset), I merged it with the intermediate table after summing the total calories burnt and total calories consumed (assumption). The BigQuery code and the schema of the resulting *user_weightdiff_prediction* are the following:

```SQL
SELECT 
  dc.Id, SUM(dc.Calories) as total_calories_burnt, 
  SUM(uc.CalorieIntake) as total_calories_consumed,
  SUM(dc.Calories - uc.CalorieIntake) as calorie_deficit,
  SUM(dc.Calories - uc.CalorieIntake)/7700 as weightloss_pred_kg,
  SUM(dc.Calories - uc.CalorieIntake)/3500 as weightloss_pred_lb
FROM user_activities.daily_calories as dc
JOIN user_activities.user_calories as uc on dc.Id = uc.Id
GROUP BY dc.Id
ORDER BY dc.Id ASC;
```
| Id      | total_calories_burnt |total_calories_consumed|calorie_deficit|weightloss_pred_kg|weightloss_pred_lb|
| ----------- | ----------- | ----------- | ---------- | ----------- | ---------- |
| INTEGER      | INTEGER       | INTEGER | INTEGER|FLOAT|FLOAT
| 1624580081   | 45984 |62000 | -16016|-2.08|-4.576|
| ... | ... | ... | ... |...|...|...|

The calorie deficit is negative if it is predicted that the user's total calorie intake is bigger than total calories burnt.

**actual_weight_diff**
In order to see if the predictions are correct, I used the given data in *weightLogInfo_merged* to find each user's first and last weigh-in and the weight difference between those two dates. This task was done by running the following BigQuery code:

```SQL
SELECT 
  Id,
  MIN(Date) as first_weigh_in,
  MAX(Date) as last_weigh_in,
  MAX(WeightKg) - MIN(WeightKg) as weight_diff_kg,
  MAX(WeightPounds) - MIN(WeightPounds) as weight_diff_lb
FROM user_activities.weight_info
GROUP BY Id;
```
**weightdiff_pred_actual_merged**
After finding the actual weight differences users recorded in their system, I merged the *user_weightdiff_prediction* to *actual_weight_diff* using the following code:

```SQL
SELECT wp.Id,aw.first_weigh_in,aw.last_weigh_in,wp.weightloss_pred_lb,aw.weight_diff_lb
FROM user_activities.actual_weightloss as aw
JOIN user_activities.weightloss_prediction as wp on aw.Id = wp.Id;
```
The resulting table had the following schema and resembled given sample data:

| Id | first_weigh_in |last_weigh_in|weightloss_pred_lb|weight_diff_lb|
| ----------- | ----------- | ----------- | ---------- | ----------- |
| INTEGER | TIMESTAMP | TIMESETAMP | FLOAT|FLOAT|
| 8877689391|2016-04-12 06:47:11 UTC|2016-05-12 06:42:53 UTC | 10.808|3.9683275000000151|
| ... | ... | ... | ... |...|

### Cleaning - BigQuery: Sleep Data
Since I also utilized BigQuery to clean users' sleep data, here's a quick switch of gears and cleaning up said sleep dataset with BigQuery.

**sedentary_vs_asleep**
I wanted to see if there's any data that will reveal any relationship (if any) between time spent sedentary and sleeping quality (sleep time). Data extraction for this task is done by merging each users' average of sedentary time and average of time asleep in *daily_intensities* and *sleepDay_merged*.

```SQL
SELECT di.Id,AVG(di.SedentaryMinutes) as sedentary_minutes, AVG(ds.TotalMinutesAsleep) as asleep_minutes
FROM user_activities.daily_intensities as di
JOIN user_activities.daily_sleep as ds on ds.Id = di.Id
GROUP BY di.Id
ORDER BY di.Id ASC
```

**users_sleep_healthy**
I've set a range of percentage where the user (during the observed time period) falls for healthy sleep in all sleep records. If healthy sleep is over 75% (arbitrary assumption), the user is assumed to have a healthy sleeping habit.

```SQL
SELECT 
  Id,
  AVG(TotalMinutesAsleep) as avg_asleep_minutes,
  AVG(TotalTimeInBed) as avg_time_in_bed,
  AVG(TotalTimeInBed)-AVG(TotalMinutesAsleep) as avg_time_in_bed_awake,
  COUNTIF(HealthySleep=TRUE)/COUNT(*)*100 as percent_healthy_sleep
FROM user_activities.daily_sleep 
GROUP BY Id
```

Now that all of the data I require are cleaned and prepared, it's time to visualize them and look for any trends among them.

## Visualization, Analysis, and More Cleaning

R (RStudio for IDE) was utilized for visualizing the data I cleaned. Before I present the visualization, let's look back to the questions I'm aiming to answer. 

1. Is there a trend between users' weight and the calories they are burning each day?
2. What is the relationship between users' time in bed and their sleep qualities?

### Weight vs. Calories Burnt

*Note: Negative weight change indicates weight gain, whether it is predicted or actual.*

![Weight Change](img/Users'%20Predicted%20vs%20Actual%20Weight%20Change.jpg)

```R
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
```

As you can see from the plot, there is no visual relationship between predicted weight change and actual weight change. Since predicted weight change was calculated based on an assumed calorific intake and constant calorie burn, maybe this lack of trend is obvious. 

One more observation to note is that not all users were consistent with their weight logging. Most users recorded their weight for the first few days and didn't, and the fact that there were only eight users that recorded their weight data makes the hypothesis even more inconclusive. There's also a room for human error since more than half of the weight data are recorded manually, which is prone to typos and dishonest data. 

#### Recommendations to Improve Weights Data Analysis
**Encourage users to weigh in at a constant rate.**
Since the biggest inconsistency was shown in the frequency of the users weighing in, for some data, I had to record the very first weigh-in and the last as the same (some users only weighed in once). This would not be accurate data compared to those of the users that did weigh in several more times.

**Get Data on Calorie and Nutritions Intake**
This analysis was done purely on the assumption that more calories burnt than calories consumed will lead to a weight change, which is not entirely true. More data on what kind of food the users were consuming would greatly help with accuracy. There are many applications that track calories based on a specific dish or even individual ingredients, and Bellabeats can benefit by collaborating with them if they don't have an internal food tracker available.

**Users' Age and Health Data**
Another factor that can affect weight change is the users' age and their medical conditions, if any. Certain age groups burn less calories than others, and certain medical conditions can also amplify or reduce this effect. One well-known example is [Polycystic Ovary Syndrome (PCOS)](https://www.webmd.com/women/polycystic-ovary-syndrome-pcos-and-weight-gain). Knowing that users have a certain condition may help adjust their weight change goals more accurately.

### Idle Time (But Awake) vs. Sleep Quality
I wanted to know how many users were getting quality sleep. The standard of quality sleep in this context means that for 75% users' time in bed, the user was asleep. This is the visualization process for the *users_sleep_healthy* dataset. The result is as following:

![Healthy Sleep](img/Healthy%20Sleep%20Percentage%20for%20Each%20User.jpg)

```R
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
```

It is observed that most users sleep quality weren't that great, with some of them even recording 0 minutes of sleep throughout several days or weeks, which is not possible unless said users have illnesses that cause severe insomnia as a symptom. Due to the extremely low but possible case as such, I left the data with 0 minutes of sleep recorded.

What can possibly be disrupting the users from getting the much needed rest? I decided to investigate further by dividing the original question "What is the relationship between users' time in bed and their sleep qualities?" into two sub questions:
1. Is there a relationship between time spent in bed awake and % healthy sleep?
2. Is there a relationship between average time asleep vs. % healthy sleep?

Let's take a look at the scatter plot that shows the relationship between time spent in bed awake and % healthy sleep first.

![Time Awake Healthy Sleep Pre-Cleaning](img/Avg%20Time%20Awake%20in%20Bed%20and%20Healthy%20Sleep%20Percentage%20(Pre-Cleaning).jpg)
```R
ggplot(data=sleep,aes(x=percent_healthy_sleep,y=avg_time_in_bed_awake)) + 
  geom_point(size=3) +
  scale_y_continuous(expand=c(0,0), limits=c(0,330)) +
  ggtitle("Average Time in Bed Awake vs. % Healthy Sleep (Pre-Cleaning)") +
  theme(plot.title = element_text(hjust=0.5)) + 
  labs(x="% Healthy Sleep",y="Minutes")
```

It seems that there might possibly be a trend between time spent awake in bed and % healthy sleep. I removed the outliers and created a trendline for this dataset to see if there is indeed a trend or a relationship.

![Time Awake Healthy Sleep](img/Avg%20Time%20Awake%20in%20Bed%20and%20Healthy%20Sleep%20Percentage.jpg)

```R
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
```