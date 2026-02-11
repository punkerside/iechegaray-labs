service = test3_postgres

build:
	docker build -t ${service} .

up:
	@docker compose up --build

down:
	@docker compose down

bad_query:
	docker run --rm -e PGPASSWORD="challenge" -v "${PWD}:/app" "${service}" -h 192.168.1.83 -p 5432 -U challenge -d challenge -f bad_query.sql