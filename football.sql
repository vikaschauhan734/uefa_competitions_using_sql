create table goals (goal_id VARCHAR,
					match_id VARCHAR,
					pid VARCHAR,
					duration INT,
					assist VARCHAR,
					goal_desc VARCHAR);

create table matches (match_id VARCHAR,
					season VARCHAR,
					date VARCHAR,
					home_team VARCHAR,
					away_team VARCHAR,
					stadium VARCHAR,
					home_team_score INT,
					away_team_score INT,
					penalty_shoot_out INT,
					attendance INT);

create table players (player_id VARCHAR,
					first_name VARCHAR,
					last_name VARCHAR,
					nationality VARCHAR,
					dob DATE,
					team VARCHAR,
					jersey_number FLOAT,
					position VARCHAR,
					height FLOAT,
					weight FLOAT,
					foot VARCHAR);

create table teams (team_name VARCHAR,
					country VARCHAR,
					home_stadium VARCHAR);

create table stadium (name VARCHAR,
					city VARCHAR,
					country VARCHAR,
					capacity INT);


copy goals from 'D:\cuvatte\sql\goals.csv' delimiter ',' csv header;

copy matches from 'D:\cuvatte\sql\Matches.csv' delimiter ',' csv header;

copy players from 'D:\cuvatte\sql\Players.csv' delimiter ',' csv header;

copy stadium from 'D:\cuvatte\sql\Stadiums.csv' delimiter ',' csv header;

copy teams from 'D:\cuvatte\sql\Teams.csv' delimiter ',' csv header;

-- Question 1
-- Count the Total Number of Teams
select count(team_name) as total_teams from teams;

-- Question 2
-- Find the Number of Teams per Country
select country, count(team_name) as number_of_teams from teams group by country;

-- Question 3
-- Calculate the Average Team Name Length
select avg(length(team_name)) as average_team_name_length from teams;
-- Alternate
select avg(length) as average_team_name_length from (select team_name, length(team_name) as length from teams);

-- Question 4
-- Calculate the Average Stadium Capacity in Each Country round it off and sort by the total stadiums in the country
select country ,round(avg(capacity)) as average_capacity, count(distinct(name)) as total_stadiums 
	from stadium group by country order by total_stadiums desc;
-- Aternate if you don't want to show number of stadiums
select country , average_capacity from (select country ,round(avg(capacity)) as average_capacity, count(distinct(name)) as total_stadiums 
	from stadium group by country order by total_stadiums desc);

-- Question 5
-- Calculate the Total Goals Scored
select count(distinct(goal_id)) as total_goals_scored from goals;

-- Question 6
-- Find the total teams that have city in their names
select count(distinct(team_name)) from teams where team_name like '%City%';

-- Question 7
-- Use Text Functions to Concatenate the Team's Name and Country
select concat(team_name,' - ',Country) as team_country from teams;

-- Question 8
-- What is the highest attendance recorded in the dataset, and which match (including home and away teams, and date) does it correspond to?
select home_team, away_team, date, attendance from matches 
	where attendance = (select max(attendance) from matches);

-- Question 9
-- What is the lowest attendance recorded in the dataset, and which match (including home and away teams, and date)
-- does it correspond to set the criteria as greater than 1 as some matches had 0 attendance because of covid
select home_team, away_team, date, attendance from matches 
	where attendance = (select min(attendance) from (select * from matches where attendance > 1 order by attendance asc));

-- Question 10
-- Identify the match with the highest total score (sum of home and away team scores) in the dataset. Include the match ID, home and away teams, and the total score.
select match_id, home_team, away_team, home_team_score + away_team_score as total_score from matches order by total_score desc limit 1;
-- Alternate
select match_id, home_team, away_team, home_team_score + away_team_score as total_score from matches where home_team_score + away_team_score = (select max(home_team_score+away_team_score) from matches);

-- Question 11
-- Find the total goals scored by each team, distinguishing between home and away goals.
-- Use a CASE WHEN statement to differentiate home and away goals within the subquery
select a.team_name, sum(case when b.home_team = a.team_name then home_team_score else 0 end) as home_goals, 
	sum(case when b.away_team = a.team_name then away_team_score else 0 end) as away_goals from teams a 
	left join matches b on a.team_name = b.home_team or a.team_name = b.away_team
	group by a.team_name;

-- Question 12
-- windows function - Rank teams based on their total scored goals (home and away combined) using a window function.In the stadium Old Trafford.
select away_team as team_name, rank() over (order by total_goals desc) as rank 
	from (select away_team , sum(home_team_score + away_team_score) as total_goals from matches where stadium like 'Old Trafford' group by away_team);

-- Question 13
-- TOP 5 l players who scored the most goals in Old Trafford, ensuring null values are not included in the result (especially pertinent for cases where a player might not have scored any goals).
select player_name, count(distinct(goal_id)) as total_goals from (select concat(a.first_name, ' ', a.last_name) as player_name ,b.* from players as a 
	right join (select goals.goal_id, goals.match_id, goals.pid, matches.stadium from goals left join matches on goals.match_id = matches.match_id) as b
	on a.player_id = b.pid where b.stadium like 'Old Trafford') group by player_name having count(distinct(goal_id)) is not null order by total_goals desc limit 5;

-- Question 14
-- Write a query to list all players along with the total number of goals they have scored. 
-- Order the results by the number of goals scored in descending order to easily identify the top 6 scorers.
select player_name, total_goals from 
	(select a.player_id, concat(a.first_name, ' ', a.last_name) as player_name , count(b.goal_id) as total_goals 
	from players a right join goals b on a.player_id = b.pid group by a.player_id, player_name having a.player_id is not null order by total_goals desc limit 6);

-- Question 15
-- Identify the Top Scorer for Each Team - Find the player from each team who has scored the most goals in all matches combined.
-- This question requires joining the Players, Goals, and possibly the Matches tables, and then using a subquery to aggregate goals by players and teams.
select player_name, team, total_goals from(select player_name, team, total_goals, row_number() over (partition by team order by total_goals desc) as rank 
	from (select player_name, team, count((goal_id)) as total_goals from (select p.player_id, concat(p.first_name, ' ' , p.last_name) as player_name, p.team, g.goal_id from goals g 
	left join players p on g.pid = p.player_id where p.team is not null) group by player_name, team)) where rank = 1;

-- Question 16
-- Find the Total Number of Goals Scored in the Latest Season - Calculate the total number of goals scored in the latest season available in the dataset.
-- This question involves using a subquery to first identify the latest season from the Matches table, then summing the goals from the Goals table that occurred in matches from that season.
select count(g.goal_id) as total_number_of_goals from goals as g inner join 
	(select * from matches where season = (select distinct(season) as seasons from matches order by seasons desc limit 1)) as m on g.match_id = m.match_id;
-- Alternate
select count(g.goal_id) as total_number_of_goals from goals as g inner join
	matches as m on g.match_id = m.match_id where m.season = (select max(season) from matches);

-- Question 17
-- Find Matches with Above Average Attendance - Retrieve a list of matches that had an attendance higher than the average attendance across all matches.
-- This question requires a subquery to calculate the average attendance first, then use it to filter matches.
select * from matches where attendance > (select avg(attendance) from matches);

-- Question 18
-- Find the Number of Matches Played Each Month - Count how many matches were played in each month across all seasons.
-- This question requires extracting the month from the match dates and grouping the results by this value. as January Feb march
select to_char(date::date, 'Month') as months, count(distinct(match_id)) as number_of_matches from matches group by months order by number_of_matches desc;
