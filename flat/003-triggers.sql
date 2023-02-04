/*******************************************************************************
 * Meta Triggers
 * Adds insert, update and delete triggers to the meta system catalog
 *
 * Copyriright (c) 2019 - Aquameta - http://aquameta.org/
 ******************************************************************************/

/******************************************************************************
 * utility functions
 *****************************************************************************/

create function meta2.require_all(fields public.hstore, required_fields text[]) returns void as $$
    declare
        f record;

    begin
        for f in select unnest(required_fields) as field_name loop
            if (fields operator(public.->) f.field_name) is null then
                raise exception '% is a required field.', f.field_name;
            end if;
        end loop;
    end;
$$ language plpgsql;


create function meta2.require_one(fields public.hstore, required_fields text[]) returns void as $$
    declare
        f record;

    begin
        for f in select unnest(required_fields) as field_name loop
            if (fields operator(public.->) f.field_name) is not null then
                return;
            end if;
        end loop;

        raise exception 'One of the fields % is required.', required_fields;
    end;
$$ language plpgsql;


/******************************************************************************
 * meta.schema
 *****************************************************************************/

create function meta2.stmt_schema_create(name text) returns text as $$
    select 'create schema ' || quote_ident(name)
$$ language sql;


create function meta2.stmt_schema_rename(old_name text, new_name text) returns text as $$
    select 'alter schema ' || quote_ident(old_name) || ' rename to ' || quote_ident(new_name);
$$ language sql;


create function meta2.stmt_schema_drop(name text) returns text as $$
    select 'drop schema ' || quote_ident(name);
$$ language sql;


create function meta2.schema_insert() returns trigger as $$
    begin
        perform meta2.require_all(public.hstore(NEW), array['name']);
        execute meta2.stmt_schema_create(NEW.name);
        NEW.id := row(NEW.name)::meta2.schema_id;
        return NEW;
    end;
$$ language plpgsql;


create function meta2.schema_update() returns trigger as $$
    begin
        perform meta2.require_all(public.hstore(NEW), array['name']);
        if OLD.name is distinct from NEW.name then
            execute meta2.stmt_schema_rename(OLD.name, NEW.name);
        end if;
        return NEW;
    end;
$$ language plpgsql;


create function meta2.schema_delete() returns trigger as $$
    begin
        execute meta2.stmt_schema_drop(OLD.name);
        return OLD;
    end;
$$ language plpgsql;


/******************************************************************************
 * meta.sequence
 *****************************************************************************/

create function meta2.stmt_sequence_create(
    schema_name text,
    name text,
    start_value bigint,
    minimum_value bigint,
    maximum_value bigint,
    increment bigint,
    cycle boolean
) returns text as $$
    select 'create sequence ' || quote_ident(schema_name) || '.' || quote_ident(name)
           || coalesce(' increment ' || increment, '')
           || coalesce(' minvalue ' || minimum_value, ' no minvalue ')
           || coalesce(' maxvalue ' || maximum_value, ' no maxvalue ')
           || coalesce(' start ' || start_value, '')
           || case cycle when true then ' cycle '
                         else ' no cycle '
              end;
$$ language sql;


create function meta2.stmt_sequence_set_schema(
    schema_name text,
    name text,
    new_schema_name text
) returns text as $$
    select 'alter sequence ' || quote_ident(schema_name) || '.' || quote_ident(name)
           || ' set schema ' || quote_ident(new_schema_name);
$$ language sql immutable;


create function meta2.stmt_sequence_rename(
    schema_name text,
    name text,
    new_name text
) returns text as $$
    select 'alter sequence ' || quote_ident(schema_name) || '.' || quote_ident(name)
           || ' rename to ' || quote_ident(new_name);
$$ language sql immutable;


create function meta2.stmt_sequence_alter(
    schema_name text,
    name text,
    start_value bigint,
    minimum_value bigint,
    maximum_value bigint,
    increment bigint,
    cycle boolean
) returns text as $$
    select 'alter sequence ' || quote_ident(schema_name) || '.' || quote_ident(name)
           || coalesce(' increment ' || increment, '')
           || coalesce(' minvalue ' || minimum_value, ' no minvalue ')
           || coalesce(' maxvalue ' || maximum_value, ' no maxvalue ')
           || coalesce(' start ' || start_value, '')
           || case cycle when true then ' cycle '
                         else ' no cycle '
              end;
$$ language sql;


create function meta2.stmt_sequence_drop(schema_name text, name text) returns text as $$
    select 'drop sequence ' || quote_ident(schema_name) || '.' || quote_ident(name);
$$ language sql;


create function meta2.sequence_insert() returns trigger as $$
    begin
        perform meta2.require_all(public.hstore(NEW), array['name']);
        perform meta2.require_one(public.hstore(NEW), array['schema_id', 'schema_name']);

        execute meta2.stmt_sequence_create(
            coalesce(NEW.schema_name, (NEW.schema_id).name),
            NEW.name,
            NEW.start_value,
            NEW.minimum_value,
            NEW.maximum_value,
            NEW.increment,
            NEW.cycle
        );

        NEW.id := meta2.sequence_id(
            coalesce(NEW.schema_name, (NEW.schema_id).name),
            NEW.name
        );

        return NEW;
    end;
$$ language plpgsql;


create function meta2.sequence_update() returns trigger as $$
    begin
        perform meta2.require_all(public.hstore(NEW), array['name']);

        if NEW.schema_id != OLD.schema_id or OLD.schema_name != NEW.schema_name then
            execute meta2.stmt_sequence_set_schema(OLD.schema_name, OLD.name, coalesce(nullif(NEW.schema_name, OLD.schema_name), (NEW.schema_id).name));
        end if;

        if NEW.name != OLD.name then
            execute meta2.stmt_sequence_rename(coalesce(nullif(NEW.schema_name, OLD.schema_name), (NEW.schema_id).name), OLD.name, NEW.name);
        end if;

        execute meta2.stmt_sequence_alter(
            coalesce(nullif(NEW.schema_name, OLD.schema_name), (NEW.schema_id).name),
            NEW.name,
            NEW.start_value,
            NEW.minimum_value,
            NEW.maximum_value,
            NEW.increment,
            NEW.cycle
        );

        return NEW;
    end;
$$ language plpgsql;


create function meta2.sequence_delete() returns trigger as $$
    begin
        execute meta2.stmt_sequence_drop(OLD.schema_name, OLD.name);
        return OLD;
    end;
$$ language plpgsql;


/******************************************************************************
 * meta.table
 *****************************************************************************/

create function meta2.stmt_table_create(schema_name text, table_name text) returns text as $$
    select 'create table ' || quote_ident(schema_name) || '.' || quote_ident(table_name) || '()'
$$ language sql;


create function meta2.stmt_table_set_schema(schema_name text, table_name text, new_schema_name text) returns text as $$
    select 'alter table ' || quote_ident(schema_name) || '.' || quote_ident(table_name) || ' set schema ' || quote_ident(new_schema_name);
$$ language sql;

create function meta2.stmt_table_enable_rowsecurity(schema_name text, table_name text) returns text as $$
    select 'alter table ' || quote_ident(schema_name) || '.' || quote_ident(table_name) || ' enable row level security'
$$ language sql;

create function meta2.stmt_table_disable_rowsecurity(schema_name text, table_name text) returns text as $$
    select 'alter table ' || quote_ident(schema_name) || '.' || quote_ident(table_name) || ' disable row level security'
$$ language sql;

create function meta2.stmt_table_rename(schema_name text, table_name text, new_table_name text) returns text as $$
    select 'alter table ' || quote_ident(schema_name) || '.' || quote_ident(table_name) || ' rename to ' || quote_ident(new_table_name);
$$ language sql;


create function meta2.stmt_table_drop(schema_name text, table_name text) returns text as $$
    select 'drop table ' || quote_ident(schema_name) || '.' || quote_ident(table_name);
$$ language sql;


create function meta2.table_insert() returns trigger as $$
    begin
        perform meta2.require_all(public.hstore(NEW), array['name']);
        perform meta2.require_one(public.hstore(NEW), array['schema_id', 'schema_name']);
        execute meta2.stmt_table_create(coalesce(NEW.schema_name, (NEW.schema_id).name),  NEW.name);
        if NEW.rowsecurity = true then
            execute meta2.stmt_table_enable_rowsecurity(NEW.schema_name, NEW.name);
        end if;

        NEW.id := row(row(coalesce(NEW.schema_name, (NEW.schema_id).name)), NEW.name)::meta2.relation_id;
        return NEW;
    end;
$$ language plpgsql;


create function meta2.table_update() returns trigger as $$
    begin
        perform meta2.require_all(public.hstore(NEW), array['name']);
        perform meta2.require_one(public.hstore(NEW), array['schema_id', 'schema_name']);

        if NEW.schema_id != OLD.schema_id or OLD.schema_name != NEW.schema_name then
            execute meta2.stmt_table_set_schema(OLD.schema_name, OLD.name, coalesce(nullif(NEW.schema_name, OLD.schema_name), (NEW.schema_id).name));
        end if;

        if NEW.name != OLD.name then
            execute meta2.stmt_table_rename(coalesce(nullif(NEW.schema_name, OLD.schema_name), (NEW.schema_id).name), OLD.name, NEW.name);
        end if;

        if NEW.rowsecurity != OLD.rowsecurity then
            if NEW.rowsecurity = true then
                execute meta2.stmt_table_enable_rowsecurity(NEW.schema_name, NEW.name);
            else
                execute meta2.stmt_table_disable_rowsecurity(NEW.schema_name, NEW.name);
            end if;
        end if;
        return NEW;
    end;
$$ language plpgsql;


create function meta2.table_delete() returns trigger as $$
    begin
        execute meta2.stmt_table_drop(OLD.schema_name, OLD.name);
        return OLD;
    end;
$$ language plpgsql;


/******************************************************************************
 * meta.view
 *****************************************************************************/

