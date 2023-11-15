create type meta.cast_id as (source_type_schema_name text,source_type_name text,target_type_schema_name text,target_type_name text);
create function meta.cast_id(source_type_schema_name text,source_type_name text,target_type_schema_name text,target_type_name text) returns meta.cast_id as $_$ select row(source_type_schema_name,source_type_name,target_type_schema_name,target_type_name)::meta.cast_id $_$ language sql immutable;
create function meta.meta_id(cast_id meta.cast_id) returns meta.meta_id as $_$ select meta.meta_id('cast'); $_$ language sql;
create function meta.eq(leftarg meta.cast_id, rightarg json) returns boolean as $_$select ((leftarg).source_type_schema_name)::text = ((rightarg)->>'source_type_schema_name')::text and ((leftarg).source_type_name)::text = ((rightarg)->>'source_type_name')::text and ((leftarg).target_type_schema_name)::text = ((rightarg)->>'target_type_schema_name')::text and ((leftarg).target_type_name)::text = ((rightarg)->>'target_type_name')::text$_$ language sql;
create operator meta.= (leftarg = meta.cast_id, rightarg = json, procedure = meta.eq);
create function meta.cast_id(value json) returns meta.cast_id as $_$select meta.cast_id((value->>'source_type_schema_name')::text, (value->>'source_type_name')::text, (value->>'target_type_schema_name')::text, (value->>'target_type_name')::text) $_$ immutable language sql;
create cast (json as meta.cast_id) with function meta.cast_id(json) as assignment;
create type meta.column_id as (schema_name text,relation_name text,name text);
create function meta.column_id(schema_name text,relation_name text,name text) returns meta.column_id as $_$ select row(schema_name,relation_name,name)::meta.column_id $_$ language sql immutable;
create function meta.meta_id(column_id meta.column_id) returns meta.meta_id as $_$ select meta.meta_id('column'); $_$ language sql;
create function meta.eq(leftarg meta.column_id, rightarg json) returns boolean as $_$select ((leftarg).schema_name)::text = ((rightarg)->>'schema_name')::text and ((leftarg).relation_name)::text = ((rightarg)->>'relation_name')::text and ((leftarg).name)::text = ((rightarg)->>'name')::text$_$ language sql;
create operator meta.= (leftarg = meta.column_id, rightarg = json, procedure = meta.eq);
create function meta.column_id(value json) returns meta.column_id as $_$select meta.column_id((value->>'schema_name')::text, (value->>'relation_name')::text, (value->>'name')::text) $_$ immutable language sql;
create cast (json as meta.column_id) with function meta.column_id(json) as assignment;
create type meta.connection_id as (pid int4,connection_start timestamptz);
create function meta.connection_id(pid int4,connection_start timestamptz) returns meta.connection_id as $_$ select row(pid,connection_start)::meta.connection_id $_$ language sql immutable;
create function meta.meta_id(connection_id meta.connection_id) returns meta.meta_id as $_$ select meta.meta_id('connection'); $_$ language sql;
create function meta.eq(leftarg meta.connection_id, rightarg json) returns boolean as $_$select ((leftarg).pid)::text = ((rightarg)->>'pid')::text and ((leftarg).connection_start)::text = ((rightarg)->>'connection_start')::text$_$ language sql;
create operator meta.= (leftarg = meta.connection_id, rightarg = json, procedure = meta.eq);
create function meta.connection_id(value json) returns meta.connection_id as $_$select meta.connection_id((value->>'pid')::int4, (value->>'connection_start')::timestamptz) $_$ immutable language sql;
create cast (json as meta.connection_id) with function meta.connection_id(json) as assignment;
create type meta.constraint_id as (schema_name text,relation_name text,name text);
create function meta.constraint_id(schema_name text,relation_name text,name text) returns meta.constraint_id as $_$ select row(schema_name,relation_name,name)::meta.constraint_id $_$ language sql immutable;
create function meta.meta_id(constraint_id meta.constraint_id) returns meta.meta_id as $_$ select meta.meta_id('constraint'); $_$ language sql;
create function meta.eq(leftarg meta.constraint_id, rightarg json) returns boolean as $_$select ((leftarg).schema_name)::text = ((rightarg)->>'schema_name')::text and ((leftarg).relation_name)::text = ((rightarg)->>'relation_name')::text and ((leftarg).name)::text = ((rightarg)->>'name')::text$_$ language sql;
create operator meta.= (leftarg = meta.constraint_id, rightarg = json, procedure = meta.eq);
create function meta.constraint_id(value json) returns meta.constraint_id as $_$select meta.constraint_id((value->>'schema_name')::text, (value->>'relation_name')::text, (value->>'name')::text) $_$ immutable language sql;
create cast (json as meta.constraint_id) with function meta.constraint_id(json) as assignment;
create type meta.constraint_check_id as (schema_name text,table_name text,name text,column_names text);
create function meta.constraint_check_id(schema_name text,table_name text,name text,column_names text) returns meta.constraint_check_id as $_$ select row(schema_name,table_name,name,column_names)::meta.constraint_check_id $_$ language sql immutable;
create function meta.meta_id(constraint_check_id meta.constraint_check_id) returns meta.meta_id as $_$ select meta.meta_id('constraint_check'); $_$ language sql;
create function meta.eq(leftarg meta.constraint_check_id, rightarg json) returns boolean as $_$select ((leftarg).schema_name)::text = ((rightarg)->>'schema_name')::text and ((leftarg).table_name)::text = ((rightarg)->>'table_name')::text and ((leftarg).name)::text = ((rightarg)->>'name')::text and ((leftarg).column_names)::text = ((rightarg)->>'column_names')::text$_$ language sql;
create operator meta.= (leftarg = meta.constraint_check_id, rightarg = json, procedure = meta.eq);
create function meta.constraint_check_id(value json) returns meta.constraint_check_id as $_$select meta.constraint_check_id((value->>'schema_name')::text, (value->>'table_name')::text, (value->>'name')::text, (value->>'column_names')::text) $_$ immutable language sql;
create cast (json as meta.constraint_check_id) with function meta.constraint_check_id(json) as assignment;
create type meta.constraint_unique_id as (schema_name text,table_name text,name text,column_names text);
create function meta.constraint_unique_id(schema_name text,table_name text,name text,column_names text) returns meta.constraint_unique_id as $_$ select row(schema_name,table_name,name,column_names)::meta.constraint_unique_id $_$ language sql immutable;
create function meta.meta_id(constraint_unique_id meta.constraint_unique_id) returns meta.meta_id as $_$ select meta.meta_id('constraint_unique'); $_$ language sql;
create function meta.eq(leftarg meta.constraint_unique_id, rightarg json) returns boolean as $_$select ((leftarg).schema_name)::text = ((rightarg)->>'schema_name')::text and ((leftarg).table_name)::text = ((rightarg)->>'table_name')::text and ((leftarg).name)::text = ((rightarg)->>'name')::text and ((leftarg).column_names)::text = ((rightarg)->>'column_names')::text$_$ language sql;
create operator meta.= (leftarg = meta.constraint_unique_id, rightarg = json, procedure = meta.eq);
create function meta.constraint_unique_id(value json) returns meta.constraint_unique_id as $_$select meta.constraint_unique_id((value->>'schema_name')::text, (value->>'table_name')::text, (value->>'name')::text, (value->>'column_names')::text) $_$ immutable language sql;
create cast (json as meta.constraint_unique_id) with function meta.constraint_unique_id(json) as assignment;
create type meta.extension_id as (name text);
create function meta.extension_id(name text) returns meta.extension_id as $_$ select row(name)::meta.extension_id $_$ language sql immutable;
create function meta.meta_id(extension_id meta.extension_id) returns meta.meta_id as $_$ select meta.meta_id('extension'); $_$ language sql;
create function meta.eq(leftarg meta.extension_id, rightarg json) returns boolean as $_$select ((leftarg).name)::text = ((rightarg)->>'name')::text$_$ language sql;
create operator meta.= (leftarg = meta.extension_id, rightarg = json, procedure = meta.eq);
create function meta.extension_id(value json) returns meta.extension_id as $_$select meta.extension_id((value->>'name')::text) $_$ immutable language sql;
create cast (json as meta.extension_id) with function meta.extension_id(json) as assignment;
create type meta.field_id as (schema_name text,relation_name text,pk_column_name text,pk_value text,column_name text);
create function meta.field_id(schema_name text,relation_name text,pk_column_name text,pk_value text,column_name text) returns meta.field_id as $_$ select row(schema_name,relation_name,pk_column_name,pk_value,column_name)::meta.field_id $_$ language sql immutable;
create function meta.meta_id(field_id meta.field_id) returns meta.meta_id as $_$ select meta.meta_id('field'); $_$ language sql;
create function meta.eq(leftarg meta.field_id, rightarg json) returns boolean as $_$select ((leftarg).schema_name)::text = ((rightarg)->>'schema_name')::text and ((leftarg).relation_name)::text = ((rightarg)->>'relation_name')::text and ((leftarg).pk_column_name)::text = ((rightarg)->>'pk_column_name')::text and ((leftarg).pk_value)::text = ((rightarg)->>'pk_value')::text and ((leftarg).column_name)::text = ((rightarg)->>'column_name')::text$_$ language sql;
create operator meta.= (leftarg = meta.field_id, rightarg = json, procedure = meta.eq);
create function meta.field_id(value json) returns meta.field_id as $_$select meta.field_id((value->>'schema_name')::text, (value->>'relation_name')::text, (value->>'pk_column_name')::text, (value->>'pk_value')::text, (value->>'column_name')::text) $_$ immutable language sql;
create cast (json as meta.field_id) with function meta.field_id(json) as assignment;
create type meta.foreign_column_id as (schema_name text,name text);
create function meta.foreign_column_id(schema_name text,name text) returns meta.foreign_column_id as $_$ select row(schema_name,name)::meta.foreign_column_id $_$ language sql immutable;
create function meta.meta_id(foreign_column_id meta.foreign_column_id) returns meta.meta_id as $_$ select meta.meta_id('foreign_column'); $_$ language sql;
create function meta.eq(leftarg meta.foreign_column_id, rightarg json) returns boolean as $_$select ((leftarg).schema_name)::text = ((rightarg)->>'schema_name')::text and ((leftarg).name)::text = ((rightarg)->>'name')::text$_$ language sql;
create operator meta.= (leftarg = meta.foreign_column_id, rightarg = json, procedure = meta.eq);
create function meta.foreign_column_id(value json) returns meta.foreign_column_id as $_$select meta.foreign_column_id((value->>'schema_name')::text, (value->>'name')::text) $_$ immutable language sql;
create cast (json as meta.foreign_column_id) with function meta.foreign_column_id(json) as assignment;
create type meta.foreign_data_wrapper_id as (name text);
create function meta.foreign_data_wrapper_id(name text) returns meta.foreign_data_wrapper_id as $_$ select row(name)::meta.foreign_data_wrapper_id $_$ language sql immutable;
create function meta.meta_id(foreign_data_wrapper_id meta.foreign_data_wrapper_id) returns meta.meta_id as $_$ select meta.meta_id('foreign_data_wrapper'); $_$ language sql;
create function meta.eq(leftarg meta.foreign_data_wrapper_id, rightarg json) returns boolean as $_$select ((leftarg).name)::text = ((rightarg)->>'name')::text$_$ language sql;
create operator meta.= (leftarg = meta.foreign_data_wrapper_id, rightarg = json, procedure = meta.eq);
create function meta.foreign_data_wrapper_id(value json) returns meta.foreign_data_wrapper_id as $_$select meta.foreign_data_wrapper_id((value->>'name')::text) $_$ immutable language sql;
create cast (json as meta.foreign_data_wrapper_id) with function meta.foreign_data_wrapper_id(json) as assignment;
create type meta.foreign_key_id as (schema_name text,relation_name text,name text);
create function meta.foreign_key_id(schema_name text,relation_name text,name text) returns meta.foreign_key_id as $_$ select row(schema_name,relation_name,name)::meta.foreign_key_id $_$ language sql immutable;
create function meta.meta_id(foreign_key_id meta.foreign_key_id) returns meta.meta_id as $_$ select meta.meta_id('foreign_key'); $_$ language sql;
create function meta.eq(leftarg meta.foreign_key_id, rightarg json) returns boolean as $_$select ((leftarg).schema_name)::text = ((rightarg)->>'schema_name')::text and ((leftarg).relation_name)::text = ((rightarg)->>'relation_name')::text and ((leftarg).name)::text = ((rightarg)->>'name')::text$_$ language sql;
create operator meta.= (leftarg = meta.foreign_key_id, rightarg = json, procedure = meta.eq);
create function meta.foreign_key_id(value json) returns meta.foreign_key_id as $_$select meta.foreign_key_id((value->>'schema_name')::text, (value->>'relation_name')::text, (value->>'name')::text) $_$ immutable language sql;
create cast (json as meta.foreign_key_id) with function meta.foreign_key_id(json) as assignment;
create type meta.foreign_server_id as (name text);
create function meta.foreign_server_id(name text) returns meta.foreign_server_id as $_$ select row(name)::meta.foreign_server_id $_$ language sql immutable;
create function meta.meta_id(foreign_server_id meta.foreign_server_id) returns meta.meta_id as $_$ select meta.meta_id('foreign_server'); $_$ language sql;
create function meta.eq(leftarg meta.foreign_server_id, rightarg json) returns boolean as $_$select ((leftarg).name)::text = ((rightarg)->>'name')::text$_$ language sql;
create operator meta.= (leftarg = meta.foreign_server_id, rightarg = json, procedure = meta.eq);
create function meta.foreign_server_id(value json) returns meta.foreign_server_id as $_$select meta.foreign_server_id((value->>'name')::text) $_$ immutable language sql;
create cast (json as meta.foreign_server_id) with function meta.foreign_server_id(json) as assignment;
create type meta.foreign_table_id as (schema_name text,name text);
create function meta.foreign_table_id(schema_name text,name text) returns meta.foreign_table_id as $_$ select row(schema_name,name)::meta.foreign_table_id $_$ language sql immutable;
create function meta.meta_id(foreign_table_id meta.foreign_table_id) returns meta.meta_id as $_$ select meta.meta_id('foreign_table'); $_$ language sql;
create function meta.eq(leftarg meta.foreign_table_id, rightarg json) returns boolean as $_$select ((leftarg).schema_name)::text = ((rightarg)->>'schema_name')::text and ((leftarg).name)::text = ((rightarg)->>'name')::text$_$ language sql;
create operator meta.= (leftarg = meta.foreign_table_id, rightarg = json, procedure = meta.eq);
create function meta.foreign_table_id(value json) returns meta.foreign_table_id as $_$select meta.foreign_table_id((value->>'schema_name')::text, (value->>'name')::text) $_$ immutable language sql;
create cast (json as meta.foreign_table_id) with function meta.foreign_table_id(json) as assignment;
create type meta.function_id as (schema_name text,name text,parameters text[]);
create function meta.function_id(schema_name text,name text,parameters text[]) returns meta.function_id as $_$ select row(schema_name,name,parameters)::meta.function_id $_$ language sql immutable;
create function meta.meta_id(function_id meta.function_id) returns meta.meta_id as $_$ select meta.meta_id('function'); $_$ language sql;
create function meta.eq(leftarg meta.function_id, rightarg json) returns boolean as $_$select ((leftarg).schema_name)::text = ((rightarg)->>'schema_name')::text and ((leftarg).name)::text = ((rightarg)->>'name')::text and to_json((leftarg).parameters)::text = (rightarg->'parameters')::text$_$ language sql;
create operator meta.= (leftarg = meta.function_id, rightarg = json, procedure = meta.eq);
create function meta.function_id(value json) returns meta.function_id as $_$select meta.function_id((value->>'schema_name')::text, (value->>'name')::text, (select array_agg(value) from json_array_elements_text(value->'parameters'))) $_$ immutable language sql;
create cast (json as meta.function_id) with function meta.function_id(json) as assignment;
create type meta.operator_id as (schema_name text,name text,left_arg_type_schema_name text,left_arg_type_name text,right_arg_type_schema_name text,right_arg_type_name text);
create function meta.operator_id(schema_name text,name text,left_arg_type_schema_name text,left_arg_type_name text,right_arg_type_schema_name text,right_arg_type_name text) returns meta.operator_id as $_$ select row(schema_name,name,left_arg_type_schema_name,left_arg_type_name,right_arg_type_schema_name,right_arg_type_name)::meta.operator_id $_$ language sql immutable;
create function meta.meta_id(operator_id meta.operator_id) returns meta.meta_id as $_$ select meta.meta_id('operator'); $_$ language sql;
create function meta.eq(leftarg meta.operator_id, rightarg json) returns boolean as $_$select ((leftarg).schema_name)::text = ((rightarg)->>'schema_name')::text and ((leftarg).name)::text = ((rightarg)->>'name')::text and ((leftarg).left_arg_type_schema_name)::text = ((rightarg)->>'left_arg_type_schema_name')::text and ((leftarg).left_arg_type_name)::text = ((rightarg)->>'left_arg_type_name')::text and ((leftarg).right_arg_type_schema_name)::text = ((rightarg)->>'right_arg_type_schema_name')::text and ((leftarg).right_arg_type_name)::text = ((rightarg)->>'right_arg_type_name')::text$_$ language sql;
create operator meta.= (leftarg = meta.operator_id, rightarg = json, procedure = meta.eq);
create function meta.operator_id(value json) returns meta.operator_id as $_$select meta.operator_id((value->>'schema_name')::text, (value->>'name')::text, (value->>'left_arg_type_schema_name')::text, (value->>'left_arg_type_name')::text, (value->>'right_arg_type_schema_name')::text, (value->>'right_arg_type_name')::text) $_$ immutable language sql;
create cast (json as meta.operator_id) with function meta.operator_id(json) as assignment;
create type meta.policy_id as (schema_name text,relation_name text,name text);
create function meta.policy_id(schema_name text,relation_name text,name text) returns meta.policy_id as $_$ select row(schema_name,relation_name,name)::meta.policy_id $_$ language sql immutable;
create function meta.meta_id(policy_id meta.policy_id) returns meta.meta_id as $_$ select meta.meta_id('policy'); $_$ language sql;
create function meta.eq(leftarg meta.policy_id, rightarg json) returns boolean as $_$select ((leftarg).schema_name)::text = ((rightarg)->>'schema_name')::text and ((leftarg).relation_name)::text = ((rightarg)->>'relation_name')::text and ((leftarg).name)::text = ((rightarg)->>'name')::text$_$ language sql;
create operator meta.= (leftarg = meta.policy_id, rightarg = json, procedure = meta.eq);
create function meta.policy_id(value json) returns meta.policy_id as $_$select meta.policy_id((value->>'schema_name')::text, (value->>'relation_name')::text, (value->>'name')::text) $_$ immutable language sql;
create cast (json as meta.policy_id) with function meta.policy_id(json) as assignment;
create type meta.relation_id as (schema_name text,name text);
create function meta.relation_id(schema_name text,name text) returns meta.relation_id as $_$ select row(schema_name,name)::meta.relation_id $_$ language sql immutable;
create function meta.meta_id(relation_id meta.relation_id) returns meta.meta_id as $_$ select meta.meta_id('relation'); $_$ language sql;
create function meta.eq(leftarg meta.relation_id, rightarg json) returns boolean as $_$select ((leftarg).schema_name)::text = ((rightarg)->>'schema_name')::text and ((leftarg).name)::text = ((rightarg)->>'name')::text$_$ language sql;
create operator meta.= (leftarg = meta.relation_id, rightarg = json, procedure = meta.eq);
create function meta.relation_id(value json) returns meta.relation_id as $_$select meta.relation_id((value->>'schema_name')::text, (value->>'name')::text) $_$ immutable language sql;
create cast (json as meta.relation_id) with function meta.relation_id(json) as assignment;
create type meta.role_id as (name text);
create function meta.role_id(name text) returns meta.role_id as $_$ select row(name)::meta.role_id $_$ language sql immutable;
create function meta.meta_id(role_id meta.role_id) returns meta.meta_id as $_$ select meta.meta_id('role'); $_$ language sql;
create function meta.eq(leftarg meta.role_id, rightarg json) returns boolean as $_$select ((leftarg).name)::text = ((rightarg)->>'name')::text$_$ language sql;
create operator meta.= (leftarg = meta.role_id, rightarg = json, procedure = meta.eq);
create function meta.role_id(value json) returns meta.role_id as $_$select meta.role_id((value->>'name')::text) $_$ immutable language sql;
create cast (json as meta.role_id) with function meta.role_id(json) as assignment;
create type meta.row_id as (schema_name text,relation_name text,pk_column_name text,pk_value text);
create function meta.row_id(schema_name text,relation_name text,pk_column_name text,pk_value text) returns meta.row_id as $_$ select row(schema_name,relation_name,pk_column_name,pk_value)::meta.row_id $_$ language sql immutable;
create function meta.meta_id(row_id meta.row_id) returns meta.meta_id as $_$ select meta.meta_id('row'); $_$ language sql;
create function meta.eq(leftarg meta.row_id, rightarg json) returns boolean as $_$select ((leftarg).schema_name)::text = ((rightarg)->>'schema_name')::text and ((leftarg).relation_name)::text = ((rightarg)->>'relation_name')::text and ((leftarg).pk_column_name)::text = ((rightarg)->>'pk_column_name')::text and ((leftarg).pk_value)::text = ((rightarg)->>'pk_value')::text$_$ language sql;
create operator meta.= (leftarg = meta.row_id, rightarg = json, procedure = meta.eq);
create function meta.row_id(value json) returns meta.row_id as $_$select meta.row_id((value->>'schema_name')::text, (value->>'relation_name')::text, (value->>'pk_column_name')::text, (value->>'pk_value')::text) $_$ immutable language sql;
create cast (json as meta.row_id) with function meta.row_id(json) as assignment;
create type meta.schema_id as (name text);
create function meta.schema_id(name text) returns meta.schema_id as $_$ select row(name)::meta.schema_id $_$ language sql immutable;
create function meta.meta_id(schema_id meta.schema_id) returns meta.meta_id as $_$ select meta.meta_id('schema'); $_$ language sql;
create function meta.eq(leftarg meta.schema_id, rightarg json) returns boolean as $_$select ((leftarg).name)::text = ((rightarg)->>'name')::text$_$ language sql;
create operator meta.= (leftarg = meta.schema_id, rightarg = json, procedure = meta.eq);
create function meta.schema_id(value json) returns meta.schema_id as $_$select meta.schema_id((value->>'name')::text) $_$ immutable language sql;
create cast (json as meta.schema_id) with function meta.schema_id(json) as assignment;
create type meta.sequence_id as (schema_name text,name text);
create function meta.sequence_id(schema_name text,name text) returns meta.sequence_id as $_$ select row(schema_name,name)::meta.sequence_id $_$ language sql immutable;
create function meta.meta_id(sequence_id meta.sequence_id) returns meta.meta_id as $_$ select meta.meta_id('sequence'); $_$ language sql;
create function meta.eq(leftarg meta.sequence_id, rightarg json) returns boolean as $_$select ((leftarg).schema_name)::text = ((rightarg)->>'schema_name')::text and ((leftarg).name)::text = ((rightarg)->>'name')::text$_$ language sql;
create operator meta.= (leftarg = meta.sequence_id, rightarg = json, procedure = meta.eq);
create function meta.sequence_id(value json) returns meta.sequence_id as $_$select meta.sequence_id((value->>'schema_name')::text, (value->>'name')::text) $_$ immutable language sql;
create cast (json as meta.sequence_id) with function meta.sequence_id(json) as assignment;
create type meta.table_id as (schema_name text,name text);
create function meta.table_id(schema_name text,name text) returns meta.table_id as $_$ select row(schema_name,name)::meta.table_id $_$ language sql immutable;
create function meta.meta_id(table_id meta.table_id) returns meta.meta_id as $_$ select meta.meta_id('table'); $_$ language sql;
create function meta.eq(leftarg meta.table_id, rightarg json) returns boolean as $_$select ((leftarg).schema_name)::text = ((rightarg)->>'schema_name')::text and ((leftarg).name)::text = ((rightarg)->>'name')::text$_$ language sql;
create operator meta.= (leftarg = meta.table_id, rightarg = json, procedure = meta.eq);
create function meta.table_id(value json) returns meta.table_id as $_$select meta.table_id((value->>'schema_name')::text, (value->>'name')::text) $_$ immutable language sql;
create cast (json as meta.table_id) with function meta.table_id(json) as assignment;
create type meta.table_privilege_id as (schema_name text,relation_name text,role text,type text);
create function meta.table_privilege_id(schema_name text,relation_name text,role text,type text) returns meta.table_privilege_id as $_$ select row(schema_name,relation_name,role,type)::meta.table_privilege_id $_$ language sql immutable;
create function meta.meta_id(table_privilege_id meta.table_privilege_id) returns meta.meta_id as $_$ select meta.meta_id('table_privilege'); $_$ language sql;
create function meta.eq(leftarg meta.table_privilege_id, rightarg json) returns boolean as $_$select ((leftarg).schema_name)::text = ((rightarg)->>'schema_name')::text and ((leftarg).relation_name)::text = ((rightarg)->>'relation_name')::text and ((leftarg).role)::text = ((rightarg)->>'role')::text and ((leftarg).type)::text = ((rightarg)->>'type')::text$_$ language sql;
create operator meta.= (leftarg = meta.table_privilege_id, rightarg = json, procedure = meta.eq);
create function meta.table_privilege_id(value json) returns meta.table_privilege_id as $_$select meta.table_privilege_id((value->>'schema_name')::text, (value->>'relation_name')::text, (value->>'role')::text, (value->>'type')::text) $_$ immutable language sql;
create cast (json as meta.table_privilege_id) with function meta.table_privilege_id(json) as assignment;
create type meta.trigger_id as (schema_name text,relation_name text,name text);
create function meta.trigger_id(schema_name text,relation_name text,name text) returns meta.trigger_id as $_$ select row(schema_name,relation_name,name)::meta.trigger_id $_$ language sql immutable;
create function meta.meta_id(trigger_id meta.trigger_id) returns meta.meta_id as $_$ select meta.meta_id('trigger'); $_$ language sql;
create function meta.eq(leftarg meta.trigger_id, rightarg json) returns boolean as $_$select ((leftarg).schema_name)::text = ((rightarg)->>'schema_name')::text and ((leftarg).relation_name)::text = ((rightarg)->>'relation_name')::text and ((leftarg).name)::text = ((rightarg)->>'name')::text$_$ language sql;
create operator meta.= (leftarg = meta.trigger_id, rightarg = json, procedure = meta.eq);
create function meta.trigger_id(value json) returns meta.trigger_id as $_$select meta.trigger_id((value->>'schema_name')::text, (value->>'relation_name')::text, (value->>'name')::text) $_$ immutable language sql;
create cast (json as meta.trigger_id) with function meta.trigger_id(json) as assignment;
create type meta.type_id as (schema_name text,name text);
create function meta.type_id(schema_name text,name text) returns meta.type_id as $_$ select row(schema_name,name)::meta.type_id $_$ language sql immutable;
create function meta.meta_id(type_id meta.type_id) returns meta.meta_id as $_$ select meta.meta_id('type'); $_$ language sql;
create function meta.eq(leftarg meta.type_id, rightarg json) returns boolean as $_$select ((leftarg).schema_name)::text = ((rightarg)->>'schema_name')::text and ((leftarg).name)::text = ((rightarg)->>'name')::text$_$ language sql;
create operator meta.= (leftarg = meta.type_id, rightarg = json, procedure = meta.eq);
create function meta.type_id(value json) returns meta.type_id as $_$select meta.type_id((value->>'schema_name')::text, (value->>'name')::text) $_$ immutable language sql;
create cast (json as meta.type_id) with function meta.type_id(json) as assignment;
create type meta.view_id as (schema_name text,name text);
create function meta.view_id(schema_name text,name text) returns meta.view_id as $_$ select row(schema_name,name)::meta.view_id $_$ language sql immutable;
create function meta.meta_id(view_id meta.view_id) returns meta.meta_id as $_$ select meta.meta_id('view'); $_$ language sql;
create function meta.eq(leftarg meta.view_id, rightarg json) returns boolean as $_$select ((leftarg).schema_name)::text = ((rightarg)->>'schema_name')::text and ((leftarg).name)::text = ((rightarg)->>'name')::text$_$ language sql;
create operator meta.= (leftarg = meta.view_id, rightarg = json, procedure = meta.eq);
create function meta.view_id(value json) returns meta.view_id as $_$select meta.view_id((value->>'schema_name')::text, (value->>'name')::text) $_$ immutable language sql;
create cast (json as meta.view_id) with function meta.view_id(json) as assignment;
-- (286 rows)

