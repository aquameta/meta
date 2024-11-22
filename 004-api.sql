create function meta.get_columns(_relation_id meta.relation_id) returns meta.column_id[] as $$
    select array_agg(id) from meta.column where relation_id=_relation_id order by position;
$$ language sql;
