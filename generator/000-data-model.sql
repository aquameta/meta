/******************************************************************************
* Meta Generator
******************************************************************************/
drop schema if exists meta_meta cascade;
create schema meta_meta;

create extension if not exists hstore schema public;

begin;

/*
 * pg_entity: 
 * A type of identifiable thing in PostgreSQL:  e.g. table, column, schema, view, function, etc.
 */
create table meta_meta.pg_entity (
	id serial not null primary key,

    -- definition vars
	name text not null,
	constructor_arg_names text[] not null,
	constructor_arg_types text[] not null
);


/*
 * pg_entity_component
 *
 * Each entity's identifier gets supported by a number of "components" that support the CREATE TYPE
 * statement with nicities like constructors, casts, etc.  These "components" are generated along
 * with the identifier's TYPE declaration.
 */

create table meta_meta.pg_entity_component (
	id serial not null primary key,
    name text, -- create type $name
    position integer, -- the sequential position this entity's id is generate ind -- because they compound
    "type" text -- create $type $name -- e.g. function, type, op etc
);


create schema meta;
create type meta.meta_id as (id text);
create or replace function meta.meta_id(id text) returns meta.meta_id as $$
begin
    -- validation
    return row(id);
end;
$$ language plpgsql;


/*
 * pg_entity data
 */

insert into meta_meta.pg_entity(name, constructor_arg_names, constructor_arg_types) values ('schema',      '{"name"}', '{"text"}');
insert into meta_meta.pg_entity(name, constructor_arg_names, constructor_arg_types) values ('type',        '{"schema_name", "name"}', '{"text","text"}');
insert into meta_meta.pg_entity(name, constructor_arg_names, constructor_arg_types) values ('cast',        '{"source_type_schema_name", "source_type_name", "target_type_schema_name", "target_type_name"}', '{"text","text","text","text"}');
insert into meta_meta.pg_entity(name, constructor_arg_names, constructor_arg_types) values ('operator',    '{"schema_name", "name", "left_arg_type_schema_name", "left_arg_type_name", "right_arg_type_schema_name", "right_arg_type_name"}', '{"text","text","text","text","text","text"}');
insert into meta_meta.pg_entity(name, constructor_arg_names, constructor_arg_types) values ('sequence',    '{"schema_name", "name"}', '{"text","text"}');
insert into meta_meta.pg_entity(name, constructor_arg_names, constructor_arg_types) values ('relation',    '{"schema_name", "name"}', '{"text","text"}');
insert into meta_meta.pg_entity(name, constructor_arg_names, constructor_arg_types) values ('table',       '{"schema_name", "name"}', '{"text","text"}');
insert into meta_meta.pg_entity(name, constructor_arg_names, constructor_arg_types) values ('view',        '{"schema_name", "name"}', '{"text","text"}');
insert into meta_meta.pg_entity(name, constructor_arg_names, constructor_arg_types) values ('column',      '{"schema_name", "relation_name", "name"}', '{"text","text","text"}');
insert into meta_meta.pg_entity(name, constructor_arg_names, constructor_arg_types) values ('foreign_key', '{"schema_name", "relation_name", "name"}', '{"text","text","text"}');
insert into meta_meta.pg_entity(name, constructor_arg_names, constructor_arg_types) values ('row',         '{"schema_name", "relation_name", "pk_column_name", "pk_value"}', '{"text","text","text","text"}');
insert into meta_meta.pg_entity(name, constructor_arg_names, constructor_arg_types) values ('field',       '{"schema_name", "relation_name", "pk_column_name", "pk_value", "column_name"}', '{"text","text","text","text","text"}');
insert into meta_meta.pg_entity(name, constructor_arg_names, constructor_arg_types) values ('function',    '{"schema_name", "name", "parameters"}', '{"text","text","text[]"}');
insert into meta_meta.pg_entity(name, constructor_arg_names, constructor_arg_types) values ('trigger',     '{"schema_name", "relation_name", "name"}', '{"text","text","text"}');
insert into meta_meta.pg_entity(name, constructor_arg_names, constructor_arg_types) values ('role',        '{"name"}', '{"text"}');
insert into meta_meta.pg_entity(name, constructor_arg_names, constructor_arg_types) values ('connection',  '{"pid", "connection_start"}', '{"int4","timestamptz"}');
insert into meta_meta.pg_entity(name, constructor_arg_names, constructor_arg_types) values ('constraint',  '{"schema_name", "relation_name", "name"}', '{"text","text","text"}');
insert into meta_meta.pg_entity(name, constructor_arg_names, constructor_arg_types) values ('constraint_unique', '{"schema_name", "table_name", "name", "column_names"}', '{"text","text","text","text"}');
insert into meta_meta.pg_entity(name, constructor_arg_names, constructor_arg_types) values ('constraint_check', '{"schema_name", "table_name", "name", "column_names"}', '{"text","text","text","text"}');
insert into meta_meta.pg_entity(name, constructor_arg_names, constructor_arg_types) values ('extension',   '{"name"}', '{"text"}');
insert into meta_meta.pg_entity(name, constructor_arg_names, constructor_arg_types) values ('foreign_data_wrapper', '{"name"}', '{"text"}');
insert into meta_meta.pg_entity(name, constructor_arg_names, constructor_arg_types) values ('foreign_server', '{"name"}', '{"text"}');
insert into meta_meta.pg_entity(name, constructor_arg_names, constructor_arg_types) values ('foreign_table', '{"schema_name", "name"}', '{"text","text"}');
insert into meta_meta.pg_entity(name, constructor_arg_names, constructor_arg_types) values ('foreign_column', '{"schema_name", "name"}', '{"text","text"}');
insert into meta_meta.pg_entity(name, constructor_arg_names, constructor_arg_types) values ('table_privilege', '{"schema_name", "relation_name", "role", "type"}', '{"text","text","text","text"}');
insert into meta_meta.pg_entity(name, constructor_arg_names, constructor_arg_types) values ('policy', '{"schema_name", "relation_name", "name"}', '{"text","text","text"}');








