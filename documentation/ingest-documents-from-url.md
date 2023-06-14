# Ingest Documents from URL
This document explains step-by-step how to ingest documents from an archive at a URL to make them searchable using this AWS semantic search solution.

If you are on MacOS make sure that when compressing your documents into the archive that it does not add AppleDouble blobs `*_` files, see also [this StackExchange answer for the question Create tar archive of a directory, except for hidden files?](https://unix.stackexchange.com/a/9865)

## Deploy Semantic Search Ingestion for Documents from URL
The next steps guide you through ingesting documents from a URL into the Amazon OpenSearch index. The URL needs to point to an archive (zip, gz or tar.gz) and has to be accessible from the `NLPSearchPrivateSubnet` subnet. The subnet can reach the internet through a NAT gateway.
1. In your terminal navigate to `cd ~/semantic-search-aws-docs/ingestion`
2. Initialize Terraform `terraform init`
2. Set `DOCS_SRC` variable to the URL from which you want to ingest the documents from, for example  if your documents are in Amazon S3 then you could create a [presigned URL](https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-presigned-url.html) for the archive in Amazon S3 and assign `DOCS_SRC=https://<BUCKET_NAME>.s3.<REGION>.amazonaws.com/data.zip?response-content-disposition=inline&X-Amz-Security-Token=[...]`.
3. Deploy the ingestion resources `terraform apply -var-file="urldocs.tfvars" -var="infra_region=$REGION" -var="infra_tf_state_s3_bucket=$S3_BUCKET" -var="docs_src=$DOCS_SRC"`
    1. Enter `yes` when Terraform prompts you _"to perform these actions"_. 
4. After the successful deployment of the ingestion resources you need to wait until the ingestion task completes. Follow the [Wait for Ingestion to Complete instructions to check for completion from you terminal](ingest-wait-for-completion.md).

## Clean up Ingestion Resources
After ingesting your documents you can remove the ingestion resources. Follow the [Clean up Ingestion Resources instructions](./clean-up-ingestion-resources.md) to clean up the ingestion resources.