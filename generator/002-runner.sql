begin;
set search_path=meta_meta;

CREATE FUNCTION exec(text) RETURNS text AS $$
    BEGIN EXECUTE $1; RETURN $1; END
$$ LANGUAGE plpgsql;

select e.name as entity_name, c.name as component_name, exec(component_statement(e.name, c.name))
from pg_entity e, pg_entity_component c
order by e.name, c.position;

commit;