create function meta2.stmt_view_create(schema_name text, view_name text, query text) returns text as $$
    select 'create view ' || quote_ident(schema_name) || '.' || quote_ident(view_name) || ' as ' || query;
$$ language sql;


create function meta2.stmt_view_set_schema(schema_name text, view_name text, new_schema_name text) returns text as $$
    select 'alter view ' || quote_ident(schema_name) || '.' || quote_ident(view_name) || ' set schema ' || quote_ident(new_schema_name);
$$ language sql;


create function meta2.stmt_view_rename(schema_name text, view_name text, new_name text) returns text as $$
    select 'alter view ' || quote_ident(schema_name) || '.' || quote_ident(view_name) || ' rename to ' || quote_ident(new_name);
$$ language sql;


create function meta2.stmt_view_drop(schema_name text, view_name text) returns text as $$
    select 'drop view ' || quote_ident(schema_name) || '.' || quote_ident(view_name);
$$ language sql;


create function meta2.view_insert() returns trigger as $$
    begin
        perform meta2.require_all(public.hstore(NEW), array['name', 'query']);
        perform meta2.require_one(public.hstore(NEW), array['schema_id', 'schema_name']);

        execute meta2.stmt_view_create(coalesce(NEW.schema_name, (NEW.schema_id).name), NEW.name, NEW.query);

        return NEW;
    end;
$$ language plpgsql;


create function meta2.view_update() returns trigger as $$
    begin
        perform meta2.require_all(public.hstore(NEW), array['name', 'query']);
        perform meta2.require_one(public.hstore(NEW), array['schema_id', 'schema_name']);

        if NEW.schema_id != OLD.schema_id or NEW.schema_name != OLD.schema_name then
            execute meta2.stmt_view_set_schema(OLD.schema_name, OLD.name, coalesce(nullif(NEW.schema_name, OLD.schema_name), (NEW.schema_id).name));
        end if;

        if NEW.name != OLD.name then
            execute meta2.stmt_view_rename(coalesce(nullif(NEW.schema_name, OLD.schema_name), (NEW.schema_id).name), OLD.name, NEW.name);
        end if;

        if NEW.query != OLD.query then
            execute meta2.stmt_view_drop(coalesce(nullif(NEW.schema_name, OLD.schema_name), (NEW.schema_id).name), NEW.name);
            execute meta2.stmt_view_create(coalesce(nullif(NEW.schema_name, OLD.schema_name), (NEW.schema_id).name), NEW.name, NEW.query);
        end if;

        return NEW;
    end;
$$ language plpgsql;


create function meta2.view_delete() returns trigger as $$
    begin
        execute meta2.stmt_view_drop(OLD.schema_name, OLD.name);
        return OLD;
    end;
$$ language plpgsql;


/******************************************************************************
 * meta.column
 *****************************************************************************/

create function meta2.stmt_column_create(schema_name text, relation_name text, column_name text, type_name text, nullable boolean, "default" text, primary_key boolean) returns text as $$
    select 'alter table ' || quote_ident(schema_name) || '.' || quote_ident(relation_name) ||
           ' add column ' || quote_ident(column_name) || ' ' || type_name ||
           case when nullable then ''
                else ' not null'
           end ||
           case when "default" is not null and column_name != 'id' then (' default ' || "default" || '::' || type_name)
                else ''
           end ||
           case when primary_key then ' primary key'
                else ''
           end;
$$ language sql;


create function meta2.stmt_column_rename(schema_name text, relation_name text, column_name text, new_column_name text) returns text as $$
    select 'alter table ' || quote_ident(schema_name) || '.' || quote_ident(relation_name) ||
           ' rename column ' || quote_ident(column_name) || ' to ' || quote_ident(new_column_name);
$$ language sql;


create function meta2.stmt_column_add_primary_key(schema_name text, relation_name text, column_name text) returns text as $$
    select 'alter table ' || quote_ident(schema_name) || '.' || quote_ident(relation_name) ||
           ' add primary key (' || quote_ident(column_name) || ')';
$$ language sql;


create function meta2.stmt_column_drop_primary_key(schema_name text, relation_name text, column_name text) returns text as $$
    select 'alter table ' || quote_ident(schema_name) || '.' || quote_ident(relation_name) ||
           ' drop constraint ' || quote_ident(column_name) || '_pkey';
$$ language sql;


create function meta2.stmt_column_set_not_null(schema_name text, relation_name text, column_name text) returns text as $$
    select 'alter table ' || quote_ident(schema_name) || '.' || quote_ident(relation_name) ||
           ' alter column ' || quote_ident(column_name) || ' set not null';
$$ language sql;


create function meta2.stmt_column_drop_not_null(schema_name text, relation_name text, column_name text) returns text as $$
    select 'alter table ' || quote_ident(schema_name) || '.' || quote_ident(relation_name) ||
           ' alter column ' || quote_ident(column_name) || ' drop not null';
$$ language sql;


create function meta2.stmt_column_set_default(schema_name text, relation_name text, column_name text, "default" text, type_name text) returns text as $$
    select 'alter table ' || quote_ident(schema_name) || '.' || quote_ident(relation_name) ||
           ' alter column ' || quote_ident(column_name) || ' set default ' || "default" || '::' || type_name;
$$ language sql;


create function meta2.stmt_column_drop_default(schema_name text, relation_name text, column_name text) returns text as $$
    select 'alter table ' || quote_ident(schema_name) || '.' || quote_ident(relation_name) ||
           ' alter column ' || quote_ident(column_name) || ' drop default ';
$$ language sql;


create function meta2.stmt_column_set_type(schema_name text, relation_name text, column_name text, type_name text) returns text as $$
    select 'alter table ' || quote_ident(schema_name) || '.' || quote_ident(relation_name) ||
           ' alter column ' || quote_ident(column_name) || ' type ' || type_name;
$$ language sql;


create function meta2.stmt_column_drop(schema_name text, relation_name text, column_name text) returns text as $$
    select 'alter table ' || quote_ident(schema_name) || '.' || quote_ident(relation_name) ||
           ' drop column ' || quote_ident(column_name);
$$ language sql;


create function meta2.column_insert() returns trigger as $$
    begin
        perform meta2.require_all(public.hstore(NEW), array['name', 'type_name']);
        perform meta2.require_one(public.hstore(NEW), array['relation_id', 'schema_name']);
        perform meta2.require_one(public.hstore(NEW), array['relation_id', 'relation_name']);

        execute meta2.stmt_column_create(coalesce(NEW.schema_name, ((NEW.relation_id).schema_name)), coalesce(NEW.relation_name, (NEW.relation_id).name), NEW.name, NEW.type_name, NEW.nullable, NEW."default", NEW.primary_key);

        return NEW;
    end;
$$ language plpgsql;


create function meta2.column_update() returns trigger as $$
    declare
        schema_name text;
        relation_name text;

    begin
        perform meta2.require_all(public.hstore(NEW), array['name', 'type_name', 'nullable']);
        perform meta2.require_one(public.hstore(NEW), array['relation_id', 'schema_name']);
        perform meta2.require_one(public.hstore(NEW), array['relation_id', 'relation_name']);

        if NEW.relation_id is not null and OLD.relation_id != NEW.relation_id or
           NEW.schema_name is not null and OLD.schema_name != NEW.schema_name or
           NEW.relation_name is not null and OLD.relation_name != NEW.relation_name then

            raise exception 'Moving a column to another table is not yet supported.';
        end if;

        schema_name := OLD.schema_name;
        relation_name := OLD.relation_name;

        if NEW.name != OLD.name then
            execute meta2.stmt_column_rename(schema_name, relation_name, OLD.name, NEW.name);
        end if;

        if NEW.type_name != OLD.type_name then
            execute meta2.stmt_column_set_type(schema_name, relation_name, NEW.name, NEW.type_name);
        end if;

        if NEW.nullable != OLD.nullable then
            if NEW.nullable then
                execute meta2.stmt_column_drop_not_null(schema_name, relation_name, NEW.name);
            else
                execute meta2.stmt_column_set_not_null(schema_name, relation_name, NEW.name);
            end if;
        end if;

        if NEW."default" is distinct from OLD."default" then
            if NEW."default" is null then
                execute meta2.stmt_column_drop_default(schema_name, relation_name, NEW.name);
            else
                execute meta2.stmt_column_set_default(schema_name, relation_name, NEW.name, NEW."default", NEW."type_name");
            end if;
        end if;

        if NEW.primary_key != OLD.primary_key then
            if NEW.primary_key then
                execute meta2.stmt_column_add_primary_key(schema_name, relation_name, NEW.name);
            else
                execute meta2.stmt_column_drop_primary_key(schema_name, relation_name, NEW.name);
            end if;
        end if;

        return NEW;
    end;
$$ language plpgsql;


create function meta2.column_delete() returns trigger as $$
    begin
        execute meta2.stmt_column_drop(OLD.schema_name, OLD.relation_name, OLD.name);
        return OLD;
    end;
$$ language plpgsql;


/******************************************************************************
 * meta.foreign_key
 *****************************************************************************/

create function meta2.stmt_foreign_key_create(schema_name text, table_name text, constraint_name text, from_column_ids meta2.column_id[], to_column_ids meta2.column_id[], on_update text, on_delete text) returns text as $$
    select 'alter table ' || quote_ident(schema_name) || '.' || quote_ident(table_name) || ' add constraint ' || quote_ident(constraint_name) ||
           ' foreign key (' || (
               select string_agg(name, ', ')
               from meta2."column"
               where id = any(from_column_ids)

           ) || ') references ' || (to_column_ids[1]).schema_name || '.' || (to_column_ids[1]).relation_name || (
               select '(' || string_agg(c.name, ', ') || ')'
               from meta2."column" c
               where c.id = any(to_column_ids)

           ) || ' on update ' || on_update
             || ' on delete ' || on_delete;
$$ language sql;


create function meta2.stmt_foreign_key_drop(schema_name text, table_name text, constraint_name text) returns text as $$
    select 'alter table ' || quote_ident(schema_name) || '.' || quote_ident(table_name) || ' drop constraint ' || quote_ident(constraint_name);
