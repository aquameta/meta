begin;
set search_path=meta_meta;

CREATE FUNCTION exec(text) RETURNS text AS $$
    BEGIN EXECUTE $1; RETURN $1; END
$$ LANGUAGE plpgsql;

-- all components except downcasts for every entity
select exec(component_statement(e.name, c.name))
from pg_entity e, pg_entity_component c
where c.position < 20
order by e.name, c.position;

-- downcasts to schema_id for everything that has a schema_name
select exec(component_statement(e.name, c.name))
from pg_entity e, pg_entity_component c
where c.position in (20,21) and 'schema_name' = any(constructor_arg_names)
order by e.name, c.position;

-- downcasts to relation_id for everything that has a relation_name
select exec(component_statement(e.name, c.name))
from pg_entity e, pg_entity_component c
where c.position in(22,23) and 'relation_name' = any(constructor_arg_names)
order by e.name, c.position;

-- downcasts to column_id for everything that has a column_name
select exec(component_statement(e.name, c.name))
from pg_entity e, pg_entity_component c
where c.position in(24,25) and 'column_name' = any(constructor_arg_names)
order by e.name, c.position;

/*
field_id cast to row_id

select e.name as entity_name, c.name as component_name, exec(component_statement(e.name, c.name))
from pg_entity e, pg_entity_component c
where c.position in(26,27) and 'column_name' = any(constructor_arg_names)
order by e.name, c.position;
*/

commit;
