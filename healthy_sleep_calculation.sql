-- Find the users' average time in bed asleep or awake.
-- Find the percentage of healthy sleep (7-9 hours) users are getting
SELECT 
  Id,
  AVG(TotalMinutesAsleep) as avg_asleep_minutes,
  AVG(TotalTimeInBed) as avg_time_in_bed,
  AVG(TotalTimeInBed)-AVG(TotalMinutesAsleep) as avg_time_in_bed_awake,
  COUNTIF(HealthySleep=TRUE)/COUNT(*)*100 as percent_healthy_sleep
FROM user_activities.daily_sleep 
GROUP BY Id