$$ language sql;


create function meta2.foreign_key_insert() returns trigger as $$
    begin
        perform meta2.require_all(public.hstore(NEW), array['name', 'from_column_ids', 'to_column_ids', 'on_update', 'on_delete']);
        perform meta2.require_one(public.hstore(NEW), array['table_id', 'schema_name']);
        perform meta2.require_one(public.hstore(NEW), array['table_id', 'table_name']);

        execute meta2.stmt_foreign_key_create(
                    coalesce(NEW.schema_name, ((NEW.table_id).schema_name)),
                    coalesce(NEW.table_name, (NEW.table_id).name),
                    NEW.name, NEW.from_column_ids, NEW.to_column_ids, NEW.on_update, NEW.on_delete
                );
        return NEW;

    exception
        when null_value_not_allowed then
            raise exception 'A provided column_id was not found in meta.column.';
    end;
$$ language plpgsql;


create function meta2.foreign_key_update() returns trigger as $$
    begin
        perform meta2.require_all(public.hstore(NEW), array['name', 'from_column_ids', 'to_column_ids', 'on_update', 'on_delete']);
        perform meta2.require_one(public.hstore(NEW), array['table_id', 'schema_name']);
        perform meta2.require_one(public.hstore(NEW), array['table_id', 'table_name']);

        execute meta2.stmt_foreign_key_drop(OLD.schema_name, OLD.table_name, OLD.name);
        execute meta2.stmt_foreign_key_create(
                    coalesce(NEW.schema_name, ((NEW.table_id).schema_name)),
                    coalesce(NEW.table_name, (NEW.table_id).name),
                    NEW.name, NEW.from_column_ids, NEW.to_column_ids, NEW.on_update, NEW.on_delete
                );
        return NEW;

    exception
        when null_value_not_allowed then
            raise exception 'A provided column_id was not found in meta.column.';
    end;
$$ language plpgsql;


create function meta2.foreign_key_delete() returns trigger as $$
    begin
        execute meta2.stmt_foreign_key_drop(OLD.schema_name, OLD.table_name, OLD.name);
        return OLD;
    end;
$$ language plpgsql;


/******************************************************************************
 * meta.function
 *****************************************************************************/

create function meta2.stmt_function_create(schema_name text, function_name text, parameters text[], return_type text, definition text, language text) returns text as $$
    select 'create function ' || quote_ident(schema_name) || '.' || quote_ident(function_name) || '(' ||
            array_to_string(parameters, ',') || ') returns ' || return_type || ' as $body$' || definition || '$body$
            language ' || quote_ident(language) || ';';
$$ language sql;


create function meta2.stmt_function_drop(schema_name text, function_name text, parameters text[]) returns text as $$
    select 'drop function ' || quote_ident(schema_name) || '.' || quote_ident(function_name) || '(' ||
               array_to_string(parameters, ',') ||
           ');';
$$ language sql;


create function meta2.function_insert() returns trigger as $$
    begin
        perform meta2.require_all(public.hstore(NEW), array['name', 'parameters', 'return_type', 'definition', 'language']);
        perform meta2.require_one(public.hstore(NEW), array['schema_id', 'schema_name']);

        execute meta2.stmt_function_create(coalesce(NEW.schema_name, (NEW.schema_id).name), NEW.name, NEW.parameters, NEW.return_type, NEW.definition, NEW.language);

        return NEW;
    end;
$$ language plpgsql;


create function meta2.function_update() returns trigger as $$
    begin
        perform meta2.require_all(public.hstore(NEW), array['name', 'parameters', 'return_type', 'definition', 'language']);
        perform meta2.require_one(public.hstore(NEW), array['schema_id', 'schema_name']);

        execute meta2.stmt_function_drop(OLD.schema_name, OLD.name, OLD.parameters);
        execute meta2.stmt_function_create(coalesce(NEW.schema_name, (NEW.schema_id).name), NEW.name, NEW.parameters, NEW.return_type, NEW.definition, NEW.language);

        return NEW;
    end;
$$ language plpgsql;


create function meta2.function_delete() returns trigger as $$
    begin
        execute meta2.stmt_function_drop(OLD.schema_name, OLD.name, OLD.parameters);
        return OLD;
    end;
$$ language plpgsql;




/******************************************************************************
 * meta.type_definition
 *****************************************************************************/

create function meta2.stmt_type_definition_create(definition text) returns text as $$
    select definition;
$$ language sql;


create function meta2.stmt_type_definition_drop(type_id meta2.type_id) returns text as $$
    select 'drop type ' ||
        quote_ident((type_id).schema_name) || '.' ||
        quote_ident(type_id.name) || ';';
$$ language sql;


create function meta2.type_definition_insert() returns trigger as $$
    begin
        perform meta2.require_all(public.hstore(NEW), array['definition']);

        execute meta2.stmt_type_definition_create(NEW.definition);

        return NEW;
    end;
$$ language plpgsql;


create function meta2.type_definition_update() returns trigger as $$
    begin
        perform meta2.require_all(public.hstore(NEW), array['definition']);

        execute meta2.stmt_type_definition_drop(OLD.id);
        execute meta2.stmt_type_definition_create(NEW.definition);

        return NEW;
    end;
$$ language plpgsql;


create function meta2.type_definition_delete() returns trigger as $$
    begin
        execute meta2.stmt_type_definition_drop(OLD.id);
        return OLD;
    end;
$$ language plpgsql;




/******************************************************************************
 * meta.trigger
 *****************************************************************************/

create function meta2.stmt_trigger_create(schema_name text, relation_name text, trigger_name text, function_schema_name text, function_name text, "when" text, "insert" boolean, "update" boolean, "delete" boolean, "truncate" boolean, "level" text) returns text as $$
    select 'create trigger ' || quote_ident(trigger_name) || ' ' || "when" || ' ' ||
           array_to_string(
               array[]::text[]
               || case "insert" when true then 'insert'
                                    else null
                  end
               || case "update" when true then 'update'
                                    else null
                  end
               || case "delete" when true then 'delete'
                                    else null
                  end
               || case "truncate" when true then 'truncate'
                                      else null
                  end,
            ' or ') ||
            ' on ' || quote_ident(schema_name) || '.' || quote_ident(relation_name) ||
            ' for each ' || "level" || ' execute procedure ' ||
            quote_ident(function_schema_name) || '.' || quote_ident(function_name) || '()';
$$ language sql;


create function meta2.stmt_trigger_drop(schema_name text, relation_name text, trigger_name text) returns text as $$
    select 'drop trigger ' || quote_ident(trigger_name) || ' on ' || quote_ident(schema_name) || '.' || quote_ident(relation_name);
$$ language sql;


create function meta2.trigger_insert() returns trigger as $$
    begin
        perform meta2.require_all(public.hstore(NEW), array['name', 'when', 'level']);
        perform meta2.require_one(public.hstore(NEW), array['relation_id', 'schema_name']);
        perform meta2.require_one(public.hstore(NEW), array['relation_id', 'relation_name']);

        execute meta2.stmt_trigger_create(
                    coalesce(NEW.schema_name, ((NEW.relation_id).schema_name)),
                    coalesce(NEW.relation_name, (NEW.relation_id).name),
                    NEW.name,
                    ((NEW.function_id).schema_name),
                    (NEW.function_id).name,
                    NEW."when", NEW."insert", NEW."update", NEW."delete", NEW."truncate", NEW."level"
                );

        return NEW;
    end;
$$ language plpgsql;


create function meta2.trigger_update() returns trigger as $$
    begin
        perform meta2.require_all(public.hstore(NEW), array['name', 'when', 'level']);
        perform meta2.require_one(public.hstore(NEW), array['relation_id', 'schema_name']);
        perform meta2.require_one(public.hstore(NEW), array['relation_id', 'relation_name']);

        execute meta2.stmt_trigger_drop(OLD.schema_name, OLD.relation_name, OLD.name);
        execute meta2.stmt_trigger_create(
                    coalesce(nullif(NEW.schema_name, OLD.schema_name), ((NEW.relation_id).schema_name)),
                    coalesce(nullif(NEW.relation_name, OLD.relation_name), (NEW.relation_id).name),
                    NEW.name,
                    ((NEW.function_id).schema_name),
                    (NEW.function_id).name,
                    NEW."when", NEW."insert", NEW."update", NEW."delete", NEW."truncate", NEW."level"
                );

        return NEW;
    end;
$$ language plpgsql;


create function meta2.trigger_delete() returns trigger as $$
    begin
        execute meta2.stmt_trigger_drop(OLD.schema_name, OLD.relation_name, OLD.name);
        return OLD;
    end;
$$ language plpgsql;


/******************************************************************************
 * meta.role
 *****************************************************************************/

create function meta2.stmt_role_create(role_name text, superuser boolean, inherit boolean, create_role boolean, create_db boolean, can_login boolean, replication boolean, connection_limit integer, password text, valid_until timestamp with time zone) returns text as $$
    select  'create role ' || quote_ident(role_name) ||
            case when superuser then ' with superuser '
                                else ' with nosuperuser '
            end ||
            case when inherit then ' inherit '
                              else ' noinherit '
            end ||
            case when create_role then ' createrole '
                                  else ' nocreaterole '
            end ||
            case when create_db then ' createdb '
                                else ' nocreatedb '
            end ||
            case when can_login then ' login '
                                else ' nologin '
            end ||
            case when replication then ' replication '
                                  else ' noreplication '
            end ||
            coalesce(' connection limit ' || connection_limit, '') || -- can't take quoted literal
            coalesce(' password ' || quote_literal(password), '') ||
            coalesce(' valid until ' || quote_literal(valid_until), '');
$$ language sql;


create function meta2.stmt_role_rename(role_name text, new_role_name text) returns text as $$
    select 'alter role ' || quote_ident(role_name) || ' rename to ' || quote_ident(new_role_name);
$$ language sql;


