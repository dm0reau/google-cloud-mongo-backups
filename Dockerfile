FROM mongo:4
WORKDIR /app
# Install gcloud SDK
RUN apt update && \
    apt install -y curl python3 && \
    rm -fr /var/lib/apt/lists/*
RUN curl https://sdk.cloud.google.com > install.sh && \
    bash install.sh --disable-prompts && \
    rm install.sh
ENV PATH="/root/google-cloud-sdk/bin:${PATH}"
# Copy scripts and launch Python server
COPY mongo-backup.sh .
RUN chmod +x mongo-backup.sh
COPY server.py .
ENTRYPOINT ["/usr/bin/python3", "server.py"]