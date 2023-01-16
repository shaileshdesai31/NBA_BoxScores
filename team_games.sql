use nba;
set @team_name := 'MIL';
select *, o.rating + d.rating as ovr
from all_games ag
join offense o on o.team = ag.opp
join defense d on d.team = ag.opp
join Standings s on s.team = ag.opp
where ag.team = @team_name and d.rating <= 10 and
	not exists(select *
		   from PlayerLog pl
		   where pl.player_name = 'Giannis Antetokounmpo' and pl.game_id = ag.game_id and pl.sp >= 1200)

# This query shows games of the Milwaukee Bucks' under the following two conditions:
# 1) The opposing team has a defensive rating of 10 or lower
# 2) Giannis Antetokounmpo didn't play or played less than 20 minutes in the game.