create function meta2.stmt_role_alter(role_name text, superuser boolean, inherit boolean, create_role boolean, create_db boolean, can_login boolean, replication boolean, connection_limit integer, password text, valid_until timestamp with time zone) returns text as $$
    select  'alter role ' || quote_ident(role_name) ||
            case when superuser then ' with superuser '
                                else ' with nosuperuser '
            end ||
            case when inherit then ' inherit '
                              else ' noinherit '
            end ||
            case when create_role then ' createrole '
                                  else ' nocreaterole '
            end ||
            case when create_db then ' createdb '
                                else ' nocreatedb '
            end ||
            case when can_login then ' login '
                                else ' nologin '
            end ||
            case when replication then ' replication '
                                  else ' noreplication '
            end ||
            case when connection_limit is not null then ' connection limit ' || connection_limit -- can't take quoted literal
                                                   else ''
            end ||
            case when password is not null and password <> '********' then ' password ' || quote_literal(password)
                                           else ''
            end ||
            case when valid_until is not null then ' valid until ' || quote_literal(valid_until)
                                              else ''
            end;
$$ language sql;


create function meta2.stmt_role_reset(role_name text, config_param text) returns text as $$
    select 'alter role ' || quote_ident(role_name) || ' reset ' || config_param;
$$ language sql;


create function meta2.stmt_role_drop(role_name text) returns text as $$
    select 'drop role ' || quote_ident(role_name);
$$ language sql;


create function meta2.role_insert() returns trigger as $$
    begin
        perform meta2.require_all(public.hstore(NEW), array['name']);
        execute meta2.stmt_role_create(NEW.name, NEW.superuser, NEW.inherit, NEW.create_role, NEW.create_db, NEW.can_login, NEW.replication, NEW.connection_limit, NEW.password, NEW.valid_until);
        return NEW;
    end;
$$ language plpgsql;


create function meta2.role_update() returns trigger as $$
    begin
        perform meta2.require_all(public.hstore(NEW), array['name']);

        if OLD.name != NEW.name then
            execute meta2.stmt_role_rename(OLD.name, NEW.name);
        end if;

        execute meta2.stmt_role_alter(NEW.name, NEW.superuser, NEW.inherit, NEW.create_role, NEW.create_db, NEW.can_login, NEW.replication, NEW.connection_limit, NEW.password, NEW.valid_until);

        if OLD.connection_limit is not null and NEW.connection_limit is null then
            perform meta2.stmt_role_reset(NEW.name, 'connection limit');
        end if;

        if OLD.password is not null and NEW.password is null then
            perform meta2.stmt_role_reset(NEW.name, 'password');
        end if;

        if OLD.valid_until is not null and NEW.valid_until is null then
            perform meta2.stmt_role_reset(NEW.name, 'valid until');
        end if;

        return NEW;
    end;
$$ language plpgsql;


create function meta2.role_delete() returns trigger as $$
    begin
        execute meta2.stmt_role_drop(OLD.name);
        return OLD;
    end;
$$ language plpgsql;


create function meta2.current_role_id() returns meta2.role_id as $$
    select id from meta2.role where name=current_user;
$$ language sql;


/******************************************************************************
 * meta.role_inheritance
 *****************************************************************************/

create function meta2.stmt_role_inheritance_create(role_name text, member_role_name text) returns text as $$
    select  'grant ' || quote_ident(role_name) || ' to ' || quote_ident(member_role_name);
$$ language sql;


create function meta2.stmt_role_inheritance_drop(role_name text, member_role_name text) returns text as $$
    select 'revoke ' || quote_ident(role_name) || ' from ' || quote_ident(member_role_name);
$$ language sql;


create function meta2.role_inheritance_insert() returns trigger as $$
    begin

        perform meta2.require_one(public.hstore(NEW), array['role_name', 'role_id']);
        perform meta2.require_one(public.hstore(NEW), array['member_role_name', 'member_role_id']);

        execute meta2.stmt_role_inheritance_create(coalesce(NEW.role_name, (NEW.role_id).name), coalesce(NEW.member_role_name, (NEW.member_role_id).name));

        return NEW;
    end;
$$ language plpgsql;


create function meta2.role_inheritance_update() returns trigger as $$
    begin
        perform meta2.require_one(public.hstore(NEW), array['role_id', 'role_name']);
        perform meta2.require_one(public.hstore(NEW), array['member_role_id', 'member_role_name']);

        execute meta2.stmt_role_inheritance_drop((OLD.role_id).name, (OLD.member_role_id).name);
        execute meta2.stmt_role_inheritance_create(coalesce(NEW.role_name, (NEW.role_id).name), coalesce(NEW.member_role_name, (NEW.member_role_id).name));

        return NEW;
    end;
$$ language plpgsql;


create function meta2.role_inheritance_delete() returns trigger as $$
    begin
        execute meta2.stmt_role_inheritance_drop((OLD.role_id).name, (OLD.member_role_id).name);
        return OLD;
    end;
$$ language plpgsql;


/******************************************************************************
 * meta.table_privilege
 *****************************************************************************/

create function meta2.stmt_table_privilege_create(schema_name text, table_name text, role_name text, type text) returns text as $$
    -- TODO: create privilege_type so that "type" can be escaped here
    select 'grant ' || type || ' on ' || quote_ident(schema_name) || '.' || quote_ident(table_name) || ' to ' || quote_ident(role_name);
$$ language sql;


create function meta2.stmt_table_privilege_drop(schema_name text, table_name text, role_name text, type text) returns text as $$
    -- TODO: create privilege_type so that "type" can be escaped here
    select 'revoke ' || type || ' on ' || quote_ident(schema_name) || '.' || quote_ident(table_name) || ' from ' || quote_ident(role_name);
$$ language sql;


create function meta2.table_privilege_insert() returns trigger as $$
    begin
        perform meta2.require_one(public.hstore(NEW), array['role_id', 'role_name']);
        perform meta2.require_one(public.hstore(NEW), array['table_id', 'schema_name']);
        perform meta2.require_one(public.hstore(NEW), array['table_id', 'table_name']);
        perform meta2.require_all(public.hstore(NEW), array['type']);

        execute meta2.stmt_table_privilege_create(
        coalesce(NEW.schema_name, (NEW.table_id).schema_name),
        coalesce(NEW.table_name, (NEW.table_id).name),
        coalesce(NEW.role_name, (NEW.role_id).name),
        NEW.type);

        return NEW;
    end;
$$ language plpgsql;


create function meta2.table_privilege_update() returns trigger as $$
    begin
        perform meta2.require_one(public.hstore(NEW), array['role_id', 'role_name']);
        perform meta2.require_one(public.hstore(NEW), array['table_id', 'schema_name']);
        perform meta2.require_one(public.hstore(NEW), array['table_id', 'table_name']);
        perform meta2.require_all(public.hstore(NEW), array['type']);

        execute meta2.stmt_table_privilege_drop(OLD.schema_name, OLD.table_name, OLD.role_name, OLD.type);

        execute meta2.stmt_table_privilege_create(
        coalesce(NEW.schema_name, (NEW.table_id).schema_name),
        coalesce(NEW.table_name, (NEW.table_id).name),
        coalesce(NEW.role_name, (NEW.role_id).name),
        NEW.type);

        return NEW;
    end;
$$ language plpgsql;


create function meta2.table_privilege_delete() returns trigger as $$
    begin
        execute meta2.stmt_table_privilege_drop(OLD.schema_name, OLD.table_name, OLD.role_name, OLD.type);
        return OLD;
    end;
$$ language plpgsql;


/******************************************************************************
 * meta.policy
 *****************************************************************************/

create function meta2.stmt_policy_create(schema_name text, relation_name text, policy_name text, command meta2.siuda, "using" text, "check" text) returns text as $$
    select  'create policy ' || quote_ident(policy_name) || ' on ' || quote_ident(schema_name) || '.' || quote_ident(relation_name) ||
            case when command is not null then ' for ' || command::text
                      else ''
            end ||
            case when "using" is not null then ' using (' || "using" || ')'
                    else ''
            end ||
            case when "check" is not null then ' with check (' || "check" || ')'
                    else ''
            end;
$$ language sql;


create function meta2.stmt_policy_rename(schema_name text, relation_name text, policy_name text, new_policy_name text) returns text as $$
    select 'alter policy ' || quote_ident(policy_name) || ' on ' || quote_ident(schema_name) || '.' || quote_ident(relation_name) || ' rename to ' || quote_ident(new_policy_name);
$$ language sql;


create function meta2.stmt_policy_alter(schema_name text, relation_name text, policy_name text, "using" text, "check" text) returns text as $$
    select  'alter policy ' || quote_ident(policy_name) || ' on ' || quote_ident(schema_name) || '.' || quote_ident(relation_name) ||
            case when "using" is not null then ' using (' || "using" || ')'
                    else ''
            end ||
            case when "check" is not null then ' with check (' || "check" || ')'
                        else ''
            end;
$$ language sql;


create function meta2.stmt_policy_drop(schema_name text, relation_name text, policy_name text) returns text as $$
    select 'drop policy ' || quote_ident(policy_name) || ' on ' || quote_ident(schema_name) || '.' || quote_ident(relation_name);
$$ language sql;


create function meta2.policy_insert() returns trigger as $$
    begin
        perform meta2.require_all(public.hstore(NEW), array['name']);
        perform meta2.require_one(public.hstore(NEW), array['relation_id', 'schema_name']);
        perform meta2.require_one(public.hstore(NEW), array['relation_id', 'relation_name']);

        execute meta2.stmt_policy_create(coalesce(NEW.schema_name, ((NEW.relation_id).schema_name)), coalesce(NEW.relation_name, (NEW.relation_id).name), NEW.name, NEW.command, NEW."using", NEW."check");

        return NEW;
    end;
$$ language plpgsql;


