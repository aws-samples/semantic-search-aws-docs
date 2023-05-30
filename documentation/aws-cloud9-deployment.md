# AWS Cloud9 Deployment
This document walks through the deployment of Semantic Search on AWS using AWS Cloud9. Following this guide deploys the semantic search application with default configurations.

## Create AWS Cloud9 environment
1. Open [AWS Cloud9 in AWS](https://console.aws.amazon.com/cloud9control/home)
2. Use the **Create environment** button to create a new AWS Cloud9 IDE.
    1. Give your AWS Cloud9 environment a name, for example `semantic-search-deployment`.
    2. Leave the other configurations as the defaults.
    3. **Create** the AWS Cloud9 environment.

## Open the AWS Cloud9 environment
1. Go to your [AWS Cloud9 Dashboard in AWS](https://console.aws.amazon.com/cloud9control/home)
2. In the list of AWS Cloud9 environments **open** your AWS Cloud9 environment that you created before. The **open** button opens your AWS Cloud9 IDE in a new browser tab. Wait for the Cloud9 IDE to connect. This may take a minute.

## Semantic Search Infrastructure Code
1. Execute `git clone https://github.com/aws-samples/semantic-search-aws-docs.git` in the terminal of your AWS Cloud9 IDE.

## Modify AWS Cloud9 EC2 Instance
Once your AWS Cloud9 environment creation completes you will need to increase the underlying EC2 instance storage to be able to pull the container images that the semantic search application deploys.
1. In the Terminal of your AWS Cloud9 IDE make the resize bash script executable `chmod +x ~/environment/semantic-search-aws-docs/cloud9/resize.sh`
2. Increase the Amazon EBS volume size of your AWS Cloud9 environment to 50 GB `~/environment/semantic-search-aws-docs/cloud9/resize.sh 50`

## AWS CLI Credentials
Terraform needs to access AWS resources from within your AWS Cloud9 environment to deploy the semantic search application. The recommended way to access AWS resources from within the AWS Cloud9 environment is to use [AWS managed temporary credentials](https://docs.aws.amazon.com/cloud9/latest/user-guide/security-iam.html#auth-and-access-control-temporary-managed-credentials-supported). For the semantic search deployment the AWS managed temporary credentials do not have sufficient permissions to create an Amazon EC2 instance profile.
1. In your AWS Cloud9 IDE at the top left click on **AWS Cloud9** and then on **Preferences**.
2. On the Preferences page navigate to **AWS Settings**, **Credentials**, and disable **AWS managed temporary credentials**.

You need to authenticate directly with the AWS CLI in your AWS Cloud9 IDE. To do so you need to follow one of the AWS CLI [Authentication and access credentials methods](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-authentication.html). Once you authenticated with the AWS CLI you can go on to the next step.

## GPU or CPU deployment
The default configuration uses GPU instances for the semantic search application. If you want to deploy this solution with GPU acceleration you will need to increase the _Running On-Demand G and VT instances_ [EC2 Service quota to at least 8](https://aws.amazon.com/premiumsupport/knowledge-center/ec2-instance-limit/).

To deploy the semantic search application without GPU instance open `semantic-search-aws-docs/infrastructure/main.tf` in your AWS Cloud9 IDE. Search for _Using a CPU instance_ in the Terraform file. Uncomment the CPU `image_id` and `instance_type` and add comments before the GPU `image_id` and `instance_type`. The code should now look like the following:
```
### Using a CPU instance ###
image_id      =  data.aws_ssm_parameter.ami.value #AMI name like amzn2-ami-ecs-hvm-2.0.20220520-x86_64-ebs
instance_type =  "c6i.2xlarge"

### Using a GPU instance ###
#image_id      = data.aws_ssm_parameter.ami_gpu.value #AMI name like amzn2-ami-ecs-gpu-hvm-2.0.20220520-x86_64-ebs
#instance_type = "g4dn.xlarge"
```

## Deploy Semantic Search Infrastructure
1. In your AWS Cloud9 environment terminal navigate to `cd ~/environment/semantic-search-aws-docs/infrastructure`.
2. Set the following environment variables. Change their value if you are using a different region other than `us-east-1` or if you want to give the Terraform state Amazon S3 bucket and state sync Amazon DynamoDB table different names.
    1. `REGION=us-east-1`
    2. `S3_BUCKET="terraform-semantic-search-state-$(date +%Y%m%dt%H%M%S)"`
    3. `SYNC_TABLE="terraform-semantic-search-state-sync"`
3. Create the Terraform state bucket in Amazon S3 `aws s3 mb s3://$S3_BUCKET --region=$REGION` 
4. Create the Terraform state sync table in Amazon DynamoDB `aws dynamodb create-table --table-name $SYNC_TABLE --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema   AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region=$REGION`
5. Initialize Terraform for the infrastructure deployment `terraform init -backend-config="bucket=$S3_BUCKET" -backend-config="region=$REGION" -backend-config="dynamodb_table=$SYNC_TABLE"`
6. Deploy the Semantic Search infrastructure with Terraform `terraform apply -var="region=$REGION" -var="index_name=awsdocs"`
    1. Change the terraform variable `index_name` if you want to change the name of your [index](https://opensearch.org/docs/latest/dashboards/im-dashboards/index-management/) in the Amazon OpenSearch cluster. The search API uses this variable to search for documents.
    2. Enter `yes` when Terraform prompts you _"to perform these actions"_.
    3. The deployment will take 10–20 minutes. Wait for completion before moving on with the document ingestion deployment.

## Deploy Semantic Search Ingestion
In your AWS Cloud9 environments terminal navigate to `cd ~/environment/semantic-search-aws-docs/ingestion`. 
* If you want to ingest the AWS documentation follow the **[Ingest AWS Documentation instructions](./ingest-aws-documentation.md)**.
* If instead you like to make local documents searchable follow the **[Local Documents Ingestion instructions](./ingest-custom-local-documents.md)**.

### Clean up Ingestion
After ingesting your documents you can remove the ingestion resources. Follow the [Clean up Ingestion Resources instructions](./clean-up-ingestion-resources.md) to clean up the ingestion resources.

## Clean up Infrastructure
Destroy the resources that were deployed for the infrastructure of the semantic search application if you are not using the application anymore.
1. In your AWS Cloud9 IDE navigate to the ingestion directory `cd ~/environment/semantic-search-aws-docs/infrastructure`
2. Clean up the semantic search application infrastructure with the `terraform destroy -var="region=$REGION"` command. 
    1. Run `eval REGION=$(terraform output region)` if your `REGION` variable is not set anymore.
3. Enter `yes` when Terraform prompts you _"Do you really want to destroy all resources?"_.
