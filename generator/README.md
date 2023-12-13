Meta-Id Generator
-----------------

## 1. Overview

A meta-identifier is a *composite type*, that encapsulates the identifier for an "entity" in
PostgreSQL, for example a schema, cast, table, view, column, type, etc.  Each type encapsulates all
variables necessary to uniquely identify the entity.  For example. a *column* is uniquely identified
by it's `schema_name`, `relation_name` and name, so the `meta.column_id` identifier encapsulates
these three variables in a single composite key.

Beyond just the `CREATE TYPE` issued for each identifier, there are a number of supporting
"components" that flesh out the functionality of the type, things like casts, constructor functions,
comparator ops, etc.

There are 25 meta-identifiers, each with 16 components which *may* be generated, depending on
whether they are appropriate for the identifier.  This makes a 25x16 sparse matrix of components
that this script generates, so up to 400 components.  It's very nice not to maintain all those by
hand, since they are structured mostly the same.

PostgreSQL feature coverage is not complete, and the supported entites and components may evolve
over time to expand coverage.

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

For each entity, a number of "components" *may* be generated, depending on whether they're
appropriate for the type.  These components flesh out the functionality of the type with casts, ops
and constructors:

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

Here is a general description of the type, and each of the components that are generated to support
it.

### a) Identifier Type

Each meta-identifier (e.g. schema_id, table_id, column_id, etc.) is a composite type that
encapsulates the variables necessary to uniquely identify some entity in PostgreSQL.  For example, a
column is uniquely identified by a schema name, relation name and column name.  Identifiers don't
describe the entity, they just serve as an identifier.  Actual entity descriptions go in the meta
system catalog, which uses these identifiers as the "soft" parimary key of each view, typically
called `id`.


### b) Type Constructor Function

Meta-identifiers are composite types.  In PostgreSQL, composite types are instantiated via
`row('public','my_table', 'id')::column_id`, but this isn't very pretty, so each meta-id also has a
constructor function whose arguments are the same as the arguments you would pass to row().

Instead of:
    select row('public','my_table','my_column')::meta.column_id
We generate a nice constructor:
    create function column_id(schema, relation, name) returns meta.column_id
and then instantiate a column_id via the constructor:
    select meta.column_id('public','monkeys','name');



### c) Cast to json/jsonb

Each type can be cast to either json or jsonb:
    select meta.column_id::jsonb

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

TODO: I don't remember why these are necessary and I think they might be useless.


### f) System Catalog

Not completed yet, but some commented-out stubs.  This same system could generate much of the system
catalog, aka the views and that fully describe each entity, and the triggers that are fired for
insert an dupdate on these views, and the DDL statements that are executed by the triggers.



## 4. Snippets

There are a bunch of functions that take a component and an entity as arguments, and return a code
snippet.  These consolidate commonly-repeated DDL statement fragments for reuse.

## 5. Runner

The runner pulls all this together.  For each entity, it generates DDL statements for each of the
components, and then (optionally) executes each statement, or prints it to the screen.  The
[identifiers.sql](../000-identifiers.sql) script is the output of this generator.
(optionally) executes the DDL statements that 
