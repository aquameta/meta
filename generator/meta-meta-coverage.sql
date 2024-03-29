/*
meta-meta-coverage

checks to see that for each meta entity (table, view, column, type, cast,
etc.), there are the appropriate identifiers, casts, comparison operators, etc.
basically checks to see if it's all here.
*/

begin;

/*
drop schema if exists meta_meta cascade;
create schema meta_meta;
set search_path=meta_meta, meta;
*/

/*
 * entity: a meta_entitty "thing" in PostgreSQL, e.g. table, column, schema, view, etc.  something that the meta catalog should track.
 */

create table meta_meta.entity (
	id serial not null primary key,

    -- definition vars
	name text not null,
	constructor_arg_names text[] not null,
	constructor_arg_types text[] not null,

	-- TYPE
	-- gripe: ERROR:  cannot use column references in default expression
	type_id meta.type_id not null,
	type_constructor_function_id meta.function_id,-- not null,
	type_to_json_comparator_op_id meta.operator_id,-- not null,
	type_to_json_type_constructor_function_id meta.function_id,-- not null,
	type_to_json_cast_id meta.cast_id,-- not null,

	-- VIEW
	relation_id meta.relation_id,-- not null,

	-- create
	relation_create_stmt_function_id meta.function_id,-- not null,
	relation_insert_trigger_function_id meta.function_id,-- not null,
	relation_insert_trigger_id meta.trigger_id,-- not null,

	-- delete
	relation_drop_stmt_function_id meta.function_id,-- not null,
	relation_delete_trigger_function_id meta.function_id,-- not null,
	relation_delete_trigger_id meta.trigger_id not null,

	-- update
	/*
	relation_update_stmt_function_id meta.function_id not null,
	*/
	relation_update_trigger_function_id meta.function_id not null,
	relation_update_trigger_id meta.trigger_id not null
);

/*
create table meta_relation_update_handler (
	id serial not null primary key,
	stmt_function_id meta.function_id not null,
	trigger_function_id meta.function_id not null,
	trigger_id meta.trigger_id not null
);
*/


/*
 * inserts a db entity that should exist in meta, into the `meta_meta.entity` table.
 */

create or replace function generate_meta_meta_entity (name text, constructor_arg_names text[], constructor_arg_types text[]) returns void as $$
declare
	-- type
	_type_id meta.type_id;
	_type_constructor_function_id meta.function_id;
	_type_to_json_comparator_op_id meta.operator_id;
	_type_to_json_type_constructor_function_id meta.function_id;
	_type_to_json_cast_id meta.cast_id;

	-- relation
	_relation_id meta.relation_id;

	_relation_create_stmt_function_id meta.function_id;
	_relation_insert_trigger_function_id meta.function_id;
	_relation_insert_trigger_id meta.trigger_id;

	_relation_drop_stmt_function_id meta.function_id;
	_relation_delete_trigger_function_id meta.function_id;
	_relation_delete_trigger_id meta.trigger_id;
	
	_relation_update_trigger_function_id meta.function_id;
	_relation_update_trigger_id meta.trigger_id;