create function meta2.policy_update() returns trigger as $$
    declare
    schema_name text;
    relation_name text;
    begin
        perform meta2.require_all(public.hstore(NEW), array['name']);

    -- could support moving policy to new relation, but is that useful?
        if NEW.relation_id is not null and OLD.relation_id != NEW.relation_id or
           NEW.schema_name is not null and OLD.schema_name != NEW.schema_name or
           NEW.relation_name is not null and OLD.relation_name != NEW.relation_name then

            raise exception 'Moving a policy to another table is not yet supported.';
        end if;

        if OLD.command != NEW.command then
            raise exception 'Postgres does not allow altering the type of command';
        end if;

        schema_name := OLD.schema_name;
        relation_name := OLD.relation_name;

        if OLD.name != NEW.name then
            execute meta2.stmt_policy_rename(schema_name, relation_name, OLD.name, NEW.name);
        end if;

        execute meta2.stmt_policy_alter(schema_name, relation_name, NEW.name, NEW."using", NEW."check");

        return NEW;
    end;
$$ language plpgsql;


create function meta2.policy_delete() returns trigger as $$
    begin
        execute meta2.stmt_policy_drop(OLD.schema_name, OLD.relation_name, OLD.name);
        return OLD;
    end;
$$ language plpgsql;


/******************************************************************************
 * meta.policy_role
 *****************************************************************************/

create function meta2.stmt_policy_role_create(schema_name text, relation_name text, policy_name text, role_name text) returns text as $$
    select  'alter policy ' || quote_ident(policy_name) || ' on ' || quote_ident(schema_name) || '.' || quote_ident(relation_name) ||
        ' to ' ||
        ( select array_to_string(
            array_append(
                array_remove(
                    array(
                        select distinct(unnest(polroles::regrole[]::text[]))
                                                from pg_policy p
                                                    join pg_class c on c.oid = p.polrelid
                                                    join pg_namespace n on n.oid = c.relnamespace
                        where polname = policy_name
                                                    and meta2.relation_id(n.nspname, c.relname) = meta2.relation_id(schema_name, relation_name)
                    ),
                '-'), -- Remove public from list of roles
            quote_ident(role_name)),
         ', '));
$$ language sql;


create function meta2.stmt_policy_role_drop(schema_name text, relation_name text, policy_name text, role_name text) returns text as $$
declare
    roles text;
begin
    select array_to_string(
        array_remove(
            array_remove(
                array(
                    select distinct(unnest(polroles::regrole[]::text[]))
                                        from pg_policy p
                                            join pg_class c on c.oid = p.polrelid
                                            join pg_namespace n on n.oid = c.relnamespace
                    where polname = policy_name
                                            and meta2.relation_id(n.nspname, c.relname) = meta2.relation_id(schema_name, relation_name)
                ),
            '-'), -- Remove public from list of roles
        role_name),
     ', ') into roles;

    if roles = '' then
        return  'alter policy ' || quote_ident(policy_name) || ' on ' || quote_ident(schema_name) || '.' || quote_ident(relation_name) || ' to public';
    else
        return  'alter policy ' || quote_ident(policy_name) || ' on ' || quote_ident(schema_name) || '.' || quote_ident(relation_name) || ' to ' || roles;
    end if;
end;
$$ language plpgsql;


create function meta2.policy_role_insert() returns trigger as $$
    begin

        perform meta2.require_one(public.hstore(NEW), array['policy_name', 'policy_id']);
        perform meta2.require_one(public.hstore(NEW), array['role_name', 'role_id']);
        perform meta2.require_one(public.hstore(NEW), array['policy_id', 'relation_id', 'relation_name']);
        perform meta2.require_one(public.hstore(NEW), array['policy_id', 'relation_id', 'schema_name']);

        execute meta2.stmt_policy_role_create(
        coalesce(NEW.schema_name, ((NEW.relation_id).schema_name), (((NEW.policy_id).relation_id).schema_name)),
        coalesce(NEW.relation_name, (NEW.relation_id).name, ((NEW.policy_id).relation_name)),
        coalesce(NEW.policy_name, (NEW.policy_id).name),
        coalesce(NEW.role_name, (NEW.role_id).name));

        return NEW;
    end;
$$ language plpgsql;


create function meta2.policy_role_update() returns trigger as $$
    declare
        schema_name text;
        relation_name text;
    begin
        perform meta2.require_one(public.hstore(NEW), array['policy_name', 'policy_id']);
        perform meta2.require_one(public.hstore(NEW), array['role_name', 'role_id']);
        perform meta2.require_one(public.hstore(NEW), array['policy_id', 'relation_id', 'relation_name']);
        perform meta2.require_one(public.hstore(NEW), array['policy_id', 'relation_id', 'schema_name']);

    -- delete old policy_role
        execute meta2.stmt_policy_role_drop((OLD.policy_id).schema_name, (OLD.policy_id).relation_name, (OLD.policy_id).name, (OLD.role_id).name);

    -- create new policy_role
        execute meta2.stmt_policy_role_create(
        coalesce(NEW.schema_name, (NEW.relation_id).schema_name, (NEW.policy_id).schema_name),
        coalesce(NEW.relation_name, (NEW.relation_id).name, (NEW.policy_id).relation_name),
        coalesce(NEW.policy_name, (NEW.policy_id).name),
        coalesce(NEW.role_name, (NEW.role_id).name));

        return NEW;

    end;
$$ language plpgsql;


create function meta2.policy_role_delete() returns trigger as $$
    begin
        execute meta2.stmt_policy_role_drop((OLD.policy_id).schema_name, (OLD.policy_id).relation_name, (OLD.policy_id).name, (OLD.role_id).name);
        return OLD;
    end;
$$ language plpgsql;



/******************************************************************************
 * meta.connection
 *****************************************************************************/

create function meta2.stmt_connection_delete(unix_pid integer) returns text as $$
    select 'select pg_terminate_backend( ' || unix_pid || ')'
$$ language sql;


create function meta2.connection_delete() returns trigger as $$
    begin
        execute meta2.stmt_connection_delete(OLD.unix_pid);
        return OLD;
    end;
$$ language plpgsql;

create function meta2.current_connection_id() returns meta2.connection_id as $$
    select id from meta2.connection where unix_pid=pg_backend_pid();
$$ language sql;



/******************************************************************************
 * meta.constraint_unique
 *****************************************************************************/
create function meta2.constraint_unique_create(schema_name text, table_name text, name text, column_names text[]) returns text as $$
    select 'alter table ' || quote_ident(schema_name) || '.' || quote_ident(table_name) || ' add constraint ' || quote_ident(name) ||
           ' unique(' || array_to_string(column_names, ', ') || ')';
$$ language sql;


create function meta2.constraint_unique_drop(schema_name text, table_name text, "name" text) returns text as $$
    select 'alter table ' || quote_ident(schema_name) || '.' || quote_ident(table_name) || ' drop constraint ' || quote_ident(name);
$$ language sql;


create function meta2.constraint_unique_insert() returns trigger as $$
    begin
        perform meta2.require_all(public.hstore(NEW), array['name']);
        perform meta2.require_one(public.hstore(NEW), array['table_id', 'schema_name']);
        perform meta2.require_one(public.hstore(NEW), array['table_id', 'table_name']);
        perform meta2.require_one(public.hstore(NEW), array['column_ids', 'column_names']);

        if array_length(NEW.column_names, 1) = 0 or array_length(NEW.column_ids, 1) = 0 then
            raise exception 'Unique constraints must have at least one column.';
        end if;

        execute meta2.constraint_unique_create(
                    coalesce(NEW.schema_name, (NEW.table_id).schema_name),
                    coalesce(NEW.table_name, (NEW.table_id).name),
                    NEW.name,
                    coalesce(NEW.column_names, (
                        select array_agg((column_id).name) as column_name
                        from (
                            select unnest(NEW.column_ids) as column_id
                        ) c
                    ))
                );

        return NEW;
    end;
$$ language plpgsql;


create function meta2.constraint_unique_update() returns trigger as $$
    begin
        perform meta2.require_all(public.hstore(NEW), array['name']);
        perform meta2.require_one(public.hstore(NEW), array['table_id', 'schema_name']);
        perform meta2.require_one(public.hstore(NEW), array['table_id', 'table_name']);
        perform meta2.require_one(public.hstore(NEW), array['column_ids', 'column_names']);

        if array_length(NEW.column_names, 1) = 0 or array_length(NEW.column_ids, 1) = 0 then
            raise exception 'Unique constraints must have at least one column.';
        end if;

        execute meta2.constraint_unique_drop(OLD.schema_name, OLD.table_name, OLD.name);
        execute meta2.constraint_unique_create(
                    coalesce(nullif(NEW.schema_name, OLD.schema_name), (NEW.table_id).schema_name),
                    coalesce(nullif(NEW.table_name, OLD.table_name), (NEW.table_id).name),
                    NEW.name,
                    coalesce(nullif(NEW.column_names, OLD.column_names), (
                        select array_agg((column_id).name) as column_name
                        from (
                            select unnest(NEW.column_ids) as column_id
                        ) c
                    ))
                );

        return NEW;
    end;
$$ language plpgsql;


create function meta2.constraint_unique_delete() returns trigger as $$
    begin
        execute meta2.constraint_unique_drop(OLD.schema_name, OLD.table_name, OLD.name);
        return OLD;
    end;
$$ language plpgsql;


/******************************************************************************
 * meta.constraint_check
 *****************************************************************************/

create function meta2.constraint_check_create(schema_name text, table_name text, name text, check_clause text) returns text as $$
    select 'alter table ' || quote_ident(schema_name) || '.' || quote_ident(table_name) || ' add constraint ' || quote_ident(name) ||
           ' check (' || check_clause || ')';
$$ language sql;


create function meta2.constraint_check_drop(schema_name text, table_name text, "name" text) returns text as $$
    select 'alter table ' || quote_ident(schema_name) || '.' || quote_ident(table_name) || ' drop constraint ' || quote_ident(name);
$$ language sql;


create function meta2.constraint_check_insert() returns trigger as $$
    begin
        perform meta2.require_all(public.hstore(NEW), array['name', 'check_clause']);
        perform meta2.require_one(public.hstore(NEW), array['table_id', 'schema_name']);
        perform meta2.require_one(public.hstore(NEW), array['table_id', 'table_name']);

        execute meta2.constraint_check_create(
                    coalesce(NEW.schema_name, (NEW.table_id).schema_name),
                    coalesce(NEW.table_name, (NEW.table_id).name),
                    NEW.name, NEW.check_clause
                );

        return NEW;
    end;
