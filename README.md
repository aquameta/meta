Meta: A writable system catalog extension for PostgreSQL
========================================================

This extension provides two facilities:

1. A set of "meta-identifiers" for unambiguously referencing database objects like tables, views, schemas, roles, etc.
2. A normalized system catalog similar in function to `pg_catalog` or `information_schema`, but layed out more readably.

INSTALL
-------

Install the extension into PostgreSQL's `extension/` directory:
```shell
make
sudo make install
```

From a PostgreSQL shell, install meta's required extensions:

`CREATE EXTENSION hstore SCHEMA public;`

`CREATE EXTENSION` [pg_catalog_get_defs](https://github.com/aquametalabs/aquameta/tree/master/src/pg-extension/pg_catalog_get_defs) `SCHEMA pg_catalog;`

Finally, install the meta extension:
```sql
CREATE EXTENSION meta;
```
