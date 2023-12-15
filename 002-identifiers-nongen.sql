set search_path=meta;

-- for some reason, generator isn't generating these.  they're commented out.
create function meta.field_id_to_row_id(field_id meta.field_id) returns meta.row_id as $_$select meta.row_id((field_id).schema_name, (field_id).relation_name, (field_id).pk_column_name, (field_id).pk_value) $_$ immutable language sql;
create cast (meta.field_id as meta.row_id) with function meta.field_id_to_row_id(meta.field_id) as assignment;


-- single key row_id constructor
create function meta.row_id(schema_name text, relation_name text, pk_column_name text, pk_value text) returns meta.row_id as $_$ select meta.row_id(schema_name, relation_name, array[pk_column_name], array[pk_value]) $_$ immutable language sql;



-- helper function for iterating primary key arrays and generating a stmt fragment.
-- template is rendered by format(), using positional argument notation.
--     1: pk_column_names[i]
--     2: pk_values[i]
--     3: i
--
-- select _pk_stmt (
--     array['id','other_id'],
--     array[public.uuid_generate_v4()::text,public.uuid_generate_v4()::text],
--     '(row_id).pk_values[%3$s] = x.%1$I'
-- );
--                               _pk_stmt                               
-- ---------------------------------------------------------------------
--  (row_id).pk_values[1] = x.id and (row_id).pk_values[2] = x.other_id

create or replace function meta._pk_stmt(pk_column_names text[], pk_values text[], template text, delimeter text default ' and ') returns text as $$
    declare
        pk_comparisons text[];
        column_name text;
        i integer;
    begin
        i := 1;
        foreach column_name in array pk_column_names loop
            pk_comparisons[i] := format(template, pk_column_names[i], pk_values[i], i);
            i := i + 1;
        end loop;
        return array_to_string(pk_comparisons, delimeter);
    end
$$ language plpgsql;

/*
select meta._pk_stmt (
    meta.row_id(
        'public',
        'foo',
        array['id','other_id'],
        array[public.uuid_generate_v4()::text,public.uuid_generate_v4()::text]
    ),
    '(row_id).pk_values[%3$s] = x.%1$I',
	' OR '
);
                              _pk_stmt                              
--------------------------------------------------------------------
 (row_id).pk_values[1] = x.id OR (row_id).pk_values[2] = x.other_id
*/

create function meta._pk_stmt(row_id meta.row_id, template text, delimeter text default ' and ') returns text as $$
	select meta._pk_stmt((row_id).pk_column_names, (row_id).pk_values, template, delimeter);
$$ language sql;


