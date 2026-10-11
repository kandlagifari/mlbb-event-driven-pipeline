#!/usr/bin/env python3
import argparse, boto3, json, random, string, time, uuid
from datetime import datetime, timezone

LANES      = ["exp", "gold", "mid", "jungle", "roam"]
PLAYERS    = [f"PLAYER-0{i}" for i in range(1, 6)]
TASK_TYPES = ["kill", "assist", "turret", "objective", "survival"]
DELTAS     = [5, 10, 15, 20]


def make_match(bad=False, duplicate_id=None, poison=False):
    if poison:
        return b"NOT_JSON_AT_ALL"
    payload = {
        "match_id":     duplicate_id or f"m-{uuid.uuid4().hex[:8]}",
        "player_id":    random.choice(PLAYERS),
        "lane":         random.choice(LANES),
        "task_type":    random.choice(TASK_TYPES),
        "points_delta": 12 if bad else random.choice(DELTAS),
        "timestamp":    datetime.now(timezone.utc).isoformat(),
    }
    return json.dumps(payload).encode()


def upload(s3, bucket, body, key):
    s3.put_object(Bucket=bucket, Key=f"matches/{key}", Body=body)
    try:
        data = json.loads(body)
        print(f"Uploaded: {data['player_id']} | {data['lane']:<8} | +{data['points_delta']} pts")
    except Exception:
        print(f"Uploaded: poison message → {key}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--count",     type=int,   default=10)
    parser.add_argument("--interval",  type=float, default=3.0)
    parser.add_argument("--bad",       action="store_true")
    parser.add_argument("--duplicate", action="store_true")
    parser.add_argument("--poison",    action="store_true")
    parser.add_argument("--bucket",    default=None)
    args = parser.parse_args()

    s3     = boto3.client("s3")
    bucket = args.bucket or boto3.client("ssm").get_parameter(
        Name="/mlbb/simulator/bucket")["Parameter"]["Value"]

    dup_id = f"m-{uuid.uuid4().hex[:8]}" if args.duplicate else None

    for i in range(args.count):
        key  = f"{uuid.uuid4().hex}.json"
        body = make_match(bad=args.bad, duplicate_id=dup_id, poison=args.poison)
        upload(s3, bucket, body, key)
        if args.duplicate and i == 0:
            time.sleep(1)
            upload(s3, bucket, body, f"{uuid.uuid4().hex}.json")
            break
        if i < args.count - 1:
            time.sleep(args.interval)


if __name__ == "__main__":
    main()
