# # Create the OpenSearch index required by Bedrock Knowledge Base
# resource "null_resource" "create_opensearch_index" {
#   depends_on = [aws_opensearchserverless_collection.example]

#   provisioner "local-exec" {
#     command = <<-EOT
#       python3 << 'PYTHON_SCRIPT'
# import json
# import boto3
# import requests
# from requests_aws4auth import AWS4Auth
# from botocore.auth import SigV4Auth
# from botocore.awsrequest import AWSRequest
# from elasticsearch import Elasticsearch, RequestsHttpConnection
# from opensearchpy import OpenSearch
# import os

# # Configuration
# region = "${local.region}"
# collection_endpoint = "${aws_opensearchserverless_collection.example.collection_endpoint}"
# index_name = "bedrock-knowledge-base-default-index"

# # Index mapping configuration
# index_mapping = {
#     "settings": {
#         "index": {
#             "knn": True,
#             "knn.algo_param.ef_search": 512
#         }
#     },
#     "mappings": {
#         "properties": {
#             "bedrock-knowledge-base-default-vector": {
#                 "type": "knn_vector",
#                 "dimension": 1024,
#                 "method": {
#                     "name": "hnsw",
#                     "space_type": "l2",
#                     "engine": "faiss",
#                     "parameters": {
#                         "ef_construction": 512,
#                         "m": 16
#                     }
#                 }
#             },
#             "AMAZON_BEDROCK_TEXT_CHUNK": {
#                 "type": "text"
#             },
#             "AMAZON_BEDROCK_METADATA": {
#                 "type": "text"
#             }
#         }
#     }
# }

# try:
#     # Create AWS session
#     session = boto3.Session()
#     credentials = session.get_credentials()
#     service = 'aoss'

#     awsauth = AWS4Auth(
#         credentials.access_key,
#         credentials.secret_key,
#         region,
#         service,
#         session_token=credentials.token,
#     )

#     client = OpenSearch(
#         hosts=[{"host": collection_endpoint, "port": 443}],
#         http_auth=awsauth,
#         use_ssl=True,
#         verify_certs=True,
#         connection_class=RequestsHttpConnection,
#         timeout=300,
#     )

#     response = client.indices.create(
#         index=index_name,
#         body=index_mapping,
#     )

#     if response.status_code in [200, 201]:
#         print(f"Successfully created index: {index_name}")
#         print(f"Response: {response.text}")
#     else:
#         print(f"Failed to create index. Status: {response.status_code}")
#         print(f"Response: {response.text}")
#         exit(1)

# except Exception as e:
#     print(f"Error creating index: {str(e)}")
#     exit(1)
# PYTHON_SCRIPT
#     EOT
#   }

#   # Trigger recreation if collection endpoint changes
#   triggers = {
#     collection_endpoint = aws_opensearchserverless_collection.example.collection_endpoint
#     # index_name         = local.index_name
#   }
# }

# Create the OpenSearch index required by Bedrock Knowledge Base
resource "null_resource" "create_opensearch_index" {
  depends_on = [aws_opensearchserverless_collection.example]

  provisioner "local-exec" {
    command = <<-EOT
      python3 create_index.py --region ${local.region} \
      --collection-endpoint ${aws_opensearchserverless_collection.example.collection_endpoint} \
      --index-name bedrock-knowledge-base-default-index \
      --vector-field bedrock-knowledge-base-default-vector \
      --text-field AMAZON_BEDROCK_TEXT_CHUNK \
      --metadata-field AMAZON_BEDROCK_METADATA
    EOT
  }

  # Trigger recreation if collection endpoint changes
  triggers = {
    collection_endpoint = aws_opensearchserverless_collection.example.collection_endpoint
    # index_name         = local.index_name
  }
}