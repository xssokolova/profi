DROP TABLE IF EXISTS teams, players_stat;

CREATE TABLE teams (
    id            int,
    name          varchar(32),
    games_played  smallint,
    goals         smallint,
    goals_minus   smallint,
    yellow_cards  smallint,
	red_cards     smallint,
	PRIMARY KEY(id)
);

CREATE TABLE players_stat (
    id            int,
    name          varchar(32),
	team_id       int,
	position      varchar(8),
	age           smallint,
	min_played    int,
    goals         smallint,
    yellow_cards  smallint,
	red_cards     smallint,
	PRIMARY KEY(id)
);
 
INSERT INTO 
	players_stat(id, name, team_id, position, age, min_played, goals, yellow_cards, red_cards)
VALUES 
	(1, 'Ivan Ivanov',   1, 'GK', 18, 270, 0, 1, 0),
	(2, 'Max Maximov',   1, 'GK', 32, 270, 0, 0, 1),
    (3, 'Petr Petrov',   1, 'DF', 24, 180, 0, 0, 0),
    (4, 'Vasya Vasyev',  1, 'MD', 17, 220, 0, 0, 0),
    (5, 'Fedor Fedorov', 1, 'AT', 18, 60,  4, 2, 0),
    
    (6, 'Johny John', 2,  'GK', 26, 360, 0, 1, 0),
    (7, 'Peter Peter', 2, 'DF', 30, 280, 0, 1, 0),
    (8, 'Basil Basil', 2, 'MD', 28, 300, 0, 1, 0),
    (9, 'Smith Smith', 2, 'AT', 21, 20,  1, 0, 1),
    
    (10, 'Ernst Ernst', 3, 'GK', 28, 270, 0, 0, 0),
    (11, 'Hans Hans',   3, 'DF', 28, 270, 0, 1, 1),
    (12, 'Frank Frank', 3, 'MD', 23, 180, 0, 0, 1),
    (13, 'Klaus Klaus', 3, 'AT', 36, 90,  0, 0, 0);
	
-- Задаём непараметрируемые поля teams
INSERT INTO 
	teams(id, name, games_played, goals_minus)
VALUES
	(1, 'Russia', 3, 2),
	(2, 'England', 4, 1),
	(3, 'Germany', 3, 3);
    
-- Задаём поля teams, параметрируемые от players_stat 
UPDATE teams SET
  goals = (SELECT sum(goals) FROM players_stat WHERE team_id = teams.id GROUP BY team_id),
  yellow_cards = (SELECT sum(yellow_cards) FROM players_stat WHERE team_id = teams.id GROUP BY team_id),
  red_cards = (SELECT sum(red_cards) FROM players_stat WHERE team_id = teams.id GROUP BY team_id);

-- В каких командах есть вратари (‘GK’), получавшие карточки на турнире?
-- если таблица пустая, значит ни один из вратарей не получил желтую карточку за время турнира
SELECT teams.name AS 'name of team' FROM teams JOIN players_stat
  ON teams.id = players_stat.team_id
  WHERE players_stat.position='GK' and (players_stat.yellow_cards + players_stat.red_cards) > 0
  GROUP BY teams.id;
  
 -- Каков 90-ый перцентиль возраста игроков, сыгравших на турнире не менее 270 минут?
 -- метод ближайшего ранга

WITH play AS (SELECT age FROM players_stat WHERE min_played >= 270 )
SELECT 
    CAST(SUBSTRING_INDEX(SUBSTRING_INDEX( GROUP_CONCAT(age ORDER BY 
    age SEPARATOR ','), ',', 90/100 * COUNT(*) + 1), ',', -1) AS DECIMAL) 
    AS '90th Per'
FROM play;

-- В каких командах голы на турнире забивали только нападающие (`AT`)?
-- если таблица пустая, значит нет команд, в которых голы на турнире забивали только нападающие
SELECT teams.name FROM teams 
WHERE teams.goals > 0 AND NOT EXISTS 
	(SELECT * FROM players_stat
	WHERE (players_stat.team_id = teams.id AND players_stat.position <> 'AT' AND players_stat.goals > 0));
 
 -- Представители какой команды чаще других получали желтые карточки во время игр?
 
SELECT name, yellow_cards 
FROM teams 
WHERE teams.yellow_cards >= ALL(SELECT teams.yellow_cards FROM teams);
        
-- или

WITH temp AS 
	(SELECT players_stat.team_id, teams.name, players_stat.yellow_cards
	FROM players_stat 
	JOIN teams
	ON players_stat.team_id = teams.id)
SELECT name, sum(yellow_cards)
FROM temp
GROUP BY team_id
HAVING sum(yellow_cards) >= ALL(SELECT sum(yellow_cards) FROM temp GROUP BY team_id);