$$ language plpgsql;


create function meta2.constraint_check_update() returns trigger as $$
    begin
        perform meta2.require_all(public.hstore(NEW), array['name', 'check_clause']);
        perform meta2.require_one(public.hstore(NEW), array['table_id', 'schema_name']);
        perform meta2.require_one(public.hstore(NEW), array['table_id', 'table_name']);

        execute meta2.constraint_check_drop(OLD.schema_name, OLD.table_name, OLD.name);
        execute meta2.constraint_check_create(
                    coalesce(nullif(NEW.schema_name, OLD.schema_name), (NEW.table_id).schema_name),
                    coalesce(nullif(NEW.table_name, OLD.table_name), (NEW.table_id).name),
                    NEW.name, NEW.check_clause
                );

        return NEW;
    end;
$$ language plpgsql;


create function meta2.constraint_check_delete() returns trigger as $$
    begin
        execute meta2.constraint_check_drop(OLD.schema_name, OLD.table_name, OLD.name);
        return OLD;
    end;
$$ language plpgsql;


/******************************************************************************
 * meta.extension
 *****************************************************************************/

create function meta2.stmt_extension_create(
    schema_name text,
    name text,
    version text
) returns text as $$
    select 'create extension ' || quote_ident(name)
           || ' schema ' || quote_ident(schema_name)
           || coalesce(' version ' || version, '');
$$ language sql immutable;


create function meta2.stmt_extension_set_schema(
    name text,
    new_schema_name text
) returns text as $$
    select 'alter extension ' || quote_ident(name)
           || ' set schema ' || quote_ident(new_schema_name);
$$ language sql immutable;


create function meta2.stmt_extension_set_version(
    name text,
    version text
) returns text as $$
    select 'alter extension ' || quote_ident(name)
           || ' version ' || version;
$$ language sql;


create function meta2.stmt_extension_drop(schema_name text, name text) returns text as $$
    select 'drop extension ' || quote_ident(name);
$$ language sql;


create function meta2.extension_insert() returns trigger as $$
    begin
        perform meta2.require_all(public.hstore(NEW), array['name']);
        perform meta2.require_one(public.hstore(NEW), array['schema_id', 'schema_name']);

        execute meta2.stmt_extension_create(
            coalesce(NEW.schema_name, (NEW.schema_id).name),
            NEW.name,
            NEW.version
        );

        NEW.id := meta2.extension_id(NEW.name);

        return NEW;
    end;
$$ language plpgsql;


create function meta2.extension_update() returns trigger as $$
    begin
        perform meta2.require_all(public.hstore(NEW), array['name']);

        if NEW.schema_id != OLD.schema_id or OLD.schema_name != NEW.schema_name then
            execute meta2.stmt_extension_set_schema(OLD.name, coalesce(nullif(NEW.schema_name, OLD.schema_name), (NEW.schema_id).name));
        end if;

        if NEW.name != OLD.name then
            raise exception 'Extensions cannot be renamed.';
        end if;

        if NEW.version != OLD.version then
            execute meta2.stmt_extension_alter(NEW.name, NEW.version);
        end if;

        return NEW;
    end;
$$ language plpgsql;


create function meta2.extension_delete() returns trigger as $$
    begin
        execute meta2.stmt_extension_drop(OLD.schema_name, OLD.name);
        return OLD;
    end;
$$ language plpgsql;

/******************************************************************************
 * meta.foreign_data_wrapper
 *****************************************************************************/

create function meta2.stmt_foreign_data_wrapper_create(
    name text,
    handler_id meta2.function_id,
    validator_id meta2.function_id,
    options public.hstore
) returns text as $$
    select 'create foreign data wrapper ' || quote_ident(name)
           || coalesce(' handler ' || quote_ident((handler_id).schema_name) || '.'  || quote_ident((handler_id).name), ' no handler ')
           || coalesce(' validator ' || quote_ident((validator_id).schema_name) || '.'  || quote_ident((validator_id).name), ' no validator ')
           || coalesce(' options (' || (
               select string_agg(key || ' ' || quote_literal(value), ',') from public.each(options)
           ) || ')', '');
$$ language sql immutable;


create function meta2.stmt_foreign_data_wrapper_rename(
    name text,
    new_name text
) returns text as $$
    select 'alter foreign data wrapper ' || quote_ident(name) || ' rename to ' || quote_ident(new_name);
$$ language sql immutable;


create function meta2.stmt_foreign_data_wrapper_alter(
    name text,
    handler_id meta2.function_id,
    validator_id meta2.function_id
) returns text as $$
    select 'alter foreign data wrapper ' || quote_ident(name)
           || coalesce(' handler ' || quote_ident((handler_id).schema_name) || '.'  || quote_ident((handler_id).name), ' no handler ')
           || coalesce(' validator ' || quote_ident((validator_id).schema_name) || '.'  || quote_ident((validator_id).name), ' no validator ');
$$ language sql immutable;


create function meta2.stmt_foreign_data_wrapper_drop_options(
    name text,
    options public.hstore,
    new_options public.hstore
) returns text as $$
    select 'alter foreign data wrapper ' || quote_ident(name) || ' options (' || (
        select string_agg('drop ' || key, ',') from public.each(options::public.hstore OPERATOR(public.-) public.akeys(new_options)::public.hstore)
    ) || ')';
$$ language sql;


create function meta2.stmt_foreign_data_wrapper_set_options(
    name text,
    options public.hstore,
    new_options public.hstore
) returns text as $$
    select 'alter foreign data wrapper ' || quote_ident(name) || ' options (' || (
        select string_agg('set ' || key || ' ' || quote_literal(value), ',')
        from public.each(new_options) where options operator(public.?) key
    ) || ')';
$$ language sql;


create function meta2.stmt_foreign_data_wrapper_add_options(
    name text,
    options public.hstore,
    new_options public.hstore
) returns text as $$
    select 'alter foreign data wrapper ' || quote_ident(name) || ' options (' || (
        select string_agg('add ' || key || ' ' || quote_literal(value), ',')
        from public.each(new_options operator(public.-) public.akeys(options))
    ) || ')';
$$ language sql;


create function meta2.stmt_foreign_data_wrapper_drop(name text) returns text as $$
    select 'drop foreign data wrapper ' || quote_ident(name);
$$ language sql;


create function meta2.foreign_data_wrapper_insert() returns trigger as $$
    begin
        perform meta2.require_all(public.hstore(NEW), array['name']);

        execute meta2.stmt_foreign_data_wrapper_create(
            NEW.name,
            NEW.handler_id,
            NEW.validator_id,
            NEW.options
        );

        NEW.id := meta2.foreign_data_wrapper_id(NEW.name);

        return NEW;
    end;
$$ language plpgsql;


create function meta2.foreign_data_wrapper_update() returns trigger as $$
    begin
        perform meta2.require_all(public.hstore(NEW), array['name']);

        if NEW.name != OLD.name then
            execute meta2.stmt_foreign_data_wrapper_rename(OLD.name, NEW.name);
        end if;

        if NEW.options != OLD.options then
            execute meta2.stmt_foreign_data_wrapper_drop_options(NEW.name, OLD.options, NEW.options);
            execute meta2.stmt_foreign_data_wrapper_set_options(NEW.name, OLD.options, NEW.options);
            execute meta2.stmt_foreign_data_wrapper_add_options(NEW.name, OLD.options, NEW.options);
        end if;

        execute meta2.stmt_foreign_data_wrapper_alter(NEW.name, NEW.handler_id, NEW.validator_id);

        return NEW;
    end;
$$ language plpgsql;


create function meta2.foreign_data_wrapper_delete() returns trigger as $$
    begin
        execute meta2.stmt_foreign_data_wrapper_drop(OLD.name);
        return OLD;
    end;
$$ language plpgsql;



/******************************************************************************
 * meta.foreign_server
 *****************************************************************************/

create function meta2.stmt_foreign_server_create(
    foreign_data_wrapper_id meta2.foreign_data_wrapper_id,
    name text,
    "type" text,
    version text,
    options public.hstore
) returns text as $$
    select 'create server ' || quote_ident(name)
           || coalesce(' type ' || quote_literal("type"), '')
           || coalesce(' version ' || quote_literal(version), '')
           || ' foreign data wrapper ' || quote_ident((foreign_data_wrapper_id).name)
           || coalesce(' options (' || (
               select string_agg(key || ' ' || quote_literal(value), ',') from public.each(options)
           ) || ')', '');
$$ language sql immutable;


create function meta2.stmt_foreign_server_rename(
    name text,
    new_name text
) returns text as $$
    select 'alter server ' || quote_ident(name) || ' rename to ' || quote_ident(new_name);
$$ language sql immutable;


create function meta2.stmt_foreign_server_set_version(
    name text,
    version text
) returns text as $$
    select 'alter server ' || quote_ident(name) || ' version ' || quote_literal(version);
$$ language sql immutable;


create function meta2.stmt_foreign_server_drop_options(
    name text,
    options public.hstore,
    new_options public.hstore
) returns text as $$
    select 'alter server ' || quote_ident(name) || ' options (' || (
        select string_agg('drop ' || key, ',') from public.each(options operator(public.-) public.akeys(new_options))
    ) || ')';
$$ language sql;


create function meta2.stmt_foreign_server_set_options(
    name text,
    options public.hstore,
    new_options public.hstore
) returns text as $$
    select 'alter server ' || quote_ident(name) || ' options (' || (
        select string_agg('set ' || key || ' ' || quote_literal(value), ',')
        from public.each(new_options) where options operator(public.?) key
    ) || ')';
$$ language sql;


