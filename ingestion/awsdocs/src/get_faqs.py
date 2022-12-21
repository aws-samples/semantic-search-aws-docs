import urllib.request, json
from pathlib import Path
import os
import re
url_services="https://aws.amazon.com/api/dirs/items/search?item.directoryId=aws-products&sort_by=item.additionalFields.productNameLowercase&sort_order=asc&size=500&item.locale=en_US&tags.id=!aws-products"

services_json = "./data/faqs-aws-services.json"
services_dir = "./data/faqs_aws_services"

import requests
from bs4 import BeautifulSoup
import pandas as pd
#pd.set_option('display.max_rows', 500)
pd.set_option('display.max_columns', 10)
pd.set_option('display.width', 1000)
import glob
import tqdm

def get_amazon_faqs(url = "https://aws.amazon.com/alexaforbusiness/faqs/"):
    """
    crawls the frequently asked questions and answers for a given amazon services.
    Assumes paragraphs in a div with  class=lb-rtxt and h2 below the div to define the category of faqs.
    :param url:
    :return:
    """
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Max-Age': '3600',
        'User-Agent': 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:52.0) Gecko/20100101 Firefox/52.0'
    }

    req = requests.get(url, headers)
    soup = BeautifulSoup(req.content, 'html.parser')
    faqs = []
    faqs_category = []
    for div in soup.find_all(class_="lb-rtxt"):
        cat = div.find_previous_sibling('h2')
        if cat is None: continue
        category = cat.getText()
        paragraphs = div.find_all("p")
        for p in paragraphs:
            if "?" in p.getText():
                #new question, split
                faqs.append([])
                faqs_category.append(category)
            if len(faqs)>0:
                faqs[-1].append(p)

    rows = []
    for (cat, faq_par) in zip (faqs_category, faqs):
        question = faq_par[0].getText().strip()
        answer = "\n\n".join([p.getText() for p in faq_par[1:]]).strip()
        row= {"type":cat, "question":question, "answer":answer, "url":url}
        rows.append(row)
    df = pd.DataFrame(rows)
    return df

#get_amazon_faqs()


if not os.path.exists(services_json):
    with urllib.request.urlopen(url_services) as url:
        data_url = json.loads(url.read().decode())
        with open(services_json, 'w', encoding='utf-8') as f:
            json.dump(data_url, f, ensure_ascii=False, indent=4)
os.makedirs(services_dir,exist_ok=True)

import time
with open(services_json) as json_file:
    data = json.load(json_file)
    items = [item["item"] for item in data["items"]]
    for item in tqdm.tqdm(items):
        productUrl = item["additionalFields"]["productUrl"]

        re_all = re.findall(r"(.*aws.amazon.com/(.+)/)", productUrl)
        if len(re_all) ==0:
            print(f"Could not match url, skipping: {productUrl}")
            continue

        service = re_all[0][1]
        service_name = service.replace("/","-")

        faq_out = os.path.join(services_dir, service_name + "_faqs.csv")
        if os.path.exists(faq_out):
            continue

        faq_url = re_all[0][0]
        faqs = get_amazon_faqs(faq_url + "faqs")

        if faqs.shape[0]==0:
            print(f"Getting Faqs failed for: {faq_url} , {service_name}")
            faqs = get_amazon_faqs(faq_url + "faq")
            if faqs.shape[0] == 0:
                continue

        faqs["service"] = service
        faqs.to_csv(faq_out, index=False)
        print(faqs)
        # time.sleep(1.1)


files = glob.glob(services_dir+"/*.csv")
df_list = []
for f in files:
    df = pd.read_csv(f)
    df_list.append(df)

df_all = pd.concat(df_list)

print(df_all.shape)
df_all.to_csv("aws-services-faqs-dataset.csv", index=False)