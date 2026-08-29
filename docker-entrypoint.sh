#!/bin/sh
set -e

CERT_DIR=/certs
HOST_CERT_DIR=/host-certs
mkdir -p "$CERT_DIR"
if [ -f "$HOST_CERT_DIR/cert.pem" ] && [ -f "$HOST_CERT_DIR/key.pem" ]; then
    # Locally-trusted cert from mkcert (see dev-certs/), bind-mounted read-only.
    cp "$HOST_CERT_DIR/cert.pem" "$CERT_DIR/cert.pem"
    cp "$HOST_CERT_DIR/key.pem" "$CERT_DIR/key.pem"
elif [ ! -f "$CERT_DIR/cert.pem" ] || [ ! -f "$CERT_DIR/key.pem" ]; then
    # No mkcert cert available: fall back to a self-signed one so the app
    # still runs, just with a browser trust warning.
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$CERT_DIR/key.pem" \
        -out "$CERT_DIR/cert.pem" \
        -subj "/CN=localhost" \
        -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"
fi

python manage.py migrate --noinput
python manage.py collectstatic --noinput

exec "$@"
