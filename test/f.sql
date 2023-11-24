begin;
drop schema foo cascade;
create schema foo;
set search_path=foo;


create function text_arr_param(x text[]) returns void as $$select 1; $$language sql;
create function text_arr_return(x text) returns text[] as $$select '{}'::text[]; $$language sql;
create function in_out_params(in x text, out y text) returns text as $$select 'hi'; $$language sql;
create function immutable(x text) returns integer as $$select 1; $$language sql immutable;
create function many_params(a text, b text, c text, d text) returns text as $$select id::text from meta.schema; $$language sql;
create function setof_return(a text) returns setof text as $$select 'hi'; $$language sql;
create function composite_param(f meta.field_id) returns integer as $$select 1; $$language sql;
create function composite_array_param(f meta.field_id[]) returns integer as $$select 1; $$language sql;
create function composite_array_return () returns meta.field_id[] as $$select array[meta.field_id('a','b','c','d','e')]; $$language sql;
create function composite_param_out(out f meta.field_id) as $$select meta.field_id('endpoint','resource','content', 'id','1234'); $$language sql;
create function param_default(x integer default 9000) returns integer as $$select 1234; $$language sql;
create function no_params() returns integer as $$select 1; $$language sql;
create function no_return() returns void as $$select 1; $$language sql;
create function "has""quote"() returns void as $$select 1; $$language sql;
create function "has,comma"() returns void as $$select 1; $$language sql;
create function param_with_quote("quote""param" text) returns void as $$select 1;$$language sql;
-- create function "has space"() returns void as $$select 1;$$ language sql;
-- create function horrible_param("x int DEFAULT 1" integer default 2) returns void as $$select 1;$$ language sql;
create function just_one_out(OUT integer) returns integer as $$select 1;$$ language sql;
create function just_one_out_no_return(OUT integer) as $$select 1;$$ language sql;

commit;
