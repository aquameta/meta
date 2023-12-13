Meta-Identifier Generator
-------------------------

This module generates meta's "meta-identifiers".  Here is what, how and why.

## 1. Overview

A meta-identifier is a *composite type*, that encapsualates all the variables necessary to identify
a PostgreSQL "entity", e.g. a table, column, schema, type, function, etc.  For example. a *column*
is uniquely identified by it's `schema_name`, `relation_name` and `name`, so those variables are
encapsulated in the `meta.column_id` composite type.

Beyond just a composite type, each identifier has a number of supporting "components" that flesh out
the functionality of the type, e.g. constructor functions, comparator operatorss, casts to more
primitive types, etc.

There are 25 meta-identifiers, each with 16 components which *may* be generated, depending on
whether they are appropriate for the identifier.  This makes a 25x16 sparse matrix of
entities-cross-components that this script generates, so up to 400 components.  They're
auto-generated because they all share a similar structure and functionality, and maintaining and
evolving them by hand is suboptimal.

The end result is a consistent set of identifiers for most common PostgreSQL features.  The goal is
to mirror PostgreSQL's structure as closely as possible.  Any divergence or incongruence with how
PostgreSQL works would be considered a bug.  Not every feature in PostgreSQL is covered, but should
be able to easily evolve to accomodate additional features.  Requests are welcome.

## 2. Entities

Meta-identifiers are generated for the following PostgreSQL entities:

```
create type meta.cast_id as (source_type_schema_name text,source_type_name text,target_type_schema_name text,target_type_name text);
create type meta.column_id as (schema_name text,relation_name text,name text);
create type meta.connection_id as (pid int4,connection_start timestamptz);
create type meta.constraint_id as (schema_name text,relation_name text,name text);
create type meta.constraint_check_id as (schema_name text,table_name text,name text,column_names text);
create type meta.constraint_unique_id as (schema_name text,table_name text,name text,column_names text);
create type meta.extension_id as (name text);
create type meta.field_id as (schema_name text,relation_name text,pk_column_name text,pk_value text,column_name text);
create type meta.foreign_column_id as (schema_name text,name text);
create type meta.foreign_data_wrapper_id as (name text);
create type meta.foreign_key_id as (schema_name text,relation_name text,name text);
create type meta.foreign_server_id as (name text);
create type meta.foreign_table_id as (schema_name text,name text);
create type meta.function_id as (schema_name text,name text,parameters text[]);
create type meta.operator_id as (schema_name text,name text,left_arg_type_schema_name text,left_arg_type_name text,right_arg_type_schema_name text,right_arg_type_name text);
create type meta.policy_id as (schema_name text,relation_name text,name text);
create type meta.relation_id as (schema_name text,name text);
create type meta.role_id as (name text);
create type meta.row_id as (schema_name text,relation_name text,pk_column_name text,pk_value text);
create type meta.schema_id as (name text);
create type meta.sequence_id as (schema_name text,name text);
create type meta.table_id as (schema_name text,name text);
create type meta.table_privilege_id as (schema_name text,relation_name text,role text,type text);
create type meta.trigger_id as (schema_name text,relation_name text,name text);
create type meta.type_id as (schema_name text,name text);
create type meta.view_id as (schema_name text,name text);
```


## 3. Components

For each entity, a number of "components" are be generated, that flesh out the functionality of the
type.  Not every component is appropriate for every type, but here are the set of components that
*may* be generated for each type:

- type
- type_constructor_function
- meta_id_constructor
- type_to_jsonb_comparator_function
- type_to_jsonb_comparator_op
- type_to_jsonb_type_constructor_function
- type_to_jsonb_cast
- type_to_json_comparator_function
- type_to_json_comparator_op
- type_to_json_type_constructor_function
- type_to_json_cast
- type_to_schema_type_constructor_function
- type_to_schema_cast
- type_to_relation_type_constructor_function
- type_to_relation_cast

Here is a general description the components that are generated:

### a) Composite Type

Each meta-identifier (e.g. schema_id, table_id, column_id, etc.) is a composite type, created with a
`CREATE TYPE` statement.  Identifiers don't describe the entity, they only contain enough
information to uniquely identify it within the scope of a database.  Their uniqueness is enforced by
PostgreSQL, e.g. `ERROR:  type "test" already exists`.


### b) Type Constructor Function

Meta-identifiers are composite types.  In PostgreSQL, composite types are instantiated via
`row('public','my_table', 'id')::column_id`, but this isn't very pretty, so each meta-id also has a
constructor function whose arguments are the same as the arguments you would pass to row().

Instead of:

```sql
    select row('public','my_table','my_column')::meta.column_id
```

We generate a nice constructor:

```sql
    create function column_id(schema, relation, name) returns meta.column_id
```

and then instantiate a column_id via the constructor:

```sql
    select meta.column_id('public','monkeys','name');
```



### c) Cast to json/jsonb

Each type can be cast to either json or jsonb:

```
    select meta.column_id::jsonb
```

A cast needs several components:

- type_to_jsonb_comparator_function
- type_to_jsonb_comparator_op
- type_to_jsonb_type_constructor_function
- type_to_jsonb_cast


### d) Downcasts

When appropriate, an identifier can be "downcast" to a less-specific identifier.  For example a
column_id can be cast to a relation_id or a schema_id.  When appropriate, these casts are generated.


### e) CAST to "meta_id"

A cast to a pretty text representation.


### f) System Catalog

WIP.  This same system could generate much of the meta system catalog, which also has a very uniform
structure.  Each view in the system catalog has the following components:

- relation
- relation_create_stmt_function
- relation_insert_trigger_function
- relation_insert_trigger
- relation_drop_stmt_function
- relation_delete_trigger_function
- relation_delete_trigger
- relation_update_trigger_function
- relation_update_trigger

The generator does not know about all the columns of the views, but it could generate all the
boilerplate for the view, trigger and DDL statements.


## 4. Snippets

There are a bunch of functions that take a component and an entity as arguments, and return a code
snippet.  These consolidate commonly-repeated DDL statement fragments for reuse.

## 5. Runner

The runner pulls all this together.  For each entity, it generates DDL statements for each of the
components, and then (optionally) executes each statement, or prints it to the screen.  The
[identifiers.sql](../001-identifiers.sql) script is the output of this generator.
