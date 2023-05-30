provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project = "semantic-search-aws-docs"
    }
  }
}

### Networking ###
resource "aws_vpc" "aws-vpc" {
  cidr_block = var.vpc_cidr

  enable_dns_hostnames = true # Required for DNS-based service discovery
  enable_dns_support   = true # Required for DNS-based service discovery
  tags = {
    name = "NLPSearchVPC"
  }
}
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.aws-vpc.id
  count             = length(var.private_subnets)
  cidr_block        = element(var.private_subnets, count.index)
  availability_zone = element(var.availability_zones, count.index)
  tags = {
    Name = "NLPSearchPrivateSubnet"
    Tier = "Private"
  }
}
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.aws-vpc.id
  cidr_block              = element(var.public_subnets, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  count                   = length(var.public_subnets)
  map_public_ip_on_launch = true
  tags = {
    Name = "NLPSearchPublicSubnet"
    Tier = "Public"
  }
}
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.aws-vpc.id
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.aws-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}
resource "aws_alb" "main" {
  name               = "nlp-search-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = aws_subnet.public.*.id
  security_groups    = [aws_security_group.alb.id]
}
resource "aws_lb_target_group" "search_ui" {
  name        = "nlp-search-alb-target-group"
  port        = 8501
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.aws-vpc.id

  health_check {
    protocol            = "HTTP"
    healthy_threshold   = "3"
    interval            = "30"
    matcher             = "200"
    timeout             = "10"
    path                = "/"
    unhealthy_threshold = "2"
  }
}
resource "aws_lb_listener" "search_ui" {
  load_balancer_arn = aws_alb.main.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.search_ui.id
  }
}

resource "aws_eip" "nat_gw" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat_gw.id
  subnet_id     = element(aws_subnet.public.*.id, 0)

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.aws-vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.private.id
}

### Logs ###
resource "aws_cloudwatch_log_group" "app" {
  name              = "/semantic-search"
  retention_in_days = 30
}


### IAM ###
resource "aws_iam_role" "search_ui" {
  name = "NLPSearchSearchUIECSTaskRole"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "search_ui" {
  role       = aws_iam_role.search_ui.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "search_api" {
  name = "NLPSearchSearchAPIECSTaskRole"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "search_api" {
  role       = aws_iam_role.search_api.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy" "sm" {
  name        = "ecs-secrets-manager-policy"
  description = "Giving an ECS task access to the OpenSearch credientials in Secrete Manager"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Effect": "Allow",
      "Resource": "${aws_secretsmanager_secret.opensearch.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "search_api_sm" {
  role       = aws_iam_role.search_api.name
  policy_arn = aws_iam_policy.sm.arn
}

### EC2 instance role/profile with permissions to register in ECS, pull from ECR, logging to CloudWatch
data "aws_iam_policy_document" "ec2_node_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_node" {
  assume_role_policy = data.aws_iam_policy_document.ec2_node_assume_role.json
  name               = "NLPSearchClusterNodeRole"
}

resource "aws_iam_role_policy_attachment" "ecs_node" {
  role       = aws_iam_role.ec2_node.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_node_ssm" {
  role       = aws_iam_role.ec2_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ecs_ec2_node" {
  name = "NLPSearchClusterNodeProfile"
  role = aws_iam_role.ec2_node.name
}


### Security Groups ###

resource "aws_security_group" "search_ui" {
  vpc_id      = aws_vpc.aws-vpc.id
  description = "Managed by Terraform. Configuring TCP ingress on port 8501 from the ALB security group."

  ingress {
    description     = "TCP 8501 from ALB"
    from_port       = 8501
    to_port         = 8501
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "NLPSearchSearchUISecurityGroup"
  }
}

resource "aws_security_group" "search_api" {
  vpc_id      = aws_vpc.aws-vpc.id
  description = "Managed by Terraform. Configuring TCP ingress on port 8000 from the search UI security group"

  ingress {
    description     = "TCP 8000 from Search UI"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.search_ui.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "NLPSearchSearchAPISecurityGroup"
  }
}

resource "aws_security_group" "alb" {
  vpc_id      = aws_vpc.aws-vpc.id
  description = "Managed by Terraform. Configuring HTTP(S) access from the internet"

  ingress {
    description      = "HTTP from public internet"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "TLS from public internet"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "NLPSearchALBSecurityGroup"
  }
}

### ECS Cluster###
resource "aws_ecs_cluster" "main" {
  name = "NLPSearchECSCluster"
}
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = [aws_ecs_capacity_provider.ec2_gpu.name, "FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }
}

resource "aws_ecs_capacity_provider" "ec2_gpu" {
  name = "ec2_gpu_capacity_provider"
  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ec2_gpu.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      status          = "ENABLED"
      target_capacity = 50
    }
  }
}

resource "aws_autoscaling_group" "ec2_gpu" {
  name_prefix               = "ecs_cluster_node_"
  desired_capacity          = 2
  max_size                  = 10
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"
  vpc_zone_identifier       = aws_subnet.private.*.id

  launch_template {
    id      = aws_launch_template.ec2_gpu.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
}

data "aws_ssm_parameter" "ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

data "aws_ssm_parameter" "ami_gpu" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/gpu/recommended/image_id"
}


resource "aws_launch_template" "ec2_gpu" {
  name_prefix = "ec2_gpu_launch_template"

  ### Using a CPU instance ###
  #image_id      =  data.aws_ssm_parameter.ami.value #AMI name like amzn2-ami-ecs-hvm-2.0.20220520-x86_64-ebs
  #instance_type =  "c6i.2xlarge"

  ### Using a GPU instance ###
  image_id      = data.aws_ssm_parameter.ami_gpu.value #AMI name like amzn2-ami-ecs-gpu-hvm-2.0.20220520-x86_64-ebs
  instance_type = "g4dn.xlarge"

  vpc_security_group_ids = [aws_security_group.search_api.id]
  iam_instance_profile {
    arn = aws_iam_instance_profile.ecs_ec2_node.arn
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "NLPSearchInstance"
    }
  }
  user_data = base64encode(<<EOF
#!/bin/bash
echo ECS_CLUSTER="${aws_ecs_cluster.main.name}" >> /etc/ecs/ecs.config
echo ECS_ENABLE_CONTAINER_METADATA=true >> /etc/ecs/ecs.config
echo ECS_ENABLED_GPU_SUPPORT=true >> /etc/ecs/ecs.config
EOF
  )
}


