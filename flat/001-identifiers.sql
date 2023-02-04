begin;

create type meta2.cast_id as (source_type_schema_name text,source_type_name text,target_type_schema_name text,target_type_name text);
create function meta2.cast_id(source_type_schema_name text,source_type_name text,target_type_schema_name text,target_type_name text) returns meta2.cast_id as $_$ select row(source_type_schema_name,source_type_name,target_type_schema_name,target_type_name)::meta2.cast_id $_$ language sql immutable;
create function meta2.meta_id(cast_id meta2.cast_id) returns meta2.meta_id as $_$ select meta2.meta_id('cast'); $_$ language sql;
create function meta2.eq(leftarg meta2.cast_id, rightarg jsonb) returns boolean as $_$select ((leftarg).source_type_schema_name)::text = (rightarg)->>'source_type_schema_name' and ((leftarg).source_type_name)::text = (rightarg)->>'source_type_name' and ((leftarg).target_type_schema_name)::text = (rightarg)->>'target_type_schema_name' and ((leftarg).target_type_name)::text = (rightarg)->>'target_type_name'$_$ language sql;
create operator meta2.= (leftarg = meta2.cast_id, rightarg = jsonb, procedure = meta2.eq);
create function meta2.cast_id(value jsonb) returns meta2.cast_id as $_$select meta2.cast_id((value->>'source_type_schema_name')::text, (value->>'source_type_name')::text, (value->>'target_type_schema_name')::text, (value->>'target_type_name')::text) $_$ immutable language sql;
create cast (jsonb as meta2.cast_id) with function meta2.cast_id(jsonb) as assignment;
create type meta2.column_id as (schema_name text,relation_name text,name text);
create function meta2.column_id(schema_name text,relation_name text,name text) returns meta2.column_id as $_$ select row(schema_name,relation_name,name)::meta2.column_id $_$ language sql immutable;
create function meta2.meta_id(column_id meta2.column_id) returns meta2.meta_id as $_$ select meta2.meta_id('column'); $_$ language sql;
create function meta2.eq(leftarg meta2.column_id, rightarg jsonb) returns boolean as $_$select ((leftarg).schema_name)::text = (rightarg)->>'schema_name' and ((leftarg).relation_name)::text = (rightarg)->>'relation_name' and ((leftarg).name)::text = (rightarg)->>'name'$_$ language sql;
create operator meta2.= (leftarg = meta2.column_id, rightarg = jsonb, procedure = meta2.eq);
create function meta2.column_id(value jsonb) returns meta2.column_id as $_$select meta2.column_id((value->>'schema_name')::text, (value->>'relation_name')::text, (value->>'name')::text) $_$ immutable language sql;
create cast (jsonb as meta2.column_id) with function meta2.column_id(jsonb) as assignment;
create type meta2.connection_id as (pid int4,connection_start timestamptz);
create function meta2.connection_id(pid int4,connection_start timestamptz) returns meta2.connection_id as $_$ select row(pid,connection_start)::meta2.connection_id $_$ language sql immutable;
create function meta2.meta_id(connection_id meta2.connection_id) returns meta2.meta_id as $_$ select meta2.meta_id('connection'); $_$ language sql;
create function meta2.eq(leftarg meta2.connection_id, rightarg jsonb) returns boolean as $_$select ((leftarg).pid)::text = (rightarg)->>'pid' and ((leftarg).connection_start)::text = (rightarg)->>'connection_start'$_$ language sql;
create operator meta2.= (leftarg = meta2.connection_id, rightarg = jsonb, procedure = meta2.eq);
create function meta2.connection_id(value jsonb) returns meta2.connection_id as $_$select meta2.connection_id((value->>'pid')::int4, (value->>'connection_start')::timestamptz) $_$ immutable language sql;
create cast (jsonb as meta2.connection_id) with function meta2.connection_id(jsonb) as assignment;
create type meta2.constraint_id as (schema_name text,relation_name text,name text);
create function meta2.constraint_id(schema_name text,relation_name text,name text) returns meta2.constraint_id as $_$ select row(schema_name,relation_name,name)::meta2.constraint_id $_$ language sql immutable;
create function meta2.meta_id(constraint_id meta2.constraint_id) returns meta2.meta_id as $_$ select meta2.meta_id('constraint'); $_$ language sql;
create function meta2.eq(leftarg meta2.constraint_id, rightarg jsonb) returns boolean as $_$select ((leftarg).schema_name)::text = (rightarg)->>'schema_name' and ((leftarg).relation_name)::text = (rightarg)->>'relation_name' and ((leftarg).name)::text = (rightarg)->>'name'$_$ language sql;
create operator meta2.= (leftarg = meta2.constraint_id, rightarg = jsonb, procedure = meta2.eq);
create function meta2.constraint_id(value jsonb) returns meta2.constraint_id as $_$select meta2.constraint_id((value->>'schema_name')::text, (value->>'relation_name')::text, (value->>'name')::text) $_$ immutable language sql;
create cast (jsonb as meta2.constraint_id) with function meta2.constraint_id(jsonb) as assignment;
create type meta2.constraint_check_id as (schema_name text,table_name text,name text,column_names text);
create function meta2.constraint_check_id(schema_name text,table_name text,name text,column_names text) returns meta2.constraint_check_id as $_$ select row(schema_name,table_name,name,column_names)::meta2.constraint_check_id $_$ language sql immutable;
create function meta2.meta_id(constraint_check_id meta2.constraint_check_id) returns meta2.meta_id as $_$ select meta2.meta_id('constraint_check'); $_$ language sql;
create function meta2.eq(leftarg meta2.constraint_check_id, rightarg jsonb) returns boolean as $_$select ((leftarg).schema_name)::text = (rightarg)->>'schema_name' and ((leftarg).table_name)::text = (rightarg)->>'table_name' and ((leftarg).name)::text = (rightarg)->>'name' and ((leftarg).column_names)::text = (rightarg)->>'column_names'$_$ language sql;
create operator meta2.= (leftarg = meta2.constraint_check_id, rightarg = jsonb, procedure = meta2.eq);
create function meta2.constraint_check_id(value jsonb) returns meta2.constraint_check_id as $_$select meta2.constraint_check_id((value->>'schema_name')::text, (value->>'table_name')::text, (value->>'name')::text, (value->>'column_names')::text) $_$ immutable language sql;
create cast (jsonb as meta2.constraint_check_id) with function meta2.constraint_check_id(jsonb) as assignment;
create type meta2.constraint_unique_id as (schema_name text,table_name text,name text,column_names text);
create function meta2.constraint_unique_id(schema_name text,table_name text,name text,column_names text) returns meta2.constraint_unique_id as $_$ select row(schema_name,table_name,name,column_names)::meta2.constraint_unique_id $_$ language sql immutable;
create function meta2.meta_id(constraint_unique_id meta2.constraint_unique_id) returns meta2.meta_id as $_$ select meta2.meta_id('constraint_unique'); $_$ language sql;
create function meta2.eq(leftarg meta2.constraint_unique_id, rightarg jsonb) returns boolean as $_$select ((leftarg).schema_name)::text = (rightarg)->>'schema_name' and ((leftarg).table_name)::text = (rightarg)->>'table_name' and ((leftarg).name)::text = (rightarg)->>'name' and ((leftarg).column_names)::text = (rightarg)->>'column_names'$_$ language sql;
create operator meta2.= (leftarg = meta2.constraint_unique_id, rightarg = jsonb, procedure = meta2.eq);
create function meta2.constraint_unique_id(value jsonb) returns meta2.constraint_unique_id as $_$select meta2.constraint_unique_id((value->>'schema_name')::text, (value->>'table_name')::text, (value->>'name')::text, (value->>'column_names')::text) $_$ immutable language sql;
create cast (jsonb as meta2.constraint_unique_id) with function meta2.constraint_unique_id(jsonb) as assignment;
create type meta2.extension_id as (name text);
create function meta2.extension_id(name text) returns meta2.extension_id as $_$ select row(name)::meta2.extension_id $_$ language sql immutable;
create function meta2.meta_id(extension_id meta2.extension_id) returns meta2.meta_id as $_$ select meta2.meta_id('extension'); $_$ language sql;
create function meta2.eq(leftarg meta2.extension_id, rightarg jsonb) returns boolean as $_$select ((leftarg).name)::text = (rightarg)->>'name'$_$ language sql;
create operator meta2.= (leftarg = meta2.extension_id, rightarg = jsonb, procedure = meta2.eq);
create function meta2.extension_id(value jsonb) returns meta2.extension_id as $_$select meta2.extension_id((value->>'name')::text) $_$ immutable language sql;
create cast (jsonb as meta2.extension_id) with function meta2.extension_id(jsonb) as assignment;
create type meta2.field_id as (schema_name text,relation_name text,pk_column_name text,pk_value text,column_name text);
create function meta2.field_id(schema_name text,relation_name text,pk_column_name text,pk_value text,column_name text) returns meta2.field_id as $_$ select row(schema_name,relation_name,pk_column_name,pk_value,column_name)::meta2.field_id $_$ language sql immutable;
create function meta2.meta_id(field_id meta2.field_id) returns meta2.meta_id as $_$ select meta2.meta_id('field'); $_$ language sql;
create function meta2.eq(leftarg meta2.field_id, rightarg jsonb) returns boolean as $_$select ((leftarg).schema_name)::text = (rightarg)->>'schema_name' and ((leftarg).relation_name)::text = (rightarg)->>'relation_name' and ((leftarg).pk_column_name)::text = (rightarg)->>'pk_column_name' and ((leftarg).pk_value)::text = (rightarg)->>'pk_value' and ((leftarg).column_name)::text = (rightarg)->>'column_name'$_$ language sql;
create operator meta2.= (leftarg = meta2.field_id, rightarg = jsonb, procedure = meta2.eq);
create function meta2.field_id(value jsonb) returns meta2.field_id as $_$select meta2.field_id((value->>'schema_name')::text, (value->>'relation_name')::text, (value->>'pk_column_name')::text, (value->>'pk_value')::text, (value->>'column_name')::text) $_$ immutable language sql;
create cast (jsonb as meta2.field_id) with function meta2.field_id(jsonb) as assignment;
create type meta2.foreign_column_id as (schema_name text,name text);
create function meta2.foreign_column_id(schema_name text,name text) returns meta2.foreign_column_id as $_$ select row(schema_name,name)::meta2.foreign_column_id $_$ language sql immutable;
create function meta2.meta_id(foreign_column_id meta2.foreign_column_id) returns meta2.meta_id as $_$ select meta2.meta_id('foreign_column'); $_$ language sql;
create function meta2.eq(leftarg meta2.foreign_column_id, rightarg jsonb) returns boolean as $_$select ((leftarg).schema_name)::text = (rightarg)->>'schema_name' and ((leftarg).name)::text = (rightarg)->>'name'$_$ language sql;
create operator meta2.= (leftarg = meta2.foreign_column_id, rightarg = jsonb, procedure = meta2.eq);
create function meta2.foreign_column_id(value jsonb) returns meta2.foreign_column_id as $_$select meta2.foreign_column_id((value->>'schema_name')::text, (value->>'name')::text) $_$ immutable language sql;
create cast (jsonb as meta2.foreign_column_id) with function meta2.foreign_column_id(jsonb) as assignment;
create type meta2.foreign_data_wrapper_id as (name text);
create function meta2.foreign_data_wrapper_id(name text) returns meta2.foreign_data_wrapper_id as $_$ select row(name)::meta2.foreign_data_wrapper_id $_$ language sql immutable;
create function meta2.meta_id(foreign_data_wrapper_id meta2.foreign_data_wrapper_id) returns meta2.meta_id as $_$ select meta2.meta_id('foreign_data_wrapper'); $_$ language sql;
create function meta2.eq(leftarg meta2.foreign_data_wrapper_id, rightarg jsonb) returns boolean as $_$select ((leftarg).name)::text = (rightarg)->>'name'$_$ language sql;
create operator meta2.= (leftarg = meta2.foreign_data_wrapper_id, rightarg = jsonb, procedure = meta2.eq);
create function meta2.foreign_data_wrapper_id(value jsonb) returns meta2.foreign_data_wrapper_id as $_$select meta2.foreign_data_wrapper_id((value->>'name')::text) $_$ immutable language sql;
create cast (jsonb as meta2.foreign_data_wrapper_id) with function meta2.foreign_data_wrapper_id(jsonb) as assignment;
create type meta2.foreign_key_id as (schema_name text,relation_name text,name text);
create function meta2.foreign_key_id(schema_name text,relation_name text,name text) returns meta2.foreign_key_id as $_$ select row(schema_name,relation_name,name)::meta2.foreign_key_id $_$ language sql immutable;
create function meta2.meta_id(foreign_key_id meta2.foreign_key_id) returns meta2.meta_id as $_$ select meta2.meta_id('foreign_key'); $_$ language sql;
create function meta2.eq(leftarg meta2.foreign_key_id, rightarg jsonb) returns boolean as $_$select ((leftarg).schema_name)::text = (rightarg)->>'schema_name' and ((leftarg).relation_name)::text = (rightarg)->>'relation_name' and ((leftarg).name)::text = (rightarg)->>'name'$_$ language sql;
create operator meta2.= (leftarg = meta2.foreign_key_id, rightarg = jsonb, procedure = meta2.eq);
create function meta2.foreign_key_id(value jsonb) returns meta2.foreign_key_id as $_$select meta2.foreign_key_id((value->>'schema_name')::text, (value->>'relation_name')::text, (value->>'name')::text) $_$ immutable language sql;
create cast (jsonb as meta2.foreign_key_id) with function meta2.foreign_key_id(jsonb) as assignment;
create type meta2.foreign_server_id as (name text);
create function meta2.foreign_server_id(name text) returns meta2.foreign_server_id as $_$ select row(name)::meta2.foreign_server_id $_$ language sql immutable;
create function meta2.meta_id(foreign_server_id meta2.foreign_server_id) returns meta2.meta_id as $_$ select meta2.meta_id('foreign_server'); $_$ language sql;
create function meta2.eq(leftarg meta2.foreign_server_id, rightarg jsonb) returns boolean as $_$select ((leftarg).name)::text = (rightarg)->>'name'$_$ language sql;
create operator meta2.= (leftarg = meta2.foreign_server_id, rightarg = jsonb, procedure = meta2.eq);
create function meta2.foreign_server_id(value jsonb) returns meta2.foreign_server_id as $_$select meta2.foreign_server_id((value->>'name')::text) $_$ immutable language sql;
create cast (jsonb as meta2.foreign_server_id) with function meta2.foreign_server_id(jsonb) as assignment;
create type meta2.foreign_table_id as (schema_name text,name text);
create function meta2.foreign_table_id(schema_name text,name text) returns meta2.foreign_table_id as $_$ select row(schema_name,name)::meta2.foreign_table_id $_$ language sql immutable;
create function meta2.meta_id(foreign_table_id meta2.foreign_table_id) returns meta2.meta_id as $_$ select meta2.meta_id('foreign_table'); $_$ language sql;
create function meta2.eq(leftarg meta2.foreign_table_id, rightarg jsonb) returns boolean as $_$select ((leftarg).schema_name)::text = (rightarg)->>'schema_name' and ((leftarg).name)::text = (rightarg)->>'name'$_$ language sql;
create operator meta2.= (leftarg = meta2.foreign_table_id, rightarg = jsonb, procedure = meta2.eq);
create function meta2.foreign_table_id(value jsonb) returns meta2.foreign_table_id as $_$select meta2.foreign_table_id((value->>'schema_name')::text, (value->>'name')::text) $_$ immutable language sql;
create cast (jsonb as meta2.foreign_table_id) with function meta2.foreign_table_id(jsonb) as assignment;
create type meta2.function_id as (schema_name text,name text,parameters text[]);
create function meta2.function_id(schema_name text,name text,parameters text[]) returns meta2.function_id as $_$ select row(schema_name,name,parameters)::meta2.function_id $_$ language sql immutable;
create function meta2.meta_id(function_id meta2.function_id) returns meta2.meta_id as $_$ select meta2.meta_id('function'); $_$ language sql;
create function meta2.eq(leftarg meta2.function_id, rightarg jsonb) returns boolean as $_$select ((leftarg).schema_name)::text = (rightarg)->>'schema_name' and ((leftarg).name)::text = (rightarg)->>'name' and to_jsonb((leftarg).parameters) = rightarg->'parameters'$_$ language sql;
create operator meta2.= (leftarg = meta2.function_id, rightarg = jsonb, procedure = meta2.eq);
create function meta2.function_id(value jsonb) returns meta2.function_id as $_$select meta2.function_id((value->>'schema_name')::text, (value->>'name')::text, (select array_agg(value) from jsonb_array_elements_text(value->'parameters'))) $_$ immutable language sql;
create cast (jsonb as meta2.function_id) with function meta2.function_id(jsonb) as assignment;
create type meta2.operator_id as (schema_name text,name text,left_arg_type_schema_name text,left_arg_type_name text,right_arg_type_schema_name text,right_arg_type_name text);
create function meta2.operator_id(schema_name text,name text,left_arg_type_schema_name text,left_arg_type_name text,right_arg_type_schema_name text,right_arg_type_name text) returns meta2.operator_id as $_$ select row(schema_name,name,left_arg_type_schema_name,left_arg_type_name,right_arg_type_schema_name,right_arg_type_name)::meta2.operator_id $_$ language sql immutable;
create function meta2.meta_id(operator_id meta2.operator_id) returns meta2.meta_id as $_$ select meta2.meta_id('operator'); $_$ language sql;
create function meta2.eq(leftarg meta2.operator_id, rightarg jsonb) returns boolean as $_$select ((leftarg).schema_name)::text = (rightarg)->>'schema_name' and ((leftarg).name)::text = (rightarg)->>'name' and ((leftarg).left_arg_type_schema_name)::text = (rightarg)->>'left_arg_type_schema_name' and ((leftarg).left_arg_type_name)::text = (rightarg)->>'left_arg_type_name' and ((leftarg).right_arg_type_schema_name)::text = (rightarg)->>'right_arg_type_schema_name' and ((leftarg).right_arg_type_name)::text = (rightarg)->>'right_arg_type_name'$_$ language sql;
create operator meta2.= (leftarg = meta2.operator_id, rightarg = jsonb, procedure = meta2.eq);
create function meta2.operator_id(value jsonb) returns meta2.operator_id as $_$select meta2.operator_id((value->>'schema_name')::text, (value->>'name')::text, (value->>'left_arg_type_schema_name')::text, (value->>'left_arg_type_name')::text, (value->>'right_arg_type_schema_name')::text, (value->>'right_arg_type_name')::text) $_$ immutable language sql;
create cast (jsonb as meta2.operator_id) with function meta2.operator_id(jsonb) as assignment;
create type meta2.policy_id as (schema_name text,relation_name text,name text);
create function meta2.policy_id(schema_name text,relation_name text,name text) returns meta2.policy_id as $_$ select row(schema_name,relation_name,name)::meta2.policy_id $_$ language sql immutable;
create function meta2.meta_id(policy_id meta2.policy_id) returns meta2.meta_id as $_$ select meta2.meta_id('policy'); $_$ language sql;
create function meta2.eq(leftarg meta2.policy_id, rightarg jsonb) returns boolean as $_$select ((leftarg).schema_name)::text = (rightarg)->>'schema_name' and ((leftarg).relation_name)::text = (rightarg)->>'relation_name' and ((leftarg).name)::text = (rightarg)->>'name'$_$ language sql;
create operator meta2.= (leftarg = meta2.policy_id, rightarg = jsonb, procedure = meta2.eq);
create function meta2.policy_id(value jsonb) returns meta2.policy_id as $_$select meta2.policy_id((value->>'schema_name')::text, (value->>'relation_name')::text, (value->>'name')::text) $_$ immutable language sql;
create cast (jsonb as meta2.policy_id) with function meta2.policy_id(jsonb) as assignment;
create type meta2.relation_id as (schema_name text,name text);
create function meta2.relation_id(schema_name text,name text) returns meta2.relation_id as $_$ select row(schema_name,name)::meta2.relation_id $_$ language sql immutable;
create function meta2.meta_id(relation_id meta2.relation_id) returns meta2.meta_id as $_$ select meta2.meta_id('relation'); $_$ language sql;
create function meta2.eq(leftarg meta2.relation_id, rightarg jsonb) returns boolean as $_$select ((leftarg).schema_name)::text = (rightarg)->>'schema_name' and ((leftarg).name)::text = (rightarg)->>'name'$_$ language sql;
create operator meta2.= (leftarg = meta2.relation_id, rightarg = jsonb, procedure = meta2.eq);
create function meta2.relation_id(value jsonb) returns meta2.relation_id as $_$select meta2.relation_id((value->>'schema_name')::text, (value->>'name')::text) $_$ immutable language sql;
create cast (jsonb as meta2.relation_id) with function meta2.relation_id(jsonb) as assignment;
create type meta2.role_id as (name text);
create function meta2.role_id(name text) returns meta2.role_id as $_$ select row(name)::meta2.role_id $_$ language sql immutable;
create function meta2.meta_id(role_id meta2.role_id) returns meta2.meta_id as $_$ select meta2.meta_id('role'); $_$ language sql;
create function meta2.eq(leftarg meta2.role_id, rightarg jsonb) returns boolean as $_$select ((leftarg).name)::text = (rightarg)->>'name'$_$ language sql;
create operator meta2.= (leftarg = meta2.role_id, rightarg = jsonb, procedure = meta2.eq);
create function meta2.role_id(value jsonb) returns meta2.role_id as $_$select meta2.role_id((value->>'name')::text) $_$ immutable language sql;
create cast (jsonb as meta2.role_id) with function meta2.role_id(jsonb) as assignment;
create type meta2.row_id as (schema_name text,relation_name text,pk_column_name text,pk_value text);
create function meta2.row_id(schema_name text,relation_name text,pk_column_name text,pk_value text) returns meta2.row_id as $_$ select row(schema_name,relation_name,pk_column_name,pk_value)::meta2.row_id $_$ language sql immutable;
create function meta2.meta_id(row_id meta2.row_id) returns meta2.meta_id as $_$ select meta2.meta_id('row'); $_$ language sql;
create function meta2.eq(leftarg meta2.row_id, rightarg jsonb) returns boolean as $_$select ((leftarg).schema_name)::text = (rightarg)->>'schema_name' and ((leftarg).relation_name)::text = (rightarg)->>'relation_name' and ((leftarg).pk_column_name)::text = (rightarg)->>'pk_column_name' and ((leftarg).pk_value)::text = (rightarg)->>'pk_value'$_$ language sql;
create operator meta2.= (leftarg = meta2.row_id, rightarg = jsonb, procedure = meta2.eq);
create function meta2.row_id(value jsonb) returns meta2.row_id as $_$select meta2.row_id((value->>'schema_name')::text, (value->>'relation_name')::text, (value->>'pk_column_name')::text, (value->>'pk_value')::text) $_$ immutable language sql;
create cast (jsonb as meta2.row_id) with function meta2.row_id(jsonb) as assignment;
create type meta2.schema_id as (name text);
create function meta2.schema_id(name text) returns meta2.schema_id as $_$ select row(name)::meta2.schema_id $_$ language sql immutable;
create function meta2.meta_id(schema_id meta2.schema_id) returns meta2.meta_id as $_$ select meta2.meta_id('schema'); $_$ language sql;
create function meta2.eq(leftarg meta2.schema_id, rightarg jsonb) returns boolean as $_$select ((leftarg).name)::text = (rightarg)->>'name'$_$ language sql;
create operator meta2.= (leftarg = meta2.schema_id, rightarg = jsonb, procedure = meta2.eq);
create function meta2.schema_id(value jsonb) returns meta2.schema_id as $_$select meta2.schema_id((value->>'name')::text) $_$ immutable language sql;
create cast (jsonb as meta2.schema_id) with function meta2.schema_id(jsonb) as assignment;
create type meta2.sequence_id as (schema_name text,name text);
create function meta2.sequence_id(schema_name text,name text) returns meta2.sequence_id as $_$ select row(schema_name,name)::meta2.sequence_id $_$ language sql immutable;
create function meta2.meta_id(sequence_id meta2.sequence_id) returns meta2.meta_id as $_$ select meta2.meta_id('sequence'); $_$ language sql;
create function meta2.eq(leftarg meta2.sequence_id, rightarg jsonb) returns boolean as $_$select ((leftarg).schema_name)::text = (rightarg)->>'schema_name' and ((leftarg).name)::text = (rightarg)->>'name'$_$ language sql;
create operator meta2.= (leftarg = meta2.sequence_id, rightarg = jsonb, procedure = meta2.eq);
create function meta2.sequence_id(value jsonb) returns meta2.sequence_id as $_$select meta2.sequence_id((value->>'schema_name')::text, (value->>'name')::text) $_$ immutable language sql;
create cast (jsonb as meta2.sequence_id) with function meta2.sequence_id(jsonb) as assignment;
create type meta2.table_id as (schema_name text,name text);
create function meta2.table_id(schema_name text,name text) returns meta2.table_id as $_$ select row(schema_name,name)::meta2.table_id $_$ language sql immutable;
create function meta2.meta_id(table_id meta2.table_id) returns meta2.meta_id as $_$ select meta2.meta_id('table'); $_$ language sql;
create function meta2.eq(leftarg meta2.table_id, rightarg jsonb) returns boolean as $_$select ((leftarg).schema_name)::text = (rightarg)->>'schema_name' and ((leftarg).name)::text = (rightarg)->>'name'$_$ language sql;
create operator meta2.= (leftarg = meta2.table_id, rightarg = jsonb, procedure = meta2.eq);
create function meta2.table_id(value jsonb) returns meta2.table_id as $_$select meta2.table_id((value->>'schema_name')::text, (value->>'name')::text) $_$ immutable language sql;
create cast (jsonb as meta2.table_id) with function meta2.table_id(jsonb) as assignment;
create type meta2.table_privilege_id as (schema_name text,relation_name text,role text,type text);
create function meta2.table_privilege_id(schema_name text,relation_name text,role text,type text) returns meta2.table_privilege_id as $_$ select row(schema_name,relation_name,role,type)::meta2.table_privilege_id $_$ language sql immutable;
create function meta2.meta_id(table_privilege_id meta2.table_privilege_id) returns meta2.meta_id as $_$ select meta2.meta_id('table_privilege'); $_$ language sql;
create function meta2.eq(leftarg meta2.table_privilege_id, rightarg jsonb) returns boolean as $_$select ((leftarg).schema_name)::text = (rightarg)->>'schema_name' and ((leftarg).relation_name)::text = (rightarg)->>'relation_name' and ((leftarg).role)::text = (rightarg)->>'role' and ((leftarg).type)::text = (rightarg)->>'type'$_$ language sql;
create operator meta2.= (leftarg = meta2.table_privilege_id, rightarg = jsonb, procedure = meta2.eq);
create function meta2.table_privilege_id(value jsonb) returns meta2.table_privilege_id as $_$select meta2.table_privilege_id((value->>'schema_name')::text, (value->>'relation_name')::text, (value->>'role')::text, (value->>'type')::text) $_$ immutable language sql;
create cast (jsonb as meta2.table_privilege_id) with function meta2.table_privilege_id(jsonb) as assignment;
create type meta2.trigger_id as (schema_name text,relation_name text,name text);
create function meta2.trigger_id(schema_name text,relation_name text,name text) returns meta2.trigger_id as $_$ select row(schema_name,relation_name,name)::meta2.trigger_id $_$ language sql immutable;
create function meta2.meta_id(trigger_id meta2.trigger_id) returns meta2.meta_id as $_$ select meta2.meta_id('trigger'); $_$ language sql;
create function meta2.eq(leftarg meta2.trigger_id, rightarg jsonb) returns boolean as $_$select ((leftarg).schema_name)::text = (rightarg)->>'schema_name' and ((leftarg).relation_name)::text = (rightarg)->>'relation_name' and ((leftarg).name)::text = (rightarg)->>'name'$_$ language sql;
create operator meta2.= (leftarg = meta2.trigger_id, rightarg = jsonb, procedure = meta2.eq);
create function meta2.trigger_id(value jsonb) returns meta2.trigger_id as $_$select meta2.trigger_id((value->>'schema_name')::text, (value->>'relation_name')::text, (value->>'name')::text) $_$ immutable language sql;
create cast (jsonb as meta2.trigger_id) with function meta2.trigger_id(jsonb) as assignment;
create type meta2.type_id as (schema_name text,name text);
create function meta2.type_id(schema_name text,name text) returns meta2.type_id as $_$ select row(schema_name,name)::meta2.type_id $_$ language sql immutable;
create function meta2.meta_id(type_id meta2.type_id) returns meta2.meta_id as $_$ select meta2.meta_id('type'); $_$ language sql;
create function meta2.eq(leftarg meta2.type_id, rightarg jsonb) returns boolean as $_$select ((leftarg).schema_name)::text = (rightarg)->>'schema_name' and ((leftarg).name)::text = (rightarg)->>'name'$_$ language sql;
create operator meta2.= (leftarg = meta2.type_id, rightarg = jsonb, procedure = meta2.eq);
create function meta2.type_id(value jsonb) returns meta2.type_id as $_$select meta2.type_id((value->>'schema_name')::text, (value->>'name')::text) $_$ immutable language sql;
create cast (jsonb as meta2.type_id) with function meta2.type_id(jsonb) as assignment;
create type meta2.view_id as (schema_name text,name text);
create function meta2.view_id(schema_name text,name text) returns meta2.view_id as $_$ select row(schema_name,name)::meta2.view_id $_$ language sql immutable;
create function meta2.meta_id(view_id meta2.view_id) returns meta2.meta_id as $_$ select meta2.meta_id('view'); $_$ language sql;
create function meta2.eq(leftarg meta2.view_id, rightarg jsonb) returns boolean as $_$select ((leftarg).schema_name)::text = (rightarg)->>'schema_name' and ((leftarg).name)::text = (rightarg)->>'name'$_$ language sql;
create operator meta2.= (leftarg = meta2.view_id, rightarg = jsonb, procedure = meta2.eq);
create function meta2.view_id(value jsonb) returns meta2.view_id as $_$select meta2.view_id((value->>'schema_name')::text, (value->>'name')::text) $_$ immutable language sql;
create cast (jsonb as meta2.view_id) with function meta2.view_id(jsonb) as assignment;

