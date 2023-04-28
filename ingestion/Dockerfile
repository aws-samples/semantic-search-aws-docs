FROM amazonlinux:2
RUN yum install -y amazon-linux-extras
RUN amazon-linux-extras enable python3.8
RUN yum install -y python3.8 jq wget gzip tar git

RUN wget https://github.com/jgm/pandoc/releases/download/2.18/pandoc-2.18-linux-amd64.tar.gz
RUN tar -xvzf pandoc-2.18-linux-amd64.tar.gz
ENV PATH="/pandoc-2.18/bin:${PATH}"

RUN pandoc --version
COPY awsdocs/requirements.txt /awsdocs/requirements.txt
RUN python3.8 -m pip --no-cache-dir install -r /awsdocs/requirements.txt

COPY awsdocs/scripts /awsdocs/scripts
COPY awsdocs/src /awsdocs/src
RUN mkdir awsdocs/data
WORKDIR "awsdocs/data"

#RUN python3.8 ../src/ingest.py
ENTRYPOINT [ "bash", "/awsdocs/scripts/run_ingestion.sh" ]
CMD ["amazon-ec2-user-guide"] #repo substring or 'full' for all repos