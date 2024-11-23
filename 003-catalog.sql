/******************************************************************************
 * meta.siuda
 *****************************************************************************/
create type meta.siuda as enum ('select', 'insert', 'update', 'delete', 'all');

create function meta.siuda(c char) returns meta.siuda as $$
begin
    case c
        when 'r' then
            return 'select'::meta.siuda;
        when 'a' then
            return 'insert'::meta.siuda;
        when 'w' then
            return 'update'::meta.siuda;
        when 'd' then
            return 'delete'::meta.siuda;
        when '*' then
            return 'all'::meta.siuda;
    end case;
end;
$$ immutable language plpgsql;


create cast (char as meta.siuda)
with function meta.siuda(char)
as assignment;


/******************************************************************************
 * meta.schema
 *****************************************************************************/
create view meta.schema as
    select meta.schema_id(schema_name) id, schema_name::text as name
    from information_schema.schemata
--    where schema_name not in ('pg_catalog', 'information_schema')
;


/******************************************************************************
 * meta.type
 *****************************************************************************/
-- https://github.com/aquameta/pg_catalog_get_defs/blob/master/pg_get_typedef.sql
create or replace function get_typedef_composite(oid) returns text
  language plpgsql
  as $$
  declare
    defn text;
  begin
    select into defn
           format('CREATE TYPE %s AS (%s)',
                  $1::regtype,
                  string_agg(coldef, ', ' order by attnum))
      from (select a.attnum,
                   format('%I %s%s',
                          a.attname,
                          format_type(a.atttypid, a.atttypmod),
                          case when a.attcollation <> ct.typcollation
                               then format(' COLLATE %I ', co.collname)
                               else ''
                          end) as coldef
              from pg_type t
              join pg_attribute a on a.attrelid=t.typrelid
              join pg_type ct on ct.oid=a.atttypid
              left join pg_collation co on co.oid=a.attcollation
             where t.oid = $1
               and a.attnum > 0
               and not a.attisdropped) s;
    return defn;
  end;
  $$;

create or replace function get_typedef_enum(oid) returns text
  language plpgsql
  as $$
  declare
    defn text;
  begin
    select into defn
           format('CREATE TYPE %s AS ENUM (%s)',
                  $1::regtype,
                  string_agg(quote_literal(enumlabel), ', '
                             order by enumsortorder))
      from pg_enum
     where enumtypid = $1;
    return defn;
  end;
  $$;


create or replace view meta.type as
select
    meta.type_id(n.nspname, pg_catalog.format_type(t.oid, NULL)) as id,
    t.typtype as "type",
    n.nspname::text as schema_name,
    t.typname as name,
    case when c.relkind = 'c' then true else false end as composite,
    case when t.typtype = 'c' then meta.get_typedef_composite(t.oid)
         when t.typtype = 'e' then meta.get_typedef_enum(t.oid)
         else 'UNSUPPORTED'
    end as definition,
    pg_catalog.obj_description(t.oid, 'pg_type') as description
from pg_catalog.pg_type t
     left join pg_catalog.pg_namespace n on n.oid = t.typnamespace
     left join pg_catalog.pg_class c on c.oid = t.typrelid
where (t.typrelid = 0 or c.relkind = 'c')
  and not exists(select 1 from pg_catalog.pg_type el where el.oid = t.typelem and el.typarray = t.oid)
--   and pg_catalog.pg_type_is_visible(t.oid)
    AND n.nspname <> 'pg_catalog'
    AND n.nspname <> 'information_schema'
;



/******************************************************************************
 * meta.cast
 *****************************************************************************/
create view meta.cast as
SELECT meta.cast_id(ts.typname, pg_catalog.format_type(castsource, NULL),tt.typname, pg_catalog.format_type(casttarget, NULL)) as id,
       pg_catalog.format_type(castsource, NULL) AS "source type",
       pg_catalog.format_type(casttarget, NULL) AS "target type",
       (CASE WHEN castfunc = 0 THEN '(binary coercible)'
            ELSE p.proname
       END)::text as "function",
       CASE WHEN c.castcontext = 'e' THEN 'no'
           WHEN c.castcontext = 'a' THEN 'in assignment'
        ELSE 'yes'
       END as "implicit?" FROM pg_catalog.pg_cast c LEFT JOIN pg_catalog.pg_proc p
     ON c.castfunc = p.oid
     LEFT JOIN pg_catalog.pg_type ts
     ON c.castsource = ts.oid
     LEFT JOIN pg_catalog.pg_namespace ns
     ON ns.oid = ts.typnamespace
     LEFT JOIN pg_catalog.pg_type tt
     ON c.casttarget = tt.oid
     LEFT JOIN pg_catalog.pg_namespace nt
     ON nt.oid = tt.typnamespace
/*
WHERE ( (true  AND pg_catalog.pg_type_is_visible(ts.oid)
    ) OR (true  AND pg_catalog.pg_type_is_visible(tt.oid)
) )
ORDER BY 1, 2
*/;

/******************************************************************************
 * meta.operator
 *****************************************************************************/
create view meta.operator as
SELECT meta.operator_id(n.nspname, o.oprname, trns.nspname, tr.typname, trns.nspname, tr.typname) as id,
    n.nspname::text as schema_name,
    o.oprname::text as name,
    CASE WHEN o.oprkind='l' THEN NULL ELSE pg_catalog.format_type(o.oprleft, NULL) END AS "Left arg type",
    CASE WHEN o.oprkind='r' THEN NULL ELSE pg_catalog.format_type(o.oprright, NULL) END AS "Right arg type",
    pg_catalog.format_type(o.oprresult, NULL) AS "Result type",
    coalesce(pg_catalog.obj_description(o.oid, 'pg_operator'),
        pg_catalog.obj_description(o.oprcode, 'pg_proc')) AS "Description"
