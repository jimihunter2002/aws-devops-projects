import {PublishCommand, SNSClient} from '@aws-sdk/client-sns';

export const lambdaHandler = async (event, context, callback) => {
  const snsClient = new SNSClient({region: "eu-west-2"});  
  const bucketName = event.Records[0].s3.bucket.name;
  const objectKey = event.Records[0].s3.object.key;

  const lambdaFunctionArn = context.invokedFunctionArn;
  const awsAccountId = lambdaFunctionArn.split(':')[4];

  console.log(`File ${objectKey} was uploaded to bucket ${bucketName}`);
  
 //set the parameters
 const params = {
   TopicArn: `arn:aws:sns:eu-west-2:${awsAccountId}:s3-lambda-sns`,
   Message: `File ${objectKey} was uploaded to bucket ${bucketName}`,
   Subject: 'S3 Object Created'
 }
 try {
      const data = await snsClient.send(new PublishCommand(params));
      console.log('Success');
   } 

 catch(err){
     console.log('Error', err.stack); 
  }  
  return JSON.stringify({
  statusCode: 200,
  body: 'Lambda function executed successfully'
});

}
