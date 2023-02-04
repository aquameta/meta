begin;

create extension if not exists hstore schema public;

create schema meta2;
set search_path=meta2;


create type meta2.meta_id as (id text);
create or replace function meta2.meta_id(id text) returns meta2.meta_id as $$
begin
    -- validation
    return row(id);
end;
$$ language plpgsql;

commit;
