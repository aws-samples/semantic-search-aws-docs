aws ecs run-task --region "$REGION" --cluster="$ECS_CLUSTER_NAME" --task-definition=ingestion-job --network-configuration='{"awsvpcConfiguration": {"subnets": '$JOB_SUBNETS',"securityGroups": ["'$JOB_SECURITY_GROUP'"], "assignPublicIp": "DISABLED" }}' --overrides='{"containerOverrides":[{"name":"ingestion-job","command":["'${DOCS_SRC}'","'${INDEX_NAME}'"]}]}'

