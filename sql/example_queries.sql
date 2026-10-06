-- PostgreSQL. Each numbered query answers the matching business question.
-- Q1: Rank games by their mean monthly average across available history.
SELECT g.appid, MAX(g.game_name) AS game_name, AVG(f.avg_players) AS avg_players
FROM fact_game_activity f JOIN dim_game g USING (game_key)
GROUP BY g.appid ORDER BY avg_players DESC LIMIT 10;

-- Q2: Mean activity per represented game for each primary genre and month.
SELECT d.year, d.month, ge.genre_name, AVG(f.avg_players) AS avg_players
FROM fact_game_activity f JOIN dim_date d USING (date_key)
JOIN dim_genre ge USING (genre_key)
GROUP BY d.year, d.month, ge.genre_name
ORDER BY d.year, d.month, avg_players DESC;

-- Q3: Monthly activity and percentage change for each game.
SELECT g.appid, g.game_name, d.year, d.month, f.avg_players,
       f.peak_players, f.player_gain, f.player_change_percentage
FROM fact_game_activity f JOIN dim_game g USING (game_key)
JOIN dim_date d USING (date_key)
ORDER BY g.appid, d.year, d.month;

-- Q4: CURRENT price versus historical mean popularity, one point per game.
-- This is descriptive association, not historical pricing or causal evidence.
WITH popularity AS (
  SELECT g.appid, AVG(f.avg_players) AS avg_players
  FROM fact_game_activity f JOIN dim_game g USING (game_key)
  GROUP BY g.appid
)
SELECT CORR(g.current_price::DOUBLE PRECISION, p.avg_players::DOUBLE PRECISION)
       AS price_player_correlation
FROM popularity p JOIN dim_game g USING (appid)
WHERE g.is_current AND g.current_price IS NOT NULL;

-- Q5: Mean of monthly average/peak ratios, not individual-player retention.
SELECT g.appid, MAX(g.game_name) AS game_name,
       AVG(f.avg_players / NULLIF(f.peak_players, 0)) * 100 AS avg_to_peak_pct
FROM fact_game_activity f JOIN dim_game g USING (game_key)
GROUP BY g.appid ORDER BY avg_to_peak_pct DESC NULLS LAST;
