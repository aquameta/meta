/*
meta-meta-generator

generates the source code for meta!

type_id
type_constructor_function_id
type_to_json_comparator_op_id
type_to_json_type_constructor_function_id
type_to_json_cast_id
relation_id
relation_create_stmt_function_id
relation_insert_trigger_function_id
relation_insert_trigger_id
relation_drop_stmt_function_id
relation_delete_trigger_function_id
relation_delete_trigger_id
relation_update_trigger_function_id
relation_update_trigger_id

:'<,'>s/^/create function stmt_create_/g
:'<,'>s/$/ (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$^Mdeclare stmt text;^Mbegin^Mend;^M$$ language plpgsql;^M^M/g
*/

begin;

set search_path=meta_meta;

-- create type stmt
create or replace function stmt_create_type (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare 
    stmt text := '';
    attributes text := '';
    arg_name text;
    i integer := 1;
begin
	foreach arg_name in array constructor_arg_names loop
        raise notice 'names: %', constructor_arg_names;
        raise notice 'types: %', constructor_arg_types;
		attributes := attributes || format('%I %I', constructor_arg_names[i], constructor_arg_types[i]);
        if i < array_length(constructor_arg_names,1) then
            attributes := attributes || ',';
        end if;
        i := i+1;
	end loop;

	stmt := format('create type meta2.%I as (%s);', name || '_id', attributes);
    return stmt;
end;
$$ language plpgsql;


/*

create function stmt_create_type_constructor_function (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare stmt text;
begin
end;
$$ language plpgsql;


create function stmt_create_type_to_json_comparator_op (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare stmt text;
begin
end;
$$ language plpgsql;


create function stmt_create_type_to_json_type_constructor_function (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare stmt text;
begin
end;
$$ language plpgsql;


create function stmt_create_type_to_json_cast (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare stmt text;
begin
end;
$$ language plpgsql;


create function stmt_create_relation (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare stmt text;
begin
end;
$$ language plpgsql;


create function stmt_create_relation_create_stmt_function (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare stmt text;
begin
end;
$$ language plpgsql;


create function stmt_create_relation_insert_trigger_function (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare stmt text;
begin
end;
$$ language plpgsql;


create function stmt_create_relation_insert_trigger (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare stmt text;
begin
end;
$$ language plpgsql;


create function stmt_create_relation_drop_stmt_function (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare stmt text;
begin
end;
$$ language plpgsql;


create function stmt_create_relation_delete_trigger_function (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare stmt text;
begin
end;
$$ language plpgsql;


create function stmt_create_relation_delete_trigger (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare stmt text;
begin
end;
$$ language plpgsql;


create function stmt_create_relation_update_trigger_function (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare stmt text;
begin
end;
$$ language plpgsql;


create function stmt_create_relation_update_trigger (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare stmt text;
begin
end;
$$ language plpgsql;

*/

commit;
