FROM mongo:4
WORKDIR /app
# Install gcloud SDK
RUN apt update && \
    apt install -y curl python && \
    rm -fr /var/lib/apt/lists/*
RUN curl https://sdk.cloud.google.com > install.sh && \
    bash install.sh --disable-prompts && \
    rm install.sh
ENV PATH="/root/google-cloud-sdk/bin:${PATH}"
# Copy and launch backup script
COPY mongo-backup.sh .
ENTRYPOINT ["/bin/sh", "mongo-backup.sh"]