FROM pg_catalog.pg_operator o
    LEFT JOIN pg_catalog.pg_namespace n ON n.oid = o.oprnamespace
    JOIN pg_catalog.pg_type tl ON o.oprleft = tl.oid
    JOIN pg_catalog.pg_namespace tlns on tl.typnamespace = tlns.oid
    JOIN pg_catalog.pg_type tr ON o.oprleft = tr.oid
    JOIN pg_catalog.pg_namespace trns on tr.typnamespace = trns.oid
WHERE n.nspname <> 'pg_catalog'
    AND n.nspname <> 'information_schema'
--    AND pg_catalog.pg_operator_is_visible(o.oid)
-- ORDER BY 1, 2, 3, 4;
;


/******************************************************************************
 * meta.sequence
 *****************************************************************************/
create view meta.sequence as
    select meta.sequence_id(sequence_schema, sequence_name) as id,
           meta.schema_id(sequence_schema) as schema_id,
           sequence_schema::text as schema_name,
           sequence_name::text as name,
           start_value::bigint,
           minimum_value::bigint,
           maximum_value::bigint,
           increment::bigint,
           cycle_option = 'YES' as cycle

    from information_schema.sequences;


/******************************************************************************
 * meta.table
 *****************************************************************************/
create view meta.table as
    select meta.relation_id(schemaname, tablename) as id,
           meta.schema_id(schemaname) as schema_id,
           schemaname::text as schema_name,
           tablename::text as name,
           rowsecurity as rowsecurity
    from pg_catalog.pg_tables;


/******************************************************************************
 * meta.view
 *****************************************************************************/
create view meta.view as
    select meta.relation_id(table_schema, table_name) as id,
           meta.schema_id(table_schema) as schema_id,
           table_schema::text as schema_name,
           table_name::text as name,
           view_definition::text as query

    from information_schema.views v;


/******************************************************************************
 * meta.relation_column
 *****************************************************************************/
create view meta.relation_column as
    select meta.column_id(c.table_schema, c.table_name, c.column_name) as id,
           meta.relation_id(c.table_schema, c.table_name) as relation_id,
           c.table_schema::text as schema_name,
           c.table_name::text as relation_name,
           c.column_name::text as name,
           c.ordinal_position::integer as position,
           quote_ident(c.udt_schema) || '.' || quote_ident(c.udt_name) as type_name,
           meta.type_id (c.udt_schema, c.udt_name) as "type_id",
           (c.is_nullable = 'YES') as nullable,
           c.column_default::text as "default",
           k.column_name is not null or (c.table_schema = 'meta' and c.column_name = 'id') as primary_key

    from information_schema.columns c

    left join information_schema.table_constraints t
          on t.table_catalog = c.table_catalog and
             t.table_schema = c.table_schema and
             t.table_name = c.table_name and
             t.constraint_type = 'PRIMARY KEY'

    left join information_schema.key_column_usage k
          on k.constraint_catalog = t.constraint_catalog and
             k.constraint_schema = t.constraint_schema and
             k.constraint_name = t.constraint_name and
             k.column_name = c.column_name;


/******************************************************************************
 * meta.column
 *****************************************************************************/
create view meta.column as
    -- select c.id, c.relation_id as table_id, c.schema_name, c.relation_name, c.name, c.position, c.type_name, c.type_id, c.nullable, c.column_default, c.primary_key
    select c.*
    from meta.table t
        join meta.relation_column c on c.relation_id = t.id;


/******************************************************************************
 * meta.relation
 *****************************************************************************/
create view meta.relation as
    select meta.relation_id(t.table_schema, t.table_name) as id,
           meta.schema_id(t.table_schema) as schema_id,
           t.table_schema::text as schema_name,
           t.table_name::text as name,
           t.table_type::text as "type",
           nullif(array_agg(c.id order by c.position), array[null]::meta.column_id[]) as primary_key_column_ids,
           nullif(array_agg(c.name::text order by c.position), array[null]::text[]) as primary_key_column_names

    from information_schema.tables t

    left join meta.relation_column c
           on c.relation_id = meta.relation_id(t.table_schema, t.table_name) and c.primary_key

    group by t.table_schema, t.table_name, t.table_type;


/******************************************************************************
 * meta.foreign_key
 *****************************************************************************/
create or replace view meta.foreign_key as
select meta.constraint_id(from_schema_name, from_table_name, constraint_name) as id,
    from_schema_name::text as schema_name,
    from_table_name::text as table_name,
    constraint_name::text,
    array_agg(from_column_name::text order by from_col_key_position) as from_column_names,
    to_schema_name::text,
    to_table_name::text,
    array_agg(to_column_name::text order by to_col_key_position) as to_column_names,
    match_option::text,
    on_update::text,
    on_delete::text
