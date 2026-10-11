CREATE TABLE IF NOT EXISTS match_history (
  id           BIGSERIAL PRIMARY KEY,
  match_id     VARCHAR(64)  NOT NULL UNIQUE,
  player_id    VARCHAR(32)  NOT NULL,
  lane         VARCHAR(16)  NOT NULL,
  task_type    VARCHAR(32)  NOT NULL,
  points_delta INT          NOT NULL,
  played_at    TIMESTAMPTZ  NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_player_lane ON match_history (player_id, lane, played_at);
