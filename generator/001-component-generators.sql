/*
meta-meta-generator

generates the source code for meta!

type_id
type_constructor_function_id

-- json stuff
type_to_json_comparator_function
type_to_json_comparator_op_id
type_to_json_type_constructor_function_id
type_to_json_cast_id

-- view
relation_id
relation_create_stmt_function_id
create_relation_drop_stmt_create_function

-- view triggers
relation_insert_trigger_function_id
relation_insert_trigger_id
relation_delete_trigger_function_id
relation_delete_trigger_id
relation_update_trigger_function_id
relation_update_trigger_id

:'<,'>s/^/create function stmt_create_/g
:'<,'>s/$/ (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$^Mdeclare stmt text;^Mbegin^Mend;^M$$ language plpgsql;^M^M/g

select stmt_create_type(name, constructor_arg_names, constructor_arg_types) from meta_meta.entity;
select stmt_create_type_constructor_function(name, constructor_arg_names, constructor_arg_types) from meta_meta.entity;

select stmt_create_type_to_json_comparator_function(name, constructor_arg_names, constructor_arg_types) from meta_meta.entity;
select stmt_create_type_to_json_comparator_op(name, constructor_arg_names, constructor_arg_types) from meta_meta.entity;
select stmt_create_type_to_json_type_constructor_function(name, constructor_arg_names, constructor_arg_types) from meta_meta.entity;
select stmt_create_type_to_json_cast(name, constructor_arg_names, constructor_arg_types) from meta_meta.entity;

select stmt_create_relation(name, constructor_arg_names, constructor_arg_types) from meta_meta.entity;
select stmt_create_relation_create_stmt_create_function(name, constructor_arg_names, constructor_arg_types) from meta_meta.entity;
select stmt_create_relation_drop_stmt_create_function(name, constructor_arg_names, constructor_arg_types) from meta_meta.entity;

select stmt_create_relation_insert_trigger_function(name, constructor_arg_names, constructor_arg_types) from meta_meta.entity;
select stmt_create_relation_insert_trigger(name, constructor_arg_names, constructor_arg_types) from meta_meta.entity;
select stmt_create_relation_delete_trigger_function(name, constructor_arg_names, constructor_arg_types) from meta_meta.entity;
select stmt_create_relation_delete_trigger(name, constructor_arg_names, constructor_arg_types) from meta_meta.entity;
select stmt_create_relation_update_trigger_function(name, constructor_arg_names, constructor_arg_types) from meta_meta.entity;
select stmt_create_relation_update_trigger(name, constructor_arg_names, constructor_arg_types) from meta_meta.entity;

:'<,'>s/^/select stmt_create_/g
:'<,'>s/_id$/(name, constructor_arg_names, constructor_arg_types) from meta_meta.entity;/g

*/
begin;

-- these functions are created in meta_meta (so they can be discarded)
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
    constructor_args text := '';           -- "schema_name text, relation_name text, name text"
    attributes text := '';                 -- "schema_name text, relation_name text, name text"
    arg_names text := '';                  -- "schema_name, relation_name, name"
    compare_to_json text := 'select ';     -- "select (leftarg).schema_name = rightarg->>'schema_name' and (leftarg).name = rightarg->>'name'"
    constructor_args_from_json text := ''; -- value->>'schema_name', value->>'name'

