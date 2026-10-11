import os, json, boto3, psycopg2, time, logging
from datetime import datetime

logger      = logging.getLogger()
logger.setLevel(logging.INFO)

TABLE       = os.environ["TABLE_NAME"]
TOPIC_ARN   = os.environ["TOPIC_ARN"]
SSM_PREFIX  = os.environ["SSM_PREFIX"]
TTL_SECONDS = 86_400  # 24 hours: how long dedupe markers are kept

dynamodb = boto3.client("dynamodb")
sns      = boto3.client("sns")


def _get_rds_creds() -> dict:
    ssm = boto3.client("ssm")
    def get(name):
        return ssm.get_parameter(Name=name, WithDecryption=True)["Parameter"]["Value"]
    return {
        "host":     get(f"{SSM_PREFIX}/host"),
        "port":     int(get(f"{SSM_PREFIX}/port")),
        "user":     get(f"{SSM_PREFIX}/username"),
        "password": get(f"{SSM_PREFIX}/password"),
        "dbname":   "mlbb",
    }


CREDS = _get_rds_creds()  # module-level: runs once per container


def _get_level(points: int, thresholds: list) -> int:
    return sum(1 for t in thresholds if points >= t)


def _load_tiers() -> dict:
    path = os.path.join(os.path.dirname(__file__), "common", "tiers.json")
    with open(path) as f:
        return json.load(f)


TIERS = _load_tiers()


def process(record: dict):
    payload      = json.loads(record["body"])
    match_id     = payload["match_id"]
    player_id    = payload["player_id"]
    lane         = payload["lane"]
    points_delta = int(payload["points_delta"])
    title        = TIERS["lanes"][lane]

    try:
        dynamodb.transact_write_items(TransactItems=[
            {
                "Put": {
                    "TableName": TABLE,
                    "Item": {
                        "pk":  {"S": f"MATCH#{match_id}"},
                        "sk":  {"S": "DEDUPE"},
                        "ttl": {"N": str(int(time.time()) + TTL_SECONDS)},
                    },
                    "ConditionExpression": "attribute_not_exists(pk)",
                }
            },
            {
                "Update": {
                    "TableName": TABLE,
                    "Key": {"pk": {"S": player_id}, "sk": {"S": lane}},
                    "UpdateExpression": "ADD style_points :delta SET lane=:lane, title=:title, updated_at=:ts",
                    "ExpressionAttributeValues": {
                        ":delta": {"N": str(points_delta)},
                        ":lane":  {"S": lane},
                        ":title": {"S": title},
                        ":ts":    {"S": datetime.utcnow().isoformat()},
                    },
                }
            },
        ])
    except dynamodb.exceptions.TransactionCanceledException as e:
        reasons = [r.get("Code") for r in e.response["CancellationReasons"]]
        if "ConditionalCheckFailed" in reasons:
            logger.info(f"duplicate match_id, skipping: {match_id}")
            return
        raise

    item       = dynamodb.get_item(TableName=TABLE, Key={"pk": {"S": player_id}, "sk": {"S": lane}})["Item"]
    new_points = int(item["style_points"]["N"])
    new_level  = _get_level(new_points, TIERS["levels"])

    try:
        dynamodb.update_item(
            TableName=TABLE,
            Key={"pk": {"S": player_id}, "sk": {"S": lane}},
            UpdateExpression="SET last_alerted_level = :lvl, style_level = :lvl",
            ConditionExpression=(
                "attribute_not_exists(last_alerted_level) OR last_alerted_level < :lvl"
            ),
            ExpressionAttributeValues={":lvl": {"N": str(new_level)}},
        )
        if new_level > 0:
            sns.publish(
                TopicArn=TOPIC_ARN,
                Subject=f"Style Level Up: {player_id} / {lane}",
                Message=f"{player_id} reached {title} Lv. {new_level} ({new_points} pts)",
            )
    except dynamodb.exceptions.ConditionalCheckFailedException:
        pass  # another invocation already sent this alert

    with psycopg2.connect(**CREDS) as conn:
        with conn.cursor() as cur:
            cur.execute("""
                CREATE TABLE IF NOT EXISTS match_history (
                    id BIGSERIAL PRIMARY KEY, match_id VARCHAR(64) NOT NULL UNIQUE,
                    player_id VARCHAR(32) NOT NULL, lane VARCHAR(16) NOT NULL,
                    task_type VARCHAR(32) NOT NULL, points_delta INT NOT NULL,
                    played_at TIMESTAMPTZ NOT NULL
                );
                CREATE INDEX IF NOT EXISTS idx_player_lane
                    ON match_history (player_id, lane, played_at);
            """)
            cur.execute(
                """
                INSERT INTO match_history
                    (match_id, player_id, lane, task_type, points_delta, played_at)
                VALUES (%s, %s, %s, %s, %s, %s)
                ON CONFLICT DO NOTHING
                """,
                (match_id, player_id, lane, payload["task_type"],
                 points_delta, payload["timestamp"]),
            )


def handler(event, context):
    failures = []
    for record in event["Records"]:
        try:
            process(record)
        except Exception as e:
            logger.error(f"failed: {record['messageId']}: {e}")
            failures.append({"itemIdentifier": record["messageId"]})
    return {"batchItemFailures": failures}
