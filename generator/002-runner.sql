begin;
set search_path=meta_meta;

CREATE FUNCTION exec(text) RETURNS text AS $$ BEGIN EXECUTE $1; RETURN $1; END $$ LANGUAGE plpgsql;


select exec(stmt_create_type(name, constructor_arg_names, constructor_arg_types)) from meta_meta.pg_entity;
select exec(stmt_create_type_constructor_function(name, constructor_arg_names, constructor_arg_types)) from meta_meta.pg_entity;
select exec(stmt_create_type_to_json_comparator_function(name, constructor_arg_names, constructor_arg_types)) from meta_meta.pg_entity;
-- select exec(stmt_create_type_to_json_comparator_op(name, constructor_arg_names, constructor_arg_types)) from meta_meta.pg_entity;
-- select exec(stmt_create_type_to_json_type_constructor_function(name, constructor_arg_names, constructor_arg_types)) from meta_meta.pg_entity;
-- select exec(stmt_create_type_to_json_cast(name, constructor_arg_names, constructor_arg_types)) from meta_meta.pg_entity;

commit;
