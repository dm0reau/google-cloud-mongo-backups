FROM mongo:4
WORKDIR /app
COPY mongo-backup.sh .
ENTRYPOINT ["/bin/sh", "mongo-backup.sh"]
