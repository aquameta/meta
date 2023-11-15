create type meta.meta_id as (id text);
create or replace function meta.meta_id(id text) returns meta.meta_id as $$
begin
    -- validation
    return row(id);
end;
$$ language plpgsql;