create function meta.column_id_to_schema_id(column_id meta.column_id) returns meta.schema_id as $_$select meta.schema_id((column_id).schema_name) $_$ immutable language sql;
create cast (meta.column_id as meta.schema_id) with function meta.column_id_to_schema_id(meta.column_id) as assignment;
create function meta.constraint_id_to_schema_id(constraint_id meta.constraint_id) returns meta.schema_id as $_$select meta.schema_id((constraint_id).schema_name) $_$ immutable language sql;
create cast (meta.constraint_id as meta.schema_id) with function meta.constraint_id_to_schema_id(meta.constraint_id) as assignment;
create function meta.constraint_check_id_to_schema_id(constraint_check_id meta.constraint_check_id) returns meta.schema_id as $_$select meta.schema_id((constraint_check_id).schema_name) $_$ immutable language sql;
create cast (meta.constraint_check_id as meta.schema_id) with function meta.constraint_check_id_to_schema_id(meta.constraint_check_id) as assignment;
create function meta.constraint_unique_id_to_schema_id(constraint_unique_id meta.constraint_unique_id) returns meta.schema_id as $_$select meta.schema_id((constraint_unique_id).schema_name) $_$ immutable language sql;
create cast (meta.constraint_unique_id as meta.schema_id) with function meta.constraint_unique_id_to_schema_id(meta.constraint_unique_id) as assignment;
create function meta.field_id_to_schema_id(field_id meta.field_id) returns meta.schema_id as $_$select meta.schema_id((field_id).schema_name) $_$ immutable language sql;
create cast (meta.field_id as meta.schema_id) with function meta.field_id_to_schema_id(meta.field_id) as assignment;
create function meta.foreign_column_id_to_schema_id(foreign_column_id meta.foreign_column_id) returns meta.schema_id as $_$select meta.schema_id((foreign_column_id).schema_name) $_$ immutable language sql;
create cast (meta.foreign_column_id as meta.schema_id) with function meta.foreign_column_id_to_schema_id(meta.foreign_column_id) as assignment;
create function meta.foreign_key_id_to_schema_id(foreign_key_id meta.foreign_key_id) returns meta.schema_id as $_$select meta.schema_id((foreign_key_id).schema_name) $_$ immutable language sql;
create cast (meta.foreign_key_id as meta.schema_id) with function meta.foreign_key_id_to_schema_id(meta.foreign_key_id) as assignment;
create function meta.foreign_table_id_to_schema_id(foreign_table_id meta.foreign_table_id) returns meta.schema_id as $_$select meta.schema_id((foreign_table_id).schema_name) $_$ immutable language sql;
create cast (meta.foreign_table_id as meta.schema_id) with function meta.foreign_table_id_to_schema_id(meta.foreign_table_id) as assignment;
create function meta.function_id_to_schema_id(function_id meta.function_id) returns meta.schema_id as $_$select meta.schema_id((function_id).schema_name) $_$ immutable language sql;
create cast (meta.function_id as meta.schema_id) with function meta.function_id_to_schema_id(meta.function_id) as assignment;
create function meta.operator_id_to_schema_id(operator_id meta.operator_id) returns meta.schema_id as $_$select meta.schema_id((operator_id).schema_name) $_$ immutable language sql;
create cast (meta.operator_id as meta.schema_id) with function meta.operator_id_to_schema_id(meta.operator_id) as assignment;
create function meta.policy_id_to_schema_id(policy_id meta.policy_id) returns meta.schema_id as $_$select meta.schema_id((policy_id).schema_name) $_$ immutable language sql;
create cast (meta.policy_id as meta.schema_id) with function meta.policy_id_to_schema_id(meta.policy_id) as assignment;
create function meta.relation_id_to_schema_id(relation_id meta.relation_id) returns meta.schema_id as $_$select meta.schema_id((relation_id).schema_name) $_$ immutable language sql;
create cast (meta.relation_id as meta.schema_id) with function meta.relation_id_to_schema_id(meta.relation_id) as assignment;
create function meta.row_id_to_schema_id(row_id meta.row_id) returns meta.schema_id as $_$select meta.schema_id((row_id).schema_name) $_$ immutable language sql;
create cast (meta.row_id as meta.schema_id) with function meta.row_id_to_schema_id(meta.row_id) as assignment;
create function meta.sequence_id_to_schema_id(sequence_id meta.sequence_id) returns meta.schema_id as $_$select meta.schema_id((sequence_id).schema_name) $_$ immutable language sql;
create cast (meta.sequence_id as meta.schema_id) with function meta.sequence_id_to_schema_id(meta.sequence_id) as assignment;
create function meta.table_id_to_schema_id(table_id meta.table_id) returns meta.schema_id as $_$select meta.schema_id((table_id).schema_name) $_$ immutable language sql;
create cast (meta.table_id as meta.schema_id) with function meta.table_id_to_schema_id(meta.table_id) as assignment;
create function meta.table_privilege_id_to_schema_id(table_privilege_id meta.table_privilege_id) returns meta.schema_id as $_$select meta.schema_id((table_privilege_id).schema_name) $_$ immutable language sql;
create cast (meta.table_privilege_id as meta.schema_id) with function meta.table_privilege_id_to_schema_id(meta.table_privilege_id) as assignment;
create function meta.trigger_id_to_schema_id(trigger_id meta.trigger_id) returns meta.schema_id as $_$select meta.schema_id((trigger_id).schema_name) $_$ immutable language sql;
create cast (meta.trigger_id as meta.schema_id) with function meta.trigger_id_to_schema_id(meta.trigger_id) as assignment;
create function meta.type_id_to_schema_id(type_id meta.type_id) returns meta.schema_id as $_$select meta.schema_id((type_id).schema_name) $_$ immutable language sql;
create cast (meta.type_id as meta.schema_id) with function meta.type_id_to_schema_id(meta.type_id) as assignment;
create function meta.view_id_to_schema_id(view_id meta.view_id) returns meta.schema_id as $_$select meta.schema_id((view_id).schema_name) $_$ immutable language sql;
create cast (meta.view_id as meta.schema_id) with function meta.view_id_to_schema_id(meta.view_id) as assignment;
-- (38 rows)


