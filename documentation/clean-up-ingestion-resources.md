# Clean up Ingestion Resources
You can clean up the ingestion resources immediately after ingesting the documents into your OpenSearch index. The ingestion executes as a one-off Amazon ECS task. For a production scenario with changes to the source documents you should consider [scheduling Amazon ECS tasks](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/scheduling_tasks.html) for ingesting the latest version of documents on a schedule.
1. In your terminal navigate to the ingestion directory `cd ~/semantic-search-aws-docs/ingestion` in this repository.
2. Run `terraform destroy -var-file="awsdocs.tfvars" -var="infra_region=$REGION" -var="infra_tf_state_s3_bucket=$S3_BUCKET" -var="aws_docs=(eval sed -e 's/^"//' -e 's/"$//' <<< (terraform output aws_docs))"` to clean up the ingestion resources.
3. Enter `yes` when Terraform prompts you _"Do you really want to destroy all resources?"_.

