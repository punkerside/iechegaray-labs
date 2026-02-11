# iechegaray-labs

Repositorio de prueba tecnica compuesto por tres ejercicios independientes que abarcan Terraform, Docker/Troubleshooting y PostgreSQL.

## Prerequisitos

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.6.0
- [Docker](https://docs.docker.com/get-docker/) y Docker Compose
- GNU Make

## Estructura del proyecto

```
.
├── test1_terraform/        # Ejercicio 1 - Terraform
├── test2_troubleshooting/  # Ejercicio 2 - Docker Troubleshooting
├── test3_postgres/          # Ejercicio 3 - PostgreSQL
└── README.md
```

---

## Test 1 - Terraform

Genera archivos de texto en tres carpetas que representan ambientes (`QA`, `STG`, `PRD`) utilizando el provider `local`. Se crean 10 archivos por ambiente (30 en total) mediante `count` y `flatten`, cada uno con un texto personalizable por ambiente a traves de la variable `user_text`.

### Archivos principales

| Archivo | Descripcion |
|---|---|
| `main.tf` | Recurso `local_file` que genera los archivos |
| `data.tf` | Locals con la logica de iteracion (`folders`, `files_nested`, `files`) |
| `variables.tf` | Variable `user_text` (mapa por ambiente) |
| `versions.tf` | Restricciones de version de Terraform y providers |
| `Makefile` | Atajos para `init`, `apply` y `destroy` |

### Ejecucion

```bash
cd test1_terraform
make init
make apply
```

Para destruir los recursos:

```bash
make destroy
```

### Resolucion

Se utilizo un **loop anidado con `for`** en Terraform para simplificar la generacion de los 30 archivos. En lugar de declarar un recurso por archivo o por ambiente, la logica se concentra en `data.tf`:

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

- El `for` externo itera sobre los ambientes (`QA`, `STG`, `PRD`).
- El `for` interno genera 10 objetos por ambiente con el indice y la ruta del archivo.
- `flatten()` convierte la lista de listas en una lista plana de 30 elementos.
- Un unico recurso `local_file` con `count = length(local.files)` crea todos los archivos, evitando duplicar bloques de recursos.
- El texto de cada archivo se personaliza por ambiente mediante la variable `user_text` (tipo `map(string)`), permitiendo cambiar el contenido sin modificar la logica del recurso.

---

## Test 2 - Troubleshooting

Aplicacion con arquitectura frontend/backend desplegada con Docker Compose. El objetivo es identificar y resolver problemas de conectividad y configuracion.

| Componente | Tecnologia | Puerto expuesto |
|---|---|---|
| Frontend | Nginx (Alpine) | `8080 -> 80` |
| Backend | Flask (Python 3.11) | `8081 -> 5000` |

### Ejecucion

```bash
cd test2_troubleshooting
make up
```

Acceder al frontend en `http://localhost:8080` y probar el boton "CALL BACKEND".

Para detener:

```bash
make down
```

### Resolucion

**1. CORS - Proxy reverso en Nginx**

El frontend hace `fetch("http://localhost:8081/")` directamente al puerto del backend, generando una peticion cross-origin. El backend maneja esto con la cabecera `Access-Control-Allow-Origin: *`, pero esta solucion es fragil y expone el backend al exterior.

La correccion consiste en configurar Nginx como **proxy reverso** agregando un bloque `location /api/` en `nginx.conf`:

```nginx
location /api/ {
    proxy_pass http://backend:5000/;
}
```

Con esto el frontend pasa a hacer `fetch("/api/")`, eliminando CORS ya que la peticion sale del mismo origen. El backend deja de necesitar exponer su puerto al host y la cabecera `Access-Control-Allow-Origin` se vuelve innecesaria.

**2. Calculo del valor de Pi**

El codigo original usa `math.pi`, que es una constante en memoria. El `time.perf_counter()` que lo envuelve mide un tiempo practicamente nulo, por lo que no representa un calculo real.

La mejora consiste en reemplazarlo por un algoritmo que compute Pi de forma efectiva (por ejemplo, la serie de Leibniz), de modo que `calculation_time_seconds` refleje un tiempo de computo real y permita observar el impacto del limite de CPU (`0.10`) configurado en `docker-compose.yml`.

```python
def compute_pi(iterations=1_000_000):
    pi = 0.0
    for i in range(iterations):
        pi += ((-1) ** i) / (2 * i + 1)
    return pi * 4
```

Con este cambio el endpoint se convierte en un caso de prueba realista donde el limite de CPU tiene un efecto observable en el tiempo de respuesta.

**3. Bloqueo de curl**

El backend rechaza peticiones cuyo `User-Agent` contiene `curl` (retorna 403). Esto dificulta pruebas rapidas desde terminal pero no afecta al frontend ya que el navegador envia su propio User-Agent.

---

## Test 3 - PostgreSQL

Ejercicio de optimizacion de consultas SQL sobre PostgreSQL 16. Se trabaja con dos tablas (`users` y `addresses`) con un volumen de 10,000 usuarios y 10,000,000 direcciones para evidenciar diferencias de rendimiento.

### Ejecucion

```bash
cd test3_postgres

# Levantar la base de datos
make up

# En otra terminal, construir la imagen del cliente psql
make build

# Generar datos de prueba
make generate_data

# Ejecutar consulta no optimizada
make bad_query

# Ejecutar consulta optimizada
make optimized_query

# Detener la base de datos
make down
```

### Resolucion

**Mejoras al esquema**

Esquema original:

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

Correcciones aplicadas:

1. **Primary keys**: Las tablas originales no definen `PRIMARY KEY`, por lo que `id` no tiene restriccion de unicidad ni indice implicito. Se agrego `PRIMARY KEY` en ambas tablas.
2. **`BIGSERIAL` a `SERIAL`**: Con 10K usuarios y 10M direcciones, `SERIAL` (max ~2.1 mil millones) es mas que suficiente. Reduce el almacenamiento de 8 bytes a 4 bytes por fila en `id` y `user_id`, lo cual en 10M de filas representa un ahorro significativo en disco e indices.
3. **Foreign key**: `user_id` no tenia referencia a `users(id)`. Se agrego `REFERENCES users(id)` para garantizar integridad referencial y evitar direcciones huerfanas.
4. **Indice compuesto**: Se creo `idx_addresses_user_id_created_at ON addresses (user_id, created_at DESC)` para cubrir el patron de consulta principal (filtro por usuario + orden por fecha).

**Consulta no optimizada (`bad_query.sql`)**

```sql
SELECT a.*
FROM users u
RIGHT JOIN addresses a ON a.user_id = u.id
WHERE u.id = 42
ORDER BY a.created_at DESC;
```

El `RIGHT JOIN` obliga al planificador a considerar ambas tablas aunque el `SELECT` solo necesita columnas de `addresses`. El join genera un paso adicional innecesario que no aporta datos al resultado.

**Consulta optimizada (`optimized_query.sql`)**

```sql
SELECT *
FROM addresses
WHERE user_id = 42
ORDER BY created_at DESC;
```

Al eliminar el `RIGHT JOIN` y consultar `addresses` directamente, el planificador aprovecha el indice compuesto `idx_addresses_user_id_created_at (user_id, created_at DESC)` tanto para filtrar por `user_id` como para resolver el `ORDER BY` sin un paso adicional de ordenamiento, resultando en un **Index Scan** directo en lugar de un plan con join y sort.