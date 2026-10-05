# Taller 2 — PulsePass

PulsePass implementa la capa de servicios para gestionar venues, eventos, artistas, usuarios y tickets.
Incluye persistencia con Spring Data JPA, migraciones Flyway para PostgreSQL, DTOs con Java records,
MapStruct y pruebas unitarias con JUnit 5, Mockito y AssertJ.

## Requisitos

- Java 21
- PostgreSQL

## Configuración

La aplicación lee la conexión a PostgreSQL de estas variables de entorno:

| Variable | Valor local predeterminado |
| --- | --- |
| `DB_URL` | `jdbc:postgresql://localhost:5432/pulsepass` |
| `DB_USER` | `postgres` |
| `DB_PASSWORD` | `postgres` |

Los valores predeterminados son solo para desarrollo local. Configura credenciales seguras fuera del código
cuando ejecutes la aplicación en otros entornos. Flyway crea el esquema desde `src/main/resources/db/migration`;
Hibernate valida el esquema existente.

## Pruebas

En Windows PowerShell:

```powershell
.\mvnw.cmd clean test
```

Los tests de servicios son unitarios y no requieren PostgreSQL ni Docker.

## Alcance

Esta entrega cubre la capa de servicios y persistencia del laboratorio. Controllers REST, seguridad y frontend
están fuera del alcance actual.
