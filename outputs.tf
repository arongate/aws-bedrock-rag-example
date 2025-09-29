output "knowledge_base_id" {
  value       = aws_bedrockagent_knowledge_base.example.id
  description = "The ID of the Bedrock Knowledge Base"
}

output "opensearch_collection_endpoint" {
  value       = aws_opensearchserverless_collection.example.collection_endpoint
  description = "The endpoint of the OpenSearch Serverless collection"
}