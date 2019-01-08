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


def response(status, body="", headers=None):
    _headers = {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Credentials": True,
    }
    if headers:
        _headers.update(headers)
    return {"statusCode": status, "body": body, "headers": _headers}


def lambda_handler(event, context):
    print(event, context)
    if event["httpMethod"] == "OPTIONS":
        return response(200)
    if event["httpMethod"] != "POST":
        return response(301, body=None, headers={"Location": "https://www.10kb.site/"})
    if event.get("path") and event["path"] != "/":
        if event["path"][1] == ".":
            return response(422, "No paths that start with a .")
        try:
            s3.Object("10kb.site", event["path"][1:]).load()
        except botocore.exceptions.ClientError as e:
            if e.response["Error"]["Code"] == "404":
                if not event["body"]:
                    return response(422, "No body")
                if len(event["body"]) > 1e4:
                    return response(422, "Daft Punk. Discovery. Track 14")
                client.put_object(
                    Key=event["path"][1:],
                    Bucket="10kb.site",
                    Expires=datetime.datetime.now() + datetime.timedelta(seconds=30),
                    Body=event["body"],
                    ContentType="text/plain",
                )
                client.put_object_tagging(
                    Bucket="10kb.site",
                    Key=event["path"][1:],
                    Tagging={
                        'TagSet': [
                            {
                                'Key': 'unprotected',
                                'Value': 'true'
                            },
                        ]
                    }
                )
                return response(201, "https://www.10kb.site/{}".format(event["path"][1:]))
            return response(500, str(e))
    return response(409, "Already exists")
