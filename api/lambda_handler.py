import json
import boto3
from xml.dom import minidom
import urllib3
import os
import datetime
import logging
from decimal import Decimal

dynamodbTableName = os.environ.get


def lambda_handler(event, context):

    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    logger.info(event)

    httpMethod = event["httpMethod"]
    path = event["path"]
    table_name = os.environ["dbtablename"]

    if httpMethod == "GET" and path == "/health":
        response = buildResponse(200)
    elif httpMethod == "GET" and path == "/comment":
        response = getComment(event["queryStringParameters"]["commentId"], table_name)
    elif httpMethod == "GET" and path == "/comments":
        response = getComments(table_name)
    elif httpMethod == "POST" and path == "/comment":
        response = saveComment(json.loads(event["body"]), table_name)
    elif httpMethod == "DELETE" and path == "/comment":
        requestBody = json.loads(event["body"])
        response = deleteComment(requestBody["commentId"], table_name)
    else:
        response = buildResponse(404, "Not Found")
    return response


class CustomEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)

        return json.JSONEncoder.default(self, obj)


def buildResponse(statusCode, body=None):
    response = {
        "statusCode": statusCode,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
    }

    if body is not None:
        response["body"] = json.dumps(body, cls=CustomEncoder)
    return response


def getComment(commentId, table):
    try:
        response = table.get_item(Key={"commentId": commentId})
        if "Item" in response:
            return buildResponse(200, response["Item"])
        else:
            return buildResponse(
                404, {"Message": "commentId: {0}s not found".format(commentId)}
            )
    except:
        logger.exception(
            "The session with the DB table in the getComment function failed."
        )


def getComments(table):
    try:
        response = table.scan()
        result = response["Items"]

        while "LastEvaluateKey" in response:
            response = table.scan(ExclusiveStartKey=response["LastEvaluatedKey"])
            result.extend(response["Items"])

        body = {"comments": response}
        return buildResponse(200, body)
    except:
        logger.exception(
            "The session with the DB table in the getComments function failed."
        )


def saveComment(requestBody, table):
    try:
        table.put_item(Item=requestBody)
        body = {"Operation": "SAVE", "Message": "SUCCESS", "Item": requestBody}
        return buildResponse(200, body)
    except:
        logger.exception(
            "The session with the DB table in the saceComment function failed."
        )


def deleteComment(commentId, table):
    try:
        response = table.delete_item(
            Key={"commentId": commentId}, ReturnValues="ALL_OLD"
        )
        body = {"Operation": "DELETE", "Message": "SUCCESS", "deltedItem": response}
        return buildResponse(200, body)
    except:
        logger.exception(
            "The session with the DB table in the delComment function failed."
        )
