Meta: A writable system catalog extension for PostgreSQL
========================================================

This extension provides two facilities:

1. A set of "meta-identifiers" for unambiguously referencing database objects like tables, views, schemas, roles, etc.
2. A normalized system catalog similar in function to `pg_catalog` or `information_schema`, but layed out more readably.

INSTALL
-------

Install the extension into PostgreSQL's `extension/` directory:
```shell
cd meta/
make
sudo make install
```

From a PostgreSQL shell, install the `hstore` extension in schema `public`.

```sql
CREATE EXTENSION hstore SCHEMA public;
```

Finally, install the meta extension:
```sql
CREATE EXTENSION meta;
```

Optionally, install the [meta_triggers](https://github.com/aquametalabs/meta_triggers) extension, to make views updatable.
