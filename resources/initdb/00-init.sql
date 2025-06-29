-- init.sql

-- Create databases if needed
CREATE DATABASE litellm;
CREATE DATABASE openwebui;
CREATE DATABASE n8n;

-- Create users with strong passwords
CREATE USER litellm_user WITH ENCRYPTED PASSWORD 'litellm_pass';
CREATE USER openwebui_user WITH ENCRYPTED PASSWORD 'openwebui_pass';
CREATE USER n8n_user WITH ENCRYPTED PASSWORD 'n8n_pass';

-- Grant access to each DB
GRANT ALL PRIVILEGES ON DATABASE litellm TO litellm_user;
GRANT ALL PRIVILEGES ON DATABASE openwebui TO openwebui_user;
GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n_user;

-- Grant privileges in `litellm`
\connect litellm

GRANT USAGE, CREATE ON SCHEMA public TO litellm_user;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  GRANT ALL ON TABLES TO litellm_user;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  GRANT ALL ON SEQUENCES TO litellm_user;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  GRANT ALL ON TYPES TO litellm_user;

-- Grant privileges in `openwebui`
\connect openwebui

GRANT USAGE, CREATE ON SCHEMA public TO openwebui_user;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  GRANT ALL ON TABLES TO openwebui_user;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  GRANT ALL ON SEQUENCES TO openwebui_user;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  GRANT ALL ON TYPES TO openwebui_user;

-- Grant privileges in `n8n`
\connect n8n

GRANT USAGE, CREATE ON SCHEMA public TO n8n_user;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  GRANT ALL ON TABLES TO n8n_user;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  GRANT ALL ON SEQUENCES TO n8n_user;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  GRANT ALL ON TYPES TO n8n_user;