begin
	-- type
	_type_id := meta.type_id('meta2', name || '_id');
	_type_constructor_function_id :=
		meta.function_id('meta2', name || '_id', constructor_arg_types);
	_type_to_json_comparator_op_id :=
		meta.operator_id('meta2', '=', 'meta2', name || '_id', 'public', 'json');
	_type_to_json_type_constructor_function_id :=
		meta.function_id('meta2', name || '_id', '{"json"}');
	_type_to_json_cast_id :=
		meta.cast_id('meta2', name || '_id', 'public', 'json');

	-- relation
	_relation_id :=
		meta.relation_id('meta2', name);
	-- create -> insert
	_relation_create_stmt_function_id :=
		meta.function_id('meta2', 'stmt_' || name || '_create', constructor_arg_types);
	_relation_insert_trigger_function_id :=
		meta.function_id('meta2', name || '_insert', NULL);
	_relation_insert_trigger_id :=
		meta.trigger_id('meta2', name, 'meta_' || name || '_insert_trigger');

	-- drop -> delete
	_relation_drop_stmt_function_id :=
		meta.function_id('meta2', 'stmt_' || name || '_drop', constructor_arg_types);
	_relation_delete_trigger_function_id :=
		meta.function_id('meta2', name || '_delete', NULL);
	_relation_delete_trigger_id :=
		meta.trigger_id('meta2', name, 'meta_' || name || '_delete_trigger');

	-- alter -> update
	_relation_update_trigger_function_id :=
		meta.function_id('meta2', name || '_update', NULL);
	_relation_update_trigger_id :=
		meta.trigger_id('meta2', name, 'meta_' || name || '_update_trigger');

	insert into meta_meta.entity (
        name,
        constructor_arg_names,
        constructor_arg_types,

		-- type
		type_id,
		type_constructor_function_id,
		type_to_json_comparator_op_id,
		type_to_json_type_constructor_function_id,
		type_to_json_cast_id,

		-- relation
		relation_id,

		relation_create_stmt_function_id,
		relation_insert_trigger_function_id,
		relation_insert_trigger_id,

		relation_drop_stmt_function_id,
		relation_delete_trigger_function_id,
		relation_delete_trigger_id,
		
		relation_update_trigger_function_id,
		relation_update_trigger_id
	) values (
        name,
        constructor_arg_names,
        constructor_arg_types,

		-- type
		_type_id,
		_type_constructor_function_id,
		_type_to_json_comparator_op_id,
		_type_to_json_type_constructor_function_id,
		_type_to_json_cast_id,

		-- relation
		_relation_id,

		_relation_create_stmt_function_id,
		_relation_insert_trigger_function_id,
		_relation_insert_trigger_id,

		_relation_drop_stmt_function_id,
		_relation_delete_trigger_function_id,
		_relation_delete_trigger_id,
		
		_relation_update_trigger_function_id,
		_relation_update_trigger_id
	);
end;
$$ language plpgsql;


-- use the generator function to propogate meta_meta.entity with the stuff that is expected to be there
select
    generate_meta_meta_entity('schema',      '{"name"}', '{"text"}'),
    generate_meta_meta_entity('type',        '{"schema_name", "name"}', '{"text","text"}'),
    generate_meta_meta_entity('cast',        '{"source_type_schema_name", "source_type_name", "target_type_schema_name", "target_type_name"}', '{"text","text","text","text"}'),
    generate_meta_meta_entity('operator',    '{"schema_name", "name", "left_arg_type_schema_name", "left_arg_type_name", "right_arg_type_schema_name", "right_arg_type_name"}','{"text","text","text","text","text","text"}'),
    generate_meta_meta_entity('sequence',    '{"schema_name", "name"}','{"text","text"}'),
    generate_meta_meta_entity('relation',    '{"schema_name", "name"}','{"text","text"}'),
    generate_meta_meta_entity('table',       '{"schema_name", "name"}','{"text","text"}'),
    generate_meta_meta_entity('view',        '{"schema_name", "name"}','{"text","text"}'),
    generate_meta_meta_entity('column',      '{"schema_name", "relation_name", "name"}','{"text","text","text"}'),
    generate_meta_meta_entity('foreign_key', '{"schema_name", "relation_name", "name"}','{"text","text","text"}'),
    generate_meta_meta_entity('row',         '{"schema_name", "relation_name", "pk_column_name", "pk_value"}','{"text","text","text","text"}'),
    generate_meta_meta_entity('field',       '{"schema_name", "relation_name", "pk_column_name", "pk_value", "column_name"}','{"text","text","text","text","text"}'),
    generate_meta_meta_entity('function',    '{"schema_name", "name", "parameters"}','{"text","text","text[]"}'),
    generate_meta_meta_entity('trigger',     '{"schema_name", "relation_name", "name"}','{"text","text","text"}'),
    generate_meta_meta_entity('role',        '{"name"}','{"text"}'),
    generate_meta_meta_entity('connection',  '{"pid", "connection_start"}','{"text","text"}'),
    generate_meta_meta_entity('constraint',  '{"schema_name", "relation_name", "name"}','{"text","text","text"}'),
    generate_meta_meta_entity('constraint_unique', '{"schema_name", "table_name", "name", "column_names"}','{"text","text","text","text"}'),
    -- generate_meta_meta_entity('constraint_check',-- '{"schema_name", "table_name", "name", "column_names"}'),
    generate_meta_meta_entity('extension',   '{"name"}','{"text"}'),
    generate_meta_meta_entity('foreign_data_wrapper', '{"name"}', '{"text"}'),
    generate_meta_meta_entity('foreign_server','{"name"}', '{"text"}'),
    generate_meta_meta_entity('foreign_table','{"schema_name", "name"}', '{"text","text"}'),
    generate_meta_meta_entity('foreign_column','{"schema_name", "name"}', '{"text","text"}')
