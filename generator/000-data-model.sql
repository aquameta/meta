/*
 * Meta Generator
 * Generates the writable system catalog.
 */

begin;

drop schema if exists meta2 cascade;
create schema meta2;

drop schema if exists meta_meta cascade;
create schema meta_meta;

/*
 * pg_entity: 
 * Something PostgreSQL that meta tracks, e.g. table, column, schema, view, etc.
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
 * Every entity needs these components (type, casts to/from json with their operators and function, casts to/from text, a catalog view)
 */

create table meta_meta.pg_entity_component (
	id serial not null primary key,
    name text,
    "type" text
);


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
insert into meta_meta.pg_entity(name, constructor_arg_names, constructor_arg_types) values ('connection',  '{"pid", "connection_start"}', '{"text","text"}');
insert into meta_meta.pg_entity(name, constructor_arg_names, constructor_arg_types) values ('constraint',  '{"schema_name", "relation_name", "name"}', '{"text","text","text"}');
insert into meta_meta.pg_entity(name, constructor_arg_names, constructor_arg_types) values ('constraint_unique', '{"schema_name", "table_name", "name", "column_names"}', '{"text","text","text","text"}');
    -- generate_meta_meta_pg_entity('constraint_check',-- '{"schema_name", "table_name", "name", "column_names"}');
insert into meta_meta.pg_entity(name, constructor_arg_names, constructor_arg_types) values ('extension',   '{"name"}', '{"text"}');
insert into meta_meta.pg_entity(name, constructor_arg_names, constructor_arg_types) values ('foreign_data_wrapper', '{"name"}', '{"text"}');
insert into meta_meta.pg_entity(name, constructor_arg_names, constructor_arg_types) values ('foreign_server', '{"name"}', '{"text"}');
insert into meta_meta.pg_entity(name, constructor_arg_names, constructor_arg_types) values ('foreign_table', '{"schema_name", "name"}', '{"text","text"}');
insert into meta_meta.pg_entity(name, constructor_arg_names, constructor_arg_types) values ('foreign_column', '{"schema_name", "name"}', '{"text","text"}');

/*
 * pg_entity_component data
 */

insert into meta_meta.pg_entity_component(name,"type") values ('type', 'type');
insert into meta_meta.pg_entity_component(name,"type") values ('type_constructor_function','function');
insert into meta_meta.pg_entity_component(name,"type") values ('type_to_json_comparator_op', 'op');
insert into meta_meta.pg_entity_component(name,"type") values ('type_to_json_type_constructor_function', 'function');
insert into meta_meta.pg_entity_component(name,"type") values ('type_to_json_cast', 'cast');
insert into meta_meta.pg_entity_component(name,"type") values ('relation', 'view');
insert into meta_meta.pg_entity_component(name,"type") values ('relation_create_stmt_function', 'function');
insert into meta_meta.pg_entity_component(name,"type") values ('relation_insert_trigger_function', 'function');
insert into meta_meta.pg_entity_component(name,"type") values ('relation_insert_trigger', 'trigger');
insert into meta_meta.pg_entity_component(name,"type") values ('relation_drop_stmt_function', 'function');
insert into meta_meta.pg_entity_component(name,"type") values ('relation_delete_trigger_function', 'function');
insert into meta_meta.pg_entity_component(name,"type") values ('relation_delete_trigger', 'trigger');
insert into meta_meta.pg_entity_component(name,"type") values ('relation_update_trigger_function', 'function');
insert into meta_meta.pg_entity_component(name,"type") values ('relation_update_trigger', 'trigger');


commit;
