import json, re, os, boto3, logging
from datetime import datetime

logger       = logging.getLogger()
VALID_LANES  = {"exp", "gold", "mid", "jungle", "roam"}
VALID_DELTAS = {5, 10, 15, 20}
PLAYER_RE    = re.compile(r"^PLAYER-0[1-5]$")

s3  = boto3.client("s3")
sqs = boto3.client("sqs")

QUEUE_URL = os.environ["QUEUE_URL"]
BUCKET    = os.environ["BUCKET"]


def validate(event: dict) -> str | None:
    for field in ("match_id", "player_id", "lane", "task_type", "points_delta", "timestamp"):
        if field not in event:
            return f"missing field: {field}"
    if event["lane"] not in VALID_LANES:
        return f"invalid lane: {event['lane']}"
    if event["points_delta"] not in VALID_DELTAS:
        return f"invalid points_delta: {event['points_delta']}, expected one of {sorted(VALID_DELTAS)}"
    if not PLAYER_RE.match(event["player_id"]):
        return f"invalid player_id: {event['player_id']}"
    try:
        datetime.fromisoformat(event["timestamp"].replace("Z", "+00:00"))
    except ValueError:
        return f"invalid timestamp: {event['timestamp']}"
    return None


def handler(event, context):
    for record in event["Records"]:
        key  = record["s3"]["object"]["key"]
        body = s3.get_object(Bucket=BUCKET, Key=key)["Body"].read()
        try:
            payload = json.loads(body)
        except json.JSONDecodeError as e:
            logger.error(f"bad JSON {key}: {e}")
            _reject(key, body, f"invalid JSON: {e}")
            continue

        reason = validate(payload)
        if reason:
            logger.warning(f"rejected {key}: {reason}")
            _reject(key, body, reason)
        else:
            sqs.send_message(QueueUrl=QUEUE_URL, MessageBody=json.dumps(payload))
            logger.info(f"queued {key}")


def _reject(key: str, body: bytes, reason: str):
    rejected_key = key.replace("matches/", "rejected/", 1)
    s3.put_object(Bucket=BUCKET, Key=rejected_key, Body=body,
                  Metadata={"rejection-reason": reason})
    s3.delete_object(Bucket=BUCKET, Key=key)
