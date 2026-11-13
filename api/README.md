# API

## Dependencies

- Python 3.10+
- MongoDB

## Setup

### Mongo

A mongo DB can be created locally via docker.

```bash
docker run --name mongo-flights -p 27017:27017 -d mongo
```

### Environment Variables

create a `.env` file in the **api** folder:

```bash
cd api
touch .env
```

Configure the .env file with the variables shown in the .env.example file.

## Execution

### Tests

```bash
cd api
python -m pytest
```

### Development

```bash
cd api
python -m fastapi dev --app app --port 8000
```

### Production

```bash
cd api
python -m fastapi run --app app --port $PORT
```

## Endpoints

when running the development environment, an OpenAPI Documentation should be available at http://localhost:8000/docs

### GET /

liveness check

```bash
curl -X 'GET' 'http://localhost:8000/'
```

returns a 204 No Content status code and an empty body

### GET /flights

List of flights

```bash
curl -X 'GET' \
  'http://localhost:8000/flights?skip=0&limit=100' \
  -H 'accept: application/json'
```

returns a 200 OK Code and a JSON body with the list of flights, an example response is:

```json
[
  {
    "status": "scheduled",
    "id": "66d853f352a3642d566785e4"
  },
  {
    "status": "scheduled",
    "id": "66d85437ef4d4f0151b17d0d"
  }
]
```

### POST /flights

Create a new Flight

```bash
curl -X 'POST' \
  'http://localhost:8000/flights' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "status": "cancelled"
}'
```

returns a 200 OK Code and a json body with the content of the created flight, an example response is:

```json
{
  "status": "cancelled",
  "id": "66d860a34d710cc91c72ba89"
}
```
