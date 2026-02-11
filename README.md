# Labs

Technical test repository.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads)
- [Docker](https://docs.docker.com/get-docker/) and Docker Compose
- GNU Make

## Project Structure

```
.
├── test1_terraform/        # Exercise 1 - Terraform
├── test2_troubleshooting/  # Exercise 2 - Docker Troubleshooting
├── test3_postgres/         # Exercise 3 - PostgreSQL
└── README.md
```

---

## Test 1 - Terraform

Generates text files in three folders representing environments (`QA`, `STG`, `PRD`) using the `local` provider. 10 files per environment (30 total) are created using `count` and `flatten`, each with a customizable text per environment through the `user_text` variable.

### Main Files

| File | Description |
|---|---|
| `main.tf` | `local_file` resource that generates the files |
| `data.tf` | Locals with the iteration logic (`folders`, `files_nested`, `files`) |
| `variables.tf` | `user_text` variable (map per environment) |
| `versions.tf` | Terraform and provider version constraints |
| `Makefile` | Shortcuts for `init`, `apply`, and `destroy` |

### Usage

```bash
cd test1_terraform
make init
make apply
```

To destroy resources:

```bash
make destroy
```

### Solution

A **nested `for` loop** in Terraform was used to simplify the generation of the 30 files:

```hcl
files_nested = [
  for folder in local.folders : [
    for i in range(1, 11) : {
      folder = folder
      idx    = i
      path   = "${folder}/file${i}.txt"
    }
  ]
]

files = flatten(local.files_nested)
```

- The outer `for` iterates over the environments (`QA`, `STG`, `PRD`).
- The inner `for` generates 10 objects per environment with the index and file path.
- `flatten()` converts the list of lists into a flat list of 30 elements.
- A single `local_file` resource with `count = length(local.files)` creates all the files, avoiding duplicate resource blocks.
- Each file's text is customized per environment through the `user_text` variable (`map(string)` type), allowing content changes without modifying the resource logic.

---

## Test 2 - Troubleshooting

Application with a frontend/backend architecture deployed with Docker Compose. The goal is to identify and resolve connectivity and configuration issues.

| Component | Technology | Exposed Port |
|---|---|---|
| Frontend | Nginx (Alpine) | `8080 -> 80` |
| Backend | Flask (Python 3.11) | `8081 -> 5000` |

### Usage

```bash
cd test2_troubleshooting
make up
```

Access the frontend at `http://localhost:8080` and test the "CALL BACKEND" button.

To stop:

```bash
make down
```

### Solution

**1. CORS - Nginx Reverse Proxy**

The frontend makes a `fetch("http://localhost:8081/")` directly to the backend port, generating a cross-origin request. The backend handles this with the `Access-Control-Allow-Origin: *` header.

With this change, the frontend switches to `fetch("/api/")`, eliminating CORS since the request originates from the same origin. The backend no longer needs to expose its port to the host, and the `Access-Control-Allow-Origin` header becomes unnecessary.

**2. Pi Value Calculation**

The original code computed Pi using the Leibniz series, a CPU-intensive iterative algorithm:

```python
def compute_pi(iterations=1_000_000):
    pi = 0.0
    for i in range(iterations):
        pi += ((-1) ** i) / (2 * i + 1)
    return pi * 4
```

It was replaced with `math.pi`, which is an in-memory constant and requires no computation. The `time.perf_counter()` wrapping it measures virtually zero time, making the endpoint lightweight and preventing the CPU limit (`0.10`) configured in `docker-compose.yml` from affecting response time.

**3. Curl Blocking**

The backend rejects requests whose `User-Agent` contains `curl` (returns 403). This hinders quick testing from the terminal but does not affect the frontend since the browser sends its own User-Agent.

---

## Test 3 - PostgreSQL

SQL query optimization exercise on PostgreSQL. It works with two tables (`users` and `addresses`) with a volume of 10,000 users and 10,000,000 addresses to demonstrate performance differences.

### Usage

```bash
cd test3_postgres

# Start the database
make up

# In another terminal, build the psql client image
make build

# Generate test data
make generate_data

# Run the non-optimized query
make bad_query

# Run the optimized query
make optimized_query

# Stop the database
make down
```

### Solution

**Schema Improvements**

Original schema:

```sql
CREATE TABLE users (
  id         BIGSERIAL,
  email      TEXT        NOT NULL,
  full_name  TEXT        NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE addresses (
  id         BIGSERIAL,
  user_id    BIGINT      NOT NULL,
  street     TEXT        NOT NULL,
  city       TEXT        NOT NULL,
  country    TEXT        NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

Applied corrections:

1. **Primary keys**: The original tables did not define a `PRIMARY KEY`, so `id` had no uniqueness constraint or implicit index. `PRIMARY KEY` was added to both tables.
2. **Foreign key**: `user_id` had no reference to `users(id)`. `REFERENCES users(id)` was added to ensure referential integrity and prevent orphaned addresses.
3. **Composite index**: `idx_addresses_user_id_created_at ON addresses (user_id, created_at DESC)` was created to cover the main query pattern (filter by user + order by date).

**Non-optimized query (`bad_query.sql`)**

```sql
SELECT a.*
FROM users u
RIGHT JOIN addresses a ON a.user_id = u.id
WHERE u.id = 42
ORDER BY a.created_at DESC;
```

The `RIGHT JOIN` forces the planner to consider both tables even though the `SELECT` only needs columns from `addresses`. The join generates an unnecessary additional step that does not contribute data to the result.

**Optimized query (`optimized_query.sql`)**

```sql
SELECT *
FROM addresses
WHERE user_id = 42
ORDER BY created_at DESC;
```

By removing the `RIGHT JOIN` and querying `addresses` directly, the planner leverages the composite index `idx_addresses_user_id_created_at (user_id, created_at DESC)` both to filter by `user_id` and to resolve the `ORDER BY` without an additional sorting step.
