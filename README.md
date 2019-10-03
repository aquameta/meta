# Meta: Simple system catalog extension for PostgreSQL

This extension provides two facilities:

1. A set of "meta-identifiers", PostgreSQL types that unambiguously reference database objects like tables, views, schemas, roles, etc.
2. A normalized system catalog similar in function to `pg_catalog` or `information_schema`, but laid out more readably.

Optionally, the [meta_triggers](https://github.com/aquametalabs/meta_triggers) extension can be installed as well, which makes the views writable, so that for example a schema can be created using an `insert` statement.

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

## Schema Diagram

![meta schema diagram](https://raw.githubusercontent.com/aquametalabs/meta/master/doc/meta.png)

## Identifiers

- cast_id
- column_id
- connection_id
- constraint_id
- extension_id
- field_id
- foreign_data_wrapper_id
- foreign_key_id
- foreign_server_id
- function_id
- operator_id
- policy_id
- relation_id
- role_id
- row_id
- schema_id
- sequence_id
- table_privilege_id
- trigger_id
- type_id

## Views

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