from (
    select
        ns.nspname as from_schema_name,
        cl.relname as from_table_name,
        c.conname as constraint_name,
        a.attname as from_column_name,
        from_cols.elem as from_column_num,
        from_cols.nr as from_col_key_position,
        to_ns.nspname as to_schema_name,
        to_cl.relname as to_table_name,
        to_a.attname as to_column_name,
        to_cols.elem as to_column_num,
        to_cols.nr as to_col_key_position,

/* big gank from information_schema.referential_constraints view */
        CASE c.confmatchtype
            WHEN 'f'::"char" THEN 'FULL'::text
            WHEN 'p'::"char" THEN 'PARTIAL'::text
            WHEN 's'::"char" THEN 'SIMPLE'::text -- was 'NONE'
            ELSE NULL::text
        END::information_schema.character_data AS match_option,
        CASE c.confupdtype
            WHEN 'c'::"char" THEN 'CASCADE'::text
            WHEN 'n'::"char" THEN 'SET NULL'::text
            WHEN 'd'::"char" THEN 'SET DEFAULT'::text
            WHEN 'r'::"char" THEN 'RESTRICT'::text
            WHEN 'a'::"char" THEN 'NO ACTION'::text
            ELSE NULL::text
        END::information_schema.character_data AS on_update,
        CASE c.confdeltype
            WHEN 'c'::"char" THEN 'CASCADE'::text
            WHEN 'n'::"char" THEN 'SET NULL'::text
            WHEN 'd'::"char" THEN 'SET DEFAULT'::text
            WHEN 'r'::"char" THEN 'RESTRICT'::text
            WHEN 'a'::"char" THEN 'NO ACTION'::text
            ELSE NULL::text
        END::information_schema.character_data AS on_delete
/* end big gank */

    from pg_constraint c
    join lateral unnest(c.conkey) with ordinality as from_cols(elem, nr) on true
    join lateral unnest(c.confkey) with ordinality as to_cols(elem, nr) on to_cols.nr = from_cols.nr -- FTW!
    join pg_namespace ns on ns.oid = c.connamespace
    join pg_class cl on cl.oid = c.conrelid
    join pg_attribute a on a.attrelid = c.conrelid and a.attnum = from_cols.elem

    -- to_cols
    join pg_class to_cl on to_cl.oid = c.confrelid
    join pg_namespace to_ns on to_cl.relnamespace = to_ns.oid
    join pg_attribute to_a on to_a.attrelid = to_cl.oid and to_a.attnum = to_cols.elem

    where contype = 'f'
) c_cols
group by 1,2,3,4,6,7,9,10,11;



/******************************************************************************
 * meta.function
 *****************************************************************************/

-- splits a string of identifiers, some of which are quoted, based on the provided delimeter, but not if it is in quotes.
create or replace function meta.split_quoted_string(input_str text, split_char text) returns text[] as $$
declare
    result_array text[];
    inside_quotes boolean := false;
    current_element text := '';
    char_at_index text;
begin
    for i in 1 .. length(input_str) loop
        char_at_index := substring(input_str from i for 1);

        -- raise notice 'current_element: __%__, char_at_index: __%__, inside_quotes: __%__', current_element, char_at_index, inside_quotes;
        -- we got a quote
        if char_at_index = '"' then
            -- raise notice '    ! got quote';
            -- is it a double double-quote?
            if substring(input_str from i + 1 for 1) = '"' then
                -- yes!
                -- raise notice '        a double double quote!';
                current_element := current_element || '""';
                i := i + 1; -- skip the next quote
            else
                -- no.  single quote means flip inside_quotes.
                -- raise notice '        a mere single double-quote';
                inside_quotes := not inside_quotes;
                current_element := current_element || '"';
            end if;
        -- non-quote char
        else
            -- is it the infamous split_charn
            if char_at_index = split_char and not inside_quotes then
                -- raise notice '    ! got the split char __%__ outside quotes', split_char;
                -- add current_element to the results_array
                result_array := array_append(result_array, trim(current_element));
                -- clear current_element
                current_element := '';
            -- no, just a normal char
            else
                -- raise notice '    . normal char, adding __%__', char_at_index;
                current_element := current_element || char_at_index;
                -- raise notice '    current_element is now__%__', current_element;
            end if;
        end if;

        -- if this is the last character, add current_element
        if i = length(input_str) then
            result_array := array_append(result_array, trim(current_element));
        end if;

    end loop;

    return result_array;
end;
$$ language plpgsql stable;


-- returns an array of types, given an identity_args string (as provided by pg_get_function_identity_arguments())
create or replace function meta._get_function_type_sig_array(identity_args text) returns text[] as $$
    declare
        param_exprs text[] := '{}';
        param_expr text[] := '{}';
        sig_array text[] := '{}';
        len integer;
        len2 integer;
        cast_try text;
        good_type text;
        good boolean;
    begin
        -- raise notice '# type_sig_array got: %', identity_args;
        param_exprs := meta.split_quoted_string(identity_args,',');
        len := array_length(param_exprs,1);
        -- raise notice '# param_exprs: %, length: %', param_exprs, len;
        if len is null or len = 0 or param_exprs[1] = '' then
            -- raise notice '    NO PARAMS';
            return '{}'::text[];
        end if;
        -- raise notice 'type_sig_array after splitting into individual exprs (length %): %', len, param_exprs;

        -- for each parameter expression
        for i in 1..len
        loop
            good_type := null;
            -- split by spaces (but not spaces within quotes)
            param_expr = meta.split_quoted_string(param_exprs[i], ' ');
            -- raise notice '        type_sig_array expr: %, length is %', param_expr, len2;

            -- skip OUTs for type-sig, the function isn't called with those
            continue when param_expr[1] = 'OUT';

            len2 := array_length(param_expr,1);
            if len2 is null then
                raise warning 'len2 is null, i: %, identity_args: %, param_exprs: %, param_expr: %', i, identity_args, param_exprs, param_expr;
            end if;

            -- no params;
            continue when len2 is null;

            -- ERROR:  len2 is null, i: 1, identity_args: "char", name, name, name[]
            for j in 1..len2 loop
                cast_try := array_to_string(param_expr[j:],' ');
                -- raise notice '    !!! casting % to ::regtype', cast_try;
                begin
                    execute format('select %L::regtype', cast_try) into good_type;
                exception when others then
                    -- raise notice '        couldnt cast %', cast_try;
                end;

                if good_type is not null then
                    -- raise notice '    GOT A TYPE!! %', good_type;
                    sig_array := array_append(sig_array, good_type);
                    exit;
                else
                    -- raise notice '    Fail.';
                end if;
            end loop;

            if good_type = null then
                raise exception 'Could not parse function parameter: %', param_expr;
            end if;
        end loop;
        return sig_array;
    end
$$ language plpgsql stable;

