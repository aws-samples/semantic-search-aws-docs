# Wait for Ingestion to Complete
After deploying the ingestion Terraform resources you will need to wait for the ingestion to complete before being able to search the documents. Check the [Amazon Elastic Container Service console](https://console.aws.amazon.com/ecs) to see when the task completes, or use below AWS CLI commands to wait for the task to complete.

## Wait in AWS Console
Go to the Tasks page of your Amazon ECS Cluster that the infrastructure stack deployed. The default name of the cluster is *NLPSearchECSCluster*. In Tasks list look for the task that has `ingestion-job` as the Task definition. Wait until the status of the `ingestion-job` task changes from *Running* to *Stopped*.

## Use AWS CLI to wait
1. Navigate to the infrastructure directory `cd ~/semantic-search-aws-docs/infrastructure`.
1. Run `ECS_CLUSTER_ARN=$(terraform output --raw ecs_cluster_arn)` to get the ARN of your Amazon ECS cluster.
2. Run `TASK_ARN=$(aws ecs list-tasks --family ingestion-job --region $REGION --cluster $ECS_CLUSTER_ARN --output text --query 'taskArns[0]')` to get the ARN of the ECS task that is ingesting the documents.
3. Run `aws ecs wait tasks-stopped --region $REGION --cluster $ECS_CLUSTER_ARN --tasks $TASK_ARN` to wait until the ingestion of the documents completes. When the command exits with _Waiter TasksStopped failed: Max attempts exceeded_ as the message run the command again. Once the command exits without any output then the ingestion job completed.
4. After the ingestion completes run `terraform output loadbalancer_url` to get the URL for the semantic search frontend.