# Wait for Ingestion to Complete
After deploying the ingestion Terraform resources you will need to wait for the ingestion to complete before being able to search the documents.
1. Navigate to the infrastructure directory `cd ~/semantic-search-aws-docs/infrastructure`.
1. Run `eval ECS_CLUSTER_ARN=$(terraform output ecs_cluster_arn)` to get the ARN of your Amazon ECS cluster.
2. Run `aws ecs list-tasks --family ingestion-job --region $REGION --cluster $ECS_CLUSTER_ARN`. Copy the arn of the ingestion job task from the commands output.
3. Run `aws ecs wait tasks-stopped --region $REGION --cluster $ECS_CLUSTER_ARN --tasks <REPLACE_WITH_INGESTION_JOB_ARN>` to wait until the ingestion of the documents completes. Replace `<REPLACE_WITH_INGESTION_JOB_ARN>` with the arn of the ECS task that is running the ingestion job form the previous commands output. When the command exists with _Waiter TasksStopped failed: Max attempts exceeded_ as the message run the command again. Once the command exits without any output then the ingestion job completed.
4. After the ingestion completes run `terraform output loadbalancer_url` to get the URL for the semantic search frontend.