begin
    foreach arg_name in array constructor_arg_names loop
        attributes :=       attributes                            || format('%I %s', constructor_arg_names[i], constructor_arg_types[i]);
        constructor_args := constructor_args                      || format('%I %s', constructor_arg_names[i], constructor_arg_types[i]);
        arg_names :=        arg_names                             || format('%I', constructor_arg_names[i]);
        compare_to_json :=  compare_to_json                       || format('(leftarg).%I = rightarg->>%L', constructor_arg_names[i], constructor_arg_names[i]);
        constructor_args_from_json :=  constructor_args_from_json || format('value->>%L', constructor_arg_names[i]);

        -- comma?
        if i < array_length(constructor_arg_names,1) then
            attributes := attributes || ',';
            constructor_args := constructor_args || ',';
            arg_names := arg_names || ',';
            compare_to_json := compare_to_json || ' and ';
            constructor_args_from_json := constructor_args_from_json || ', ';
        end if;
        i := i+1;
        -- raise notice '    arg_names: %', arg_names;
    end loop;

    -- raise notice 'results:::::';
    -- raise notice 'attributes: %', attributes;
    -- raise notice 'constructor_args: %', constructor_args;
    -- raise notice 'compare_to_json: %', compare_to_json;
    result := format('constructor_args=>"%s",attributes=>"%s",arg_names=>"%s",compare_to_json=>"%s",constructor_args_from_json=>"%s"',
        constructor_args,
        attributes,
        arg_names,
        compare_to_json,
        constructor_args_from_json
    )::public.hstore;
    -- raise notice 'result: %', result;
    return result;
end;
$$ language plpgsql;


/**********************************************************************************
create type meta.relation_id as (
    schema_id meta.schema_id,
    name text
);
**********************************************************************************/

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


/**********************************************************************************
create function meta.relation_id(schema_name text, name text) returns meta.relation_id as $$
    select row(row(schema_name), name)::meta.relation_id
$$ language sql immutable;
**********************************************************************************/

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
end;
$$ language plpgsql;


/**********************************************************************************
create function meta.eq(
    leftarg meta.relation_id,
    rightarg json
) returns boolean as $$
    select (leftarg).schema_id = rightarg->'schema_id' and
           (leftarg).name = rightarg->>'name';
$$ language sql;
**********************************************************************************/

create or replace function stmt_create_type_to_json_comparator_function (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare
    stmt text := '';
    snippets public.hstore;
    i integer := 1;
begin
    snippets := stmt_snippets(name, constructor_arg_names, constructor_arg_types);
    stmt := format('create function meta2.eq(leftarg meta2.%I, rightarg json) returns boolean as $_$%s$_$ language sql;',
                   name || '_id',
                   snippets['compare_to_json']
        );
    return stmt;
end;
$$ language plpgsql;


/**********************************************************************************
create operator = (
    leftarg = meta.foreign_key_id,
    rightarg = json,
    procedure = meta.eq
);$$ language sql;
**********************************************************************************/

create or replace function stmt_create_type_to_json_comparator_op (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare
    stmt text := '';
    snippets public.hstore;
    i integer := 1;
begin
    snippets := stmt_snippets(name, constructor_arg_names, constructor_arg_types);
    stmt := format('create operator = (leftarg meta2.%I, rightarg json, procedure = meta.eq) language sql;',
                   name || '_id'
        );
    return stmt;
end;
$$ language plpgsql;


/**********************************************************************************
create function meta.relation_id(value json) returns meta.relation_id as $$
    select row(row(value->'schema_id'->>'name'), value->>'name')::meta.relation_id
$$ immutable language sql;
**********************************************************************************/

create or replace function stmt_create_type_to_json_type_constructor_function (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare 
    stmt text := '';
    snippets public.hstore;
    i integer := 1;
begin
    snippets := stmt_snippets(name, constructor_arg_names, constructor_arg_types);
    stmt := format('create function meta2.%I(value json) returns meta.%I as $_$select meta.%I(%s) $_$ immutable language sql;',
        name || '_id',
        name || '_id',
        name || '_id',
        snippets['constructor_args_from_json']
    );
    return stmt;
end;
$$ language plpgsql;


/**********************************************************************************
create cast (json as meta.foreign_key_id)
with function meta.foreign_key_id(json)
as assignment;
**********************************************************************************/

create or replace function stmt_create_type_to_json_cast (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare
    stmt text := '';
    snippets public.hstore;
    i integer := 1;
begin
    snippets := stmt_snippets(name, constructor_arg_names, constructor_arg_types);
    stmt := format('create cast (json as meta.%I) with function meta.%I(json) as assignment;',
        name || '_id',
        name || '_id'
    );
    return stmt;
end;
$$ language plpgsql;



/*
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
