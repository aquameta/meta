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

- schema
- type
- cast
- operator
- sequence
- relation
- table
- view
- column
- foreign_key
- row
- field
- function
- trigger
- role
- connection
- constraint
- constraint_unique
- constraint_check
- extension
- foreign_data_wrapper
- foreign_server
- foreign_table
- foreign_column
- table_privilege


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
