begin;

/******************************************************************************
 * meta.siuda
 *****************************************************************************/
create type meta2.siuda as enum ('select', 'insert', 'update', 'delete', 'all');

create function meta2.siuda(c char) returns meta2.siuda as $$
begin
    case c
        when 'r' then
            return 'select'::meta2.siuda;
        when 'a' then
            return 'insert'::meta2.siuda;
        when 'w' then
            return 'update'::meta2.siuda;
        when 'd' then
            return 'delete'::meta2.siuda;
        when '*' then
            return 'all'::meta2.siuda;
    end case;
end;
$$ immutable language plpgsql;


create cast (char as meta2.siuda)
with function meta2.siuda(char)
as assignment;


/******************************************************************************
 * meta.schema
 *****************************************************************************/
create view meta2.schema as
    select meta2.schema_id(schema_name) id, schema_name::text as name
    from information_schema.schemata;


/******************************************************************************
 * meta.type
 *****************************************************************************/
create view meta2.type as
select
    meta2.type_id(n.nspname, pg_catalog.format_type(t.oid, NULL)) as id,
    t.typtype as "type",
    n.nspname::text as "schema_name",
    pg_catalog.format_type(t.oid, NULL)::text as "name",
    case when c.relkind = 'c' then true else false end as "composite",
    pg_catalog.obj_description(t.oid, 'pg_type') as "description"
from pg_catalog.pg_type t
     left join pg_catalog.pg_namespace n on n.oid = t.typnamespace
     left join pg_catalog.pg_class c on c.oid = t.typrelid
where (t.typrelid = 0 or c.relkind = 'c')
  and not exists(select 1 from pg_catalog.pg_type el where el.oid = t.typelem and el.typarray = t.oid)
  and pg_catalog.pg_type_is_visible(t.oid)
order by 1, 2;


/******************************************************************************
 * meta.cast
 *****************************************************************************/
create view meta2.cast as
--TODO
SELECT meta2.cast_id(ts.typname, pg_catalog.format_type(castsource, NULL),tt.typname, pg_catalog.format_type(casttarget, NULL)) as id,
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
WHERE ( (true  AND pg_catalog.pg_type_is_visible(ts.oid)
    ) OR (true  AND pg_catalog.pg_type_is_visible(tt.oid)
) )
ORDER BY 1, 2;

/******************************************************************************
 * meta.operator
 *****************************************************************************/
create view meta2.operator as
SELECT meta2.operator_id(n.nspname, o.oprname, trns.nspname, tr.typname, trns.nspname, tr.typname) as id,
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
    AND pg_catalog.pg_operator_is_visible(o.oid)
ORDER BY 1, 2, 3, 4;


/******************************************************************************
 * meta.sequence
 *****************************************************************************/
create view meta2.sequence as
    select meta2.sequence_id(sequence_schema, sequence_name) as id,
           meta2.schema_id(sequence_schema) as schema_id,
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
create view meta2.table as
    select meta2.relation_id(schemaname, tablename) as id,
           meta2.schema_id(schemaname) as schema_id,
           schemaname::text as schema_name,
           tablename::text as name,
           rowsecurity as rowsecurity
    /*
    -- going from pg_catalog.pg_tables instead, so we can get rowsecurity
    from information_schema.tables
    where table_type = 'BASE TABLE';
    */
    from pg_catalog.pg_tables;


/******************************************************************************
 * meta.view
 *****************************************************************************/
create view meta2.view as
    select meta2.relation_id(table_schema, table_name) as id,
           meta2.schema_id(table_schema) as schema_id,
           table_schema::text as schema_name,
           table_name::text as name,
           view_definition::text as query

    from information_schema.views v;


/******************************************************************************
 * meta.relation_column
 *****************************************************************************/
