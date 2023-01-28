begin;
set search_path=meta_meta;

CREATE FUNCTION exec(text) RETURNS text AS $$
    BEGIN EXECUTE $1; RETURN $1; END
$$ LANGUAGE plpgsql;

/*
for the given entity, iterate through each component and run it's stmt
generator function, aggregating the returned strings.

usage:
select generate_component_stmts(name) from pg_entity;
*/

create or replace function generate_component_stmts(entity_name text) returns text /* table (
    component_id text,
    component_name uuid references entity_component(id),
    statement text
) */ as $$
declare 
    components text[];
    component text;
    stmt text;
    statements text := '';
begin
    select array_agg(c.name) from (select name from meta_meta.pg_entity_component order by position) c into components;
    raise info 'components: %', components;

    foreach component in array components loop
        raise info '__component: %', component;
        execute format(
            'select %I(name, constructor_arg_names, constructor_arg_types) from meta_meta.pg_entity where name = %L',
            'stmt_create_' || component,
            entity_name
        ) into stmt;
        statements := statements || stmt || E'\n';
    end loop;

    return statements;

end
$$ language plpgsql;


commit;