;





-- exist functions for: function, trigger, op, type, relation, cast
create or replace function _exists(in f meta2.function_id, out ex boolean) as $$
    select (count(*) = 1) from meta2.function where id = f;
$$ language sql;

create or replace function _exists(in t meta2.trigger_id, out ex boolean) as $$
    select (count(*) = 1) from meta2.trigger where id = t;
$$ language sql;

create or replace function _exists(in o meta2.operator_id, out ex boolean) as $$
    select (count(*) = 1) from meta2.operator where id = o;
$$ language sql;

create or replace function _exists(in t meta2.type_id, out ex boolean) as $$
    select (count(*) = 1) from meta2.type where id = t;
$$ language sql;

create or replace function _exists(in r meta2.relation_id, out ex boolean) as $$
    select (count(*) = 1) from meta2.relation where id = r;
$$ language sql;

create or replace function _exists(in c meta2.cast_id, out ex boolean) as $$
    select (count(*) = 1) from meta2.cast where id = c;
$$ language sql;



create view checker as
select
    name,
    _exists(type_id) type_id,
    _exists(type_constructor_function_id) type_constructor_function_id,
    _exists(type_to_json_comparator_op_id) type_to_json_comparator_op_id,
    _exists(type_to_json_type_constructor_function_id) type_to_json_type_constructor_function_id,
    _exists(type_to_json_cast_id) type_to_json_cast_id,

    _exists(relation_id) relation_id,

    _exists(relation_create_stmt_function_id) relation_create_stmt_function_id,
    _exists(relation_insert_trigger_function_id) relation_insert_trigger_function_id,
    _exists(relation_insert_trigger_id) relation_insert_trigger_id,

    _exists(relation_drop_stmt_function_id) relation_drop_stmt_function_id,
    _exists(relation_delete_trigger_function_id) relation_delete_trigger_function_id,
    _exists(relation_delete_trigger_id) relation_delete_trigger_id,
    _exists(relation_update_trigger_function_id) relation_update_trigger_function_id,
    _exists(relation_update_trigger_id) relation_update_trigger_id
    from meta_meta.entity
;


create or replace view checker2 as
select
    r.name,

    (r1.id is not null) as type_id,
    (r2.id is not null) as type_constructor_function_id,
    (r3.id is not null) as type_to_json_comparator_op_id,
    (r4.id is not null) as type_to_json_type_constructor_function_id,
    (r5.id is not null) as type_to_json_cast_id,

    (r6.id is not null) as relation_id,

    (r7.id is not null) as relation_create_stmt_function_id,
    (r8.id is not null) as relation_insert_trigger_function_id,
    (r9.id is not null) as relation_insert_trigger_id,

    (r10.id is not null) as relation_drop_stmt_function_id,
    (r11.id is not null) as relation_delete_trigger_function_id,
    (r12.id is not null) as relation_delete_trigger_id,
    (r13.id is not null) as relation_update_trigger_function_id,
    (r14.id is not null) as relation_update_trigger_id

    from meta_meta.entity r

    left join meta.type r1 on type_id = r1.id
    left join meta.function r2 on type_constructor_function_id = r2.id
    left join meta.operator r3 on type_to_json_comparator_op_id = r3.id
    left join meta.function r4 on type_to_json_type_constructor_function_id = r4.id
    left join meta.cast r5 on type_to_json_cast_id = r5.id

    left join meta.relation r6 on relation_id = r6.id

    left join meta.function r7 on relation_create_stmt_function_id = r7.id
    left join meta.function r8 on relation_insert_trigger_function_id = r8.id
    left join meta.trigger r9 on relation_insert_trigger_id = r9.id

    left join meta.function r10 on relation_drop_stmt_function_id = r10.id
    left join meta.function r11 on relation_delete_trigger_function_id = r11.id
    left join meta.trigger r12 on relation_delete_trigger_id = r12.id
    left join meta.function r13 on relation_update_trigger_function_id = r13.id
    left join meta.trigger r14 on relation_update_trigger_id = r14.id
;


commit;
