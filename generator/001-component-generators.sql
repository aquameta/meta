/*
meta-meta-generator

generates the source code for meta!

-- the type and it's constructor
type
type_constructor_function

-- meta_id text identifier for any meta.*_id
meta_id_constructor

-- jsonb stuff
type_to_jsonb_comparator_function
type_to_jsonb_comparator_op
type_to_jsonb_constructor_function
type_to_jsonb_cast

-- view
relation
relation_create_stmt_function
relation_drop_stmt_create_function

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
set search_path=meta_meta,public;

/******************************************************************************
component_statement()

For the supplied entity (e.g. `relation`, `column` etc., an entry in the
pg_entity table), and the supplied component (e.g. `type`, `type_constructor`,
`cast_to_json` etc.), generate the statement that creates said component for
said entity.

Usage:  Use component_statement() with exec() in a SQL query that queries
pg_entity and pg_component.

To generate all components:

```
select e.name as entity_name, c.name as component_name, exec(component_statement(e.name, c.name))
from pg_entity e, pg_entity_component c
order by e.name, c.position;
```
******************************************************************************/

create or replace function component_statement(entity text, component text) returns text as $$
declare
    stmt text;
begin
    -- raise notice '------------- component_statement(%,%)', entity, component;
    execute format('
    select %I(name, constructor_arg_names, constructor_arg_types)
    from meta_meta.pg_entity e
    where name=%L',
        'stmt_create_' || component,
        entity
    ) into stmt;
    return stmt;
end
$$ language plpgsql;


/*
 * generates a bunch of plpgsql snippets that are recurring patterns in the the code generators below
 */
create or replace function stmt_snippets(name text, constructor_arg_names text[], constructor_arg_types text[]) returns public.hstore as $$
declare
    arg_name text;
    result public.hstore := '{a=>a}';
    i integer := 1;

    -- snippets
    constructor_args text := '';            -- "schema_name text, relation_name text, name text"
    attributes text := '';                  -- "schema_name text, relation_name text, name text"
    arg_names text := '';                   -- "schema_name, relation_name, name"
    compare_to_jsonb text := 'select ';     -- "select (leftarg).schema_name = rightarg->>'schema_name' and (leftarg).name = rightarg->>'name'"
    compare_jsonb_to_type text := 'select ';-- "select leftarg->>'schema_name' = (rightarg).schema_name and leftarg->>'name' = rightarg.name"
    constructor_args_from_jsonb text := ''; -- value->>'schema_name', value->>'name'
    compare_to_json text := 'select ';      -- "select (leftarg).schema_name = rightarg->>'schema_name' and (leftarg).name = rightarg->>'name'"
    compare_json_to_type text := 'select '; -- "select leftarg->>'schema_name' = (rightarg).schema_name and leftarg->>'name' = rightarg.name"
    constructor_args_from_json text := '';  -- value->>'schema_name', value->>'name'
    meta_id_path text := name || '/';

