#!/usr/bin/env python3
"""Pre-loads DynamoDB with starting scores so a level-up happens quickly."""
import boto3

TABLE   = "lane_leaderboard"
LANES   = ["exp", "gold", "mid", "jungle", "roam"]
TITLES  = {"exp": "Titan", "gold": "Deadeye", "mid": "Archmage", "jungle": "Slayer", "roam": "Guardian"}
PLAYERS = [f"PLAYER-0{i}" for i in range(1, 6)]

# seed points per player/lane — PLAYER-03/roam is close to Lv.9 (needs 1500)
SEEDS = {
    "PLAYER-01": {"exp": 480, "gold": 310, "mid": 195, "jungle": 390, "roam": 120},
    "PLAYER-02": {"exp": 650, "gold": 480, "mid": 300, "jungle": 500, "roam": 200},
    "PLAYER-03": {"exp": 800, "gold": 650, "mid": 500, "jungle": 400, "roam": 1485},
    "PLAYER-04": {"exp": 300, "gold": 200, "mid": 400, "jungle": 120, "roam": 650},
    "PLAYER-05": {"exp": 1100, "gold": 800, "mid": 650, "jungle": 300, "roam": 480},
}

ddb = boto3.client("dynamodb")

for player, lanes in SEEDS.items():
    for lane, pts in lanes.items():
        ddb.put_item(
            TableName=TABLE,
            Item={
                "pk":           {"S": player},
                "sk":           {"S": lane},
                "lane":         {"S": lane},
                "title":        {"S": TITLES[lane]},
                "style_points": {"N": str(pts)},
                "style_level":  {"N": "0"},
                "updated_at":   {"S": "2026-01-01T00:00:00"},
            },
        )
        print(f"Seeded:   {player} | {lane:<8} | {pts} pts")

print("Done.")