### ECS Tasks and Services ###

resource "aws_ecs_service" "search_ui" {
  name            = "search_ui"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.search_ui.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = aws_subnet.private.*.id
    security_groups = [aws_security_group.search_ui.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.search_ui.arn
    container_name   = "search-ui"
    container_port   = 8501
  }

  depends_on = [aws_lb_listener.search_ui, docker_registry_image.search_ui]

}


resource "aws_ecs_task_definition" "search_ui" {
  family                   = "search-ui"
  container_definitions    = <<DEFINITION
  [
    {
      "dnsSearchDomains": null,
      "environmentFiles": null,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.app.name}",
          "awslogs-region": "${data.aws_region.current.name}",
          "awslogs-stream-prefix": "search-ui"
        }
      },
      "entryPoint": null,
      "portMappings": [
        {
          "hostPort": 8501,
          "protocol": "tcp",
          "containerPort": 8501
        }
      ],
      "command": null,
      "linuxParameters": null,
      "cpu": 0,
      "environment": [
        {
          "name": "API_ENDPOINT",
          "value": "http://api.nlp.service:8000"
        },
        {
          "name": "API_ENDPOINT_GENERATIVE",
          "value": "http://api-gen.nlp.service:8000"
        },
        {
          "name": "EVAL_FILE",
          "value": "eval_labels_example.csv"
        },
        {
          "name": "STREAMLIT_GATHER_USAGE_STATS",
          "value": "false"
        }
      ],
      "resourceRequirements": null,
      "image": "${aws_ecr_repository.search_ui.repository_url}:latest",
      "essential": true,
      "name": "search-ui"
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"] # Stating that we are using ECS Fargate
  network_mode             = "awsvpc"    # Using awsvpc as our network mode as this is required for Fargate
  memory                   = 4096        # Specifying the memory our container requires
  cpu                      = 2048        # Specifying the CPU our container requires
  execution_role_arn       = aws_iam_role.search_ui.arn
}

resource "aws_ecs_service" "search_api" {
  name            = "search_api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.search_api.arn
  desired_count   = 1
  launch_type     = "EC2"

  network_configuration {
    subnets         = aws_subnet.private.*.id
    security_groups = [aws_security_group.search_api.id]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.api.arn
  }

  depends_on = [aws_elasticsearch_domain.es, docker_registry_image.search_api]

}


