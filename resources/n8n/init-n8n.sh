#!/bin/sh

# Ensure /home/n8n/app is owned by user 1000:1000
chown 1000:1000 /home/n8n/app

# If .n8n directory exists, ensure it has correct permissions
if [ -d "/home/n8n/app/.n8n" ]; then
  chown -R 1000:1000 /home/n8n/app/.n8n
fi

# Start n8n
exec /docker-entrypoint.sh "$@"