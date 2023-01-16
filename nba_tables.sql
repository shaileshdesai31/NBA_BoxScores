#create schema called 'nba' or however you'd like (change following line if different name)
use nba;
DROP TABLE IF EXISTS PlayerLog;
DROP TABLE IF EXISTS Game;
DROP TABLE IF EXISTS Standings;

CREATE TABLE Standings(
	team varchar(10) PRIMARY KEY NOT NULL,
    wins int NOT NULL,
    losses int NOT NULL,
    division varchar(15) NOT NULL,
    conf varchar(15) NOT NULL,
    seed int NOT NULL
);


CREATE TABLE Game(
	game_id int PRIMARY KEY AUTO_INCREMENT NOT NULL,
	home varchar(10) NOT NULL,
	away varchar(10) NOT NULL,
    home_score int NOT NULL,
    away_score int NOT NULL,
    game_date date NOT NULL
);

CREATE TABLE PlayerLog(
	player_name varchar(50) NOT NULL,
    game_id int NOT NULL,
	sp int NOT NULL,
    pts int NOT NULL,
    ast int NOT NULL,
    fg int NOT NULL,
    fga int NOT NULL,
	ft int NOT NULL,
    fta int NOT NULL,
    tp int NOT NULL,
    tpa int NOT NULL,
    blk int NOT NULL,
    drb int NOT NULL,
    orb int NOT NULL,
    stl int NOT NULL,
    tov int NOT NULL,
    pf int NOT NULL,
    team varchar(10) NOT NULL,
    opp varchar(10) NOT NULL,
    win bool NOT NULL,
	PRIMARY KEY(player_name, game_id),
    FOREIGN KEY(game_id) REFERENCES Game(game_id),
    FOREIGN KEY(team) REFERENCES Standings(team)
);


DROP VIEW IF EXISTS all_games;
CREATE VIEW all_games AS
SELECT g.game_id AS game_id, g.home AS team, g.away AS opp, g.home_score AS score, g.away_score AS opp_score,
        (CASE WHEN (g.home_score > g.away_score) THEN 1 ELSE 0 END) AS win, 1 AS home, g.game_date AS game_date
FROM Game g
UNION
SELECT g.game_id AS game_id, g.away AS team, g.home AS opp, g.away_score AS score, g.home_score AS opp_score,
        (CASE WHEN (g.away_score > g.home_score) THEN 1 ELSE 0 END) AS win, 0 AS home, g.game_date AS game_date
FROM Game g;

DROP VIEW IF EXISTS defense;
CREATE VIEW defense AS
select rank() OVER (ORDER BY avg(ag.opp_score))  AS rating, ag.team AS team, avg(ag.score) AS pts, avg(ag.opp_score) AS pts_allowed, (avg(ag.score) - avg(ag.opp_score)) AS dif
FROM all_games ag
GROUP BY ag.team;

DROP VIEW IF EXISTS offense;
CREATE VIEW offense AS
select rank() OVER (ORDER BY avg(ag.score) desc )  AS rating, ag.team AS team, avg(ag.score) AS pts, avg(ag.opp_score) AS pts_allowed, (avg(ag.score) - avg(ag.opp_score)) AS dif 
FROM all_games ag
GROUP BY ag.team;

DROP VIEW IF EXISTS team_opp_stats;
CREATE VIEW team_opp_stats AS
SELECT pl.opp AS opp,
        ((100 * SUM(pl.fg)) / SUM(pl.fga)) AS fg,
        ((100 * SUM(pl.tp)) / SUM(pl.tpa)) AS tp,
        (SUM(pl.tp) / COUNT(DISTINCT pl.game_id)) AS tpm,
        (SUM(pl.fta) / COUNT(DISTINCT pl.game_id)) AS fta,
        (SUM(pl.ast) / COUNT(DISTINCT pl.game_id)) AS ast,
        (SUM(pl.stl) / COUNT(DISTINCT pl.game_id)) AS stl,
        (SUM(pl.tov) / COUNT(DISTINCT pl.game_id)) AS tov,
        (SUM(pl.blk) / COUNT(DISTINCT pl.game_id)) AS blk,
        (SUM(pl.drb) / COUNT(DISTINCT pl.game_id)) AS drb,
        (SUM(pl.orb) / COUNT(DISTINCT pl.game_id)) AS orb,
        (SUM(pl.pf) / COUNT(DISTINCT pl.game_id)) AS pf
FROM PlayerLog pl
JOIN Game g ON ((g.game_id = pl.game_id))
GROUP BY pl.opp;

DROP VIEW IF EXISTS team_stats;
CREATE VIEW team_stats AS
SELECT pl.team AS team,
        ((100 * SUM(pl.fg)) / SUM(pl.fga)) AS fg,
        ((100 * SUM(pl.tp)) / SUM(pl.tpa)) AS tpp,
        (SUM(pl.tp) / COUNT(DISTINCT pl.game_id)) AS tpm,
        ((100 * SUM(pl.ft)) / SUM(pl.fta)) AS ft,
        (SUM(pl.ast) / COUNT(DISTINCT pl.game_id)) AS ast,
        (SUM(pl.stl) / COUNT(DISTINCT pl.game_id)) AS stl,
        (SUM(pl.tov) / COUNT(DISTINCT pl.game_id)) AS tov,
        (SUM(pl.blk) / COUNT(DISTINCT pl.game_id)) AS blk,
        (SUM(pl.drb) / COUNT(DISTINCT pl.game_id)) AS drb,
        (SUM(pl.orb) / COUNT(DISTINCT pl.game_id)) AS orb,
        (SUM(pl.pf) / COUNT(DISTINCT pl.game_id)) AS pf
FROM PlayerLog pl
GROUP BY pl.team;

