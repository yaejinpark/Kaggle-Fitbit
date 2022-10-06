# Kaggle-Fitbit

## Assumptions
* All users are women over 18 years old (though not noted in the dataset) since they are old enough to consent sharing of any personal data
* Weightloss depends on Calories In, Calories Out
* All users are consuming calories matching their calorie intake rows for their activity level
* There are the same number of users (or similar) that are in each age groups 19-30, 31-50, 51+ (for simple median calculation of calorie burning calculation)
* Assume that active users need to consume 2200 calories per day, moderately active ones 2000,sedantary users 1800 calories per day (again, for simple median calculation of required calories burnt to lose or maintain weight)
* If user walks more than 1.5-3 miles per day, they are moderately active. More than 3, they are active.
* 7-9 hours of sleep is considered healthy sleep. Yes, I know that there are short-sleepers and long-sleepers but let's go with averages.

## Cleaning Process and Adding Calculations - Google Sheets

### weightLogInfo_merged
* Added a column of calculated users' heights in meters based on their weights (kg) and BMI
* Added a column of users' height in inches, converted from users' height in meters
* Changed Date column from AM/PM format to 24 hour format for the time portion
* Assuming that data was collected from American women, the women are either really short or really tall compared to the average (5'4)

### sleepDay_merged
* Changed the SleepDay column to get rid of HH:MM:SS AM due to problem in importing to BigQuery
* Added a column for time (minutes) users were awake in bed
* Added a column for time asleep conversion from minutes to hours
* Added a boolean column for healthy sleep for each row (7 to 9 hours) based on time asleep in hours
* Add a pie graph of resulting boolean for healthy sleep if needed
* Suggestion for company: add a qualitative survey on "How was your sleep quality based on a scale of 5?"

### minuteSleep_merged
* Added a column for sleep state translated from values (1 = Asleep, 2 = Restless, 3 = Awake)
* Fitbit blog has an article about restless sleep. Maybe recommend to customers to better their sleep quality by changing what makes them uncomfortable during their sleep, which is one of the causes of restless sleep.
* If any sleep deprivation happens more frequently on Mondays, recommend more workout (need more analysis on workout vs sleep quality)/sleep preparation for users

### dailyIntensities_merged
* Added Total Distance calculation and Total Distance (miles) conversion

## Cleaning Process and Adding Calculations - Big Query
* Find the user's active status by finding the average of distance they travelled and create a new table out of it grouped by userID
* Find if user is in calories deficit, merging with dailyCalories table and calculating the calorie deficit.
* Find users in calories deficit but did not lose weight or gained weight
* Set a range of percentage where the user (during the observed time period) falls for healthy sleep in all sleep records. If healthy sleep is over 75% (some arbitrary assumption), have company recommend user to decrease screen time in the evening, workout more, etc.


Get minutesleep data and get the average value of sleep quality for each user. Maybe I can merge them with the sleepDay data?