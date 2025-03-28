-- Create supabase_admin role if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'supabase_admin') THEN
    CREATE ROLE supabase_admin WITH LOGIN SUPERUSER PASSWORD '${SUPABASE_DB_PASSWORD}';
  END IF;
END
$$;

-- Enable extensions if not already enabled
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE SCHEMA IF NOT EXISTS auth;

-- Create llms table to store model information
create table public.llms (
  id bigint generated by default as identity not null,
  active boolean not null default false,
  vision boolean not null default false,
  content boolean not null default false,
  structured_content boolean not null default false,
  embeddings boolean not null default false,
  provider character varying not null,
  name character varying not null,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint llms_pkey primary key (id),
  constraint llms_id_key unique (id),
  constraint llms_name_key unique (name)
) TABLESPACE pg_default;

-- Insert default Ollama models
INSERT INTO llms (name, provider, active, embeddings, content) VALUES
    ('mxbai-embed-large', 'ollama', true, true, false);
