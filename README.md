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

Then visit https://localhost:8000/.

The app is served over HTTPS only — gunicorn terminates TLS directly using
a self-signed certificate that `docker-entrypoint.sh` generates on first
start (and persists in the `certs_data` volume across restarts). Browsers
will show a certificate warning since it's self-signed; for `curl`, pass
`-k`. Plain `http://` requests will fail outright, since nothing is
listening for unencrypted HTTP.

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
