from pathlib import Path
from bs4 import BeautifulSoup
from sentence_transformers import SentenceTransformer
from opensearchpy import OpenSearch, RequestsHttpConnection
from haystack.nodes.retriever import EmbeddingRetriever
from haystack.document_stores import OpenSearchDocumentStore
from haystack.utils import clean_wiki_text, convert_files_to_docs, fetch_archive_from_http, print_answers

import json
import sys
import os 

host = os.environ['OPENSEARCH_HOST']
password = os.environ['OPENSEARCH_PASSWORD']

doc_dir_aws = "/awsdocs/data"
if len(sys.argv)>1:
  doc_dir_aws = sys.argv[1]

print(f"doc_dir_aws {doc_dir_aws}")

document_store = OpenSearchDocumentStore(
        host = host,
        port = 443,
        username = 'admin',
        password = password,
        scheme = 'https',
        verify_certs = False,
        similarity='cosine'
    )

dicts_aws = convert_files_to_docs(dir_path=doc_dir_aws, clean_func=clean_wiki_text, split_paragraphs=True)

path = Path(doc_dir_aws)

# Let's have a look at the first 3 entries:
print("First 3 documents to be ingested")
print(dicts_aws[:3])

print(f"Starting Ingestion, Documents: {len(dicts_aws)}")

# Now, let's write the dicts containing documents to our DB.
document_store.write_documents(dicts_aws, index="awsdocs")

print(f"Finished Ingestion, Documents: {len(dicts_aws)}")

print(f"Started Update Embeddings, Documents: {len(dicts_aws)}")
# Calculate and store a dense embedding for each document
retriever = EmbeddingRetriever(
    document_store=document_store,
    model_format = "sentence_transformers",
    embedding_model = "sentence_transformers/all-mpnet-base-v2"
)
document_store.update_embeddings(retriever)

print(f"Finished Update Embeddings, Documents: {len(dicts_aws)}")