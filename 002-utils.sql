/*******************************************************************************
 * Meta Helper Utilities
 * Handy functions for working with meta-related stuff.
 *
 * Copyriright (c) 2019 - Aquameta - http://aquameta.org/
 ******************************************************************************/
create or replace function meta.row_exists(in row_id meta.row_id, out answer boolean) as $$
    declare
        stmt text;
    begin
        execute 'select (count(*) = 1) from ' || quote_ident((row_id::meta.schema_id).name) || '.' || quote_ident((row_id::meta.relation_id).name) ||
                ' where ' || quote_ident((row_id.pk_column_id).name) || ' = ' || quote_literal(row_id.pk_value)
            into answer;
    exception
        when others then answer := false;

    end;
$$ language plpgsql;


/*
create or replace function meta.row_delete(in row_id meta.row_id, out answer boolean) as $$
$$ language plpgsql;
*/