resource "aws_ecs_service" "search_api_generative" {
  name            = "search_api_generative"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.search_api_generative.arn
  desired_count   = 1
  launch_type     = "EC2"

  network_configuration {
    subnets         = aws_subnet.private.*.id
    security_groups = [aws_security_group.search_api.id]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.api_gen.arn
  }

  depends_on = [aws_elasticsearch_domain.es, docker_registry_image.search_api]

}

resource "aws_ecs_task_definition" "search_api" {
  family                   = "search-api"
  container_definitions    = <<DEFINITION
  [
    {
      "dnsSearchDomains": null,
      "environmentFiles": null,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.app.name}",
          "awslogs-region": "${data.aws_region.current.name}",
          "awslogs-stream-prefix": "search-api"
        }
      },
      "entryPoint": null,
      "portMappings": [
        {
          "hostPort": 8000,
          "protocol": "tcp",
          "containerPort": 8000
        }
      ],
      "command": null,
      "linuxParameters": null,
      "cpu": 0,
      "secrets": [
          {
              "valueFrom": "${aws_secretsmanager_secret.opensearch.arn}",
              "name": "DOCUMENTSTORE_PARAMS_PASSWORD"
          }
      ],
      "environment": [
        {
            "name": "PIPELINE_YAML_PATH",
            "value": "/home/user/rest_api/pipeline/aws-search.haystack-pipeline.yml"
        },
        {
           "name": "DOCUMENTSTORE_PARAMS_HOST",
           "value": "${aws_elasticsearch_domain.es.endpoint}"
        },
        {
           "name": "DOCUMENTSTORE_PARAMS_PORT",
           "value": "443"
        },
        {
           "name": "DOCUMENTSTORE_PARAMS_INDEX",
           "value": "${var.index_name}"
        },
        {
           "name": "DOCUMENTSTORE_PARAMS_USERNAME",
           "value": "admin"
        }
      ],
      "image": "${aws_ecr_repository.search_api.repository_url}:latest",
      "essential": true,
      "name": "search-api"
    }
  ]
  DEFINITION
  requires_compatibilities = ["EC2"]  # Stating that we are using ECS Fargate
  network_mode             = "awsvpc" # Using awsvpc as our network mode as this is required for Fargate
  memory                   = 8192     # Specifying the memory our container requires
  cpu                      = 4096     # Specifying the CPU our container requires
  execution_role_arn       = aws_iam_role.search_api.arn
}

resource "aws_ecs_task_definition" "search_api_generative" {
  family                   = "search-api-generative"
  container_definitions    = <<DEFINITION
  [
    {
      "dnsSearchDomains": null,
      "environmentFiles": null,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.app.name}",
          "awslogs-region": "${data.aws_region.current.name}",
          "awslogs-stream-prefix": "search-api-generative"
        }
      },
      "entryPoint": null,
      "portMappings": [
        {
          "hostPort": 8000,
          "protocol": "tcp",
          "containerPort": 8000
        }
      ],
      "command": null,
      "linuxParameters": null,
      "cpu": 0,
      "secrets": [
          {
              "valueFrom": "${aws_secretsmanager_secret.opensearch.arn}",
              "name": "DOCUMENTSTORE_PARAMS_PASSWORD"
          }
      ],
      "environment": [
        {
            "name": "PIPELINE_YAML_PATH",
            "value": "/home/user/rest_api/pipeline/aws-search-generative.haystack-pipeline.yml"
        },
        {
           "name": "DOCUMENTSTORE_PARAMS_HOST",
           "value": "${aws_elasticsearch_domain.es.endpoint}"
        },
        {
           "name": "DOCUMENTSTORE_PARAMS_PORT",
           "value": "443"
        },
        {
           "name": "DOCUMENTSTORE_PARAMS_INDEX",
           "value": "${var.index_name}"
        },
        {
           "name": "DOCUMENTSTORE_PARAMS_USERNAME",
           "value": "admin"
        }
      ],
      "resourceRequirements": [
        {
          "type" : "GPU", 
          "value" : "1"
        }
      ],
      "image": "${aws_ecr_repository.search_api.repository_url}:latest",
      "essential": true,
      "name": "search-api-generative"
    }
  ]
  DEFINITION
  requires_compatibilities = ["EC2"]  # Stating that we are using ECS Fargate
  network_mode             = "awsvpc" # Using awsvpc as our network mode as this is required for Fargate
  memory                   = 8192     # Specifying the memory our container requires
  cpu                      = 4096     # Specifying the CPU our container requires
  execution_role_arn       = aws_iam_role.search_api.arn
}


