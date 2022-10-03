-- Find the average total distance miles and then classify each user as:
-- Sedantary, Moderate or Active

SELECT Id,
  AVG(TotalDistanceMiles) as avg_distance,
  CASE 
    WHEN AVG(TotalDistanceMiles) < 1.5 THEN 'Sedantary'
    WHEN AVG(TotalDistanceMiles) >= 1.5 AND AVG(TotalDistanceMiles) < 3 THEN 'Moderate'
    ELSE 'Active'
  END AS ActiveLevel
FROM user_activities.daily_intensities
GROUP BY Id;

-- Find each users' (assumed) calorie intake to use as their daily calorie consumption from food based on their three active levels

SELECT al.*, ci.CalorieIntake
FROM user_activities.active_levels as al
JOIN user_activities.calorie_intake as ci on al.ActiveLevel = ci.ActiveLevel
ORDER BY al.Id;

-- Find the user's overall calorie deficit for all recorded days
-- It takes 7700 calories to lose 1 kg, 3500 to lose 1 lb
-- Negative calorie deficit means user's calorie intake was bigger than calories burnt

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

-- Find the users' actual weight difference between their start and end dates
SELECT 
  Id,
  MIN(Date) as first_weigh_in,
  MAX(Date) as last_weigh_in,
  MAX(WeightKg) - MIN(WeightKg) as weight_diff_kg,
  MAX(WeightPounds) - MIN(WeightPounds) as weight_diff_lb
FROM user_activities.weight_info
GROUP BY Id;

-- Find the difference of users' predicted weightloss and actual weightloss
SELECT wp.Id,aw.first_weigh_in,aw.last_weigh_in,wp.weightloss_pred_lb,aw.weight_diff_lb
FROM user_activities.actual_weightloss as aw
JOIN user_activities.weightloss_prediction as wp on aw.Id = wp.Id;