begin;
set search_path=meta_meta;

CREATE FUNCTION exec(text) RETURNS text AS $$ BEGIN EXECUTE $1; RETURN $1; END $$ LANGUAGE plpgsql;
select
    exec(stmt_create_type(name, constructor_arg_names, constructor_arg_types)) as stmt_create_type,
    exec(stmt_create_type_constructor_function(name, constructor_arg_names, constructor_arg_types)) as stmt_create_type_constructor_function,

    exec(stmt_create_type_to_json_comparator_function(name, constructor_arg_names, constructor_arg_types)) as stmt_create_type_to_json_comparator_function,
    exec(stmt_create_type_to_json_comparator_op(name, constructor_arg_names, constructor_arg_types)) as stmt_create_type_to_json_comparator_op,
    exec(stmt_create_type_to_json_type_constructor_function(name, constructor_arg_names, constructor_arg_types)) as stmt_create_type_to_json_type_constructor_function,
    exec(stmt_create_type_to_json_cast(name, constructor_arg_names, constructor_arg_types)) as stmt_create_type_to_json_cast
/*
    exec(stmt_create_json_to_type_comparator_function(name, constructor_arg_names, constructor_arg_types)) as stmt_create_json_to_type_comparator_function,
    exec(stmt_create_json_to_type_comparator_op(name, constructor_arg_names, constructor_arg_types)) as stmt_create_json_to_type_comparator_op,
    exec(stmt_create_json_to_type_type_constructor_function(name, constructor_arg_names, constructor_arg_types)) as stmt_create_json_to_type_type_constructor_function,
    exec(stmt_create_json_to_type_cast(name, constructor_arg_names, constructor_arg_types)) as stmt_create_json_to_type_cast
*/

from meta_meta.pg_entity
where name in ('relation');
commit;
