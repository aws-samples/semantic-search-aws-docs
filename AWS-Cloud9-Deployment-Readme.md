# AWS Cloud9 Deployment
This document walks through the deployment of Semantic Search on AWS using AWS Cloud9. The purpose is to make it as easy as possible to deploy the solution with default configurations.

## Create AWS Cloud9 enviornment
1. Open [AWS Cloud9 in AWS](https://console.aws.amazon.com/cloud9control/home)
2. Use the **Create environment** button to create a new AWS Cloud9 IDE.
    1. Give your AWS Cloud9 environment a name, for example `semantic-search-deployment`.
    2. Leave all the other configurations as the defaults.
    3. **Create** the AWS Cloud9 enviornment.

## Open the AWS Cloud9 enviornment
With the increased storage space you can now open the AWS Cloud9 IDE.
1. Go to your [AWS Cloud9 Dashboard in AWS](https://console.aws.amazon.com/cloud9control/home)
2. In the list of AWS Cloud9 environments **open** your AWS Cloud9 enviroment that you created before. The **open** button opens your AWS Cloud9 IDE in a new browser tab. Wait for the Cloud9 IDE to connect. This can take a minute.

## Semantic Search Infrastructure Code
1. Execute `git clone https://github.com/aws-samples/semantic-search-aws-docs.git` in the terminal of your AWS Cloud9 IDE.

## Modify AWS Cloud9 EC2 Instance
Once your AWS Cloud9 environment creation completes you will need to increase the underlying EC2 instance storage to be able to pull all the container images that the semantic search solution deploys.
1. In the Terminal of your AWS Cloud9 IDE make the resize bash script executable `chmod +x ~/environment/semantic-search-aws-docs/cloud9/resize.sh`
2. Increase the Amazon EBS volume size of your AWS Cloud9 environment to 30 GB `~/environment/semantic-search-aws-docs/cloud9/resize.sh 30`

## AWS CLI Credentials
Terraform needs to access AWS resources from within your AWS Cloud9 environment to deploy the semantic search solution. The recommended way to access AWS resources from within the AWS Cloud9 environment is to use [AWS managed temporary credentials](https://docs.aws.amazon.com/cloud9/latest/user-guide/security-iam.html#auth-and-access-control-temporary-managed-credentials-supported). For the semantic search deployment the AWS managed temporary credentials do not have sufficient permissions to create an Amazon EC2 instance profile.
1. In your AWS Cloud9 IDE at the top left click on the **AWS Cloud9 Icon** and then on **Preferences**.
2. On the Preferences page navigate to **AWS Settings**, **Credentials**, and disable **AWS managed temporary credentials**.

You need to authenticate directly with the AWS CLI in your AWS Cloud9 IDE. To do so you need to follow one of the AWS CLI [Authentication and access credentials methods](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-authentication.html). Once you authenticated with the AWS CLI you can go on to the next step.

TODO GPU vs CPU setup
## Deploy Semantic Search Infrastructure
1. In your AWS Cloud9 environment terminal navigate to `cd ~/environment/semantic-search-aws-docs/infrastructure`.
2. Set the following environment variables. Change their value if you are using a different region other than `us-east-1` or if you want to give the Terraform state Amazon S3 bucket and state sync Amazon DynamoDB table different names.
    1. `STATE_REGION=us-east-1`
    2. `S3_BUCKET="terraform-semantic-search-state-$(date +%Y%m%dt%H%M%S)"`
    3. `SYNC_TABLE="terraform-semantic-search-state-sync"`
3. Create the Terraform state bucket in Amazon S3 `aws s3 mb s3://$S3_BUCKET --region=$STATE_REGION` 
4. Create the Terraform state sync table in Amazon DynamoDB `aws dynamodb create-table --table-name $SYNC_TABLE --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema   AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region=$STATE_REGION`
5. Intialize Terraform for the infrastructure deployment `terraform init -backend-config="bucket=$S3_BUCKET" -backend-config="region=$STATE_REGION" -backend-config="dynamodb_table=$SYNC_TABLE"`
6. Deploy the Semantic Search infrastructure with Terraform `terraform apply`
    1. Enter `yes` when Terraform prompts you _"to perform these actions"_.
    2. The deployment will take a few minutes. Wait for completion before moving on with the document ingestion deploymeny.

## Deploy Semantic Search Ingestion
Follow these steps to ingest the [Amazon EC2 User Guide for Linux](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide). To learn how you can ingest your own documents instead take a look at [Ingesting your own documents](https://github.com/aws-samples/semantic-search-aws-docs/tree/main#ingesting-your-own-documents).
1. In your AWS Cloud9 environments terminal navigate to `cd ~/environment/semantic-search-aws-docs/ingestion`
2. Intitalize Terraform `terraform init`
3. Deploy the ingestion resources `terraform apply -var="infra_region=$STATE_REGION" -var="infra_tf_state_s3_bucket=$S3_BUCKET" -var="aws_docs=amazon-ec2-user-guide"`
    1. You could replace `amazon-ec2-user-guide` with any of the AWS documentation repository names from the [AWS Docs GitHub](https://github.com/awsdocs), for example `amazon-eks-user-guide` or `full` to ingest all AWS Docs repos.
    2. Enter `yes` when Terraform prompts you _"to perform these actions"_. 


STATE_REGION=$(awk '/^region/ {gsub(/"/, "", $3); print $3}' terraform.tfvars)