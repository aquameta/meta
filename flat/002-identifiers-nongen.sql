-- begin;

set search_path=meta;

-- for some reason, generator isn't generating these.  they're commented out.
create function meta.field_id_to_row_id(field_id meta.field_id) returns meta.row_id as $_$select meta.row_id((field_id).schema_name, (field_id).relation_name, (field_id).pk_column_name, (field_id).pk_value) $_$ immutable language sql;
create cast (meta.field_id as meta.row_id) with function meta.field_id_to_row_id(meta.field_id) as assignment;


/*
 * Function: urldecode_arr
 * Author: Marc Mamin
 * Source: PostgreSQL Tricks (http://postgres.cz/wiki/postgresql_sql_tricks#function_for_decoding_of_url_code)
 * Decode URLs
 */
create or replace function meta.urldecode_arr(url text)
returns text as $$
begin
  return
   (with str as (select case when $1 ~ '^%[0-9a-fa-f][0-9a-fa-f]' then array[''] end
                                      || regexp_split_to_array ($1, '(%[0-9a-fa-f][0-9a-fa-f])+', 'i') plain,
                       array(select (regexp_matches ($1, '((?:%[0-9a-fa-f][0-9a-fa-f])+)', 'gi'))[1]) encoded)
     select  coalesce(string_agg(plain[i] || coalesce( convert_from(decode(replace(encoded[i], '%',''), 'hex'), 'utf8'), ''), ''), $1)
        from str,
             (select  generate_series(1, array_upper(encoded,1) + 2) i from str) blah);
end
$$ language plpgsql immutable strict;


create or replace function meta.relation_id(value text) returns meta.relation_id as $$
select meta.relation_id(
    meta.urldecode_arr((string_to_array(value, '/'))[1]::text), -- Schema name
    meta.urldecode_arr((string_to_array(value, '/'))[2]::text) -- Relation name
)
$$ immutable language sql;


drop cast if exists (text as meta.relation_id);
create cast (text as meta.relation_id)
with function meta.relation_id(text)
as assignment;


create or replace function meta.text(value meta.relation_id) returns text as $$
select (value).schema_name || '/' || value.name
$$ immutable language sql;

drop cast if exists(meta.relation_id as text);
create cast (meta.relation_id as text)
with function meta.text(meta.relation_id)
as assignment;



/******************* function to text ********************/



create or replace function meta.function_id(value text) returns meta.function_id as $$
select meta.function_id(
    meta.urldecode_arr((string_to_array(value, '/'))[1]::text), -- schema name
    meta.urldecode_arr((string_to_array(value, '/'))[2]::text), -- function name
    meta.urldecode_arr((string_to_array(value, '/'))[3]::text)::text[] -- array of ordered parameter types, e.g. {uuid,text,text}
)
$$ immutable language sql;


drop cast if exists (text as meta.function_id);
create cast (text as meta.function_id)
with function meta.function_id(text)
as assignment;


create or replace function meta.text(value meta.function_id) returns text as $$
select (value).schema_name || '/' ||
    (value).name || '/' ||
    (value).parameters::text
$$ immutable language sql;


drop cast if exists (meta.function_id as text);
create cast (meta.function_id as text)
with function meta.text(meta.function_id)
as assignment;


/********************** field to text **********************/

/* TODO: field_id doesn't include column name, so when you cast it it has to be looked up.  this is pedantic and stupid.  stop.
*/
create or replace function meta.field_id(value text) returns meta.field_id as $$
declare
    parts text[];
    schema_name text;
    relation_name text;
    pk_value text;
    column_name text;
    pk_column_name text;
begin
    select string_to_array(value, '/') into parts;
    select meta.urldecode_arr(parts[1]::text) into schema_name;
    select meta.urldecode_arr(parts[2]::text) into relation_name;
    select meta.urldecode_arr(parts[3]::text) into pk_column_name;
    select meta.urldecode_arr(parts[4]::text) into pk_value;
    select meta.urldecode_arr(parts[5]::text) into column_name;

    return meta.field_id(
        schema_name,
        relation_name,
        pk_column_name,
        pk_value,
        column_name
    );

end;
$$ immutable language plpgsql;


drop cast if exists (text as meta.field_id);
create cast (text as meta.field_id)
with function meta.field_id(text)
as assignment;


create or replace function meta.text(value meta.field_id) returns text as $$
select (value).schema_name || '/' ||
    (value).relation_name || '/' ||
    (value).pk_column_name || '/' ||
    (value).pk_value || '/' ||
    (value).column_name
$$ immutable language sql;


create cast (meta.field_id as text)
with function meta.text(meta.field_id)
as assignment;









/********************** row to text **********************/


/*
 * TODO: Audit this.
 * Seems like row_id should have pk_column_name in it instead of looking stuff
 * up.  Seems like we should be using quote_ident since idents can contain
 * slashes.  Actually kind of our own version of quote_ident that is
 * slash-aware.
 */

create or replace function meta.row_id(value text) returns meta.row_id as $$
declare
    parts text[];
    schema_name text;
    relation_name text;
    pk_value text;
    pk_column_name text;
begin
    select string_to_array(value, '/') into parts;
    select meta.urldecode_arr(parts[1]::text) into schema_name;
    select meta.urldecode_arr(parts[2]::text) into relation_name;
    select meta.urldecode_arr(parts[3]::text) into pk_column_name;
    select meta.urldecode_arr(parts[4]::text) into pk_value;

    /*
    select c.column_name as name
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
                 k.column_name = c.column_name
    where c.table_schema = schema_name and c.table_name = relation_name
            and k.column_name is not null or (c.table_schema = 'meta' and c.column_name = 'id') -- is this the primary_key
    into pk_column_name;
    */

    return meta.row_id(
        schema_name,
        relation_name,
        pk_column_name,
        pk_value
    );

end;
$$ immutable language plpgsql;


create cast (text as meta.row_id)
with function meta.row_id(text)
as assignment;


create function meta.text(value meta.row_id) returns text as $$
select (value).schema_name || '/' ||
    (value).relation_name || '/' ||
    (value).pk_column_name || '/' ||
    value.pk_value
$$ immutable language sql;


create cast (meta.row_id as text)
with function meta.text(meta.row_id)
as assignment;






-- commit;

