/* =========================================================================
   CPAN 363 - DATABASE SECURITY
   LAB 5 SETUP SCRIPT - the starting point for "Stored Procedures and SQL Injection"

   WHY THIS EXISTS
   -----------------------------------------------------------------------
   The Week 5 laboratory was replaced with a quiz, so Lab 4 was never run.
   Lab 5 expects the database that Lab 4 would have produced:

       - the app, sensitive and reporting schemas
       - app.Employees and sensitive.Salaries (moved out of dbo)
       - two reporting views that never show an actual salary
       - the roles support_role, hr_role and analyst_role
       - the test users support_user, hr_user and analyst_user
       - schema-level GRANTs, and the DENY on the sensitive schema

   This script builds all of that in one run.

   YOU ARE NOT MARKED ON THIS SCRIPT. It is scaffolding, not an assignment.
   Run it, read the report at the bottom, then start Lab 5 at Part 1.

   HOW TO RUN IT
   -----------------------------------------------------------------------
   1. Connect to your own database as the administrator login you created
      in Lab 1. (You need db_owner. EXECUTE AS will not work otherwise.)
   2. Open this file in SQL Server Management Studio or Azure Data Studio
      and run the whole file once.
      Using the Azure portal Query Editor? It does not understand GO.
      Run the script one section at a time, stopping at each GO.
   3. Read section 8. Every line should say OK.

   IT IS SAFE TO RUN TWICE
   -----------------------------------------------------------------------
   Every step checks before it acts. If you already completed part of Lab 4,
   only the missing pieces are added and your own work is left alone.
   This script never drops a table and never deletes a row.

   Made-up data only. Never put real personal information in a lab database.
   ========================================================================= */


/* -------------------------------------------------------------------------
   1. SCHEMAS
   All three are owned by dbo on purpose.

   Lab 5 Part 1 depends on OWNERSHIP CHAINING: a stored procedure in the app
   schema is allowed to read a table in the sensitive schema because both
   schemas have the same owner. If the owners differ, the chain is broken and
   Lab 5 Part 1.2 fails with a permission error. Section 8 checks this for you.
   ------------------------------------------------------------------------- */
IF SCHEMA_ID(N'app')       IS NULL EXEC(N'CREATE SCHEMA app       AUTHORIZATION dbo;');
IF SCHEMA_ID(N'sensitive') IS NULL EXEC(N'CREATE SCHEMA sensitive AUTHORIZATION dbo;');
IF SCHEMA_ID(N'reporting') IS NULL EXEC(N'CREATE SCHEMA reporting AUTHORIZATION dbo;');
GO

-- If a schema already existed under a different owner, hand it to dbo so the
-- ownership chain is unbroken.
DECLARE @fix NVARCHAR(MAX) = N'';
SELECT @fix = @fix + N'ALTER AUTHORIZATION ON SCHEMA::' + QUOTENAME(s.name) + N' TO dbo;'
FROM   sys.schemas AS s
WHERE  s.name IN (N'app', N'sensitive', N'reporting')
  AND  s.principal_id <> USER_ID(N'dbo');
IF @fix <> N'' EXEC sys.sp_executesql @fix;
GO


/* -------------------------------------------------------------------------
   2. TABLES
   Lab 3 created these as dbo.Employees and dbo.Salaries. Lab 4 would have
   moved them into the new schemas. If they are still in dbo they are moved
   here; if you never created them they are created now.
   ------------------------------------------------------------------------- */
IF OBJECT_ID(N'app.Employees', N'U') IS NULL
   AND OBJECT_ID(N'dbo.Employees', N'U') IS NOT NULL
    ALTER SCHEMA app TRANSFER dbo.Employees;
GO

IF OBJECT_ID(N'app.Employees', N'U') IS NULL
    CREATE TABLE app.Employees
    ( EmployeeID  INT IDENTITY PRIMARY KEY,
      FullName    NVARCHAR(100),
      Department  NVARCHAR(60),
      OfficePhone VARCHAR(20) );
GO

IF OBJECT_ID(N'sensitive.Salaries', N'U') IS NULL
   AND OBJECT_ID(N'dbo.Salaries', N'U') IS NOT NULL
    ALTER SCHEMA sensitive TRANSFER dbo.Salaries;
GO

IF OBJECT_ID(N'sensitive.Salaries', N'U') IS NULL
    CREATE TABLE sensitive.Salaries
    ( EmployeeID INT PRIMARY KEY,
      Salary     MONEY );
GO


