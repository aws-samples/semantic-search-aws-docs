# Local Documents Ingestion
This document explains step-by-step how to ingest local documents to make them searchable using this AWS semantic search solution.

## Deploy Semantic Search Ingestion for Local Documents
The next steps guide you through ingesting documents from you local storage into the Amazon OpenSearch index. 
1. In your terminal navigate to the ingestion directory <br> `cd ~/semantic-search-aws-docs/ingestion`
2. Initialize Terraform <br> `terraform init`
2. Set `DOCS_DIR` variable to the path of the directory that contains the documents (e.g. `*.txt` files) that you want to ingest. The path needs to be relative to the [Dockerfile](/ingestion/Dockerfile) directory. For example use `DOCS_DIR=mydocs/data` to ingest all the documents located in the [ingestion/mydocs/data](/ingestion/mydocs/data/) directory.
3. Deploy the ingestion resources <br>`terraform apply -var-file="mydocs.tfvars" -var="infra_region=$REGION" -var="infra_tf_state_s3_bucket=$S3_BUCKET" -var="docs_src=$DOCS_DIR"`
    1. Enter `yes` when Terraform prompts you _"to perform these actions"_. 
4. After the successful deployment of the ingestion resources you need to wait until the ingestion task completes. Follow the [Wait for Ingestion to Complete instructions to check for completion from you terminal](ingest-wait-for-completion.md).

## Clean up Ingestion Resources
After ingesting your documents you can remove the ingestion resources. Follow the [Clean up Ingestion Resources instructions](./clean-up-ingestion-resources.md) to clean up the ingestion resources.