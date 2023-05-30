# Semantic Search on AWS Docs

This sample project demonstrates how to set up AWS infrastructure to perform semantic search and [question answering](https://en.wikipedia.org/wiki/Question_answering) on documents using a transformer machine learning models like BERT, RoBERTa, or GPT (via the [Haystack](https://github.com/deepset-ai/haystack) open source framework).

As an example, users can type questions about AWS services and find answers from the AWS documentation.

The deployed solution support 2 answering styles:
- `extractive question answering` will find the semantically closest
documents to the questions and highlight the most likeliest answer(s) in these documents.
- `generative question answering`, also referred to as long form question answering (LFQA), will find the semantically closest documents to the question and generate a formulated answer.

Please note that this project is intended for demo purposes, see disclaimers below.

![](appdemo.gif?raw=true)

## Architecture

![](semantic-search-arch-application.png?raw=true)

The main components of this project are:

* [Amazon OpenSearch Service](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/what-is.html) to store and search documents
* The [AWS Documentation](https://github.com/awsdocs/) as a sample dataset loaded in the document store
* The [Haystack framework](https://www.deepset.ai/haystack) to set up an extractive [Question Answering pipeline](https://haystack.deepset.ai/tutorials/first-qa-system) with:
    * A [Retriever](https://haystack.deepset.ai/pipeline_nodes/retriever) that searches all the documents and returns only the most relevant ones
        * Retriever used: [sentence-transformers/all-mpnet-base-v2](https://huggingface.co/sentence-transformers/all-mpnet-base-v2)
    * A [Reader](https://haystack.deepset.ai/pipeline_nodes/reader) that uses the documents returned by the Retriever and selects a text span which is likely to contain the matching answer to the query
        * Reader used: [deepset/roberta-base-squad2](https://huggingface.co/deepset/roberta-base-squad2)
* [Streamlit](https://streamlit.io/) to set up a frontend
* [Terraform](https://www.terraform.io/) to automate the infrastructure deployment on AWS

## How to deploy the solution

### Deploy with AWS Cloud9
Follow our [step-by-step deployment instructions](documentation/aws-cloud9-deployment.md) to deploy the semantic search application if you are new to AWS, Terraform, semantic search, or you prefer detailed setp-by-step instructions.

For more general deployment instructions follow the sections below.

### General Deployment Instructions 
The backend folder contains a Terraform project that deploys an OpenSearch domain and 2 ECS services:

* frontend: Streamlit-based UI built by Haystack ([repo](https://github.com/deepset-ai/haystack/tree/master/ui))
* search API: REST API built by Haystack

The main steps to deploy the solution are:

* Deploy the terraform stack
* Optional: Ingest the AWS documentation

#### Pre-requisites

* Terraform v1.0+ ([getting started guide](https://learn.hashicorp.com/collections/terraform/aws-get-started))
* Docker installed and running ([getting started guide](https://www.docker.com/get-started/))
* AWS CLI v2 installed and configured ([getting started guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html))
* An [EC2 Service Limit of at least 8 cores for G-instance type](https://aws.amazon.com/premiumsupport/knowledge-center/ec2-instance-limit/) if you want to deploy this solution with GPU acceleration.  
Alternatively, you can switch to a CPU instance by changing the `instance_type = "g4dn.2xlarge"` to a CPU instance in the `infrastructure/main.tf` file.

#### Deploy the application infrastructure terraform stack

* git clone this repository
* **Configure**
Configure and change the infrastructure region, subnets, availability zones in the `infrastructure/terraform.tfvars` file as needed
* **Initialize**  
In this example the Terrform state is stored remotely and managed through a backend using S3 and a dynamodb table to acquire the state lock. This allows collaboration on the same Terraform infrastructure from different machines.
( If you prefer to use local state instead just remove the `terraform { backend "s3" { ...}}` block from the `infrastructure/tf-backend.tf` file and run directly `terraform init`)
    * Create an S3 Bucket and DynamoDB to store the Terraform [state backend](https://www.terraform.io/language/settings/backends/s3) in a region of choice.
      ```shell
      STATE_REGION=<AWS region>
      ```
      ```shell
      S3_BUCKET=<YOUR-BUCKET-NAME>
      aws s3 mb s3://$S3_BUCKET -region=$STATE_REGION
      ```
      ```shell
      SYNC_TABLE=<YOUR-TABLE-NAME>
      aws dynamodb create-table --table-name $SYNC_TABLE --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema   AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region=$STATE_REGION
      ```
   * Change to the directory containing the application infrastucture's `infrastructure/main.tf` file
      ```shell
      cd infrastructure
      ```
   * Initialize terraform with the S3 remote state backend by running
      ```shell
      terraform init \
      -backend-config="bucket=$S3_BUCKET" \
      -backend-config="region=$STATE_REGION" \
      -backend-config="dynamodb_table=$SYNC_TABLE"
      ```

* **Deploy**  
Run terraform deploy and approve changes by typing yes.
    ```shell
    terraform apply
    ```    
    ***Please note:*** _deployment can take a long time to push the container depending on the upload bandwidth of your machine.  
    For faster deployment you can run the terraform deployment from a development environment hosted inside the same AWS region, for example by using the [AWS Cloud9](https://aws.amazon.com/cloud9/) IDE._
* **Use**  
Once deployment is completed, browse to the output URL (`loadbalancer_url`) from the Terraform output to see the appliction.   
However, searches won't return any results until you ingest any documents.
* **Clean up**  
  To remove all created resources of the applications infrastructure again use
  ```shell
  terraform destroy
  ```
  (If you used the ingestion terrform below, make sure to first destroy the ingestion resources to avoid conflicts)

#### Ingest the AWS documentation

This second terraform stack builds, pushes and runs a docker container as an ECS task.  
The ingestion container downloads either a single (e.g. `amazon-ec2-user-guide`) or all awsdocs repos (256) (`full`) and converts the .md files into .txt using pandoc.  
The .txt documents are then being ingested into the applications OpenSearch cluster in the required haystack format and become available for search

![](semantic-search-arch-ingestion.png?raw=true)

* Change from the `infrastructure` directory to the directory containing the ingestion's `ingestion/main.tf`
   ```shell
    cd ../ingestion
    ```
* Init terraform  
(here we are using local state instead of a remote S3 backend for simplicity)
    ```shell
    terraform init
    ```
* Run ingestion as Terraform deployment.  
The S3 remote state file from the previous infrastructure deployment is needed here as input variables.  
It is used as data source to read out the infra's output variables like the OpenSearch endpoint or private subnets. 
You can set the S3 bucket and its region either in the `infrastructure/terraform.tfvars` or passing the input variables via
    ```shell
    terraform apply \
    -var="infra_region=$STATE_REGION" \
    -var="infra_tf_state_s3_bucket=$S3_BUCKET"
    ```   
    ***Please note:*** _deployment can take a long time to push the container depending on the upload bandwidth of your machine. For faster deployment you can build and push the container in AWS, for example by using the [AWS Cloud9](https://aws.amazon.com/cloud9/) IDE._
* Once the previous step finsihes, the ECS ingestion task is started. You can check its progress in the AWS console, for example in Amazon CloudWatch under the log group name `semantic-search` and checking `ingestion-job`. After the task finsihed successfully, the ingested documents are searchable via the application.
* After runing the ingestion job, you can remove the created ingestion resources, e.g. ECR repository or task definition by running
    ```shell
    terraform destroy \
    -var="infra_region=$STATE_REGION" \
    -var="infra_tf_state_s3_bucket=$S3_BUCKET"
    ```

#### Ingesting your own documents

Take a look at the `ingestion/awsdocs/ingest.py` how adopt the ingestion script for your own documents. In brief, you can ingest local or downloaded files via:
```python
# Create a wrapper for the existing OpenSearch document store
document_store = OpenSearchDocumentStore(...)

# Covert local files
dicts_aws = convert_files_to_docs(dir_path=..., ...)

# Write the documents to the OpenSearch document store
document_store.write_documents(dicts_aws, index=...)

# Compute and update the embeddings for each document with a transformer ML model. 
# An embedding is the vector representation that is learned by the transformer and that
# allows us to capture and compare the semantic meaning of documents via this 
# vector representation. 
# Be sure to use the same model that you want to use later in the search pipeline.
retriever = EmbeddingRetriever(
    document_store=document_store,
    model_format = "sentence_transformers",
    embedding_model = "all-mpnet-base-v2"
)
document_store.update_embeddings(retriever)
```

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## Contributing

If you want to contribute to Haystack, check out their [GitHub repository](https://github.com/deepset-ai/haystack).

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

## Disclaimer

This solution is intended to demonstrate the functionality of using machine learning models for semantic search and question answering. They are not intended for production deployment as is.

For best practices on modifying this solution for production use cases, please follow the [AWS well-architected guidance](https://aws.amazon.com/architecture/well-architected/).