create function meta2.column_id_to_schema_id(column_id meta2.column_id) returns meta2.schema_id as $_$select meta2.schema_id((column_id).schema_name) $_$ immutable language sql;
create cast (meta2.column_id as meta2.schema_id) with function meta2.column_id_to_schema_id(meta2.column_id) as assignment;
create function meta2.constraint_id_to_schema_id(constraint_id meta2.constraint_id) returns meta2.schema_id as $_$select meta2.schema_id((constraint_id).schema_name) $_$ immutable language sql;
create cast (meta2.constraint_id as meta2.schema_id) with function meta2.constraint_id_to_schema_id(meta2.constraint_id) as assignment;
create function meta2.constraint_check_id_to_schema_id(constraint_check_id meta2.constraint_check_id) returns meta2.schema_id as $_$select meta2.schema_id((constraint_check_id).schema_name) $_$ immutable language sql;
create cast (meta2.constraint_check_id as meta2.schema_id) with function meta2.constraint_check_id_to_schema_id(meta2.constraint_check_id) as assignment;
create function meta2.constraint_unique_id_to_schema_id(constraint_unique_id meta2.constraint_unique_id) returns meta2.schema_id as $_$select meta2.schema_id((constraint_unique_id).schema_name) $_$ immutable language sql;
create cast (meta2.constraint_unique_id as meta2.schema_id) with function meta2.constraint_unique_id_to_schema_id(meta2.constraint_unique_id) as assignment;
create function meta2.field_id_to_schema_id(field_id meta2.field_id) returns meta2.schema_id as $_$select meta2.schema_id((field_id).schema_name) $_$ immutable language sql;
create cast (meta2.field_id as meta2.schema_id) with function meta2.field_id_to_schema_id(meta2.field_id) as assignment;
create function meta2.foreign_column_id_to_schema_id(foreign_column_id meta2.foreign_column_id) returns meta2.schema_id as $_$select meta2.schema_id((foreign_column_id).schema_name) $_$ immutable language sql;
create cast (meta2.foreign_column_id as meta2.schema_id) with function meta2.foreign_column_id_to_schema_id(meta2.foreign_column_id) as assignment;
create function meta2.foreign_key_id_to_schema_id(foreign_key_id meta2.foreign_key_id) returns meta2.schema_id as $_$select meta2.schema_id((foreign_key_id).schema_name) $_$ immutable language sql;
create cast (meta2.foreign_key_id as meta2.schema_id) with function meta2.foreign_key_id_to_schema_id(meta2.foreign_key_id) as assignment;
create function meta2.foreign_table_id_to_schema_id(foreign_table_id meta2.foreign_table_id) returns meta2.schema_id as $_$select meta2.schema_id((foreign_table_id).schema_name) $_$ immutable language sql;
create cast (meta2.foreign_table_id as meta2.schema_id) with function meta2.foreign_table_id_to_schema_id(meta2.foreign_table_id) as assignment;
create function meta2.function_id_to_schema_id(function_id meta2.function_id) returns meta2.schema_id as $_$select meta2.schema_id((function_id).schema_name) $_$ immutable language sql;
create cast (meta2.function_id as meta2.schema_id) with function meta2.function_id_to_schema_id(meta2.function_id) as assignment;
create function meta2.operator_id_to_schema_id(operator_id meta2.operator_id) returns meta2.schema_id as $_$select meta2.schema_id((operator_id).schema_name) $_$ immutable language sql;
create cast (meta2.operator_id as meta2.schema_id) with function meta2.operator_id_to_schema_id(meta2.operator_id) as assignment;
create function meta2.policy_id_to_schema_id(policy_id meta2.policy_id) returns meta2.schema_id as $_$select meta2.schema_id((policy_id).schema_name) $_$ immutable language sql;
create cast (meta2.policy_id as meta2.schema_id) with function meta2.policy_id_to_schema_id(meta2.policy_id) as assignment;
create function meta2.relation_id_to_schema_id(relation_id meta2.relation_id) returns meta2.schema_id as $_$select meta2.schema_id((relation_id).schema_name) $_$ immutable language sql;
create cast (meta2.relation_id as meta2.schema_id) with function meta2.relation_id_to_schema_id(meta2.relation_id) as assignment;
create function meta2.row_id_to_schema_id(row_id meta2.row_id) returns meta2.schema_id as $_$select meta2.schema_id((row_id).schema_name) $_$ immutable language sql;
create cast (meta2.row_id as meta2.schema_id) with function meta2.row_id_to_schema_id(meta2.row_id) as assignment;
create function meta2.sequence_id_to_schema_id(sequence_id meta2.sequence_id) returns meta2.schema_id as $_$select meta2.schema_id((sequence_id).schema_name) $_$ immutable language sql;
create cast (meta2.sequence_id as meta2.schema_id) with function meta2.sequence_id_to_schema_id(meta2.sequence_id) as assignment;
create function meta2.table_id_to_schema_id(table_id meta2.table_id) returns meta2.schema_id as $_$select meta2.schema_id((table_id).schema_name) $_$ immutable language sql;
create cast (meta2.table_id as meta2.schema_id) with function meta2.table_id_to_schema_id(meta2.table_id) as assignment;
create function meta2.table_privilege_id_to_schema_id(table_privilege_id meta2.table_privilege_id) returns meta2.schema_id as $_$select meta2.schema_id((table_privilege_id).schema_name) $_$ immutable language sql;
create cast (meta2.table_privilege_id as meta2.schema_id) with function meta2.table_privilege_id_to_schema_id(meta2.table_privilege_id) as assignment;
create function meta2.trigger_id_to_schema_id(trigger_id meta2.trigger_id) returns meta2.schema_id as $_$select meta2.schema_id((trigger_id).schema_name) $_$ immutable language sql;
create cast (meta2.trigger_id as meta2.schema_id) with function meta2.trigger_id_to_schema_id(meta2.trigger_id) as assignment;
create function meta2.type_id_to_schema_id(type_id meta2.type_id) returns meta2.schema_id as $_$select meta2.schema_id((type_id).schema_name) $_$ immutable language sql;
create cast (meta2.type_id as meta2.schema_id) with function meta2.type_id_to_schema_id(meta2.type_id) as assignment;
create function meta2.view_id_to_schema_id(view_id meta2.view_id) returns meta2.schema_id as $_$select meta2.schema_id((view_id).schema_name) $_$ immutable language sql;
create cast (meta2.view_id as meta2.schema_id) with function meta2.view_id_to_schema_id(meta2.view_id) as assignment;