create view meta2.relation_column as
    select meta2.column_id(c.table_schema, c.table_name, c.column_name) as id,
           meta2.relation_id(c.table_schema, c.table_name) as relation_id,
           c.table_schema::text as schema_name,
           c.table_name::text as relation_name,
           c.column_name::text as name,
           c.ordinal_position::integer as position,
           quote_ident(c.udt_schema) || '.' || quote_ident(c.udt_name) as type_name,
           meta2.type_id (c.udt_schema, c.udt_name) as "type_id",
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
create view meta2.column as
    -- select c.id, c.relation_id as table_id, c.schema_name, c.relation_name, c.name, c.position, c.type_name, c.type_id, c.nullable, c.column_default, c.primary_key
    select c.*
    from meta2.table t
        join meta2.relation_column c on c.relation_id = t.id;


/******************************************************************************
 * meta.relation
 *****************************************************************************/
create view meta2.relation as
    select meta2.relation_id(t.table_schema, t.table_name) as id,
           meta2.schema_id(t.table_schema) as schema_id,
           t.table_schema::text as schema_name,
           t.table_name::text as name,
           t.table_type::text as "type",
           nullif(array_agg(c.id), array[null]::meta2.column_id[]) as primary_key_column_ids,
           nullif(array_agg(c.name::text), array[null]::text[]) as primary_key_column_names

    from information_schema.tables t

    left join meta2.relation_column c
           on c.relation_id = meta2.relation_id(t.table_schema, t.table_name) and c.primary_key

    group by t.table_schema, t.table_name, t.table_type;


/******************************************************************************
 * meta.foreign_key
 *****************************************************************************/
create view meta2.foreign_key as
    select meta2.foreign_key_id(tc.table_schema, tc.table_name, tc.constraint_name) as id,
           meta2.relation_id(tc.table_schema, tc.table_name) as table_id,
           tc.table_schema::text as schema_name,
           tc.table_name::text as table_name,
           tc.constraint_name::text as name,
           array_agg(meta2.column_id(kcu.table_schema, kcu.table_name, kcu.column_name)) as from_column_ids,
           array_agg(meta2.column_id(ccu.table_schema, ccu.table_name, ccu.column_name)) as to_column_ids,
           update_rule::text as on_update,
           delete_rule::text as on_delete

    from information_schema.table_constraints tc

    inner join information_schema.referential_constraints rc
            on rc.constraint_catalog = tc.constraint_catalog and
               rc.constraint_schema = tc.constraint_schema and
               rc.constraint_name = tc.constraint_name

    inner join information_schema.constraint_column_usage ccu
            on ccu.constraint_catalog = tc.constraint_catalog and
               ccu.constraint_schema = tc.constraint_schema and
               ccu.constraint_name = tc.constraint_name

    inner join information_schema.key_column_usage kcu
            on kcu.constraint_catalog = tc.constraint_catalog and
               kcu.constraint_schema = tc.constraint_schema and
               kcu.constraint_name = tc.constraint_name

    where constraint_type = 'FOREIGN KEY'

    group by tc.table_schema, tc.table_name, tc.constraint_name, update_rule, delete_rule;


/******************************************************************************
 * meta.function
 *****************************************************************************/