begin
    foreach arg_name in array constructor_arg_names loop
        attributes :=       attributes                                  || format('%I %s', constructor_arg_names[i], constructor_arg_types[i]);
        constructor_args := constructor_args                            || format('%I %s', constructor_arg_names[i], constructor_arg_types[i]);
        arg_names :=        arg_names                                   || format('%I', constructor_arg_names[i]);
        meta_id_path :=     meta_id_path                                || format('%s', constructor_arg_names[i]);

		-- constructor args from jsonb
		if constructor_arg_types[i] = 'text[]' then
			constructor_args_from_jsonb :=  constructor_args_from_jsonb ||
                format('(select array_agg(value) from jsonb_array_elements_text(value->%L))', constructor_arg_names[i]);
		else
			constructor_args_from_jsonb :=  constructor_args_from_jsonb ||
                -- format('value->>%L', constructor_arg_names[i]);
                format('(value->>%L)::%I', constructor_arg_names[i], constructor_arg_types[i]);
		end if;

        -- compare to jsonb
        if constructor_arg_types[i] = 'text[]' then
            compare_to_jsonb :=  compare_to_jsonb
                || format('to_jsonb((leftarg).%I) = rightarg->%L', constructor_arg_names[i], constructor_arg_names[i]);
        else
            compare_to_jsonb :=  compare_to_jsonb ||
                format('((leftarg).%I)::text = (rightarg)->>%L', constructor_arg_names[i], constructor_arg_names[i]);
        end if;

        -- compare jsonb to type
        if constructor_arg_types[i] = 'text[]' then
            compare_jsonb_to_type :=  compare_jsonb_to_type
                || format('leftarg->%L = to_jsonb((rightarg).%I)', constructor_arg_names[i], constructor_arg_names[i]);
        else
            compare_jsonb_to_type :=  compare_jsonb_to_type ||
                format('(leftarg)->>%L = ((rightarg).%I)::text', constructor_arg_names[i], constructor_arg_names[i]);
        end if;

		-- constructor args from json
		if constructor_arg_types[i] = 'text[]' then
			constructor_args_from_json :=  constructor_args_from_json ||
                format('(select array_agg(value) from json_array_elements_text(value->%L))', constructor_arg_names[i]);
		else
			constructor_args_from_json :=  constructor_args_from_json ||
                -- format('value->>%L', constructor_arg_names[i]);
                format('(value->>%L)::%I', constructor_arg_names[i], constructor_arg_types[i]);
		end if;

        -- compare to json
        if constructor_arg_types[i] = 'text[]' then
            compare_to_json :=  compare_to_json
                || format('to_json((leftarg).%I)::text = (rightarg->%L)::text', constructor_arg_names[i], constructor_arg_names[i]);
        else
            compare_to_json :=  compare_to_json ||
                format('((leftarg).%I)::text = ((rightarg)->>%L)::text', constructor_arg_names[i], constructor_arg_names[i]);
        end if;

        -- compare json to type
        if constructor_arg_types[i] = 'text[]' then
            compare_json_to_type :=  compare_json_to_type
                || format('(leftarg->%L)::text = (to_json((rightarg).%I))::text', constructor_arg_names[i], constructor_arg_names[i]);
        else
            compare_json_to_type :=  compare_json_to_type ||
                format('(leftarg)->>%L = ((rightarg).%I)::text', constructor_arg_names[i], constructor_arg_names[i]);
        end if;

        -- comma?
        if i < array_length(constructor_arg_names,1) then
            attributes                     := attributes || ',';
            constructor_args               := constructor_args || ',';
            arg_names                      := arg_names || ',';
            compare_to_jsonb               := compare_to_jsonb || ' and ';
            compare_jsonb_to_type          := compare_jsonb_to_type || ' and ';
            constructor_args_from_jsonb    := constructor_args_from_jsonb || ', ';
            compare_to_json                := compare_to_json || ' and ';
            compare_json_to_type           := compare_json_to_type || ' and ';
            constructor_args_from_json     := constructor_args_from_json || ', ';
            meta_id_path                   := meta_id_path || '/';
        end if;
        i := i+1;
        -- raise notice '    arg_names: %', arg_names;
    end loop;

    /*
    raise notice 'results:::::';
    raise notice 'attributes: %', attributes;
    raise notice 'constructor_args: %', constructor_args;
    raise notice 'compare_to_jsonb: %', compare_to_jsonb;
    raise notice 'meta_id_path: %', meta_id_path;
    */


    /* why is this necessary? */
    set local search_path=meta_meta,public;

    result := result || hstore('constructor_args', constructor_args);
    result := result || hstore('attributes', attributes);
    result := result || hstore('arg_names', arg_names);
    result := result || hstore('compare_to_jsonb', compare_to_jsonb);
    result := result || hstore('compare_jsonb_to_type', compare_jsonb_to_type);
    result := result || hstore('constructor_args_from_jsonb', constructor_args_from_jsonb);
    result := result || hstore('compare_to_json', compare_to_json);
    result := result || hstore('compare_json_to_type', compare_json_to_type);
    result := result || hstore('constructor_args_from_json', constructor_args_from_json);
    result := result || hstore('meta_id_path', meta_id_path);
    /*
    result := format('constructor_args=>"%s",attributes=>"%s",arg_names=>"%s",compare_to_jsonb=>"%s",constructor_args_from_jsonb=>"%s",meta_id_path=>"%s"',
        constructor_args,
        attributes,
        arg_names,
        compare_to_jsonb,
        constructor_args_from_jsonb,
        meta_id_path
    );
    */

    -- raise notice 'SNIPPETS result: %', result;
    return result;
