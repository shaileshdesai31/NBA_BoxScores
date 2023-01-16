use nba;
SELECT avg(pl.sp/60), stddev(pl.sp/60), avg(pl.pts), stddev(pl.pts), avg(pl.tp), stddev(pl.tp), avg(pl.ast), stddev(pl.ast), avg(pl.orb+pl.drb), stddev(pl.orb+pl.drb), avg(pl.blk), stddev(pl.blk), avg(pl.stl), stddev(pl.stl), count(*)
from PlayerLog pl
join Game g on g.game_id = pl.game_id
join Standings s on s.team = pl.opp
join offense o on o.team = pl.opp
join defense d on d.team = pl.opp
where pl.player_name = 'Stephen Curry' and d.rating <= 10 and
		exists(select *
		from PlayerLog pl2
		where pl2.player_name = 'Klay Thompson' and pl2.game_id = g.game_id and pl2.sp >= 600) and
		exists(select *
		from PlayerLog pl3
		where pl3.player_name = 'Draymond Green' and pl3.game_id = g.game_id and pl3.sp >= 600) and
        exists(select tm_blks.player_name, tm_blks.avg_blk
			   from (select pl4.player_name, avg(pl4.blk) as avg_blk
					 from PlayerLog pl4
					 where pl4.team = pl.opp
					 group by pl4.player_name) as tm_blks
			   where avg_blk > 1.2)

# This query shows averages and standard deviations for Stephen Curry's stats under the following four conditions:
# 1) The opposing team had a defensive rating lower or equal to 10
# 2) Klay Thompson played at least 10 minutes
# 3) Draymond Green played at least 10 minutes
# 4) The opposing team has a player who averages at least 1.2 blocks per game