service = test3_postgres

build:
	docker build -t ${service} .

up:
	@docker compose up --build

down:
	@docker compose down

generate_data:
	docker run --rm -e PGPASSWORD="challenge" -v "${PWD}:/app" "${service}" -h $(shell hostname -I | awk '{print $1}') -p 5432 -U challenge -d challenge -f generate_data.sql

bad_query:
	docker run --rm -e PGPASSWORD="challenge" -v "${PWD}:/app" "${service}" -h $(shell hostname -I | awk '{print $1}') -p 5432 -U challenge -d challenge -f bad_query.sql

optimized_query:
	docker run --rm -e PGPASSWORD="challenge" -v "${PWD}:/app" "${service}" -h $(shell hostname -I | awk '{print $1}') -p 5432 -U challenge -d challenge -f optimized_query.sql