-- Safety net: if your Lab 3 tables are missing a column (a typo, or you built
-- them differently), add it back so the views and Lab 5 procedures compile.
IF COL_LENGTH(N'app.Employees', N'FullName')    IS NULL ALTER TABLE app.Employees      ADD FullName    NVARCHAR(100);
IF COL_LENGTH(N'app.Employees', N'Department')  IS NULL ALTER TABLE app.Employees      ADD Department  NVARCHAR(60);
IF COL_LENGTH(N'app.Employees', N'OfficePhone') IS NULL ALTER TABLE app.Employees      ADD OfficePhone VARCHAR(20);
IF COL_LENGTH(N'sensitive.Salaries', N'Salary') IS NULL ALTER TABLE sensitive.Salaries ADD Salary      MONEY;
GO

/* -------------------------------------------------------------------------
   3. DATA
   The same three made-up employees used in Lab 3. Rows are added only if
   they are missing, so anything you already entered is kept.
   ------------------------------------------------------------------------- */
IF NOT EXISTS (SELECT 1 FROM app.Employees)
    INSERT INTO app.Employees (FullName, Department, OfficePhone) VALUES
      (N'Amara Okafor', N'Finance',    '416-555-0101'),
      (N'Bao Nguyen',   N'Operations', '416-555-0102'),
      (N'Carla Silva',  N'Finance',    '416-555-0103');
GO

-- Give any employee without a salary one. Lab 5 sorts salaries into three
-- bands, so the figures below deliberately fall either side of 60000 and 70000.
INSERT INTO sensitive.Salaries (EmployeeID, Salary)
SELECT e.EmployeeID,
       CASE e.FullName
            WHEN N'Amara Okafor' THEN 62000     -- Band B
            WHEN N'Bao Nguyen'   THEN 58000     -- Band A
            WHEN N'Carla Silva'  THEN 71000     -- Band C
            ELSE 60000
       END
FROM   app.Employees AS e
WHERE  NOT EXISTS (SELECT 1 FROM sensitive.Salaries AS s
                   WHERE  s.EmployeeID = e.EmployeeID);
GO


/* -------------------------------------------------------------------------
   4. app.Departments
   Lab 4 used this table to show that a schema-level grant also covers tables
   created later. Lab 5 does not read it, but it is part of the model you will
   be asked about, so it is built here too.
   ------------------------------------------------------------------------- */
IF OBJECT_ID(N'app.Departments', N'U') IS NULL
    CREATE TABLE app.Departments
    ( DepartmentID INT IDENTITY PRIMARY KEY,
      Name         NVARCHAR(60) );
GO

IF NOT EXISTS (SELECT 1 FROM app.Departments)
    INSERT INTO app.Departments (Name) VALUES (N'Finance'), (N'Operations'), (N'IT');
GO


/* -------------------------------------------------------------------------
   5. ROLES AND TEST USERS
   From Lab 3. The users have no login and no password - they exist only so
   you can switch to them with EXECUTE AS.
   ------------------------------------------------------------------------- */
IF DATABASE_PRINCIPAL_ID(N'support_role') IS NULL CREATE ROLE support_role;
IF DATABASE_PRINCIPAL_ID(N'hr_role')      IS NULL CREATE ROLE hr_role;
IF DATABASE_PRINCIPAL_ID(N'analyst_role') IS NULL CREATE ROLE analyst_role;
GO

IF DATABASE_PRINCIPAL_ID(N'support_user') IS NULL CREATE USER support_user WITHOUT LOGIN;
IF DATABASE_PRINCIPAL_ID(N'hr_user')      IS NULL CREATE USER hr_user      WITHOUT LOGIN;
IF DATABASE_PRINCIPAL_ID(N'analyst_user') IS NULL CREATE USER analyst_user WITHOUT LOGIN;
GO

IF IS_ROLEMEMBER(N'support_role', N'support_user') = 0 ALTER ROLE support_role ADD MEMBER support_user;
IF IS_ROLEMEMBER(N'hr_role',      N'hr_user')      = 0 ALTER ROLE hr_role      ADD MEMBER hr_user;
IF IS_ROLEMEMBER(N'analyst_role', N'analyst_user') = 0 ALTER ROLE analyst_role ADD MEMBER analyst_user;
GO


/* -------------------------------------------------------------------------
   6. REPORTING VIEWS
   The two views Lab 4 would have built. Neither shows an actual salary.
   ------------------------------------------------------------------------- */
