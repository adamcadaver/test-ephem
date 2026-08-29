# test-ephem

Example Django app backed by Postgres and Redis, both running in Docker
containers via Docker Compose. The app is a tiny notes list: notes are
stored in Postgres, and a page-view counter plus a cached note count are
stored in Redis (via `django-redis`) to demonstrate the cache wiring.

## Running with Docker Compose

```
cp .env.example .env   # first time only
docker compose up -d --build
```

Then visit http://localhost:8000/ (or whatever `WEB_HOST_PORT` you set in
`.env`).

If ports 5432, 6379, or 8000 are already in use on your machine, override
`POSTGRES_HOST_PORT`, `REDIS_HOST_PORT`, or `WEB_HOST_PORT` in `.env` — these
only affect the host-side port mapping, not the app's internal connections.

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

For this to work outside of Compose, point `POSTGRES_HOST` in `.env` at a
Postgres instance reachable from your machine (e.g. `localhost`), and
`REDIS_URL` at a reachable Redis instance — Compose's internal service
names (`db`, `redis`) only resolve inside the Compose network.