create or replace function meta._get_function_parameters(parameters text) returns text[] as $$
    declare
        param_exprs text[] := '{}';
        param_expr text[] := '{}';
        result text[] := '{}';
        default_pos integer;
        params_len integer;
        param_len integer;
    begin
        -- raise notice 'get_function_parameters got: %', parameters;
        param_exprs := meta.split_quoted_string(parameters, ',');

        params_len := array_length(param_exprs,1);
        if params_len is null or params_len = 0 or param_exprs[1] = '' then
            -- raise notice '   NO PARAMS';
            return '{}'::text[];
        end if;

        -- raise notice 'get_function_parameters after splitting into individual exprs: %', param_exprs;
        -- for each parameter, drop OUTs, slice off INOUTs and trim everything past 'DEFAULT'
        for i in 1..params_len loop
            -- split by spaces (but not spaces within quotes)
            param_expr = meta.split_quoted_string(param_exprs[i],' ');
            param_len := array_length(param_expr,1);
            -- raise notice '    get_function_parameters expr: %, length is %', param_expr, array_length(param_expr,1);

            result := array_append(result, param_exprs[i]);
        end loop;
        return result;
    end
$$ language plpgsql stable;


create or replace view meta.function as
    with orig as (
        -- slightly modified version of query output by \df+
        SELECT n.nspname as "schema_name",
          p.proname as "name",
          pg_get_function_result(p.oid) as "return_type",
          pg_get_function_identity_arguments(p.oid) as "type_sig",
          pg_catalog.pg_get_function_arguments(p.oid) as "parameters",
         CASE p.prokind
          WHEN 'a' THEN 'agg'
          WHEN 'w' THEN 'window'
          WHEN 'p' THEN 'proc'
          ELSE 'func'
         END as "type",
         CASE
          WHEN p.provolatile = 'i' THEN 'immutable'
          WHEN p.provolatile = 's' THEN 'stable'
          WHEN p.provolatile = 'v' THEN 'volatile'
         END as "volatility",
         CASE
          WHEN p.proparallel = 'r' THEN 'restricted'
          WHEN p.proparallel = 's' THEN 'safe'
          WHEN p.proparallel = 'u' THEN 'unsafe'
         END as "parallel",
         pg_catalog.pg_get_userbyid(p.proowner) as "owner",
         CASE WHEN prosecdef THEN 'definer' ELSE 'invoker' END AS "security",
         pg_catalog.array_to_string(p.proacl, E'\n') AS "access_privileges",
         l.lanname as "language",
         COALESCE(pg_catalog.pg_get_function_sqlbody(p.oid), p.prosrc) as "definition",
         pg_catalog.obj_description(p.oid, 'pg_proc') as "description"
        FROM pg_catalog.pg_proc p
             LEFT JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
             LEFT JOIN pg_catalog.pg_language l ON l.oid = p.prolang
        WHERE /* pg_catalog.pg_function_is_visible(p.oid)
              AND */ n.nspname <> 'pg_catalog'
              AND n.nspname <> 'information_schema'
        -- ORDER BY 1, 2, 4;
    )

    select
        meta.function_id(
            schema_name,
            name,
            meta._get_function_type_sig_array(type_sig)
        ) as id,                -- meta.function_id
        meta.schema_id(schema_name) as schema_id,
        schema_name,
        name,
        meta._get_function_type_sig_array (type_sig) as type_sig,
        meta._get_function_parameters(parameters) as parameters,
        definition,
        description,
        "type",                 -- immutable | stable | volatile
        return_type,
         -- return_type_id,      -- type_id
        language,
        case when return_type like 'SETOF %' then true else false end as returns_set,   -- boolean
        "parallel",             -- restricted | safe | unsafe
        volatility,
        access_privileges,
        security                -- definer | invoker

    from orig;

-- generates function parameter expressions from vars in information_schema
create or replace function meta.stmt_function_parameter_def(
    parameter_mode text, parameter_name text, data_type text, udt_schema text, udt_name text, ordinal_position integer, parameter_default text
) returns text as $$
declare
    argmode text := '';
    argname text := '';
    argtype text := '';
    default_expr text := '';

begin
    -- parameter_name: the name, or null if it has none
    -- data_type: Data type of the parameter, if it is a built-in type, or ARRAY if it is some array (in that case, see the view element_types), else USER-DEFINED (in that case, the type is identified in udt_name and associated columns).
    -- udt_schema: the schema that the type is in
    -- udt_name: Name of the data type of the parameter

    -- argmode IN/OUT/INOUT WIP
    if parameter_mode is not null and parameter_mode != '' and parameter_mode != 'IN' then
        argmode := parameter_mode || ' ';
    end if;

    -- argname
    if parameter_name is not null and parameter_name != '' then
        argname := quote_ident(parameter_name) || ' ';
    end if;

    -- argtype
    if data_type = 'ARRAY' then
        -- raise notice 'argtype -> ARRAY';
        if udt_schema != 'pg_catalog' then
            argtype := quote_ident(udt_schema) || '.';
        end if;
        argtype := argtype || substring(udt_name from 2) || '[]'; -- hack: trim off the _ from the beginning of udt_name for arrays....
    else
        if data_type = 'USER-DEFINED' or data_type is null or data_type = '' then -- why the last two
            -- raise notice 'argtype -> USER-DEFINED';
            argtype := quote_ident(udt_schema) || '.' || quote_ident(udt_name);
            argtype := argtype || ' ';
        else
            -- raise notice 'argtype -> else (not UD or ARR)';
            argtype := data_type || ' ';
        end if;
    end if;

    -- default_expr
    if default_expr is not null and default_expr != '' then
        default_expr := 'default ' || parameter_default;
    end if;

    -- raise notice 'mode: %, name: %, type: %, default: %', argmode, argname, argtype, default_expr;

    return trim(argmode || argname || argtype || default_expr);
end;
$$ language plpgsql;