CREATE OR ALTER VIEW reporting.vw_StaffDirectory
AS
SELECT EmployeeID, FullName, Department, OfficePhone
FROM   app.Employees;
GO

CREATE OR ALTER VIEW reporting.vw_SalaryBands
AS
SELECT e.EmployeeID,
       e.FullName,
       e.Department,
       CASE WHEN s.Salary < 60000 THEN N'Band A'
            WHEN s.Salary < 70000 THEN N'Band B'
            ELSE N'Band C' END AS PayBand
FROM   app.Employees      AS e
JOIN   sensitive.Salaries AS s ON s.EmployeeID = e.EmployeeID;
GO


/* -------------------------------------------------------------------------
   7. SCHEMA-LEVEL PERMISSIONS
   The access model from Lab 4. Running a GRANT or DENY again is harmless.
   ------------------------------------------------------------------------- */
-- Support desk: everyday data only, blocked from the sensitive schema
GRANT SELECT ON SCHEMA::app       TO support_role;
DENY  SELECT ON SCHEMA::sensitive TO support_role;

-- HR: read and change both business schemas
GRANT SELECT, INSERT, UPDATE ON SCHEMA::app       TO hr_role;
GRANT SELECT, INSERT, UPDATE ON SCHEMA::sensitive TO hr_role;

-- Analysts: the reporting views only
GRANT SELECT ON SCHEMA::reporting TO analyst_role;
GO


/* -------------------------------------------------------------------------
   8. REPORT - read this before you start Lab 5.
   Every row should say OK. If any row does not, see section 9.
   ------------------------------------------------------------------------- */