create function meta2.stmt_foreign_server_add_options(
    name text,
    options public.hstore,
    new_options public.hstore
) returns text as $$
    select 'alter server ' || quote_ident(name) || ' options (' || (
        select string_agg('add ' || key || ' ' || quote_literal(value), ',')
        from public.each(new_options operator(public.-) public.akeys(options))
    ) || ')';
$$ language sql;


create function meta2.stmt_foreign_server_drop(name text) returns text as $$
    select 'drop server ' || quote_ident(name);
$$ language sql;


create function meta2.foreign_server_insert() returns trigger as $$
    begin
        perform meta2.require_all(public.hstore(NEW), array['name']);

        execute meta2.stmt_foreign_server_create(
            NEW.foreign_data_wrapper_id,
            NEW.name,
            NEW."type",
            NEW.version,
            NEW.options
        );

        NEW.id := meta2.foreign_server_id(NEW.name);

        return NEW;
    end;
$$ language plpgsql;


create function meta2.foreign_server_update() returns trigger as $$
    begin
        perform meta2.require_all(public.hstore(NEW), array['name']);

        if NEW.name != OLD.name then
            execute meta2.stmt_foreign_server_rename(OLD.name, NEW.name);
        end if;

        if NEW.foreign_data_wrapper_id is distinct from OLD.foreign_data_wrapper_id then
            raise exception 'Server''s foreign data wrapper cannot be altered.';
        end if;

        if NEW.type is distinct from OLD.type then
            raise exception 'Server type cannot be altered.';
        end if;

        if NEW.version is distinct from OLD.version then
            execute meta2.stmt_foreign_server_set_version(NEW.name, NEW.version);
        end if;

        if NEW.options is distinct from OLD.options then
            execute meta2.stmt_foreign_server_drop_options(NEW.name, OLD.options, NEW.options);
            execute meta2.stmt_foreign_server_set_options(NEW.name, OLD.options, NEW.options);
            execute meta2.stmt_foreign_server_add_options(NEW.name, OLD.options, NEW.options);
        end if;

        return NEW;
    end;
$$ language plpgsql;


create function meta2.foreign_server_delete() returns trigger as $$
    begin
        execute meta2.stmt_foreign_server_drop(OLD.name);
        return OLD;
    end;
$$ language plpgsql;



/******************************************************************************
 * meta.foreign_table
 *****************************************************************************/

create function meta2.stmt_foreign_table_create(
    foreign_server_id meta2.foreign_server_id,
    schema_name text,
    name text,
    options public.hstore
) returns text as $$
    select 'create foreign table ' || quote_ident(schema_name) || '.' || quote_ident(name) || '()'
           || ' server ' || quote_ident((foreign_server_id).name)
           || coalesce(' options (' || (
               select string_agg(key || ' ' || quote_literal(value), ',')
               from public.each(options)
           ) || ')', '');
$$ language sql;


create function meta2.stmt_foreign_table_set_schema(
    schema_name text,
    name text,
    new_schema_name text
) returns text as $$
    select 'alter foreign table ' || quote_ident(schema_name) || '.' || quote_ident(name)
           || ' set schema ' || quote_ident(new_schema_name);
$$ language sql;


create function meta2.stmt_foreign_table_drop_options(
    schema_name text,
    name text,
    options public.hstore,
    new_options public.hstore
) returns text as $$
    select 'alter foreign table ' || quote_ident(schema_name) || '.' || quote_ident(name) || ' options (' || (
        select string_agg('drop ' || key, ',') from public.each(options operator(public.-) public.akeys(new_options))
    ) || ')';
$$ language sql;


create function meta2.stmt_foreign_table_set_options(
    schema_name text,
    name text,
    options public.hstore,
    new_options public.hstore
) returns text as $$
    select 'alter foreign table ' || quote_ident(schema_name) || '.' || quote_ident(name) || ' options (' || (
        select string_agg('set ' || key || ' ' || quote_literal(value), ',')
        from public.each(new_options) where options operator(public.?) key
    ) || ')';
$$ language sql;


create function meta2.stmt_foreign_table_add_options(
    schema_name text,
    name text,
    options public.hstore,
    new_options public.hstore
) returns text as $$
    select 'alter foreign table ' || quote_ident(schema_name) || '.' || quote_ident(name) || ' options (' || (
        select string_agg('add ' || key || ' ' || quote_literal(value), ',')
        from public.each(new_options operator(public.-) public.akeys(options))
    ) || ')';
$$ language sql;


create function meta2.stmt_foreign_table_rename(
    schema_name text,
    name text,
    new_name text
) returns text as $$
    select 'alter table ' || quote_ident(schema_name) || '.' || quote_ident(name)
           || ' rename to ' || quote_ident(new_name);
$$ language sql;


create function meta2.stmt_foreign_table_drop(schema_name text, name text) returns text as $$
    select 'drop foreign table ' || quote_ident(schema_name) || '.' || quote_ident(name);
$$ language sql;


create function meta2.foreign_table_insert() returns trigger as $$
    begin
        perform meta2.require_all(public.hstore(NEW), array['foreign_server_id', 'name']);
        perform meta2.require_one(public.hstore(NEW), array['schema_id', 'schema_name']);

        execute meta2.stmt_foreign_table_create(
            NEW.foreign_server_id,
            coalesce(NEW.schema_name, (NEW.schema_id).name),
            NEW.name,
            NEW.options
        );

        NEW.id := meta2.relation_id(coalesce(NEW.schema_name, (NEW.schema_id).name), NEW.name);

        return NEW;
    end;
$$ language plpgsql;


create function meta2.foreign_table_update() returns trigger as $$
    begin
        perform meta2.require_all(public.hstore(NEW), array['foreign_server_id', 'name']);
        perform meta2.require_one(public.hstore(NEW), array['schema_id', 'schema_name']);

        if NEW.schema_id != OLD.schema_id or OLD.schema_name != NEW.schema_name then
            execute meta2.stmt_foreign_table_set_schema(OLD.schema_name, OLD.name, coalesce(nullif(NEW.schema_name, OLD.schema_name), (NEW.schema_id).name));
        end if;

        if NEW.foreign_server_id != OLD.foreign_server_id then
            raise exception 'A foreign table''s server cannot be altered.';
        end if;

        if NEW.name != OLD.name then
            execute meta2.stmt_foreign_table_rename(coalesce(nullif(NEW.schema_name, OLD.schema_name), (NEW.schema_id).name), OLD.name, NEW.name);
        end if;

        if NEW.options is distinct from OLD.options then
            execute meta2.stmt_foreign_table_drop_options(coalesce(nullif(NEW.schema_name, OLD.schema_name), (NEW.schema_id).name), NEW.name, OLD.options, NEW.options);
            execute meta2.stmt_foreign_table_set_options(coalesce(nullif(NEW.schema_name, OLD.schema_name), (NEW.schema_id).name), NEW.name, OLD.options, NEW.options);
            execute meta2.stmt_foreign_table_add_options(coalesce(nullif(NEW.schema_name, OLD.schema_name), (NEW.schema_id).name), NEW.name, OLD.options, NEW.options);
        end if;

        return NEW;
    end;
$$ language plpgsql;


create function meta2.foreign_table_delete() returns trigger as $$
    begin
        execute meta2.stmt_foreign_table_drop(OLD.schema_name, OLD.name);
        return OLD;
    end;
$$ language plpgsql;



/******************************************************************************
 * meta.foreign_column
 *****************************************************************************/

create function meta2.stmt_foreign_column_create(
    schema_name text,
    relation_name text,
    name text,
    "type" text,
    nullable boolean
) returns text as $$
    select 'alter foreign table ' || quote_ident(schema_name) || '.' || quote_ident(relation_name)
           || ' add column ' || quote_ident(name) || ' ' || "type" || ' '
           || case when nullable then ' null'
                   else ' not null '
              end;
$$ language sql;


create function meta2.stmt_foreign_column_set_not_null(schema_name text, relation_name text, name text) returns text as $$
    select 'alter foreign table ' || quote_ident(schema_name) || '.' || quote_ident(relation_name) ||
           ' alter column ' || quote_ident(name) || ' set not null';
$$ language sql;


create function meta2.stmt_foreign_column_rename(schema_name text, relation_name text, name text, new_name text) returns text as $$
    select 'alter foreign table ' || quote_ident(schema_name) || '.' || quote_ident(relation_name) ||
           ' rename column ' || quote_ident(name) || ' to ' || quote_ident(new_name);
$$ language sql;


create function meta2.stmt_foreign_column_drop_not_null(schema_name text, relation_name text, name text) returns text as $$
    select 'alter foreign table ' || quote_ident(schema_name) || '.' || quote_ident(relation_name) ||
           ' alter column ' || quote_ident(name) || ' drop not null';
$$ language sql;


create function meta2.stmt_foreign_column_set_type(schema_name text, relation_name text, name text, "type" text) returns text as $$
    select 'alter foreign table ' || quote_ident(schema_name) || '.' || quote_ident(relation_name) ||
           ' alter column ' || quote_ident(name) || ' type ' || "type";
$$ language sql;


create function meta2.stmt_foreign_column_drop(
    schema_name text,
    relation_name text,
    name text
) returns text as $$
    select 'alter foreign table ' || quote_ident(schema_name) || '.' || quote_ident(relation_name)
           || ' drop column ' || quote_ident(name);
$$ language sql;


create function meta2.foreign_column_insert() returns trigger as $$
    begin
        perform meta2.require_all(public.hstore(NEW), array['name', 'type']);
        perform meta2.require_one(public.hstore(NEW), array['foreign_table_id', 'schema_name']);
        perform meta2.require_one(public.hstore(NEW), array['foreign_table_id', 'relation_name']);

        execute meta2.stmt_foreign_column_create(
            coalesce(NEW.schema_name, (NEW.foreign_table_id).schema_name),
            coalesce(NEW.foreign_table_name, (NEW.foreign_table_id).name),
            NEW.name,
            NEW.type,
            NEW.nullable
        );

        return NEW;
    end;
$$ language plpgsql;


