-- CPAN 363 Lab 2: sanitized reference, not an execution transcript.
-- Run sections manually in an isolated lab; creation is not rerunnable.
-- Replace placeholders only in a private working copy. Never commit passwords.

-- 1A. ADMINISTRATOR connection to master
CREATE LOGIN reporting_login WITH PASSWORD = '<set-privately>';
SELECT name, is_disabled FROM sys.sql_logins WHERE name = 'reporting_login';
GO
-- CLIENT TEST: a NEW reporting_login connection to the target database
-- should fail before the database user exists. Capture the actual error.

-- 1B. ADMINISTRATOR connection to target lab database (not master)
CREATE USER reporting_user FOR LOGIN reporting_login;
GO
-- CLIENT TEST: reconnect as reporting_login to target database, then run:
SELECT USER_NAME() AS CurrentUser, DB_NAME() AS CurrentDatabase;
GO

-- 2. ADMINISTRATOR connection to target lab database
CREATE USER app_reader WITH PASSWORD = '<set-privately>';
GO
SELECT name, type_desc, authentication_type_desc
FROM sys.database_principals
WHERE name IN ('reporting_user', 'app_reader');
GO

-- 3. ENTRA ADMINISTRATOR connection to target lab database
-- First configure the Entra administrator and sign in using the client.
-- Replace the example with an existing, resolvable tenant identity privately.
CREATE USER [lab-user@example.com] FROM EXTERNAL PROVIDER;
GO
SELECT name, authentication_type_desc FROM sys.database_principals
WHERE authentication_type_desc = 'EXTERNAL';
GO

-- 4A. ADMINISTRATOR connection to target lab database
DENY CONNECT TO app_reader;
GO
-- CLIENT TEST: attempt a NEW app_reader connection and capture the failure.
-- Back on the administrator connection:
GRANT CONNECT TO app_reader;
GO
-- CLIENT TEST: reconnect as app_reader and confirm access is restored.

-- 4B. ADMINISTRATOR connection to master
-- DISABLE restored from the documented screenshot; omitted in source SQL.
ALTER LOGIN reporting_login DISABLE;
SELECT name, is_disabled FROM sys.sql_logins WHERE name = 'reporting_login';
GO
ALTER LOGIN reporting_login ENABLE;
SELECT name, is_disabled FROM sys.sql_logins WHERE name = 'reporting_login';
GO