end;
$$ language plpgsql;


/**********************************************************************************
create type meta.relation_id as (schema_name text,name text);
**********************************************************************************/
create or replace function stmt_create_type (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare
    stmt text := '';
    snippets public.hstore;
begin
    snippets := stmt_snippets(name, constructor_arg_names, constructor_arg_types);
    -- raise notice 'stmt_create_type gets snippets %', snippets;
    stmt := format('create type meta.%I as (%s);', name || '_id', snippets['attributes']);
    -- raise notice 'stmt_create_type produceds stmt %', stmt;
    return stmt;
end;
$$ language plpgsql;


/**********************************************************************************
Constructor

PostgreSQL composite types are instantiated via `row('public','my_table',
'id')::column_id`, but this isn't very pretty, so each meta-id also has a
constructor function whose arguments are the same as the arguments you would
pass to row().

Instead of:

select row('public','my_table','my_column')::meta.column_id;

This lets you do:

select meta.column_id('public','my_table','my_column');


Function output (for relation entity):
```
create or replace function meta.meta_id(relation_id meta.relation_id) returns meta.meta_id as $_$
    select meta.meta_id('relation/' || quote_ident(relation_id.schema_name) || '/' || quote_ident(relation_id.name));
$_$ immutable language sql;
```
**********************************************************************************/
create or replace function stmt_create_meta_id_constructor (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare
    stmt text := '';
    snippets public.hstore;
begin
    snippets := stmt_snippets(name, constructor_arg_names, constructor_arg_types);
    stmt := format('create function meta.meta_id(%I meta.%I) returns meta.meta_id as $_$ select meta.meta_id(%L); $_$ immutable language sql;', name || '_id', name || '_id', name, snippets['meta_id_path']);
    return stmt;
end;
$$ language plpgsql;


/**********************************************************************************
create function meta.relation_id(schema_name text,name text) returns meta.relation_id as $_$
    select row(schema_name,name)::meta.relation_id
$_$ immutable language sql;
**********************************************************************************/
create or replace function stmt_create_type_constructor_function (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare
    stmt text := '';
    snippets public.hstore;
    i integer := 1;
begin
    snippets := stmt_snippets(name, constructor_arg_names, constructor_arg_types);
    stmt := format('create function meta.%I(%s) returns meta.%I as $_$ select row(%s)::meta.%I $_$ immutable language sql;',
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
 *
 * to jsonb
 *
 */

/**********************************************************************************
create function meta.relation_id(value jsonb) returns meta.relation_id as $_$
select meta.relation_id(value->>'schema_name', value->>'name')
$_$ immutable language sql;
**********************************************************************************/
create or replace function stmt_create_type_to_jsonb_constructor_function (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare
    stmt text := '';
    snippets public.hstore;
begin
    snippets := stmt_snippets(name, constructor_arg_names, constructor_arg_types);
    stmt := format('create function meta.%I(value jsonb) returns meta.%I as $_$select meta.%I(%s) $_$ immutable language sql;',
        name || '_id',
        name || '_id',
        name || '_id',
        snippets['constructor_args_from_jsonb']
    );
    return stmt;
end;
$$ language plpgsql;


/**********************************************************************************
create function meta.eq(leftarg meta.relation_id, rightarg jsonb) returns boolean as
    $_$select (leftarg).schema_name = rightarg->>'schema_name' and (leftarg).name = rightarg->>'name'
$_$ immutable language sql;
**********************************************************************************/
create or replace function stmt_create_type_to_jsonb_comparator_function (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare
    stmt text := '';
    snippets public.hstore;
begin
    snippets := stmt_snippets(name, constructor_arg_names, constructor_arg_types);
    stmt := format('create function meta.eq(leftarg meta.%I, rightarg jsonb) returns boolean as $_$%s$_$ immutable language sql;',
        name || '_id',
        snippets['compare_to_jsonb']
    );
    return stmt;
end;
$$ language plpgsql;


/**********************************************************************************
create operator pg_catalog.= (leftarg = meta.relation_id, rightarg = jsonb, procedure = meta.eq);
**********************************************************************************/
create or replace function stmt_create_type_to_jsonb_comparator_op (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare
    stmt text := '';
begin
    stmt := format('create operator meta.= (leftarg = meta.%I, rightarg = jsonb, procedure = meta.eq);',
        name || '_id'
    );
    return stmt;
end;
$$ language plpgsql;


/**********************************************************************************
create cast (jsonb as meta.relation_id) with function meta.relation_id(jsonb) as assignment;
**********************************************************************************/
create or replace function stmt_create_type_to_jsonb_cast (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare
    stmt text := '';
begin
    stmt := format('create cast (jsonb as meta.%I) with function meta.%I(jsonb) as assignment;',
        name || '_id',
        name || '_id'
    );
    return stmt;
end;
$$ language plpgsql;



/*
 * from jsonb
 */

/**********************************************************************************
create function meta.foreign_data_wrapper_id_to_jsonb(value meta.foreign_data_wrapper_id) returns jsonb as $_$
select row(value.name)::meta.foreign_data_wrapper_id
$_$ immutable language sql;
**********************************************************************************/
create or replace function stmt_create_jsonb_to_type_constructor_function (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare
    stmt text := '';
    snippets public.hstore;
begin
    snippets := stmt_snippets(name, constructor_arg_names, constructor_arg_types);
    stmt := format('create function meta.%I(value meta.%I) returns jsonb as $_$select to_jsonb(value)$_$ immutable language sql;',
        name || '_id_to_jsonb',
        name || '_id'
    );
    return stmt;
end;
$$ language plpgsql;


/**********************************************************************************
create function meta.eq(leftarg jsonb, rightarg meta.foreign_data_wrapper_id) returns boolean as $_$
select (leftarg)->>'name' = ((rightarg).name)::text
$_$ immutable language sql;
**********************************************************************************/
create or replace function stmt_create_jsonb_to_type_comparator_function (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare
    stmt text := '';
    snippets public.hstore;
begin
    snippets := stmt_snippets(name, constructor_arg_names, constructor_arg_types);
    stmt := format('create function meta.eq(leftarg jsonb, rightarg meta.%I) returns boolean as $_$%s$_$ immutable language sql;',
        name || '_id',
        snippets['compare_jsonb_to_type']
    );
    return stmt;
end;
$$ language plpgsql;


/**********************************************************************************
create operator pg_catalog.= (leftarg = jsonb, rightarg = meta.relation_id, procedure = meta.eq);
**********************************************************************************/
create or replace function stmt_create_jsonb_to_type_comparator_op (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare
    stmt text := '';
begin
    stmt := format('create operator meta.= (leftarg = jsonb, rightarg = meta.%I, procedure = meta.eq);',
        name || '_id'
    );
    return stmt;
end;
$$ language plpgsql;


/**********************************************************************************
create cast (meta.relation_id as json) with function meta.relation_id(jsonb) as assignment;
**********************************************************************************/
create or replace function stmt_create_jsonb_to_type_cast (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare
    stmt text := '';
begin
    stmt := format('create cast (meta.%I as jsonb) with function meta.%I(meta.%I) as assignment;',
        name || '_id',
        name || '_id_to_jsonb',
        name || '_id'
    );
    return stmt;
end;
$$ language plpgsql;


/*
 *
 * json
 *
 * NOTE: below eight components are exact copy/past of above jsonb components
 * but with :%s/jsonb/json/g.  make edits above and then paste below.
 *
 */


/**********************************************************************************
create function meta.relation_id(value json) returns meta.relation_id as $_$
select meta.relation_id(value->>'schema_name', value->>'name')
$_$ immutable language sql;
**********************************************************************************/
create or replace function stmt_create_type_to_json_constructor_function (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare
    stmt text := '';
    snippets public.hstore;
begin
    snippets := stmt_snippets(name, constructor_arg_names, constructor_arg_types);
    stmt := format('create function meta.%I(value json) returns meta.%I as $_$select meta.%I(%s) $_$ immutable language sql;',
        name || '_id',
        name || '_id',
        name || '_id',
        snippets['constructor_args_from_json']
    );
    return stmt;
end;
$$ language plpgsql;


/**********************************************************************************
create function meta.eq(leftarg meta.relation_id, rightarg json) returns boolean as
    $_$select (leftarg).schema_name = rightarg->>'schema_name' and (leftarg).name = rightarg->>'name'
$_$ immutable language sql;
**********************************************************************************/
create or replace function stmt_create_type_to_json_comparator_function (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare
    stmt text := '';
    snippets public.hstore;
begin
    snippets := stmt_snippets(name, constructor_arg_names, constructor_arg_types);
    stmt := format('create function meta.eq(leftarg meta.%I, rightarg json) returns boolean as $_$%s$_$ immutable language sql;',
        name || '_id',
        snippets['compare_to_json']
    );
    return stmt;
end;
$$ language plpgsql;


/**********************************************************************************
create operator pg_catalog.= (leftarg = meta.relation_id, rightarg = json, procedure = meta.eq);
**********************************************************************************/
create or replace function stmt_create_type_to_json_comparator_op (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare
    stmt text := '';
begin
    stmt := format('create operator meta.= (leftarg = meta.%I, rightarg = json, procedure = meta.eq);',
        name || '_id'
    );
    return stmt;
end;
$$ language plpgsql;


/**********************************************************************************
create cast (json as meta.relation_id) with function meta.relation_id(json) as assignment;
**********************************************************************************/
create or replace function stmt_create_type_to_json_cast (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare
    stmt text := '';
begin
    stmt := format('create cast (json as meta.%I) with function meta.%I(json) as assignment;',
        name || '_id',
        name || '_id'
    );
    return stmt;
end;
$$ language plpgsql;



/*
 * from json
 */

/**********************************************************************************
create function meta.foreign_data_wrapper_id_to_json(value meta.foreign_data_wrapper_id) returns json as $_$
select row(value.name)::meta.foreign_data_wrapper_id
$_$ immutable language sql;
**********************************************************************************/
create or replace function stmt_create_json_to_type_constructor_function (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare
    stmt text := '';
    snippets public.hstore;
begin
    snippets := stmt_snippets(name, constructor_arg_names, constructor_arg_types);
    stmt := format('create function meta.%I(value meta.%I) returns json as $_$select to_json(value)$_$ immutable language sql;',
        name || '_id_to_json',
        name || '_id'
    );
    return stmt;
end;
$$ language plpgsql;


/**********************************************************************************
create function meta.eq(leftarg json, rightarg meta.foreign_data_wrapper_id) returns boolean as $_$
select (leftarg)->>'name' = ((rightarg).name)::text
$_$ immutable language sql;
**********************************************************************************/
create or replace function stmt_create_json_to_type_comparator_function (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare
    stmt text := '';
    snippets public.hstore;
begin
    snippets := stmt_snippets(name, constructor_arg_names, constructor_arg_types);
    stmt := format('create function meta.eq(leftarg json, rightarg meta.%I) returns boolean as $_$%s$_$ immutable language sql;',
        name || '_id',
        snippets['compare_json_to_type']
    );
    return stmt;
end;
$$ language plpgsql;


/**********************************************************************************
create operator pg_catalog.= (leftarg = json, rightarg = meta.relation_id, procedure = meta.eq);
**********************************************************************************/
create or replace function stmt_create_json_to_type_comparator_op (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare
    stmt text := '';
begin
    stmt := format('create operator meta.= (leftarg = json, rightarg = meta.%I, procedure = meta.eq);',
        name || '_id'
    );
    return stmt;
end;
$$ language plpgsql;


/**********************************************************************************
create cast (meta.relation_id as json) with function meta.relation_id(json) as assignment;
**********************************************************************************/
create or replace function stmt_create_json_to_type_cast (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare
    stmt text := '';
begin
    stmt := format('create cast (meta.%I as json) with function meta.%I(meta.%I) as assignment;',
        name || '_id',
        name || '_id_to_json',
        name || '_id'
    );
    return stmt;
end;
$$ language plpgsql;


/*
 *
 * end json/json
 *
 */



/**********************************************************************************
**********************************************************************************/
create or replace function stmt_create_type_to_schema_type_constructor_function (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare
    stmt text := '';
begin
    stmt := format('create function meta.%I(%I meta.%I) returns meta.schema_id as $_$select meta.schema_id((%I).schema_name) $_$ immutable language sql;',
        name || '_id_to_schema_id',
        name || '_id',
        name || '_id',
        name || '_id'
    );
    return stmt;
end;
$$ language plpgsql;


/**********************************************************************************
**********************************************************************************/
create or replace function stmt_create_type_to_schema_cast (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare
    stmt text := '';
begin
    stmt := format('create cast (meta.%I as meta.schema_id) with function meta.%I(meta.%I) as assignment;',
        name || '_id',
        name || '_id_to_schema_id',
        name || '_id'
    );
    return stmt;
end;
$$ language plpgsql;


/**********************************************************************************
**********************************************************************************/
create or replace function stmt_create_type_to_relation_type_constructor_function (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare
    stmt text := '';
begin
    stmt := format('create function meta.%I(%I meta.%I) returns meta.relation_id as $_$select meta.relation_id((%I).schema_name, (%I).relation_name) $_$ immutable language sql;',
        name || '_id_to_relation_id',
        name || '_id',
        name || '_id',
        name || '_id',
        name || '_id'
    );
    return stmt;
end;
$$ language plpgsql;


/**********************************************************************************
**********************************************************************************/
create or replace function stmt_create_type_to_relation_cast (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare
    stmt text := '';
begin
    stmt := format('create cast (meta.%I as meta.relation_id) with function meta.%I(meta.%I) as assignment;',
        name || '_id',
        name || '_id_to_relation_id',
        name || '_id'
    );
    return stmt;
end;
$$ language plpgsql;


/**********************************************************************************
**********************************************************************************/
create or replace function stmt_create_type_to_column_type_constructor_function (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare
    stmt text := '';
begin
    stmt := format('create function meta.%I(%I meta.%I) returns meta.column_id as $_$select meta.column_id((%I).schema_name, (%I).relation_name, (%I).column_name) $_$ immutable language sql;',
        name || '_id_to_column_id',
        name || '_id',
        name || '_id',
        name || '_id',
        name || '_id',
        name || '_id'
    );
    return stmt;
end;
$$ language plpgsql;


/**********************************************************************************
**********************************************************************************/
create or replace function stmt_create_type_to_column_cast (name text, constructor_arg_names text[], constructor_arg_types text[]) returns text as $$
declare
    stmt text := '';
begin
    stmt := format('create cast (meta.%I as meta.column_id) with function meta.%I(meta.%I) as assignment;',
        name || '_id',
        name || '_id_to_column_id',
        name || '_id'
    );
    return stmt;
end;
$$ language plpgsql;

commit;
