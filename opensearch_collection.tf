# resource "aws_opensearchserverless_vpc_endpoint" "example" {
#   name       = local.vpc_endpoint_name
#   subnet_ids = module.vpc.private_subnets
#   vpc_id     = module.vpc.vpc_id
# }

resource "aws_opensearchserverless_security_policy" "encryption" {
  name = "${local.collection_name}-enc-01"
  type = "encryption"
  policy = jsonencode({
    "Rules" = [
      {
        "Resource" = [
          "collection/${local.collection_name}"
        ],
        "ResourceType" = "collection"
      }
    ],
    "AWSOwnedKey" = true
  })
}

resource "aws_opensearchserverless_security_policy" "network" {
  name        = "${local.collection_name}-net-01"
  type        = "network"
  description = "Public access"
  policy = jsonencode([
    {
      Description = "Public access to collection and Dashboards endpoint for ${local.collection_name} collection",
      Rules = [
        {
          ResourceType = "collection",
          Resource = [
            "collection/${local.collection_name}"
          ]
        },
        {
          ResourceType = "dashboard"
          Resource = [
            "collection/${local.collection_name}"
          ]
        }
      ],
      AllowFromPublic = true
    }
  ])
}

resource "aws_opensearchserverless_access_policy" "readwrite" {
  name        = "${local.collection_name}-01"
  type        = "data"
  description = "read and write permissions"
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "index",
          Resource = [
            "index/${local.collection_name}/*"
          ],
          Permission = [
            "aoss:*"
          ]
        },
        {
          ResourceType = "collection",
          Resource = [
            "collection/${local.collection_name}"
          ],
          Permission = [
            "aoss:*"
          ]
        }
      ],
      Principal = [
        data.aws_caller_identity.current.arn,
        "arn:aws:iam::${local.account_id}:role/${local.kb_service_role_name}",
      ]
    }
  ])
}

# resource "aws_opensearchserverless_access_policy" "kb" {
#   name        = "${local.collection_name}-02"
#   type        = "data"
#   description = "knowledge base permissions"
#   policy = jsonencode([
#     {
#       Rules = [
#         {
#           ResourceType = "index",
#           Resource = [
#             "index/${local.collection_name}/*"
#           ],
#           Permission = [
#             "aoss:DescribeIndex",
#             "aoss:ReadDocument",
#             "aoss:WriteDocument",
#             "aoss:CreateIndex",
#             "aoss:DeleteIndex",
#             "aoss:UpdateIndex"
#           ],
#         },
#         {
#           ResourceType = "collection",
#           Resource = [
#             "collection/${local.collection_name}"
#           ],
#           Permission = [
#             "aoss:CreateCollectionItems",
#             "aoss:DescribeCollectionItems",
#             "aoss:UpdateCollectionItems"
#           ],
#         }
#       ],
#       Principal = [
#         "arn:aws:iam::${local.account_id}:role/${local.kb_service_role_name}"
#       ]
#     }
#   ])
# }

resource "aws_opensearchserverless_collection" "example" {
  depends_on = [
    aws_opensearchserverless_security_policy.encryption,
    aws_opensearchserverless_security_policy.network,
    aws_opensearchserverless_access_policy.readwrite,
    # aws_opensearchserverless_access_policy.kb,
  ]
  name             = local.collection_name
  standby_replicas = "DISABLED" # this is a test collection, so no standby replicas are needed
  description      = "Collection to test Bedrock Knowledge Base ingestion"
  type             = "VECTORSEARCH"

  tags = {
    Name = local.collection_name
  }
}