insert into meta_meta.pg_entity_component(position,name,"type") values (1,'type', 'type');
insert into meta_meta.pg_entity_component(position,name,"type") values (2,'type_constructor_function','function');
insert into meta_meta.pg_entity_component(position,name,"type") values (3,'meta_id_constructor', 'function');

-- type to jsonb
-- TODO: these are disabled because they were breaking endpoint.  fix.
insert into meta_meta.pg_entity_component(position,name,"type") values (4,'type_to_jsonb_comparator_function', 'function');
insert into meta_meta.pg_entity_component(position,name,"type") values (5,'type_to_jsonb_comparator_op', 'op');
insert into meta_meta.pg_entity_component(position,name,"type") values (6,'type_to_jsonb_type_constructor_function', 'function');
insert into meta_meta.pg_entity_component(position,name,"type") values (7,'type_to_jsonb_cast', 'cast');

-- type to json
insert into meta_meta.pg_entity_component(position,name,"type") values (8,'type_to_json_comparator_function', 'function');
insert into meta_meta.pg_entity_component(position,name,"type") values (9,'type_to_json_comparator_op', 'op');
insert into meta_meta.pg_entity_component(position,name,"type") values (10,'type_to_json_type_constructor_function', 'function');
insert into meta_meta.pg_entity_component(position,name,"type") values (11,'type_to_json_cast', 'cast');

-- type downcast to schema_id
insert into meta_meta.pg_entity_component(position,name,"type") values (20,'type_to_schema_type_constructor_function', 'function');
insert into meta_meta.pg_entity_component(position,name,"type") values (21,'type_to_schema_cast', 'cast');

-- type downcast to relation_id
insert into meta_meta.pg_entity_component(position,name,"type") values (22,'type_to_relation_type_constructor_function', 'function');
insert into meta_meta.pg_entity_component(position,name,"type") values (23,'type_to_relation_cast', 'cast');

-- type downcast to column_id
insert into meta_meta.pg_entity_component(position,name,"type") values (24,'type_to_column_type_constructor_function', 'function');
insert into meta_meta.pg_entity_component(position,name,"type") values (25,'type_to_column_cast', 'cast');

-- type downcast to row_id
-- this is only for field_id, nothing else has a row_id.
-- TODO: why is this disabled again?
/*
insert into meta_meta.pg_entity_component(position,name,"type") values (26,'type_to_row_type_constructor_function', 'function');
insert into meta_meta.pg_entity_component(position,name,"type") values (27,'type_to_row_cast', 'cast');
*/

/*

Maybe someday we generate stubs for the system catalog with this thing too.  Not sure that space is
quite this uniform or simple, though.

insert into meta_meta.pg_entity_component(name,"type") values ('relation', 'view');
insert into meta_meta.pg_entity_component(name,"type") values ('relation_create_stmt_function', 'function');
insert into meta_meta.pg_entity_component(name,"type") values ('relation_insert_trigger_function', 'function');
insert into meta_meta.pg_entity_component(name,"type") values ('relation_insert_trigger', 'trigger');
insert into meta_meta.pg_entity_component(name,"type") values ('relation_drop_stmt_function', 'function');
insert into meta_meta.pg_entity_component(name,"type") values ('relation_delete_trigger_function', 'function');
insert into meta_meta.pg_entity_component(name,"type") values ('relation_delete_trigger', 'trigger');
insert into meta_meta.pg_entity_component(name,"type") values ('relation_update_trigger_function', 'function');
insert into meta_meta.pg_entity_component(name,"type") values ('relation_update_trigger', 'trigger');
*/

commit;
