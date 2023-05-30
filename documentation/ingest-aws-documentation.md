# Ingest AWS Documentation
The next steps guide you through ingesting the [Amazon EC2 User Guide for Linux](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide) into your Amazon OpenSearch index to make the AWS documentation searchable. To learn how you ingest your own documents instead take a look at [Ingesting your own documents](ingest-custom-local-documents.md).
1. In your terminal navigate to `cd ~/semantic-search-aws-docs/ingestion` in this repository.
2. Initialize Terraform `terraform init`
3. Run `AWS_DOCS=amazon-ec2-user-guide`. `amazon-ec2-user-guide` references the name of the [GitHub repository that contains the Amazon EC2 User Guide for Linux](https://github.com/awsdocs/amazon-ec2-user-guide). You can replace `amazon-ec2-user-guide` with any of the AWS documentation repository names from the [AWS Docs GitHub](https://github.com/awsdocs), for example `amazon-eks-user-guide` or `full` to ingest all AWS Docs repos.
3. Deploy the ingestion resources `terraform apply -var-file="awsdocs.tfvars" -var="infra_region=$REGION" -var="infra_tf_state_s3_bucket=$S3_BUCKET" -var="aws_docs=$AWS_DOCS"`
    2. Enter `yes` when Terraform prompts you _"to perform these actions"_. 
4. After the successful deployment of the ingestion resources you need to wait until the ingestion task completes. Follow the [Wait for Ingestion to Complete instructions to check for completion from you terminal](ingest-wait-for-completion.md).

## Clean up Ingestion Resources
After ingesting your documents you can remove the ingestion resources. Follow the [Clean up Ingestion Resources instructions](./clean-up-ingestion-resources.md) to clean up the ingestion resources.