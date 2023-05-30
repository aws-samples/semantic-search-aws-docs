provider "aws" {
  region = data.terraform_remote_state.infra.outputs.region
  default_tags {
    tags = {
      Project = "semantic-search-aws-docs"
    }
  }
}

provider "docker" {
  registry_auth {
    address  = local.aws_ecr_url
    username = data.aws_ecr_authorization_token.token.user_name
    password = data.aws_ecr_authorization_token.token.password
  }
}

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = ">=2.16.0"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_ecr_authorization_token" "token" {}

locals {
  aws_ecr_url = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.terraform_remote_state.infra.outputs.region}.amazonaws.com"
}

resource "aws_ecr_repository" "ingestion_job" {
  name         = "ingestion-job"
  force_delete = true
}

resource "docker_registry_image" "ingestion_job" {
  name = docker_image.ingestion_job_image.name
}

resource "docker_image" "ingestion_job_image" {
  name = "${local.aws_ecr_url}/${aws_ecr_repository.ingestion_job.name}:latest"
  build {
    context    = "${path.cwd}/"
    dockerfile = "Dockerfile"
    build_args = {
      DOC_DIR = var.docs_dir
      SCRIPT_NAME= var.script_name
    }
  }
}


data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = var.infra_tf_state_s3_bucket
    key    = var.infra_tf_state_s3_key
    region = var.infra_region
  }
}


resource "aws_ecs_task_definition" "ingestion_job" {
  family                   = "ingestion-job"
  container_definitions    = <<DEFINITION
  [
    {
      "dnsSearchDomains": null,
      "environmentFiles": null,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${data.terraform_remote_state.infra.outputs.log_group_name}",
          "awslogs-region": "${data.terraform_remote_state.infra.outputs.region}",
          "awslogs-stream-prefix": "ingestion-job"
        }
      },
      "entryPoint": null,
      "portMappings":  null,
      "command": [
        "${var.aws_docs}",
        "${data.terraform_remote_state.infra.outputs.index_name}"
      ],
      "linuxParameters": null,
      "cpu": 0,
      "secrets": [
          {
              "valueFrom": "${data.terraform_remote_state.infra.outputs.opensearch_secret}",
              "name": "OPENSEARCH_PASSWORD"
          }
      ],
      "environment": [
        {
           "name": "OPENSEARCH_HOST",
           "value": "${data.terraform_remote_state.infra.outputs.opensearch_endpoint}"
        }
      ],
      "image": "${aws_ecr_repository.ingestion_job.repository_url}:latest",
      "essential": true,
      "name": "ingestion-job"
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"] # Stating that we are using ECS Fargate
  network_mode             = "awsvpc"    # Using awsvpc as our network mode as this is required for Fargate
  memory                   = 8192        # Specifying the memory our container requires
  cpu                      = 4096        # Specifying the CPU our container requires
  execution_role_arn       = data.terraform_remote_state.infra.outputs.ingestion_job_role
}


# Execute the ingestion job as once-off ECS task (by running a shell script with the aws cli command)
# There is currently no native aws terraform support for the ECS run-task api.
resource "null_resource" "run_ingestion_ecs_job" {

  # rerun on every apply. 
  triggers = {
    timestamp = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "bash run_ingestion_job_ecs.sh"
    environment = {
      REGION             = "${data.terraform_remote_state.infra.outputs.region}"
      ECS_CLUSTER_NAME   = "${data.terraform_remote_state.infra.outputs.ecs_cluster_name}"
      JOB_SUBNETS        = "${jsonencode(data.terraform_remote_state.infra.outputs.private_subnets)}"
      JOB_SECURITY_GROUP = "${data.terraform_remote_state.infra.outputs.security_group_for_open_search_access}"
      AWSDOC             = "${var.aws_docs}"
      INDEX_NAME         = "${data.terraform_remote_state.infra.outputs.index_name}"
    }
  }
  depends_on = [
    docker_registry_image.ingestion_job
  ]
}