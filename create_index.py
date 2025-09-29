import boto3
from requests_aws4auth import AWS4Auth
from elasticsearch import RequestsHttpConnection
from opensearchpy import OpenSearch
import logging
import argparse

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Parse command line arguments
parser = argparse.ArgumentParser(description='Create OpenSearch index')
parser.add_argument('--region', required=True, help='AWS region')
parser.add_argument('--collection-endpoint', required=True, help='OpenSearch collection endpoint')
parser.add_argument('--index-name', required=True, help='Name of the index to create')
parser.add_argument('--vector-field', required=True, help='Name of the vector field')
parser.add_argument('--text-field', required=True, help='Name of the text field')
parser.add_argument('--metadata-field', required=True, help='Name of the metadata field')
args = parser.parse_args()

# Configuration
region = args.region
collection_endpoint = args.collection_endpoint
collection_endpoint_host = collection_endpoint.replace("https://", "").replace("/", "")
index_name = args.index_name

# Index mapping configuration
index_mapping = {
    "settings": {
        "index": {
            "knn": True,
            "knn.algo_param.ef_search": 512
        }
    },
    "mappings": {
        "properties": {
            args.vector_field: {
                "type": "knn_vector",
                "dimension": 1024,
                "method": {
                    "name": "hnsw",
                    "space_type": "l2",
                    "engine": "faiss",
                    "parameters": {
                        "ef_construction": 512,
                        "m": 16
                    }
                }
            },
            args.text_field: {
                "type": "text"
            },
            args.metadata_field: {
                "type": "text"
            }
        }
    }
}

try:
    # Create AWS session
    logger.info("Creating AWS session")
    session = boto3.Session()
    credentials = session.get_credentials()
    service = 'aoss'
    
    awsauth = AWS4Auth(
        credentials.access_key,
        credentials.secret_key,
        region,
        service,
        session_token=credentials.token,
    )

    logger.info("Initializing OpenSearch client")
    client = OpenSearch(
        hosts=[{"host": collection_endpoint_host, "port": 443}],
        http_auth=awsauth,
        use_ssl=True,
        verify_certs=True,
        connection_class=RequestsHttpConnection,
        timeout=300,
    )

    logger.info(f"Creating index: {index_name}")
    response = client.indices.create(
        index=index_name,
        body=index_mapping,
    )
    
    logger.info(f"Response: {response}")
    
    # if response.status_code in [200, 201]:
    #     logger.info(f"Successfully created index: {index_name}")
    #     logger.info(f"Response: {response.text}")
    # else:
    #     logger.error(f"Failed to create index. Status: {response.status_code}")
    #     logger.error(f"Response: {response.text}")
    #     exit(1)
        
except Exception as e:
    logger.exception(f"Error creating index: {str(e)}",exc_info=True, stack_info=True)
    exit(1)
