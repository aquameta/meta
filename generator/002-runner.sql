begin;
set search_path=meta_meta;

CREATE FUNCTION exec(text) RETURNS text AS $$
    BEGIN EXECUTE $1; RETURN $1; END
$$ LANGUAGE plpgsql;

/*
 * better approach.  use component_statement() with exec() in a SQL query that queries pg_entity and pg_component
 *
 * select e.name as entity_name, c.name as component_name, exec(component_statement(e.name, c.name))
 * from pg_entity e, pg_entity_component c
 * order by e.name, c.position;
 */

create or replace function component_statement(entity text, component text) returns text as $$
declare
stmt text;
begin
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

select e.name as entity_name, c.name as component_name, exec(component_statement(e.name, c.name))
from pg_entity e, pg_entity_component c
order by e.name, c.position;

commit;

