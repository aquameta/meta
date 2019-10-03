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

## Meta-Identifiers Type System

- cast_id ( source_type meta.type_id, target_type meta.type_id )
- column_id ( relation_id meta.relation_id, name text )
- connection_id ( pid integer, connection_start timestamp with time zone )
- constraint_id ( table_id meta.relation_id, name text )
- extension_id ( name text )
- field_id ( row_id meta.row_id, column_id meta.column_id )
- foreign_data_wrapper_id ( name text )
- foreign_key_id ( relation_id meta.relation_id, name text )
- foreign_server_id ( name text )
- function_id ( schema_id meta.schema_id, name text, parameters text[] )
- operator_id ( schema_id meta.schema_id, name text, left_arg_type_id meta.type_id, right_arg_type_id meta.type_id )
- policy_id ( relation_id meta.relation_id, name text )
- relation_id ( schema_id meta.schema_id, name text )
- role_id ( name text )
- row_id ( pk_column_id meta.column_id, pk_value text )
- schema_id ( name text )
- sequence_id ( schema_id meta.schema_id, name text )
- table_privilege_id ( relation_id meta.relation_id, role_id meta.role_id, type text )
- trigger_id ( relation_id meta.relation_id, name text )
- type_id ( schema_id meta.schema_id, name text )

## Views
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
