# Prepare environment
1. Download or build Docker images of your liking for:
 - PostgreSQL
 - RabbitMQ

2. Setup PostgreSQL
```
docker exec -it postgres createuser -P pandora
docker exec postgres createdb -O pandora pandora
echo "CREATE EXTENSION pg_trgm;" | docker exec -i postgres psql pandora
```

3. Setup RabbitMQ
```
docker exec rabbitmq rabbitmqctl add_user pandora RABBITMQ_PWD
docker exec rabbitmq rabbitmqctl add_vhost /pandora
docker exec rabbitmq rabbitmqctl set_permissions -p /pandora pandora ".*" ".*" ".*"
```

# Configure Pan.do/ra
1. Build Pan.do/ra Docker image
```
docker build -t pandora https://github.com/Disassembler0/pandora-alpine.git
```

2. Create empty data directory for persistent storage
```
mkdir -p /srv/pandora/data
```

3. Create file `/srv/pandora/local_settings.py` with the following content:
```
DATABASES = {
    'default': {
        'HOST': 'postgres',
        'NAME': 'pandora',
        'ENGINE': 'django.db.backends.postgresql_psycopg2',
        'USER': 'pandora',
        'PASSWORD': 'POSTGRES_PWD',
    }
}
BROKER_URL = 'amqp://pandora:RABBITMQ_PWD@rabbitmq:5672//pandora'
DB_GIN_TRGM = True
XACCELREDIRECT = True
```
Supply the `POSTGRES_PWD` and `RABBITMQ_PWD` according to your values.

4. Populate database
```
docker run --rm \
    --link postgres \
    -v /srv/pandora/local_settings.py:/srv/pandora/pandora/local_settings.py \
    pandora \
    /srv/pandora/pandora/manage.py init_db
```

5. Start Pan.do/ra Docker image
```
docker run -it --rm \
    --name pandora \
    --link postgres \
    --link rabbitmq \
    -p 2620:80 \
    -v /srv/pandora/data:/srv/pandora/data \
    -v /srv/pandora/local_settings.py:/srv/pandora/pandora/local_settings.py \
    pandora
```

6. Open Pan.do/ra on http://your-machine:2620/

# Updating
1. Rebuild Pan.do/ra Docker image
```
docker build -t pandora https://github.com/Disassembler0/pandora-alpine.git
```

2. Update database
```
docker run \
    --link postgres \
    -v /srv/pandora/local_settings.py:/srv/pandora/pandora/local_settings.py \
    pandora \
    /srv/pandora/update.py db
```
