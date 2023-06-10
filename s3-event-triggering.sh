#!/bin/bash

set -x
aws_account_id=$(aws sts get-caller-identity --query 'Account' --output text)
#aws_account_id=$(aws sts get-caller-identity | jq '.Account')
echo "AWS Account ID: " $aws_account_id

#Set AWS region and bucket name
aws_region="eu-west-2"
bucket_name="event-trigger-bucket-devops"
lambda_func_name="s3-event-lambda-function"
role_name="s3-event-lambda-sns"
email_address="xyz@gmail.com"

#Create IAM Role for the project
role_response=$(aws iam create-role --role-name $role_name --assume-role-policy-document '{
  "Version": "2012-10-17",
  "Statement": [{
    "Action": "sts:AssumeRole",
    "Effect": "Allow",
    "Principal": {
      "Service": [
        "lambda.amazonaws.com",
        "s3.amazonaws.com",
        "sns.amazonaws.com"
      ]
    }
 }]
}')

#Extract the role ARN from the JSON response
role_arn=$(echo "$role_response" | jq -r '.Role.Arn')
echo "This is here"
#Print the role ARN
echo "Role ARN: $role_arn"

#Attach permission to the created role
aws iam attach-role-policy --role-name $role_name --policy-arn arn:aws:iam::aws:policy/AWSLambda_FullAccess
aws iam attach-role-policy --role-name $role_name --policy-arn arn:aws:iam::aws:policy/AmazonSNSFullAccess

#Create s3 bucket
bucket_output=$(aws s3api create-bucket --bucket "$bucket_name" --region "$aws_region" --create-bucket-configuration LocationConstraint="$aws_region")

#Print the output from the bucket variable
echo "Bucket creation output: $bucket_output"

#Upload file to the bucket
aws s3 cp ./uploadToS3.txt s3://"$bucket_name"/uploadToS3Amazon.txt

#Create a Zip file to upload Lambda Function
zip -r s3-event-lambda-function.zip ./s3-event-lambda-function

sleep 10

#Create a Lambda function
aws lambda create-function --function-name $lambda_func_name \
  --region "$aws_region" \
  --runtime "nodejs16.x" \
  --handler "s3-event-lambda-function/s3-event-lambda-function.lambdaHandler" \
  --memory-size 128 \
  --timeout 30 \
  --role "arn:aws:iam::$aws_account_id:role/$role_name" \
  --zip-file "fileb://./s3-event-lambda-function.zip"

#Add permissions to s3 bucket to invoke Lambda
aws lambda add-permission \
  --function-name "$lambda_func_name" \
  --statement-id "s3-event-lambda-sns" \
  --action "lambda:InvokeFunction" \
  --principal s3.amazonaws.com \
  --source-arn "arn:aws:s3:::$bucket_name" \
  --region "$aws_region"

#Create an s3 event trigger for the Lambda function
LambdaFunctionArn="arn:aws:lambda:eu-west-2:$aws_account_id:function:s3-event-lambda-function"
echo "AM HERE MATE"
echo $LambdaFunctionArn
aws s3api put-bucket-notification-configuration \
  --region "$aws_region" \
  --bucket "$bucket_name" \
  --notification-configuration '{
    "LambdaFunctionConfigurations": [{
      "LambdaFunctionArn": "'"$LambdaFunctionArn"'",
      "Events": ["s3:ObjectCreated:*"]	
    }]
}'

#Create an SNS topic and save the topic ARN to a variable
topic_arn=$(aws sns create-topic --name s3-lambda-sns --region $aws_region --output json | jq -r '.TopicArn')

#Print the TopicArn
echo "SNS Topic ARN: $topic_arn

#Trigger SNS Topic using Lambda Function"
aws sns subscribe \
  --topic-arn "$topic_arn" \
  --protocol email \
  --region "$aws_region" \
  --notification-endpoint "$email_address"

#Publish SNS
aws sns publish \
  --topic-arn "$topic_arn" \
  --region "$aws_region" \
  --subject "A new object created in s3 bucket" \
  --message "Hello from Jimi Hunter, I am learning DevOps Zero to Hero"

