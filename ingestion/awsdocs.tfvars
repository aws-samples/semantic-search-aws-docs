#infra_region = ""
#infra_tf_state_s3_bucket = ""
infra_tf_state_s3_key = "semantic-search/terraform.tfstate"
docs_dir = "" # empty because we are not ingesting local documents
script_name = "run_ingestion_awsdocs"
aws_docs              = "amazon-eks-user-guide" #select the repo to be ingested like "amazon-eks-user-guide"
