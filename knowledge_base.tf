terraform {
  required_version = "~> 1.8"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "local" {}
}

provider "aws" {
  region = "eu-west-3"
  default_tags {
    tags = {
      EntiteFacturation = "transverse"
      map-migrated      = "migXEP06980RE"
      Environment       = "dev"
    }
  }
}

data "aws_iam_policy_document" "bedrockagent_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["bedrock.amazonaws.com"]
    }
    # condition {
    #   test     = "StringEquals"
    #   variable = "aws:SourceAccount"
    #   values   = [local.account_id]
    # }
    # condition {
    #   test     = "ArnLike"
    #   variable = "AWS:SourceArn"
    #   values   = ["arn:aws:bedrock:${local.region}:${local.account_id}:knowledge-base/*"]
    # }
  }
}

resource "aws_iam_role" "kb_service_role" {
  name               = local.kb_service_role_name
  description        = "IAM role for Bedrock Agent to interact with knowledge base"
  assume_role_policy = data.aws_iam_policy_document.bedrockagent_assume_role.json
  tags = {
    Name = local.kb_service_role_name
  }
}

data "aws_iam_policy_document" "kb_service_role_policy" {
  statement {
    actions = [
      "bedrock:ListFoundationModels",
      "bedrock:ListCustomModels"
    ]
    resources = ["*"]
  }
  statement {
    actions = [
      "bedrock:InvokeModel"
    ]
    resources = [
      local.embedding_model_arn
    ]
  }
  statement {
    sid = "DataSourceEncryptionPermissions"
    actions = [
      "KMS:Decrypt"
    ]
    resources = [
      aws_kms_key.kb_ds_encryption.arn
    ]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values = [
        "s3.${local.region}.amazonaws.com"
      ]
    }
  }
  statement {
    sid = "DataSourceBucketS3Permissions"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.example.arn
    ]
    # condition { # this is only needed if the bucket is shared across accounts
    #   test = "StringEquals"
    #   variable = "aws:ResourceAccount"
    #   values = [ local.account_id ]
    # }
  }
  statement {
    sid = "DataSourceObjectS3Permissions"
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "${aws_s3_bucket.example.arn}/*"
    ]
    # condition { # this is only needed if the bucket is shared across accounts
    #   test = "StringEquals"
    #   variable = "aws:ResourceAccount"
    #   values = [ local.account_id ]
    # }
  }
  statement {
    sid       = "ChatWitDocument"
    actions   = ["bedrock:RetrieveAndGenerate"]
    resources = ["*"]
  }
  statement {
    sid     = "ChatWitDocumentLimit"
    actions = ["bedrock:Retrieve"]
    # resources = [aws_bedrockagent_knowledge_base.example.arn]
    resources = ["*"]
  }
  statement {
    sid     = "OpenSearchAPI"
    actions = ["aoss:APIAccessAll"]
    # resources = [aws_opensearchserverless_collection.example.arn]
    resources = ["arn:aws:aoss:${local.region}:${local.account_id}:collection/*"]
  }
}

resource "aws_iam_role_policy" "kb_service_role_policy" {
  name   = "${local.project_name}-kb-svc-role-policy"
  role   = aws_iam_role.kb_service_role.id
  policy = data.aws_iam_policy_document.kb_service_role_policy.json
}

resource "aws_bedrockagent_knowledge_base" "example" {
  depends_on = [null_resource.create_opensearch_index]
  name       = "${local.project_name}-kb"
  role_arn   = aws_iam_role.kb_service_role.arn
  knowledge_base_configuration {
    vector_knowledge_base_configuration {
      embedding_model_arn = local.embedding_model_arn
      embedding_model_configuration {
        bedrock_embedding_model_configuration {
          dimensions          = 1024
          embedding_data_type = "FLOAT32"
        }
      }
    }
    type = "VECTOR"
  }
  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration {
      collection_arn = aws_opensearchserverless_collection.example.arn
      #   vector_index_name = "local.index_name"
      vector_index_name = "bedrock-knowledge-base-default-index"
      field_mapping {
        # vector_field   = "vector-${local.index_name}"
        vector_field   = "bedrock-knowledge-base-default-vector"
        text_field     = "AMAZON_BEDROCK_TEXT_CHUNK"
        metadata_field = "AMAZON_BEDROCK_METADATA"
      }
    }
  }
}

## data source ##
resource "aws_bedrockagent_data_source" "s3" {
  knowledge_base_id    = aws_bedrockagent_knowledge_base.example.id
  name                 = "${local.project_name}-s3-ds"
  data_deletion_policy = "DELETE"
  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn         = aws_s3_bucket.example.arn
      inclusion_prefixes = ["ingest/"]
    }
  }
}
