# Configuração e estruturação do Docker

## Estrutura de pastas

```
projeto/
│
├── docker-compose.yml
│
├── docker/
│   ├── nginx/
│   │   ├── Dockerfile
│   │   └── conf.d/
│   │       └── default.conf
│   │
│   ├── php/
│   │   └── Dockerfile
```

---

## Postgres image

```
postgres:
    image: postgres:15-alpine
    container_name: app_postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: app_database
      POSTGRES_USER: app_user
      POSTGRES_PASSWORD: app_password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./docker/postgres/init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - app_network
```

---

## pgAdmin4 image

```
pgAdmin:
    image: dpage/pgadmin4:latest
    container_name: app_pgadmin
    restart: unless-stopped
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@admin.com
      PGADMIN_DEFAULT_PASSWORD: admin_password
    ports:
      - "5050:80"
    volumes:
      - pgadmin_data:/var/lib/pgadmin
    networks:
      - app_network
```

---

## Running containers

```powershell
docker-compose up -d --build
```

---

## Obtendo IP do container do banco de dados

```powershell
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' container_name
```

Esperado: 172.17.0.2 ou similar.

## Conectando pgAdmin ao banco de dados

1.  Abrir navegador com `localhost:5050`
2.  Login com credenciais definidas no container (PGADMIN_DEFAULT_EMAIL e PGADMIN_DEFAULT_PASSWORD)
3.  Criar nova conexão com o ip obtido no passo anterior e credenciais definidas na imagem do postgresql(POSTGRES_DB, POSTGRES_USER e POSTGRES_PASSWORD)
