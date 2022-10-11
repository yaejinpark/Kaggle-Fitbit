# Kaggle Fitbit Data - Calories and Sleep Analysis for Bellabeat
Author: Yae Jin Park (Jin Park)
Last Revised: October 11th, 2022

(Upcoming: Tableau Dashboard of the following analysis)

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
* R (RStudio for IDE)

### Cleaning - Google Sheets
#### weightLogInfo_merged
* Added a column of calculated users' heights in meters based on their weights (kg) and BMI
* Added a column of users' height in inches, converted from users' height in meters
* Changed Date column from AM/PM format to 24 hour format for the time portion

#### sleepDay_merged
* Changed the SleepDay column to show time in a 24 hour format since AM and PM for time notation causes isues when importing to BigQuery
* Added a column for time (minutes) users were awake in bed
* Added a column for time asleep conversion from minutes to hours
* Added a boolean column for healthy sleep for each row (7 to 9 hours) based on time asleep in hours

#### minuteSleep_merged
* Added a column for sleep state translated from values (1 = Asleep, 2 = Restless, 3 = Awake)
* Deleted logId column as it is not being used in this analysis
* Changed the date column so that time is shown in 24 hr format (for importing to BigQuery)

#### dailyIntensities_merged
* Added Total Distance calculation and Total Distance (miles) conversion

### Cleaning - Big Query
*Please note that if you are to attempt in recreating my work, my queries' syntax may not work 100% for DBMS and may require minor adjustments. The queries are strictly for the BigQuery setup I have.*

#### calorieIntake_activeLevel
Manually created table for matching users' calorie requirement based on their activity levels
(Include Table Markdown here)

* Find the user's active status by finding the average of distance they travelled and create a new table out of it grouped by userID
* Find if user is in calories deficit, merging with dailyCalories table and calculating the calorie deficit.
* Find users in calories deficit but did not lose weight or gained weight
* Set a range of percentage where the user (during the observed time period) falls for healthy sleep in all sleep records. If healthy sleep is over 75% (some arbitrary assumption), have company recommend user to decrease screen time in the evening, workout more, etc.

Remaining TODO
* go deeper in analysis with above to divide sleep category (restless and fully asleep) for sleep help product recommendation with Tableau
* Fitbit blog has an article about restless sleep. Maybe recommend to customers to better their sleep quality by changing what makes them uncomfortable during their sleep, which is one of the causes of restless sleep.
* If any sleep deprivation happens more frequently on Mondays, recommend more workout (need more analysis on workout vs sleep quality)/sleep preparation for users
* Add a pie graph of resulting boolean for healthy sleep if needed
* Suggestion for company: add a qualitative survey on "How was your sleep quality based on a scale of 5?"