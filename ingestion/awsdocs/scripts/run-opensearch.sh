# Recommended: Start Elasticsearch using Docker
#! docker run -d -p 9200:9200 -e "discovery.type=single-node" elasticsearch:7.6.2

# docker pull opensearchproject/opensearch:1.0.1
#!docker run -p 9200:9200 -p 9600:9600 -e "discovery.type=single-node" opensearchproject/opensearch:1.0.1