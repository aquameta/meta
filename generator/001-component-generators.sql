/*
meta-meta-generator

generates the source code for meta!

type
type_constructor_function

-- jsonb stuff
type_to_jsonb_comparator_function
type_to_jsonb_comparator_op
type_to_jsonb_type_constructor_function
type_to_jsonb_cast

-- view
relation
relation_create_stmt_function
create_relation_drop_stmt_create_function

-- view triggers
relation_insert_trigger_function
relation_insert_trigger
relation_delete_trigger_function
relation_delete_trigger
relation_update_trigger_function
relation_update_trigger

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
    compare_to_jsonb text := 'select ';     -- "select (leftarg).schema_name = rightarg->>'schema_name' and (leftarg).name = rightarg->>'name'"
    constructor_args_from_jsonb text := ''; -- value->>'schema_name', value->>'name'

begin
    foreach arg_name in array constructor_arg_names loop
        attributes :=       attributes                              || format('%I %s', constructor_arg_names[i], constructor_arg_types[i]);
        constructor_args := constructor_args                        || format('%I %s', constructor_arg_names[i], constructor_arg_types[i]);
        arg_names :=        arg_names                               || format('%I', constructor_arg_names[i]);
		-- constructor args from json
		if constructor_arg_types[i] = 'text[]' then
			constructor_args_from_jsonb :=  constructor_args_from_jsonb || format('(select array_agg(value) from jsonb_array_elements_text(value->%L))', constructor_arg_names[i]);
		else
			constructor_args_from_jsonb :=  constructor_args_from_jsonb || format('value->>%L', constructor_arg_names[i]);
		end if;
        -- compare to jsonb
        if constructor_arg_types[i] = 'text[]' then
            compare_to_jsonb :=  compare_to_jsonb                   || format('to_jsonb((leftarg).%I) = rightarg->%L', constructor_arg_names[i], constructor_arg_names[i]);
        else
            compare_to_jsonb :=  compare_to_jsonb                   || format('(leftarg).%I = rightarg->>%L', constructor_arg_names[i], constructor_arg_names[i]);
        end if;

        -- comma?
        if i < array_length(constructor_arg_names,1) then
            attributes := attributes || ',';
            constructor_args := constructor_args || ',';
            arg_names := arg_names || ',';
            compare_to_jsonb := compare_to_jsonb || ' and ';
            constructor_args_from_jsonb := constructor_args_from_jsonb || ', ';
        end if;
        i := i+1;
        -- raise notice '    arg_names: %', arg_names;
    end loop;

    -- raise notice 'results:::::';
    -- raise notice 'attributes: %', attributes;
    -- raise notice 'constructor_args: %', constructor_args;
    -- raise notice 'compare_to_jsonb: %', compare_to_jsonb;
    result := format('constructor_args=>"%s",attributes=>"%s",arg_names=>"%s",compare_to_jsonb=>"%s",constructor_args_from_jsonb=>"%s"',
        constructor_args,
        attributes,
        arg_names,
        compare_to_jsonb,
        constructor_args_from_jsonb
    )::public.hstore;
    -- raise notice 'result: %', result;
    return result;
end;
$$ language plpgsql;





/*


 create type


 */


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
    select row(schema_name, name)::meta.relation_id
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



/*


 to jsonb


 */




/**********************************************************************************
create function meta.eq(
    leftarg meta.relation_id,
    rightarg jsonb
) returns boolean as $$
    select (leftarg).schema_id = rightarg->'schema_id' and
           (leftarg).name = rightarg->>'name';
$$ language sql;
**********************************************************************************/

create or replace function stmt_create_type_to_jsonb_comparator_function (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare
    stmt text := '';
    snippets public.hstore;
    i integer := 1;
begin
    snippets := stmt_snippets(name, constructor_arg_names, constructor_arg_types);
    stmt := format('create function meta2.eq(leftarg meta2.%I, rightarg jsonb) returns boolean as $_$%s$_$ language sql;',
        name || '_id',
        snippets['compare_to_jsonb']
    );
    return stmt;
end;
$$ language plpgsql;


/**********************************************************************************
create operator = (
    leftarg = meta.foreign_key_id,
    rightarg = jsonb,
    procedure = meta.eq
);
**********************************************************************************/

create or replace function stmt_create_type_to_jsonb_comparator_op (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare
    stmt text := '';
    snippets public.hstore;
    i integer := 1;
begin
    snippets := stmt_snippets(name, constructor_arg_names, constructor_arg_types);
    stmt := format('create operator = (leftarg = meta2.%I, rightarg = jsonb, procedure = meta2.eq);',
        name || '_id'
    );
    return stmt;
end;
$$ language plpgsql;


/**********************************************************************************
create function meta.relation_id(value jsonb) returns meta.relation_id as $$
    select row(row(value->'schema_id'->>'name'), value->>'name')::meta.relation_id
$$ immutable language sql;
**********************************************************************************/

/*
want:
create function meta2.function_id(value jsonb) returns meta2.function_id as $_$
    select meta2.function_id(
        value->>'schema_name',
        value->>'name',
        (select array_agg(value) from jsonb_array_elements_text(value->'parameters'))
    )
$_$ immutable language sql;
*/



create or replace function stmt_create_type_to_jsonb_type_constructor_function (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare 
    stmt text := '';
    snippets public.hstore;
    i integer := 1;
begin
    snippets := stmt_snippets(name, constructor_arg_names, constructor_arg_types);
    stmt := format('create function meta2.%I(value jsonb) returns meta2.%I as $_$select meta2.%I(%s) $_$ immutable language sql;',
        name || '_id',
        name || '_id',
        name || '_id',
        snippets['constructor_args_from_jsonb']
    );
    return stmt;
end;
$$ language plpgsql;


/**********************************************************************************
create cast (jsonb as meta.foreign_key_id)
with function meta.foreign_key_id(jsonb)
as assignment;
**********************************************************************************/

create or replace function stmt_create_type_to_jsonb_cast (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare
    stmt text := '';
    snippets public.hstore;
    i integer := 1;
begin
    snippets := stmt_snippets(name, constructor_arg_names, constructor_arg_types);
    stmt := format('create cast (jsonb as meta2.%I) with function meta2.%I(jsonb) as assignment;',
        name || '_id',
        name || '_id'
    );
    return stmt;
end;
$$ language plpgsql;


/**********************************************************************************
create cast (meta.foreign_key_id as jsonb)
with function meta.foreign_key_id(jsonb)
as assignment;
**********************************************************************************/

create or replace function stmt_create_jsonb_to_type_cast (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare
    stmt text := '';
    snippets public.hstore;
    i integer := 1;
begin
    snippets := stmt_snippets(name, constructor_arg_names, constructor_arg_types);
    stmt := format('create cast (meta2.%I as jsonb) with function meta2.%I(jsonb) as assignment;',
        name || '_id',
        name || '_id'
    );
    return stmt;
end;
$$ language plpgsql;


commit;
