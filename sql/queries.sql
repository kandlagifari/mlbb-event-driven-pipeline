-- task_type breakdown per player
SELECT player_id, task_type, COUNT(*) AS matches, SUM(points_delta) AS total_points
FROM match_history
GROUP BY player_id, task_type
ORDER BY player_id, total_points DESC;

-- lane activity summary
SELECT lane, COUNT(*) AS matches, SUM(points_delta) AS total_points, AVG(points_delta) AS avg_points
FROM match_history
GROUP BY lane
ORDER BY total_points DESC;
