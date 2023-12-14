set search_path=meta;

-- for some reason, generator isn't generating these.  they're commented out.
create function meta.field_id_to_row_id(field_id meta.field_id) returns meta.row_id as $_$select meta.row_id((field_id).schema_name, (field_id).relation_name, (field_id).pk_column_name, (field_id).pk_value) $_$ immutable language sql;
create cast (meta.field_id as meta.row_id) with function meta.field_id_to_row_id(meta.field_id) as assignment;


-- single key row_id constructor
create function meta.row_id(schema_name text, relation_name text, pk_column_name text, pk_value text) returns meta.row_id as $_$ select meta.row_id(schema_name, relation_name, array[pk_column_name], array[pk_value]) $_$ immutable language sql;

