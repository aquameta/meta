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


/*
 * generates a bunch of plpgsql snippets that are recurring patterns in the the code generators below
 */
create or replace function stmt_snippets(name text, constructor_arg_names text[], constructor_arg_types text[]) returns public.hstore as $$
declare 
    arg_name text;
    result public.hstore;
    i integer := 1;

    -- snippets
    constructor_args text := ''; -- "schema_name text, relation_name text, name text"
    attributes text := ''; -- "schema_name text, relation_name text, name text"
    arg_names text := ''; -- "schema_name, relation_name, name"
begin
	foreach arg_name in array constructor_arg_names loop
		attributes :=       attributes || format('%I %s', constructor_arg_names[i], constructor_arg_types[i]);
		constructor_args := constructor_args || format('%I %s', constructor_arg_names[i], constructor_arg_types[i]);
		arg_names :=        arg_names || format('%I', constructor_arg_names[i]);
        -- comma?
        if i < array_length(constructor_arg_names,1) then
            attributes := attributes || ',';
            constructor_args := constructor_args || ',';
            arg_names := arg_names || ',';
        end if;
        i := i+1;
        -- raise notice '    attributes: %', attributes;
        -- raise notice '    constructor_args: %', constructor_args;
        raise notice '    arg_names: %', arg_names;
	end loop;

    -- raise notice 'results:::::';
    -- raise notice 'attributes: %', attributes;
    -- raise notice 'constructor_args: %', constructor_args;
    result := format('constructor_args=>"%s",attributes=>"%s",arg_names=>"%s"',
        constructor_args,
        attributes,
        arg_names
    )::public.hstore;
    -- raise notice 'result: %', result;
    return result;
end;
$$ language plpgsql;






-- CREATE TYPE stmt
/*
generates this:
create type meta.schema_id as (
    name text
);
*/

create or replace function stmt_create_type (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare 
    stmt text := '';
    snippets public.hstore;
begin
    snippets := stmt_snippets(name, constructor_arg_names, constructor_arg_types);
	stmt := format('create type meta2.%I as (%s);', name || '_id', snippets['attributes']);
    return stmt;
end;
$$ language plpgsql;


-- CREATE TYPE CONSTRUCTOR FUNCTION
/*
generates this:
create function meta.schema_id(name text) returns meta.schema_id as $$
    select row(name)::meta.schema_id
$$ language sql immutable;
*/

create or replace function stmt_create_type_constructor_function (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare 
    stmt text := '';
    snippets public.hstore;
    i integer := 1;
begin
    snippets := stmt_snippets(name, constructor_arg_names, constructor_arg_types);
	stmt := format('create function meta2.%I(%s) returns meta2.%I as $_$ select row(%s)::meta2.%I $_$ language sql immutable;',
        name || '_id',
        snippets['attributes'],
        name || '_id',
        snippets['arg_names'],
        name || '_id'
    );
    return stmt;
end;$$ language plpgsql;


/*
create or replace function stmt_create_type_to_json_comparator_op (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare stmt text;
begin
end;
$$ language plpgsql;


create or replace function stmt_create_type_to_json_type_constructor_function (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare stmt text;
begin
end;
$$ language plpgsql;


create or replace function stmt_create_type_to_json_cast (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare stmt text;
begin
end;
$$ language plpgsql;


create or replace function stmt_create_relation (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare stmt text;
begin
end;
$$ language plpgsql;


create or replace function stmt_create_relation_create_stmt_function (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare stmt text;
begin
end;
$$ language plpgsql;


create or replace function stmt_create_relation_insert_trigger_function (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare stmt text;
begin
end;
$$ language plpgsql;


create or replace function stmt_create_relation_insert_trigger (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare stmt text;
begin
end;
$$ language plpgsql;


create or replace function stmt_create_relation_drop_stmt_function (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare stmt text;
begin
end;
$$ language plpgsql;


create or replace function stmt_create_relation_delete_trigger_function (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare stmt text;
begin
end;
$$ language plpgsql;


create or replace function stmt_create_relation_delete_trigger (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare stmt text;
begin
end;
$$ language plpgsql;


create or replace function stmt_create_relation_update_trigger_function (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare stmt text;
begin
end;
$$ language plpgsql;


create or replace function stmt_create_relation_update_trigger (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare stmt text;
begin
end;
$$ language plpgsql;

*/

commit;
