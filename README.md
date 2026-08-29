# test-ephem

Example Django app backed by Postgres and Redis, both running in Docker
containers via Docker Compose. The app is a tiny notes list: notes are
stored in Postgres, and a page-view counter plus a cached note count are
stored in Redis (via `django-redis`) to demonstrate the cache wiring.

Config (DB credentials, Redis URL, etc.) is hardcoded in
`config/settings.py` — there's no `.env` file to manage.

## Running with Docker Compose

```
docker compose up -d --build
```

Then visit https://localhost/ (standard HTTPS port 443, mapped in
`docker-compose.yml`; gunicorn itself still listens on 8000 inside the
container).

The app is served over HTTPS only — gunicorn terminates TLS directly.
Plain `http://` requests will fail outright, since nothing is listening
for unencrypted HTTP.

### Trusted local HTTPS cert (mkcert)

By default (no setup needed) `docker-entrypoint.sh` generates a
self-signed certificate on first start, persisted in the `certs_data`
volume. Browsers will show a "connection is not private" warning for it,
since it isn't signed by a CA they recognize — click through
(Advanced → Proceed) to continue.

To get a cert your browser trusts with no warning, use
[mkcert](https://github.com/FiloSottile/mkcert) to generate one signed by
a local CA:

```
brew install mkcert
mkcert -install                          # one-time, installs a local CA into your system/browser trust store
mkdir -p dev-certs
mkcert -cert-file dev-certs/cert.pem -key-file dev-certs/key.pem localhost 127.0.0.1 ::1
docker compose up -d --build             # rebuild so the container picks up dev-certs/
```

`dev-certs/` is bind-mounted read-only into the container and, when
present, takes priority over the self-signed fallback (see
`docker-entrypoint.sh`). It's gitignored — each developer generates their
own.

The host-side ports are remapped in `docker-compose.yml` (Postgres on
5431, Redis on 6378) to avoid clashing with other local services — the
containers still listen internally on their standard ports (5432/6379),
which is what `settings.py` and the `web` service actually talk to.

Migrations run automatically on container start (see
`docker-entrypoint.sh`). To create a Django superuser:

```
docker compose exec web python manage.py createsuperuser
```

Stop everything with `docker compose down` (add `-v` to also drop the
Postgres/Redis data volumes).

## Local development (without Docker)

This project pins Python 3.11 via `pyenv` (`.python-version`) and manages
dependencies with `pipenv`:

```
pipenv install
pipenv run python manage.py migrate
pipenv run python manage.py runserver
```

`runserver` serves plain HTTP, unlike the Compose setup above — fine for
local iteration, just not a match for the HTTPS-only container setup.

For this to work outside of Compose, edit the `HOST`/`PORT` in
`settings.py`'s `DATABASES` and the `REDIS_URL` to point at wherever
Postgres/Redis are actually reachable from your machine (e.g.
`localhost:5431` and `localhost:6378` if using the containers above) —
Compose's internal service names (`db`, `redis`) only resolve inside the
Compose network.