create view meta2.function as
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
        select meta2.function_id(
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
            meta2.schema_id(r.routine_schema) as schema_id,
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
            meta2.type_id(r.type_udt_schema, r.type_udt_name) as return_type_id,
            lower(r.external_language)::information_schema.character_data::text as language

        from information_schema.routines r

            left join information_schema.parameters p
                on p.specific_catalog = r.specific_catalog and
                    p.specific_schema = r.specific_schema and
                    p.specific_name = r.specific_name

        where r.routine_type = 'FUNCTION' and
            r.routine_name not in ('pg_identify_object', 'pg_sequence_parameters') and
            p.ordinal_position > 0 and
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

        left join information_schema.parameters p_in
            on p_in.specific_catalog = q.specific_catalog and
                p_in.specific_schema = q.specific_schema and
                p_in.specific_name = q.specific_name
         where
                p_in.ordinal_position > 0 and
                p_in.parameter_mode = 'IN'

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
create view meta2.function_parameter as
    select q.schema_id,
        q.schema_name,
        q.function_id,
        q.function_name,
        par.parameter_name as name,
        meta2.type_id(par.udt_schema, par.udt_name) as type_id,
        quote_ident(par.udt_schema) || '.' || quote_ident(par.udt_name) as type_name,
        par.parameter_mode::text as "mode",
        par.ordinal_position::integer as position,
        par.parameter_default::text as "default"

    from (
        select meta2.function_id(
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
            meta2.schema_id(r.routine_schema) as schema_id,
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
create view meta2.trigger as
    select meta2.trigger_id(t_pgn.nspname, pgc.relname, pg_trigger.tgname) as id,
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

    inner join meta2.schema t_s
            on t_s.name = t_pgn.nspname

    inner join meta2.table t
            on t.schema_id = t_s.id and
               t.name = pgc.relname

    inner join pg_proc pgp
            on pgp.oid = tgfoid

    inner join pg_namespace f_pgn
            on f_pgn.oid = pgp.pronamespace

    inner join meta2.schema f_s
            on f_s.name = f_pgn.nspname

    inner join meta2.function f
            on f.schema_id = f_s.id and
               f.name = pgp.proname;


/******************************************************************************
 * meta.role
 *****************************************************************************/
create view meta2.role as
   select meta2.role_id(pgr.rolname) as id,
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
   select meta2.role_id('0'::oid::regrole::text) as id,
    'PUBLIC' as name,
    null, null, null, null, null, null, null, null, null;


/******************************************************************************
 * meta.role_inheritance
 *****************************************************************************/
create view meta2.role_inheritance as
select
    r.rolname::text || '<-->' || r2.rolname::text as id,
    r.rolname::text::meta2.role_id as role_id,
    r.rolname::text as role_name,
    r2.rolname::text::meta2.role_id as member_role_id,
    r2.rolname::text as member_role_name
from pg_auth_members m
    join pg_roles r on r.oid = m.roleid
    join pg_roles r2 on r2.oid = m.member;



/******************************************************************************
 * meta.table_privilege
 *****************************************************************************/
create view meta2.table_privilege as
select meta2.table_privilege_id(schema_name, table_name, (role_id).name, type) as id,
    meta2.relation_id(schema_name, table_name) as table_id,
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
                meta2.role_id('-'::text)
            else
                meta2.role_id(grantee::text)
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

create view meta2.policy as
select meta2.policy_id(n.nspname, c.relname, p.polname) as id,
    p.polname::text as name,
    meta2.relation_id(n.nspname, c.relname) as relation_id,
    c.relname::text as relation_name,
    n.nspname::text as schema_name,
    p.polcmd::char::meta2.siuda as command,
    pg_get_expr(p.polqual, p.polrelid, True) as using,
    pg_get_expr(p.polwithcheck, p.polrelid, True) as check
from pg_policy p
    join pg_class c on c.oid = p.polrelid
    join pg_namespace n on n.oid = c.relnamespace;


/******************************************************************************
 * meta.policy_role
 *****************************************************************************/
create view meta2.policy_role as
select
--    meta2.policy_id((relation_id).schema_name, (relation_id).name, policy_name)::text || '<-->' || role_id::text as id,
    meta2.policy_id((relation_id).schema_name, (relation_id).name, policy_name) as policy_id,
    policy_name::text,
    relation_id,
    (relation_id).name as relation_name,
    (relation_id).schema_name as schema_name,
    role_id,
    (role_id).name as role_name
from (
    select
        p.polname as policy_name,
        meta2.relation_id(n.nspname, c.relname) as relation_id,
        unnest(p.polroles::regrole[]::text[]::meta2.role_id[]) as role_id
    from pg_policy p
        join pg_class c on c.oid = p.polrelid
        join pg_namespace n on n.oid = c.relnamespace
) a;


/******************************************************************************
 * meta.connection
 *****************************************************************************/
create view meta2.connection as
   select meta2.connection_id(psa.pid, psa.backend_start) as id,
          meta2.role_id(psa.usename::text) as role_id,
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
create view meta2.constraint_unique as
    select meta2.constraint_id(tc.table_schema, tc.table_name, tc.constraint_name) as id,
           meta2.relation_id(tc.table_schema, tc.table_name) as table_id,
           tc.table_schema::text as schema_name,
           tc.table_name::text as table_name,
           tc.constraint_name::text as name,
           array_agg(meta2.column_id(ccu.table_schema, ccu.table_name, ccu.column_name)) as column_ids,
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
create view meta2.constraint_check as
    select meta2.constraint_id(tc.table_schema, tc.table_name, tc.constraint_name) as id,
           meta2.relation_id(tc.table_schema, tc.table_name) as table_id,
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
create view meta2.extension as
    select meta2.extension_id(ext.extname) as id,
           meta2.schema_id(pgn.nspname) as schema_id,
           pgn.nspname::text as schema_name,
           ext.extname::text as name,
           ext.extversion as version

    from pg_catalog.pg_extension ext
    inner join pg_catalog.pg_namespace pgn
            on pgn.oid = ext.extnamespace;


/******************************************************************************
 * meta.foreign_data_wrapper
 *****************************************************************************/
create view meta2.foreign_data_wrapper as
    select id,
           name::text,
           handler_id,
           validator_id,
           string_agg((quote_ident(opt[1]) || '=>' || replace(array_to_string(opt[2:array_length(opt, 1)], '='), ',', '\,')), ',')::public.hstore as options

    from (
        select meta2.foreign_data_wrapper_id(fdwname) as id,
               fdwname as name,
               h_f.id as handler_id,
               v_f.id as validator_id,
               string_to_array(unnest(coalesce(fdwoptions, array['']::text[])), '=') as opt

        from pg_catalog.pg_foreign_data_wrapper

        left join pg_proc p_h
               on p_h.oid = fdwhandler

        left join pg_namespace h_n
               on h_n.oid = p_h.pronamespace

        left join meta2.function h_f
               on h_f.schema_name = h_n.nspname and
                  h_f.name = p_h.proname

        left join pg_proc p_v
               on p_v.oid = fdwvalidator

        left join pg_namespace v_n
               on v_n.oid = p_v.pronamespace

        left join meta2.function v_f
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
create view meta2.foreign_server as
    select id,
           foreign_data_wrapper_id,
           name::text,
           "type",
           version,
           string_agg((quote_ident(opt[1]) || '=>' || replace(array_to_string(opt[2:array_length(opt, 1)], '='), ',', '\,')), ',')::public.hstore as options

    from (
        select meta2.foreign_server_id(srvname) as id,
               meta2.foreign_data_wrapper_id(fdwname) as foreign_data_wrapper_id,
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
create view meta2.foreign_table as
    select id,
           foreign_server_id,
           schema_id,
           schema_name::text,
           name::text,
           string_agg((quote_ident(opt[1]) || '=>' || replace(array_to_string(opt[2:array_length(opt, 1)], '='), ',', '\,')), ',')::public.hstore as options

    from (
        select meta2.relation_id(pgn.nspname, pgc.relname) as id,
               meta2.schema_id(pgn.nspname) as schema_id,
               meta2.foreign_server_id(pfs.srvname) as foreign_server_id,
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

create view meta2.foreign_column as
    select meta2.column_id(c.table_schema, c.table_name, c.column_name) as id,
           meta2.relation_id(c.table_schema, c.table_name) as foreign_table_id,
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


create or replace function meta2.row_exists(in row_id meta2.row_id, out answer boolean) as $$
    declare
        stmt text;
    begin
        stmt := format (
            'select (count(*) = 1) from %I.%I where %I::text = %L',
                (row_id).schema_name,
                (row_id).relation_name,
                (row_id).pk_column_name,
                (row_id).pk_value
            );

        -- raise warning '%s', stmt;
        execute stmt into answer;

    exception
        when undefined_table then
            answer := false;
    end;
$$ language plpgsql;

commit;