create view meta.function_info_schema as
with f as (
    select
        -- function
        r.routine_schema::text,
        r.routine_name::text,

        -- function (specific) -- function names are not unique (w/o a type sig) but these are
        r.specific_name::text,

        -- return type
        r.data_type, -- useless?
        r.type_udt_schema::text,
        r.type_udt_name::text,

        -- definition
        r.routine_definition::text,

        -- language
        lower(r.external_language)::information_schema.character_data::text as language,

        -- routine_type: VOLATILE, IMMUTABLE or STABLE
        r.routine_type

    from information_schema.routines r

    where r.routine_type = 'FUNCTION'
        and r.routine_name not in ('pg_identify_object', 'pg_sequence_parameters')
        and r.routine_schema not in ('pg_catalog', 'information_schema')
)

select
    meta.function_id(
        f.routine_schema,
        f.routine_name,
        coalesce(
            nullif(
                array_agg( -- Array of types of the 'IN' parameters to this function
                    coalesce( nullif( nullif(p.data_type, 'ARRAY'), 'USER-DEFINED'), p.udt_schema || '.' || p.udt_name)
                    order by p.ordinal_position),
                array[null]
            ),
            array[]::text[]
        )
    ) as id,
    meta.schema_id(f.routine_schema) as schema_id,
    f.routine_schema as schema_name,
    f.routine_name as name,

    -- parameters - text array
    -- remove null, when there's no params
    array_remove(
        -- agg parameters (if any)
        array_agg(
            case
                when p.data_type is null then null -- function has no parameters, but left join makes one row
                else meta.stmt_function_parameter_def(p.parameter_mode, p.parameter_name, p.data_type, p.udt_schema, p.udt_name, p.ordinal_position::integer, p.parameter_default)
            end
        ), null
    ) as parameters,

    -- definition
    f.routine_definition as definition,

    -- return_type
    coalesce(f.type_udt_schema || '.' || f.type_udt_name) as return_type,
    meta.type_id(f.type_udt_schema, f.type_udt_name) as return_type_id,

    -- language
    f.language,

    -- returns_set
    substring(pg_get_function_result(
        -- function name
        (quote_ident(f.routine_schema) || '.' || quote_ident(f.routine_name) || '(' ||
        -- funtion type sig
        array_to_string(
            coalesce(
                 nullif(
                    array_agg(coalesce(lower(nullif(p.parameter_mode, 'IN')) || ' ', '')
                              || coalesce(nullif(nullif(p.data_type, 'ARRAY'), 'USER-DEFINED'), p.udt_schema || '.' || p.udt_name)
                              order by p.ordinal_position),
                    array[null]
                ),
                array[]::text[]
            ),
            ', '
        )
    || ')')::regprocedure) from 1 for 6) = 'SETOF '
        or (select proretset = 't' from pg_proc join pg_namespace on pg_proc.pronamespace = pg_namespace.oid where proname = f.routine_name and nspname = f.routine_schema limit 1)
    as returns_set,
    f.routine_type as volatility_type -- volatile, immutable, stable

from f
    -- left join on params because sometimes functions don't have params
    left join information_schema.parameters p
        on p.specific_schema = f.routine_schema
            and p.specific_name = f.specific_name
where
        -- allow null for position for functions have no parameters (like trigger functions)
        (p.ordinal_position > 0 or p.ordinal_position is null)
        -- only IN and INOUT parameters
        and (p.parameter_mode like 'IN%' or p.parameter_mode is null) -- FIXME!!!!

group by
    f.routine_schema,
    f.routine_name,
    f.specific_name,
    f.type_udt_schema,
    f.type_udt_name,
    f.routine_definition,
    f.language,
    f.routine_type
;


/*
-- caused by dep fail
NOTICE:  CHECKOUT EXCEPTION checking out (meta,function,id,"(endpoint,path_to_relation_id,{text})"): function endpoint.urldecode_arr(text) does not exist
NOTICE:  CHECKOUT EXCEPTION checking out (meta,function,id,"(endpoint,columns_json,""{text,text,pg_catalog._text,pg_catalog._text}"")"): "json" is not a known variable
NOTICE:  CHECKOUT EXCEPTION checking out (meta,function,id,"(endpoint,anonymous_rows_select_function,""{text,text,json}"")"): variable "mimetype" does not exist
NOTICE:  CHECKOUT EXCEPTION checking out (meta,function,id,"(endpoint,column_list,""{text,text,text,pg_catalog._text,pg_catalog._text}"")"): "column_list" is not a know
n variable
NOTICE:  CHECKOUT EXCEPTION checking out (meta,function,id,"(endpoint,rows_select_function,""{meta.function_id,json}"")"): "mimetype" is not a known variable
NOTICE:  CHECKOUT EXCEPTION checking out (meta,function,id,"(endpoint,field_select,{meta.field_id})"): "mimetype" is not a known variable

*/


