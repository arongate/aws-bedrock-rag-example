locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

locals {
  project_name    = "kb-ingest-test"
  collection_name = "${local.project_name}-opensearch"
  #   index_name           = "${local.collection_name}-index"
  #   vpc_endpoint_name    = "${local.collection_name}-vpce"
  kb_service_role_name = "${local.project_name}-kb-svc-role"
}

locals {
  embedding_model_arn = "arn:aws:bedrock:${local.region}::foundation-model/amazon.titan-embed-text-v2:0"
}