create function meta2.foreign_column_update() returns trigger as $$
    declare
        schema_name text;
        foreign_table_name text;

    begin
        perform meta2.require_all(public.hstore(NEW), array['name', 'type']);
        perform meta2.require_one(public.hstore(NEW), array['foreign_table_id', 'schema_name']);
        perform meta2.require_one(public.hstore(NEW), array['foreign_table_id', 'relation_name']);


        if NEW.foreign_table_id is not null and OLD.foreign_table_id != NEW.foreign_table_id or
           NEW.schema_name is not null and OLD.schema_name != NEW.schema_name or
           NEW.foreign_table_name is not null and OLD.foreign_table_name != NEW.foreign_table_name then

            raise exception 'Moving a column to another foreign table is not supported.';
        end if;

        schema_name := OLD.schema_name;
        foreign_table_name := OLD.foreign_table_name;

        if NEW.name != OLD.name then
            execute meta2.stmt_foreign_column_rename(schema_name, foreign_table_name, OLD.name, NEW.name);
        end if;

        if NEW."type" != OLD."type" then
            execute meta2.stmt_foreign_column_set_type(schema_name, foreign_table_name, NEW.name, NEW."type");
        end if;

        if NEW.nullable != OLD.nullable then
            if NEW.nullable then
                execute meta2.stmt_foreign_column_drop_not_null(schema_name, foreign_table_name, NEW.name);
            else
                execute meta2.stmt_foreign_column_set_not_null(schema_name, foreign_table_name, NEW.name);
            end if;
        end if;

        return NEW;
    end;
$$ language plpgsql;


create function meta2.foreign_column_delete() returns trigger as $$
    begin
        execute meta2.stmt_foreign_column_drop(OLD.schema_name, OLD.foreign_table_name, OLD.name);
        return OLD;
    end;
$$ language plpgsql;




/******************************************************************************
 * View triggers
 *****************************************************************************/
-- SCHEMA
create trigger meta_schema_insert_trigger instead of insert on meta2.schema for each row execute procedure meta2.schema_insert();
create trigger meta_schema_update_trigger instead of update on meta2.schema for each row execute procedure meta2.schema_update();
create trigger meta_schema_delete_trigger instead of delete on meta2.schema for each row execute procedure meta2.schema_delete();

-- SEQUENCE
create trigger meta_sequence_insert_trigger instead of insert on meta2.sequence for each row execute procedure meta2.sequence_insert();
create trigger meta_sequence_update_trigger instead of update on meta2.sequence for each row execute procedure meta2.sequence_update();
create trigger meta_sequence_delete_trigger instead of delete on meta2.sequence for each row execute procedure meta2.sequence_delete();

-- TABLE
create trigger meta_table_insert_trigger instead of insert on meta2.table for each row execute procedure meta2.table_insert();
create trigger meta_table_update_trigger instead of update on meta2.table for each row execute procedure meta2.table_update();
create trigger meta_table_delete_trigger instead of delete on meta2.table for each row execute procedure meta2.table_delete();

-- VIEW
create trigger meta_view_insert_trigger instead of insert on meta2.view for each row execute procedure meta2.view_insert();
create trigger meta_view_update_trigger instead of update on meta2.view for each row execute procedure meta2.view_update();
create trigger meta_view_delete_trigger instead of delete on meta2.view for each row execute procedure meta2.view_delete();

-- COLUMN
create trigger meta_column_insert_trigger instead of insert on meta2.column for each row execute procedure meta2.column_insert();
create trigger meta_column_update_trigger instead of update on meta2.column for each row execute procedure meta2.column_update();
create trigger meta_column_delete_trigger instead of delete on meta2.column for each row execute procedure meta2.column_delete();

-- FOREIGN KEY
create trigger meta_foreign_key_insert_trigger instead of insert on meta2.foreign_key for each row execute procedure meta2.foreign_key_insert();
create trigger meta_foreign_key_update_trigger instead of update on meta2.foreign_key for each row execute procedure meta2.foreign_key_update();
create trigger meta_foreign_key_delete_trigger instead of delete on meta2.foreign_key for each row execute procedure meta2.foreign_key_delete();

-- FUNCTION
create trigger meta_function_insert_trigger instead of insert on meta2.function for each row execute procedure meta2.function_insert();
create trigger meta_function_update_trigger instead of update on meta2.function for each row execute procedure meta2.function_update();
create trigger meta_function_delete_trigger instead of delete on meta2.function for each row execute procedure meta2.function_delete();

-- ROLE
create trigger meta_role_insert_trigger instead of insert on meta2.role for each row execute procedure meta2.role_insert();
create trigger meta_role_update_trigger instead of update on meta2.role for each row execute procedure meta2.role_update();
create trigger meta_role_delete_trigger instead of delete on meta2.role for each row execute procedure meta2.role_delete();

-- ROLE INHERITANCE
create trigger meta_role_inheritance_insert_trigger instead of insert on meta2.role_inheritance for each row execute procedure meta2.role_inheritance_insert();
create trigger meta_role_inheritance_update_trigger instead of update on meta2.role_inheritance for each row execute procedure meta2.role_inheritance_update();
create trigger meta_role_inheritance_delete_trigger instead of delete on meta2.role_inheritance for each row execute procedure meta2.role_inheritance_delete();

-- TABLE PRIVILEGE
create trigger meta_table_privilege_insert_trigger instead of insert on meta2.table_privilege for each row execute procedure meta2.table_privilege_insert();
create trigger meta_table_privilege_update_trigger instead of update on meta2.table_privilege for each row execute procedure meta2.table_privilege_update();
create trigger meta_table_privilege_delete_trigger instead of delete on meta2.table_privilege for each row execute procedure meta2.table_privilege_delete();

-- POLICY
create trigger meta_policy_insert_trigger instead of insert on meta2.policy for each row execute procedure meta2.policy_insert();
create trigger meta_policy_update_trigger instead of update on meta2.policy for each row execute procedure meta2.policy_update();
create trigger meta_policy_delete_trigger instead of delete on meta2.policy for each row execute procedure meta2.policy_delete();

-- POLICY ROLE
create trigger meta_policy_role_insert_trigger instead of insert on meta2.policy_role for each row execute procedure meta2.policy_role_insert();
create trigger meta_policy_role_update_trigger instead of update on meta2.policy_role for each row execute procedure meta2.policy_role_update();
create trigger meta_policy_role_delete_trigger instead of delete on meta2.policy_role for each row execute procedure meta2.policy_role_delete();

-- CONNECTION
create trigger meta_connection_delete_trigger instead of delete on meta2.connection for each row execute procedure meta2.connection_delete();

-- CONSTRAINT UNIQUE
create trigger meta_constraint_unique_insert_trigger instead of insert on meta2.constraint_unique for each row execute procedure meta2.constraint_unique_insert();
create trigger meta_constraint_unique_update_trigger instead of update on meta2.constraint_unique for each row execute procedure meta2.constraint_unique_update();
create trigger meta_constraint_unique_delete_trigger instead of delete on meta2.constraint_unique for each row execute procedure meta2.constraint_unique_delete();

-- CONSTRAINT CHECK
create trigger meta_constraint_check_insert_trigger instead of insert on meta2.constraint_check for each row execute procedure meta2.constraint_check_insert();
create trigger meta_constraint_check_update_trigger instead of update on meta2.constraint_check for each row execute procedure meta2.constraint_check_update();
create trigger meta_constraint_check_delete_trigger instead of delete on meta2.constraint_check for each row execute procedure meta2.constraint_check_delete();

-- TRIGGER
create trigger meta_trigger_insert_trigger instead of insert on meta2.trigger for each row execute procedure meta2.trigger_insert();
create trigger meta_trigger_update_trigger instead of update on meta2.trigger for each row execute procedure meta2.trigger_update();
create trigger meta_trigger_delete_trigger instead of delete on meta2.trigger for each row execute procedure meta2.trigger_delete();

-- EXTENSION
create trigger meta_extension_insert_trigger instead of insert on meta2.extension for each row execute procedure meta2.extension_insert();
create trigger meta_extension_update_trigger instead of update on meta2.extension for each row execute procedure meta2.extension_update();
create trigger meta_extension_delete_trigger instead of delete on meta2.extension for each row execute procedure meta2.extension_delete();

-- FOREIGN DATA WRAPPER
create trigger meta_foreign_data_wrapper_insert_trigger instead of insert on meta2.foreign_data_wrapper for each row execute procedure meta2.foreign_data_wrapper_insert();
create trigger meta_foreign_data_wrapper_update_trigger instead of update on meta2.foreign_data_wrapper for each row execute procedure meta2.foreign_data_wrapper_update();
create trigger meta_foreign_data_wrapper_delete_trigger instead of delete on meta2.foreign_data_wrapper for each row execute procedure meta2.foreign_data_wrapper_delete();

-- FOREIGN SERVER
create trigger meta_foreign_server_insert_trigger instead of insert on meta2.foreign_server for each row execute procedure meta2.foreign_server_insert();
create trigger meta_foreign_server_update_trigger instead of update on meta2.foreign_server for each row execute procedure meta2.foreign_server_update();
create trigger meta_foreign_server_delete_trigger instead of delete on meta2.foreign_server for each row execute procedure meta2.foreign_server_delete();

-- FOREIGN TABLE
create trigger meta_foreign_table_insert_trigger instead of insert on meta2.foreign_table for each row execute procedure meta2.foreign_table_insert();
create trigger meta_foreign_table_update_trigger instead of update on meta2.foreign_table for each row execute procedure meta2.foreign_table_update();
create trigger meta_foreign_table_delete_trigger instead of delete on meta2.foreign_table for each row execute procedure meta2.foreign_table_delete();

-- FOREIGN COLUMN
create trigger meta_foreign_column_insert_trigger instead of insert on meta2.foreign_column for each row execute procedure meta2.foreign_column_insert();
create trigger meta_foreign_column_update_trigger instead of update on meta2.foreign_column for each row execute procedure meta2.foreign_column_update();
create trigger meta_foreign_column_delete_trigger instead of delete on meta2.foreign_column for each row execute procedure meta2.foreign_column_delete();
