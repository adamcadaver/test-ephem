#!/bin/sh
set -e

CERT_DIR=/certs
if [ ! -f "$CERT_DIR/cert.pem" ] || [ ! -f "$CERT_DIR/key.pem" ]; then
    mkdir -p "$CERT_DIR"
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$CERT_DIR/key.pem" \
        -out "$CERT_DIR/cert.pem" \
        -subj "/CN=localhost" \
        -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"
fi

python manage.py migrate --noinput
python manage.py collectstatic --noinput

exec "$@"
