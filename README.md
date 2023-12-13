Meta: Simplified System Catalog for PostgreSQL
==============================================

# Overview

System catalogs are great, because they provide a data-centric view into the database's structure.
PostgreSQL has two system catalogs, `pg_catalog` and `information_schema`, but each have some
drawbacks.  `pg_catalog` mirrors PostgreSQL's *internal* structure, and centers around `oid`, object
identifiers that aren't intended for "above the hood" developers to know or care about.
`information_schema` is part of the SQL standard, and is filled with many views and columns that
don't match PostgreSQL's terminology or features.

The goals with `meta` is to provide an "above the hood" system catalog for PostgreSQL that is
normalized and uses common names for views and columns.

Features:

- Meta System catalog:  ~30 views ([full list]()) that, under the hood, query and synthesize
  `pg_catalog` and `information_schema`
- Meta-identifiers:  A set of composite types that encapsulate variables necessary to identify
  PostgreSQL objects (tables, columns, casts, types, etc.) by name, and serve as "soft" primary keys
  to the views above.  See [meta-identifiers](generator/) for more.
- Catalog triggers:  Optional [meta_triggers](https://github.com/aquametalabs/meta_triggers)
  extension, which adds INSERT/UPDATE triggers on the catalog's views.  These triggers make it
  possible to do DDL statements (e.g. `CREATE TABLE ...`) with an DML statement (e.g. `insert into
  meta.table (name) values('foo'))`, similar to a schema diff and migration tool but with a
  data-centric approach.

Status:

- The catalog is still evolving.  The goal is to mirror PostgreSQL's architecture completely and
  accurately, but we're still figuring out "where to draw the lines".
- Most common PostgreSQL features are covered, but PostgreSQL is very large, and 100% coverage is
  not complete.
- Not every feature has read/write triggers

# Install

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

# Documentation

## Meta-Identifiers Type System

See [identifiers](generator/).


## System Catalog

The system catalog contains the following views:

- cast
- column
- connection
- constraint_check
- constraint_unique
- extension
- foreign_column
- foreign_data_wrapper
- foreign_key
- foreign_server
- foreign_table
- function
- function_parameter
- operator
- policy
- policy_role
- relation
- relation_column
- role
- role_inheritance
- schema
- sequence
- table
- table_privilege
- trigger
- type
- view

![meta schema diagram](https://raw.githubusercontent.com/aquametalabs/meta/master/doc/meta-schema-diagram.png)


