-- One down, many to go

create cast (meta.function_id as oid) with function meta.function_id_to_oid(meta.function_id) as assignment; 
create or replace function meta.function_id_to_oid(f meta.function_id) returns oid as $_$
    select p.oid
    from pg_proc p
    join pg_namespace n on p.pronamespace = n.oid
    where p.proname = f.name
        and n.nspname = f.schema_name
        and p.proargtypes::oid[] = (
            select array_agg(t::regtype::oid) from unnest(f.parameters) as t
        )
$_$ immutable language sql; 
