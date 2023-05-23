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
6. Deploy the Semantic Search infrastructure with Terraform `terraform apply -var="region=$REGION"`
    1. Enter `yes` when Terraform prompts you _"to perform these actions"_.
    2. The deployment will take 10–20 minutes. Wait for completion before moving on with the document ingestion deployment.

## Deploy Semantic Search Ingestion
The next steps guide you through ingesting the [Amazon EC2 User Guide for Linux](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide) into Amazon OpenSearch. To learn how you ingest your own documents instead take a look at [Ingesting your own documents](https://github.com/aws-samples/semantic-search-aws-docs/tree/main#ingesting-your-own-documents).
1. In your AWS Cloud9 environments terminal navigate to `cd ~/environment/semantic-search-aws-docs/ingestion`
2. Initialize Terraform `terraform init`
3. Deploy the ingestion resources `terraform apply -var="infra_region=$REGION" -var="infra_tf_state_s3_bucket=$S3_BUCKET" -var="aws_docs=amazon-ec2-user-guide"`
    1. You could replace `amazon-ec2-user-guide` with any of the AWS documentation repository names from the [AWS Docs GitHub](https://github.com/awsdocs), for example `amazon-eks-user-guide` or `full` to ingest all AWS Docs repos.
    2. Enter `yes` when Terraform prompts you _"to perform these actions"_. 
4. After the successful deployment of the ingestion resources you need to wait until the ingestion task completes.
    1. Run `cd ~/environment/semantic-search-aws-docs/infrastructure && terraform output ecs_cluster_arn` and copy the output which is the ARN of your Amazon ECS cluster.
    2. Run `aws ecs list-tasks --family ingestion-job --region $REGION --cluster <REPLACE_WITH_ECS_CLUSTER_ARN>`. Copy the arn of the ingestion job task from the commands output.
    3. Run `aws ecs wait tasks-stopped --region $REGION --cluster <REPLACE_WITH_ECS_CLUSTER_ARN> --tasks <REPLACE_WITH_INGESTION_JOB_ARN>` to wait until the ingestion of the documents completes. Replace `<REPLACE_WITH_INGESTION_JOB_ARN>` with the arn of the ECS task that is running the ingestion job form the previous commands output. When the command exists with _Waiter TasksStopped failed: Max attempts exceeded_ as the message run the command again. Once the command exits without any output then the ingestion job completed.
    4. After the ingestion completes run `cd ~/environment/semantic-search-aws-docs/infrastructure && terraform output loadbalancer_url` to get the URL for the semantic search frontend.

### Clean up Ingestion
You can clean up the ingestion resources immediately after ingesting the documents into your OpenSearch store. The ingestion executes as a one-off Amazon ECS task. For a production scenario with changes to the source documents you should consider [scheduling Amazon ECS tasks](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/scheduling_tasks.html) for ingesting the latest version of documents on a schedule.
1. In your AWS Cloud9 IDE navigate to the ingestion directory `cd ~/environment/semantic-search-aws-docs/ingestion`
2. Run `terraform destroy -var="infra_region=$REGION" -var="infra_tf_state_s3_bucket=$S3_BUCKET" -var="aws_docs=amazon-ec2-user-guide"` to clean up the ingestion resources.
    1. If the `REGION` variable is not set anymore you can run `eval REGION=$(terraform output infra_region)` to retrieve the region variable from the current deployment.
    2. If the `S3_BUCKET` variable is not set anymore you can run `eval S3_BUCKET=$(terraform output infra_tf_state_s3_bucket)` to set it again.
    3. If you do not remember which documents the current deployment ingested then you can use `terraform output aws_docs` and use the output as the input for the `aws_docs` variable in the `terraform destroy` command.
3. Enter `yes` when Terraform prompts you _"Do you really want to destroy all resources?"_.

## Clean up Infrastructure
Destroy the resources that were deployed for the infrastructure of the semantic search application if you are not using the application anymore.
1. In your AWS Cloud9 IDE navigate to the ingestion directory `cd ~/environment/semantic-search-aws-docs/infrastructure`
2. Clean up the semantic search application infrastructure with the `terraform destroy -var="region=$REGION"` command. 
    1. Run `eval REGION=$(terraform output region)` if your `REGION` variable is not set anymore.
3. Enter `yes` when Terraform prompts you _"Do you really want to destroy all resources?"_.