-- old version, to be replaced
create view meta.function_old as
    select id,
           schema_id,
           schema_name,
           name,
           parameters,
           definition,
           return_type,
           return_type_id,
           language,
           substring(pg_get_function_result((quote_ident(schema_name) || '.' || quote_ident(name) || '(' ||
               array_to_string(
                   coalesce(
                        nullif(
                           array_agg(coalesce(lower(nullif(p_in.parameter_mode, 'IN')) || ' ', '')
                                     || coalesce(nullif(nullif(p_in.data_type, 'ARRAY'), 'USER-DEFINED'), p_in.udt_schema || '.' || p_in.udt_name)
                                     order by p_in.ordinal_position),
                           array[null]
                       ),
                       array[]::text[]
                   ),
                   ', '
               )
           || ')')::regprocedure) from 1 for 6) = 'SETOF '

            -- FIXME: this circumvents information_schema and uses
            -- pg_catalog because pg_proc.proretset is not used in info_schema,
            -- so it doesn't have enough information to determine whether this
            -- record returns a setof.  not enough info?  and limit 1 is a
            -- hack.  this whole function needs a rewrite, so working around
            -- it for now.
               or (select proretset = 't' from pg_proc join pg_namespace on pg_proc.pronamespace = pg_namespace.oid where proname = q.name and nspname = q.schema_name limit 1)
           as returns_set

    from (
        select meta.function_id(
                r.routine_schema::text,
                r.routine_name::text,
                coalesce(
                    nullif(
                        array_agg( -- Array of types of the 'IN' parameters to this function
                            coalesce( nullif( nullif(p.data_type, 'ARRAY'), 'USER-DEFINED'), p.udt_schema || '.' || p.udt_name)
                            order by p.ordinal_position),
                        array[null]
                    ),
                    array[]::text[]
                )
            ) as id,
            meta.schema_id(r.routine_schema) as schema_id,
            r.routine_schema as schema_name,
            r.routine_name as name,
            r.specific_catalog,
            r.specific_schema,
            r.specific_name,
            coalesce(
                nullif(
                    array_agg( -- Array of types of the 'IN' parameters to this function
                        coalesce( nullif( nullif(p.data_type, 'ARRAY'), 'USER-DEFINED'), p.udt_schema || '.' || p.udt_name)
                        order by p.ordinal_position),
                    array[null]
                ),
                array[]::text[]
            ) as parameters,
            r.routine_definition::text as definition,
            coalesce(nullif(r.data_type, 'USER-DEFINED'), r.type_udt_schema || '.' || r.type_udt_name) as return_type,
            meta.type_id(r.type_udt_schema, r.type_udt_name) as return_type_id,
            lower(r.external_language)::information_schema.character_data::text as language

        from information_schema.routines r

            left join information_schema.parameters p
                on p.specific_catalog = r.specific_catalog and
                    p.specific_schema = r.specific_schema and
                    p.specific_name = r.specific_name

        where r.routine_type = 'FUNCTION' and
            r.routine_name not in ('pg_identify_object', 'pg_sequence_parameters') and
            /* allow nulls in cases of functions that have no parameters (like trigger functions) */
            (p.ordinal_position > 0 or p.ordinal_position is null) and
            (p.parameter_mode like 'IN%' or p.parameter_mode is null)


        group by r.routine_catalog,
            r.routine_schema,
            r.routine_name,
            r.routine_definition,
            r.data_type,
            r.type_udt_schema,
            r.type_udt_name,
            r.external_language,
            r.specific_catalog,
            r.specific_schema,
            r.specific_name,
            p.specific_catalog,
            p.specific_schema,
            p.specific_name
    ) q

        left join information_schema.parameters p_in
            on p_in.specific_catalog = q.specific_catalog and
                p_in.specific_schema = q.specific_schema and
                p_in.specific_name = q.specific_name
         where
            /* allow nulls in cases of functions that have no parameters (like trigger functions) */
            (p_in.ordinal_position > 0 or p_in.ordinal_position is null) and
            (p_in.parameter_mode = 'IN' or p_in.parameter_mode is null) -- includes IN and INOUT

    group by id,
        schema_id,
        schema_name,
        name,
        parameters,
        definition,
        return_type,
        return_type_id,
        language;



/******************************************************************************
 * meta.function_parameter
 *****************************************************************************/
create view meta.function_parameter as
    select q.schema_id,
        q.schema_name,
        q.function_id,
        q.function_name,
        par.parameter_name as name,
        meta.type_id(par.udt_schema, par.udt_name) as type_id,
        quote_ident(par.udt_schema) || '.' || quote_ident(par.udt_name) as type_name,
        par.parameter_mode::text as "mode",
        par.ordinal_position::integer as position,
        par.parameter_default::text as "default"

    from (
        select meta.function_id(
                r.routine_schema::text,
                r.routine_name::text,
                coalesce(
                    nullif(
                array_agg( -- Array of types of the 'IN' parameters to this function
                    coalesce( nullif( nullif(p.data_type, 'ARRAY'), 'USER-DEFINED'), p.udt_schema || '.' || p.udt_name)
                    order by p.ordinal_position),
                array[null]
                    ),
                    array[]::text[]
                )
            ) as function_id,
            meta.schema_id(r.routine_schema) as schema_id,
            r.routine_schema as schema_name,
            r.routine_name as function_name,
            r.specific_catalog,
            r.specific_schema,
            r.specific_name

        from information_schema.routines r

            left join information_schema.parameters p
                on p.specific_catalog = r.specific_catalog and
                    p.specific_schema = r.specific_schema and
                    p.specific_name = r.specific_name

        where r.routine_type = 'FUNCTION' and
            r.routine_name not in ('pg_identify_object', 'pg_sequence_parameters') and
            p.parameter_mode like 'IN%' -- Includes IN and INOUT

        group by r.routine_catalog,
            r.routine_schema,
            r.routine_name,
            r.routine_definition,
            r.data_type,
            r.type_udt_schema,
            r.type_udt_name,
            r.external_language,
            r.specific_catalog,
            r.specific_schema,
            r.specific_name,
            p.specific_catalog,
            p.specific_schema,
            p.specific_name
    ) q
        join information_schema.parameters par
            on par.specific_catalog = q.specific_catalog and
                par.specific_schema = q.specific_schema and
                par.specific_name = q.specific_name;


/******************************************************************************
 * meta.trigger
 *****************************************************************************/