SELECT r.ord AS [#], r.check_name AS [Check], r.result AS [Result]
FROM (
    SELECT 1 AS ord, N'Schema app exists' AS check_name,
           CASE WHEN SCHEMA_ID(N'app') IS NOT NULL THEN N'OK' ELSE N'MISSING' END AS result
    UNION ALL SELECT 2, N'Schema sensitive exists',
           CASE WHEN SCHEMA_ID(N'sensitive') IS NOT NULL THEN N'OK' ELSE N'MISSING' END
    UNION ALL SELECT 3, N'Schema reporting exists',
           CASE WHEN SCHEMA_ID(N'reporting') IS NOT NULL THEN N'OK' ELSE N'MISSING' END
    UNION ALL SELECT 4, N'app and sensitive have the same owner (ownership chaining)',
           CASE WHEN (SELECT principal_id FROM sys.schemas WHERE name = N'app')
                   = (SELECT principal_id FROM sys.schemas WHERE name = N'sensitive')
                THEN N'OK' ELSE N'DIFFERENT OWNERS - Lab 5 Part 1 will fail' END
    UNION ALL SELECT 5, N'Table app.Employees exists',
           CASE WHEN OBJECT_ID(N'app.Employees', N'U') IS NOT NULL THEN N'OK' ELSE N'MISSING' END
    UNION ALL SELECT 6, N'Table sensitive.Salaries exists',
           CASE WHEN OBJECT_ID(N'sensitive.Salaries', N'U') IS NOT NULL THEN N'OK' ELSE N'MISSING' END
    UNION ALL SELECT 7, N'app.Employees has rows',
           CASE WHEN EXISTS (SELECT 1 FROM app.Employees) THEN N'OK' ELSE N'EMPTY' END
    UNION ALL SELECT 8, N'Every employee has a salary',
           CASE WHEN NOT EXISTS (SELECT 1 FROM app.Employees AS e
                                 WHERE NOT EXISTS (SELECT 1 FROM sensitive.Salaries AS s
                                                   WHERE s.EmployeeID = e.EmployeeID))
                THEN N'OK' ELSE N'SOME MISSING' END
    UNION ALL SELECT 9, N'All three pay bands are represented',
           CASE WHEN (SELECT COUNT(DISTINCT CASE WHEN Salary < 60000 THEN 1
                                                 WHEN Salary < 70000 THEN 2
                                                 ELSE 3 END)
                      FROM sensitive.Salaries) = 3
                THEN N'OK' ELSE N'ONLY SOME - Lab 5 still works' END
    UNION ALL SELECT 10, N'View reporting.vw_StaffDirectory exists',
           CASE WHEN OBJECT_ID(N'reporting.vw_StaffDirectory', N'V') IS NOT NULL THEN N'OK' ELSE N'MISSING' END
    UNION ALL SELECT 11, N'View reporting.vw_SalaryBands exists',
           CASE WHEN OBJECT_ID(N'reporting.vw_SalaryBands', N'V') IS NOT NULL THEN N'OK' ELSE N'MISSING' END
    UNION ALL SELECT 12, N'Role support_role exists',
           CASE WHEN DATABASE_PRINCIPAL_ID(N'support_role') IS NOT NULL THEN N'OK' ELSE N'MISSING' END
    UNION ALL SELECT 13, N'support_user is a member of support_role',
           CASE WHEN IS_ROLEMEMBER(N'support_role', N'support_user') = 1 THEN N'OK' ELSE N'NOT A MEMBER' END
    UNION ALL SELECT 14, N'GRANT SELECT on SCHEMA::app to support_role',
           CASE WHEN EXISTS (SELECT 1 FROM sys.database_permissions AS p
                             JOIN sys.schemas AS s ON s.schema_id = p.major_id
                             WHERE p.class = 3 AND s.name = N'app'
                               AND p.permission_name = N'SELECT' AND p.state_desc = N'GRANT'
                               AND p.grantee_principal_id = DATABASE_PRINCIPAL_ID(N'support_role'))
                THEN N'OK' ELSE N'MISSING' END
    UNION ALL SELECT 15, N'DENY SELECT on SCHEMA::sensitive to support_role',
           CASE WHEN EXISTS (SELECT 1 FROM sys.database_permissions AS p
                             JOIN sys.schemas AS s ON s.schema_id = p.major_id
                             WHERE p.class = 3 AND s.name = N'sensitive'
                               AND p.permission_name = N'SELECT' AND p.state_desc = N'DENY'
                               AND p.grantee_principal_id = DATABASE_PRINCIPAL_ID(N'support_role'))
                THEN N'OK' ELSE N'MISSING' END
) AS r
ORDER BY r.ord;
GO

-- The same two outcomes Lab 5 Part 1.2 asks you to prove, checked in advance.
EXECUTE AS USER = 'support_user';
    SELECT N'support_user can read app.Employees' AS [Check],
           CASE WHEN HAS_PERMS_BY_NAME(N'app.Employees', N'OBJECT', N'SELECT') = 1
                THEN N'OK' ELSE N'PROBLEM' END AS [Result]
    UNION ALL
    SELECT N'support_user is blocked from sensitive.Salaries',
           CASE WHEN HAS_PERMS_BY_NAME(N'sensitive.Salaries', N'OBJECT', N'SELECT') = 0
                THEN N'OK' ELSE N'PROBLEM' END;
REVERT;
GO


/* -------------------------------------------------------------------------
   9. CLEAN SLATE - only if your database is in a mess

   If the report above still shows problems after a second run, the quickest
   fix is to tear this part of the database down and let the script rebuild it.
   This deletes the employee and salary tables and the three test users.
   It does not touch anything you built in Labs 1 or 2.

   To use it: select the block below and uncomment it
   (in SSMS or Azure Data Studio, Ctrl+K then Ctrl+U), run it on its own,
   then run this whole script again from the top.
   ------------------------------------------------------------------------- */

-- DROP VIEW IF EXISTS reporting.vw_StaffDirectory;
-- DROP VIEW IF EXISTS reporting.vw_SalaryBands;
-- DROP PROCEDURE IF EXISTS app.usp_GetPayBand;
-- DROP PROCEDURE IF EXISTS app.usp_FindEmployee_UNSAFE;
-- DROP PROCEDURE IF EXISTS app.usp_FindEmployee_SAFE;
-- DROP PROCEDURE IF EXISTS app.usp_GetEmployee_UNSAFE;
-- DROP PROCEDURE IF EXISTS app.usp_GetEmployee_SAFE;
-- GO
-- DROP TABLE IF EXISTS sensitive.Salaries;
-- DROP TABLE IF EXISTS app.Departments;
-- DROP TABLE IF EXISTS app.Employees;
-- DROP TABLE IF EXISTS dbo.Salaries;
-- DROP TABLE IF EXISTS dbo.Employees;
-- GO
-- DROP USER IF EXISTS support_user;
-- DROP USER IF EXISTS hr_user;
-- DROP USER IF EXISTS analyst_user;
-- DROP ROLE IF EXISTS support_role;
-- DROP ROLE IF EXISTS hr_role;
-- DROP ROLE IF EXISTS analyst_role;
-- GO
-- DROP SCHEMA IF EXISTS reporting;
-- DROP SCHEMA IF EXISTS sensitive;
-- DROP SCHEMA IF EXISTS app;
-- GO

/* ========================= END OF SETUP SCRIPT ========================= */
