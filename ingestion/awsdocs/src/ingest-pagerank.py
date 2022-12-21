from bs4 import BeautifulSoup
from haystack.utils import clean_wiki_text, convert_files_to_docs, fetch_archive_from_http, print_answers
from haystack.nodes import FARMReader, TransformersReader
import re
#
# # Recommended: Start Elasticsearch using Docker via the Haystack utility function
# from haystack.utils import launch_es
#
# launch_es()

# Connect to Elasticsearch
from tqdm import tqdm
# from haystack.document_stores.elasticsearch import ElasticsearchDocumentStore
# document_store = ElasticsearchDocumentStore(host="localhost", username="", password="", index="document")

# # Let's first fetch some documents that we want to query
# # Here: 517 Wikipedia articles for Game of Thrones
# doc_dir = "data/article_txt_got"
# s3_url = "https://s3.eu-central-1.amazonaws.com/deepset.ai-farm-qa/datasets/documents/wiki_gameofthrones_txt.zip"
# fetch_archive_from_http(url=s3_url, output_dir=doc_dir)
#
# # Convert files to dicts
# # You can optionally supply a cleaning function that is applied to each doc (e.g. to remove footers)
# # It must take a str as input, and return a str.
# dicts = convert_files_to_docs(dir_path=doc_dir, clean_func=clean_wiki_text, split_paragraphs=True)

doc_dir_aws = "data/awsdocs/amazon-ec2-user-guide"
doc_dir_aws = "data/awsdocs"
dicts_aws = convert_files_to_docs(dir_path=doc_dir_aws, clean_func=clean_wiki_text, split_paragraphs=True)


from pathlib import Path
import markdown

path = Path(doc_dir_aws)

references =[]

doc_to_node = {}
node_count = 0

doc_to_link = {}

for p in tqdm(path.rglob("*.md")):
  #print("Document: "+p.name)
  with open(p) as f:
    contents = f.read()
    #print(contents)
    html = markdown.markdown(contents)
    #print(html)
    # create soap object
    soup = BeautifulSoup(html, 'html.parser')

    # find all the anchor tags with "href"
    # attribute starting with "https://"
    for link in soup.find_all('a',
                              attrs={'href': re.compile("^http")}):
      # display the actual urls
      #print(link.get('href'))
      href = link.get('href').strip("/")
      htext = link.text
      href_suffix = href.split("/")[-1]
      if "#" in href_suffix:
        href_suffix = href_suffix.split("#")[0]
      href_suffix = href_suffix.replace(".html", "")
      source = p.stem
      target = href_suffix
      ref = {"source_md":source, "link_suffix":target, "path":str(p), "link_text":link.text, "link_href":href  }

      if target not in doc_to_link:
        doc_to_link[source] = href

      # if source not in doc_to_node:
      #   node_count +=1
      #   doc_to_node[source] = node_count
      # if target not in doc_to_node:
      #   node_count +=1
      #   doc_to_node[target] = node_count

      #print(ref)
      references.append(ref)

import pandas as pd
df = pd.DataFrame(ref)
df.to_csv("links.csv")


# If your texts come from a different source (e.g. a DB), you can of course skip convert_files_to_dicts() and create the dictionaries yourself.
# The default format here is:
# {
#    'text': "<DOCUMENT_TEXT_HERE>",
#    'meta': {'name': "<DOCUMENT_NAME_HERE>", ...}
#}
# (Optionally: you can also add more key-value-pairs here, that will be indexed as fields in Elasticsearch and
# can be accessed later for filtering or shown in the responses of the Finder)

# TODO: add awsdocs url in meta for each md file, e.g.
# data/awsdocs/amazon-ec2-user-guide/doc_source/AmazonEFS.md
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AmazonEFS.html
# Challenge: How to know the mapping from the file to the public URL

# Let's have a look at the first 3 entries:
#print(dicts_aws[:3])

# Now, let's write the dicts containing documents to our DB.
#document_store.write_documents(dicts_aws)