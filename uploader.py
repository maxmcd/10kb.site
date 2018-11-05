import json
import boto3
import botocore
import datetime

{
    "body": "eyJ0ZXN0IjoiYm9keSJ9",
    "resource": "/{proxy+}",
    "path": "/path/to/resource",
    "httpMethod": "POST",
    "isBase64Encoded": True,
    "queryStringParameters": {"foo": "bar"},
    "pathParameters": {"proxy": "/path/to/resource"},
    "stageVariables": {"baz": "qux"},
    "headers": {},
    "requestContext": {},
}

s3 = boto3.resource("s3")
client = boto3.client("s3")


def lambda_handler(event, context):
    if event["httpMethod"] != "POST":
        return {"statusCode": 301, "headers": {"Location": "https://www.10kb.site/"}}

    if len(event["body"]) > 1e4:
        return {"statusCode": 422, "body": "Daft Punk. Discovery. Track 14"}
    if event["path"] != "/":
        try:
            s3.Object("10kb.site", event["path"][1:]).load()
        except botocore.exceptions.ClientError as e:
            if e.response["Error"]["Code"] == "404":
                client.put_object(
                    Key=event["path"][1:],
                    Bucket="10kb.site",
                    Expires=datetime.datetime.now() + datetime.timedelta(seconds=30),
                    Body=event["body"],
                    ContentType="text/plain",
                    Tagging="unprotected=true"
                )
                return {
                    "statusCode": 201,
                    "body": "https://www.10kb.site/{}".format(event["path"][1:]),
                }
            return {"statusCode": 500, "body": str(e)}
    return {"statusCode": 409, "body": "Already exists"}
