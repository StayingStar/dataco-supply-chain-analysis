-- Run once, as your admin role:  psql -f sql/00_setup.sql
CREATE DATABASE dataco;

-- A login the AI agent and pgAdmin use. It can read data, never change it.
CREATE ROLE dataco_reader LOGIN PASSWORD 'H@patel#2002!';
ALTER ROLE dataco_reader SET default_transaction_read_only = on;
ALTER ROLE dataco_reader SET statement_timeout = '15s';
GRANT CONNECT ON DATABASE dataco TO dataco_reader;