ARG BUILD_ENV="local"

FROM amazonlinux:2 as local
ONBUILD ARG DOCS_SRC="awsdocs/data"
ONBUILD WORKDIR "/awsdocs"
ONBUILD COPY $DOCS_SRC "data/"

FROM ${BUILD_ENV}
ARG SCRIPT_NAME="run_ingestion_awsdocs"
RUN yum install -y amazon-linux-extras
RUN amazon-linux-extras enable python3.8
RUN yum install -y python3.8 jq wget gzip tar git

COPY awsdocs/requirements.txt /awsdocs/requirements.txt
RUN python3.8 -m pip --no-cache-dir install -r /awsdocs/requirements.txt

RUN curl -O https://dl.xpdfreader.com/xpdf-tools-linux-4.04.tar.gz && tar -xvf xpdf-tools-linux-4.04.tar.gz && cp xpdf-tools-linux-4.04/bin64/pdftotext /usr/local/bin
RUN yum -y install fontconfig

COPY awsdocs/scripts /awsdocs/scripts
COPY awsdocs/src /awsdocs/src

WORKDIR "/awsdocs/data"


RUN ln -s /awsdocs/scripts/$SCRIPT_NAME.sh /awsdocs/scripts/docker_entrypoint.sh

#RUN python3.8 ../src/ingest.py
ENTRYPOINT [ "bash", "/awsdocs/scripts/docker_entrypoint.sh" ]
CMD ["amazon-ec2-user-guide", "awsdocs"] #repo substring or 'full' for all repos and index name defaults to 'awsdocs'