### Docker & ECR repository ###

resource "aws_ecr_repository" "search_api" {
  name         = "search-api"
  force_delete = true
}

resource "aws_ecr_repository" "search_ui" {
  name         = "search-ui"
  force_delete = true
}

# Following example in https://registry.terraform.io/providers/kreuzwerker/docker/3.0.0/docs/resources/registry_image
resource "docker_registry_image" "search_api" {
  name = docker_image.search_api_image.name
}
resource "docker_image" "search_api_image" {
  name = "${local.aws_ecr_url}/${aws_ecr_repository.search_api.name}:latest"
  build {
    context    = "../application/backend/"
    dockerfile = "search-api.Dockerfile"
  }
}

resource "docker_registry_image" "search_ui" {
  name = docker_image.search_ui_image.name
}

resource "docker_image" "search_ui_image" {
  name = "${local.aws_ecr_url}/${aws_ecr_repository.search_ui.name}:latest"

  build {
    context    = "../application/frontend/"
    dockerfile = "search-ui.Dockerfile"
  }
}


### OpenSearch cluster ###
resource "random_password" "password" {
  length           = 16
  min_upper = 1
  min_lower = 1
  min_numeric = 1
  min_special = 1
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "opensearch" {
  name_prefix = "opensearch-password"
}

resource "aws_secretsmanager_secret_version" "opensearch" {
  secret_id     = aws_secretsmanager_secret.opensearch.id
  secret_string = random_password.password.result
}

variable "domain" {
  default = "nlp-awsdocs"
}


data "aws_region" "current" {}

resource "aws_security_group" "es" {
  name        = "${aws_vpc.aws-vpc.id}-elasticsearch-${var.domain}"
  description = "Managed by Terraform. Limiting access to opensearch on https from the search API security group."
  vpc_id      = aws_vpc.aws-vpc.id
  tags = {
    Name = "NLPSearchOpenSearchSecurityGroup"
  }

  ingress {
    description     = "TLS from Search API"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.search_api.id]
  }
}

resource "aws_iam_service_linked_role" "es" {
  aws_service_name = "es.amazonaws.com"
}

resource "aws_elasticsearch_domain" "es" {
  domain_name           = var.domain
  elasticsearch_version = "OpenSearch_1.3"

  cluster_config {
    instance_type          = "r6g.large.elasticsearch"
    zone_awareness_enabled = true
    instance_count         = 4
  }

  ebs_options {
    volume_size = 50
    volume_type = "gp2"
    ebs_enabled = true
  }

  vpc_options {
    subnet_ids         = aws_subnet.private.*.id #[for s in data.aws_subnet.selected : s.id]
    security_group_ids = [aws_security_group.es.id]
  }

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
    "override_main_response_version"         = "true"
  }

  node_to_node_encryption {
    enabled = true
  }

  encrypt_at_rest {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }
  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = "admin"
      master_user_password = random_password.password.result
    }
  }

  # We are using "Principal": "*" for the Search API.
  # While Haystack provides a python class to use AWS Sig v4 signed requests, 
  # It is currently not possible to configure these as Auth method via the pipeline yaml 
  access_policies = <<CONFIG
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "es:*",
            "Principal": "*", 
            "Effect": "Allow",
            "Resource": "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.domain}/*"
        }
    ]
}
CONFIG

  tags = {
    Domain = "NLPSearch"
  }

  depends_on = [aws_iam_service_linked_role.es]
}

################# Service discovery #######################

resource "aws_service_discovery_private_dns_namespace" "dns_ns" {
  name        = "nlp.service"
  description = "Service discovery DNS namespace"
  vpc         = aws_vpc.aws-vpc.id
}

resource "aws_service_discovery_service" "api" {
  name = "api"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.dns_ns.id

    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
}

resource "aws_service_discovery_service" "api_gen" {
  name = "api-gen"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.dns_ns.id

    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
}