create view meta.trigger as
    select meta.trigger_id(t_pgn.nspname, pgc.relname, pg_trigger.tgname) as id,
           t.id as relation_id,
           t_pgn.nspname::text as schema_name,
           pgc.relname::text as relation_name,
           pg_trigger.tgname::text as name,
           f.id as function_id,
           case when (tgtype >> 1 & 1)::bool then 'before'
                when (tgtype >> 6 & 1)::bool then 'before'
                else 'after'
           end as "when",
           (tgtype >> 2 & 1)::bool as "insert",
           (tgtype >> 3 & 1)::bool as "delete",
           (tgtype >> 4 & 1)::bool as "update",
           (tgtype >> 5 & 1)::bool as "truncate",
           case when (tgtype & 1)::bool then 'row'
                else 'statement'
           end as level

    from pg_trigger

    inner join pg_class pgc
            on pgc.oid = tgrelid

    inner join pg_namespace t_pgn
            on t_pgn.oid = pgc.relnamespace

    inner join meta.schema t_s
            on t_s.name = t_pgn.nspname

    inner join meta.table t
            on t.schema_id = t_s.id and
               t.name = pgc.relname

    inner join pg_proc pgp
            on pgp.oid = tgfoid

    inner join pg_namespace f_pgn
            on f_pgn.oid = pgp.pronamespace

    inner join meta.schema f_s
            on f_s.name = f_pgn.nspname

    inner join meta.function f
            on f.schema_id = f_s.id and
               f.name = pgp.proname;


/******************************************************************************
 * meta.role
 *****************************************************************************/
create view meta.role as
   select meta.role_id(pgr.rolname) as id,
          pgr.rolname::text  as name,
          pgr.rolsuper       as superuser,
          pgr.rolinherit     as inherit,
          pgr.rolcreaterole  as create_role,
          pgr.rolcreatedb    as create_db,
          pgr.rolcanlogin    as can_login,
          pgr.rolreplication as replication,
          pgr.rolconnlimit   as connection_limit,
          '********'::text   as password,
          pgr.rolvaliduntil  as valid_until
   from pg_roles pgr
   inner join pg_authid pga
           on pgr.oid = pga.oid
    union
   select meta.role_id('0'::oid::regrole::text) as id,
    'PUBLIC' as name,
    null, null, null, null, null, null, null, null, null;


/******************************************************************************
 * meta.role_inheritance
 *****************************************************************************/
create view meta.role_inheritance as
select
    r.rolname::text || '<-->' || r2.rolname::text as id,
    r.rolname::text::meta.role_id as role_id,
    r.rolname::text as role_name,
    r2.rolname::text::meta.role_id as member_role_id,
    r2.rolname::text as member_role_name
from pg_auth_members m
    join pg_roles r on r.oid = m.roleid
    join pg_roles r2 on r2.oid = m.member;



/******************************************************************************
 * meta.table_privilege
 *****************************************************************************/
create view meta.table_privilege as
select meta.table_privilege_id(schema_name, table_name, (role_id).name, type) as id,
    meta.relation_id(schema_name, table_name) as table_id,
    schema_name::text,
    table_name::text,
    role_id,
    (role_id).name as role_name,
    type::text,
    is_grantable::boolean,
    with_hierarchy::boolean
from (
    select
        case grantee
            when 'PUBLIC' then
                meta.role_id('-'::text)
            else
                meta.role_id(grantee::text)
        end as role_id,
        table_schema as schema_name,
        table_name,
        privilege_type as type,
        is_grantable,
        with_hierarchy
    from information_schema.role_table_grants
    where table_catalog = current_database()
) a;


/******************************************************************************
 * meta.policy
 *****************************************************************************/

create view meta.policy as
select meta.policy_id(n.nspname, c.relname, p.polname) as id,
    p.polname::text as name,
    meta.relation_id(n.nspname, c.relname) as relation_id,
    c.relname::text as relation_name,
    n.nspname::text as schema_name,
    p.polcmd::char::meta.siuda as command,
    pg_get_expr(p.polqual, p.polrelid, True) as using,
    pg_get_expr(p.polwithcheck, p.polrelid, True) as check
from pg_policy p
    join pg_class c on c.oid = p.polrelid
    join pg_namespace n on n.oid = c.relnamespace;


/******************************************************************************
 * meta.policy_role
 *****************************************************************************/
create view meta.policy_role as
select
--    meta.policy_id((relation_id).schema_name, (relation_id).name, policy_name)::text || '<-->' || role_id::text as id,
    meta.policy_id((relation_id).schema_name, (relation_id).name, policy_name) as policy_id,
    policy_name::text,
    relation_id,
    (relation_id).name as relation_name,
    (relation_id).schema_name as schema_name,
    role_id,
    (role_id).name as role_name
from (
    select
        p.polname as policy_name,
        meta.relation_id(n.nspname, c.relname) as relation_id,
        unnest(p.polroles::regrole[]::text[]::meta.role_id[]) as role_id
    from pg_policy p
        join pg_class c on c.oid = p.polrelid
        join pg_namespace n on n.oid = c.relnamespace
) a;


/******************************************************************************
 * meta.connection
 *****************************************************************************/
create view meta.connection as
   select meta.connection_id(psa.pid, psa.backend_start) as id,
          meta.role_id(psa.usename::text) as role_id,
          psa.datname::text as database_name,
          psa.pid as unix_pid,
          psa.application_name,
          psa.client_addr as client_ip,
          psa.client_hostname as client_hostname,
          psa.client_port as client_port,
          psa.backend_start as connection_start,
          psa.xact_start as transaction_start,
          psa.query as last_query,
          psa.query_start as query_start,
          psa.state as state,
          psa.state_change as last_state_change,
          psa.wait_event as wait_event,
          psa.wait_event_type as wait_event_type
   from pg_stat_activity psa;



/******************************************************************************
 * meta.constraint_unique
 *****************************************************************************/
create view meta.constraint_unique as
    select meta.constraint_id(tc.table_schema, tc.table_name, tc.constraint_name) as id,
           meta.relation_id(tc.table_schema, tc.table_name) as table_id,
           tc.table_schema::text as schema_name,
           tc.table_name::text as table_name,
           tc.constraint_name::text as name,
           array_agg(meta.column_id(ccu.table_schema, ccu.table_name, ccu.column_name)) as column_ids,
           array_agg(ccu.column_name::text) as column_names

    from information_schema.table_constraints tc

    inner join information_schema.constraint_column_usage ccu
            on ccu.constraint_catalog = tc.constraint_catalog and
               ccu.constraint_schema = tc.constraint_schema and
               ccu.constraint_name = tc.constraint_name

    where constraint_type = 'UNIQUE'

    group by tc.table_schema, tc.table_name, tc.constraint_name;