create function meta2.column_id_to_relation_id(column_id meta2.column_id) returns meta2.relation_id as $_$select meta2.relation_id((column_id).schema_name, (column_id).relation_name) $_$ immutable language sql;
create cast (meta2.column_id as meta2.relation_id) with function meta2.column_id_to_relation_id(meta2.column_id) as assignment;
create function meta2.constraint_id_to_relation_id(constraint_id meta2.constraint_id) returns meta2.relation_id as $_$select meta2.relation_id((constraint_id).schema_name, (constraint_id).relation_name) $_$ immutable language sql;
create cast (meta2.constraint_id as meta2.relation_id) with function meta2.constraint_id_to_relation_id(meta2.constraint_id) as assignment;
create function meta2.field_id_to_relation_id(field_id meta2.field_id) returns meta2.relation_id as $_$select meta2.relation_id((field_id).schema_name, (field_id).relation_name) $_$ immutable language sql;
create cast (meta2.field_id as meta2.relation_id) with function meta2.field_id_to_relation_id(meta2.field_id) as assignment;
create function meta2.foreign_key_id_to_relation_id(foreign_key_id meta2.foreign_key_id) returns meta2.relation_id as $_$select meta2.relation_id((foreign_key_id).schema_name, (foreign_key_id).relation_name) $_$ immutable language sql;
create cast (meta2.foreign_key_id as meta2.relation_id) with function meta2.foreign_key_id_to_relation_id(meta2.foreign_key_id) as assignment;
create function meta2.policy_id_to_relation_id(policy_id meta2.policy_id) returns meta2.relation_id as $_$select meta2.relation_id((policy_id).schema_name, (policy_id).relation_name) $_$ immutable language sql;
create cast (meta2.policy_id as meta2.relation_id) with function meta2.policy_id_to_relation_id(meta2.policy_id) as assignment;
create function meta2.row_id_to_relation_id(row_id meta2.row_id) returns meta2.relation_id as $_$select meta2.relation_id((row_id).schema_name, (row_id).relation_name) $_$ immutable language sql;
create cast (meta2.row_id as meta2.relation_id) with function meta2.row_id_to_relation_id(meta2.row_id) as assignment;
create function meta2.table_privilege_id_to_relation_id(table_privilege_id meta2.table_privilege_id) returns meta2.relation_id as $_$select meta2.relation_id((table_privilege_id).schema_name, (table_privilege_id).relation_name) $_$ immutable language sql;
create cast (meta2.table_privilege_id as meta2.relation_id) with function meta2.table_privilege_id_to_relation_id(meta2.table_privilege_id) as assignment;
create function meta2.trigger_id_to_relation_id(trigger_id meta2.trigger_id) returns meta2.relation_id as $_$select meta2.relation_id((trigger_id).schema_name, (trigger_id).relation_name) $_$ immutable language sql;
create cast (meta2.trigger_id as meta2.relation_id) with function meta2.trigger_id_to_relation_id(meta2.trigger_id) as assignment;

create function meta2.field_id_to_column_id(field_id meta2.field_id) returns meta2.column_id as $_$select meta2.column_id((field_id).schema_name, (field_id).relation_name, (field_id).column_name) $_$ immutable language sql;
create cast (meta2.field_id as meta2.column_id) with function meta2.field_id_to_column_id(meta2.field_id) as assignment;

create function meta2.field_id_to_row_id(field_id meta2.field_id) returns meta2.row_id as $_$select meta2.row_id((field_id).schema_name, (field_id).relation_name, (field_id).pk_column_name, (field_id).pk_value) $_$ immutable language sql;
create cast (meta2.field_id as meta2.row_id) with function meta2.field_id_to_row_id(meta2.field_id) as assignment;

commit;
