FROM deepset/haystack-streamlit-ui@sha256:3584978ff23c7eb5f19596bde6f3eeca1bab65a8997758634db5563241e2b1cb

COPY utils.py /home/user/ui
COPY webapp.py /home/user/ui