# Arqiva Technical Challenge

A simple HTML page hosted on a S3 bucket which can be updated dynamically via a Lambda function.

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform installed

## Deployment

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the infrastructure
terraform apply
```

## Usage

After deployment, you'll receive two URLs:

1. **Website URL**: View HTML page in a browser
2. **Lambda Update URL**: Update HTML page content

To update the website content you can use your browser or curl:
```bash
curl "https://your-lambda-url/?str_value=Hello%20Arqiva"
```

## Clean Up

```bash
terraform destroy
```