create function meta.column_id_to_relation_id(column_id meta.column_id) returns meta.relation_id as $_$select meta.relation_id((column_id).schema_name, (column_id).relation_name) $_$ immutable language sql;
create cast (meta.column_id as meta.relation_id) with function meta.column_id_to_relation_id(meta.column_id) as assignment;
create function meta.constraint_id_to_relation_id(constraint_id meta.constraint_id) returns meta.relation_id as $_$select meta.relation_id((constraint_id).schema_name, (constraint_id).relation_name) $_$ immutable language sql;
create cast (meta.constraint_id as meta.relation_id) with function meta.constraint_id_to_relation_id(meta.constraint_id) as assignment;
create function meta.field_id_to_relation_id(field_id meta.field_id) returns meta.relation_id as $_$select meta.relation_id((field_id).schema_name, (field_id).relation_name) $_$ immutable language sql;
create cast (meta.field_id as meta.relation_id) with function meta.field_id_to_relation_id(meta.field_id) as assignment;
create function meta.foreign_key_id_to_relation_id(foreign_key_id meta.foreign_key_id) returns meta.relation_id as $_$select meta.relation_id((foreign_key_id).schema_name, (foreign_key_id).relation_name) $_$ immutable language sql;
create cast (meta.foreign_key_id as meta.relation_id) with function meta.foreign_key_id_to_relation_id(meta.foreign_key_id) as assignment;
create function meta.policy_id_to_relation_id(policy_id meta.policy_id) returns meta.relation_id as $_$select meta.relation_id((policy_id).schema_name, (policy_id).relation_name) $_$ immutable language sql;
create cast (meta.policy_id as meta.relation_id) with function meta.policy_id_to_relation_id(meta.policy_id) as assignment;
create function meta.row_id_to_relation_id(row_id meta.row_id) returns meta.relation_id as $_$select meta.relation_id((row_id).schema_name, (row_id).relation_name) $_$ immutable language sql;
create cast (meta.row_id as meta.relation_id) with function meta.row_id_to_relation_id(meta.row_id) as assignment;
create function meta.table_privilege_id_to_relation_id(table_privilege_id meta.table_privilege_id) returns meta.relation_id as $_$select meta.relation_id((table_privilege_id).schema_name, (table_privilege_id).relation_name) $_$ immutable language sql;
create cast (meta.table_privilege_id as meta.relation_id) with function meta.table_privilege_id_to_relation_id(meta.table_privilege_id) as assignment;
create function meta.trigger_id_to_relation_id(trigger_id meta.trigger_id) returns meta.relation_id as $_$select meta.relation_id((trigger_id).schema_name, (trigger_id).relation_name) $_$ immutable language sql;
create cast (meta.trigger_id as meta.relation_id) with function meta.trigger_id_to_relation_id(meta.trigger_id) as assignment;
-- (16 rows)

create function meta.field_id_to_column_id(field_id meta.field_id) returns meta.column_id as $_$select meta.column_id((field_id).schema_name, (field_id).relation_name, (field_id).column_name) $_$ immutable language sql;
create cast (meta.field_id as meta.column_id) with function meta.field_id_to_column_id(meta.field_id) as assignment;
-- (2 rows)