/******************************************************************************
 * meta.constraint_check
 *****************************************************************************/
create view meta.constraint_check as
    select meta.constraint_id(tc.table_schema, tc.table_name, tc.constraint_name) as id,
           meta.relation_id(tc.table_schema, tc.table_name) as table_id,
           tc.table_schema::text as schema_name,
           tc.table_name::text as table_name,
           tc.constraint_name::text as name,
           cc.check_clause::text

    from information_schema.table_constraints tc

    inner join information_schema.check_constraints cc
            on cc.constraint_catalog = tc.constraint_catalog and
               cc.constraint_schema = tc.constraint_schema and
               cc.constraint_name = tc.constraint_name;


/******************************************************************************
 * meta.extension
 *****************************************************************************/
create view meta.extension as
    select meta.extension_id(ext.extname) as id,
           meta.schema_id(pgn.nspname) as schema_id,
           pgn.nspname::text as schema_name,
           ext.extname::text as name,
           ext.extversion as version

    from pg_catalog.pg_extension ext
    inner join pg_catalog.pg_namespace pgn
            on pgn.oid = ext.extnamespace;


/******************************************************************************
 * meta.foreign_data_wrapper
 *****************************************************************************/
create view meta.foreign_data_wrapper as
    select id,
           name::text,
           handler_id,
           validator_id,
           string_agg((quote_ident(opt[1]) || '=>' || replace(array_to_string(opt[2:array_length(opt, 1)], '='), ',', '\,')), ',')::public.hstore as options

    from (
        select meta.foreign_data_wrapper_id(fdwname) as id,
               fdwname as name,
               h_f.id as handler_id,
               v_f.id as validator_id,
               string_to_array(unnest(coalesce(fdwoptions, array['']::text[])), '=') as opt

        from pg_catalog.pg_foreign_data_wrapper

        left join pg_proc p_h
               on p_h.oid = fdwhandler

        left join pg_namespace h_n
               on h_n.oid = p_h.pronamespace

        left join meta.function h_f
               on h_f.schema_name = h_n.nspname and
                  h_f.name = p_h.proname

        left join pg_proc p_v
               on p_v.oid = fdwvalidator

        left join pg_namespace v_n
               on v_n.oid = p_v.pronamespace

        left join meta.function v_f
               on v_f.schema_name = v_n.nspname and
                  v_f.name = p_v.proname
    ) q

    group by id,
             name,
             handler_id,
             validator_id;


/******************************************************************************
 * meta.foreign_server
 *****************************************************************************/
create view meta.foreign_server as
    select id,
           foreign_data_wrapper_id,
           name::text,
           "type",
           version,
           string_agg((quote_ident(opt[1]) || '=>' || replace(array_to_string(opt[2:array_length(opt, 1)], '='), ',', '\,')), ',')::public.hstore as options

    from (
        select meta.foreign_server_id(srvname) as id,
               meta.foreign_data_wrapper_id(fdwname) as foreign_data_wrapper_id,
               srvname as name,
               srvtype as "type",
               srvversion as version,
               string_to_array(unnest(coalesce(srvoptions, array['']::text[])), '=') as opt

        from pg_catalog.pg_foreign_server fs
        inner join pg_catalog.pg_foreign_data_wrapper fdw
                on fdw.oid = fs.srvfdw
    ) q

    group by id,
             foreign_data_wrapper_id,
             name,
             "type",
             version;



/******************************************************************************
 * meta.foreign_table
 *****************************************************************************/
create view meta.foreign_table as
    select id,
           foreign_server_id,
           schema_id,
           schema_name::text,
           name::text,
           string_agg((quote_ident(opt[1]) || '=>' || replace(array_to_string(opt[2:array_length(opt, 1)], '='), ',', '\,')), ',')::public.hstore as options

    from (
        select meta.relation_id(pgn.nspname, pgc.relname) as id,
               meta.schema_id(pgn.nspname) as schema_id,
               meta.foreign_server_id(pfs.srvname) as foreign_server_id,
               pgn.nspname as schema_name,
               pgc.relname as name,
               string_to_array(unnest(coalesce(ftoptions, array['']::text[])), '=') as opt

        from pg_catalog.pg_foreign_table pft
        inner join pg_catalog.pg_class pgc
                on pgc.oid = pft.ftrelid
        inner join pg_catalog.pg_namespace pgn
                on pgn.oid = pgc.relnamespace
        inner join pg_catalog.pg_foreign_server pfs
                on pfs.oid = pft.ftserver
    ) q

    group by id,
             schema_id,
             foreign_server_id,
             schema_name,
             name;


/******************************************************************************
 * meta.foreign_column
 *****************************************************************************/

create view meta.foreign_column as
    select meta.column_id(c.table_schema, c.table_name, c.column_name) as id,
           meta.relation_id(c.table_schema, c.table_name) as foreign_table_id,
           c.table_schema::text as schema_name,
           c.table_name::text as foreign_table_name,
           c.column_name::text as name,
           quote_ident(c.udt_schema) || '.' || quote_ident(c.udt_name) as "type",
           (c.is_nullable = 'YES') as nullable

    from pg_catalog.pg_foreign_table pft
    inner join pg_catalog.pg_class pgc
            on pgc.oid = pft.ftrelid
    inner join pg_catalog.pg_namespace pgn
            on pgn.oid = pgc.relnamespace
    inner join information_schema.columns c
            on c.table_schema = pgn.nspname and
               c.table_name = pgc.relname;

