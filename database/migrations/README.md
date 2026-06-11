# Migraciones

Traducción versionada del modelo de datos (el DER es la fuente de diseño; estas
migraciones son su traducción 1:1, ver `CONVENTIONS.md`).

- **`0001_esquema_inicial.sql`** — migración *baseline*. Crea las 24 tablas e
  índices. Es equivalente al consolidado `database/schema.sql`.

## Convención

- Una migración por cambio de esquema, **atómica y reversible**.
- Numeración incremental: `0002_<cambio>.sql`, `0003_<cambio>.sql`, …
- Para revertir el baseline, eliminar las tablas creadas (orden inverso a las
  dependencias de claves foráneas) o borrar el archivo de base de datos en un
  entorno de desarrollo.

## Aplicar

```bash
# Base nueva desde cero (equivale a aplicar todas las migraciones en orden)
sqlite3 data/inventario.db < ../schema.sql

# O migración por migración
sqlite3 data/inventario.db < 0001_esquema_inicial.sql
```

> El prototipo (Python + PyQt6) ejecuta `database/schema.sql` directamente al
> iniciar (ver `database/connection.py` del sistema). `schema.sql` y el conjunto
> de migraciones describen el mismo esquema.
