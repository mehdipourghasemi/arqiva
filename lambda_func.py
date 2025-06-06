import os
import boto3

def lambda_handler(event, context):
    bucket_name = os.getenv('BUCKET_NAME', 'mehdi-arqiva-test-bucket')
    s3 = boto3.client('s3')

    try:
        # I intentionally used query string (instead of body) and don't  
        # restrict method to POST to make it easy to use it in a browser
        query_params = event.get('queryStringParameters', {})
        new_value = query_params.get('str_value', None) 
        if not new_value:
            raise ValueError("Inavlid value!")
        html = f"<h1>The saved string is {new_value}</h1>"
        s3.put_object(
            Bucket = bucket_name,
            Key = 'index.html',
            Body = html,
            ContentType = 'text/html'
        )

        return {
            'statusCode': 200,
            'body': 'Successfully updated.'
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': f'Error: {str(e)}'
        }
