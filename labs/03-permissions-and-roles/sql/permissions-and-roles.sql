-- CPAN 363 - Lab 03: Permissions and Roles
-- Target: an isolated, empty Azure SQL lab database
-- Run sections in order in a NEW lab database. CREATE commands are not rerunnable.
-- Expected permission-denied errors are part of the exercise.
-- Do not execute this complete script against an already completed lab without resetting objects.

-- Part 1: Tables and fictional sample data
CREATE TABLE dbo.Employees (
 EmployeeID INT IDENTITY PRIMARY KEY,
 FullName NVARCHAR(100), Department NVARCHAR(60), OfficePhone VARCHAR(20)
);
CREATE TABLE dbo.Salaries (EmployeeID INT PRIMARY KEY, Salary MONEY);
INSERT INTO dbo.Employees (FullName, Department, OfficePhone) VALUES
(N'Amara Okafor',N'Finance','416-555-0101'),
(N'Bao Nguyen',N'Operations','416-555-0102'),
(N'Carla Silva',N'Finance','416-555-0103');
INSERT INTO dbo.Salaries VALUES (1,62000),(2,58000),(3,71000);
SELECT * FROM dbo.Employees;
SELECT * FROM dbo.Salaries;

-- Part 2: Roles and grants
CREATE ROLE support_role;
CREATE ROLE hr_role;
CREATE ROLE analyst_role;
GRANT SELECT ON dbo.Employees TO support_role;
DENY SELECT ON dbo.Salaries TO support_role;
GRANT SELECT, INSERT, UPDATE ON dbo.Employees TO hr_role;
GRANT SELECT, INSERT, UPDATE ON dbo.Salaries TO hr_role;
GRANT SELECT ON dbo.Employees TO analyst_role;
CREATE USER support_user WITHOUT LOGIN;
CREATE USER hr_user WITHOUT LOGIN;
CREATE USER analyst_user WITHOUT LOGIN;
ALTER ROLE support_role ADD MEMBER support_user;
ALTER ROLE hr_role ADD MEMBER hr_user;
ALTER ROLE analyst_role ADD MEMBER analyst_user;

-- Part 3: Test support user
EXECUTE AS USER = 'support_user';
SELECT USER_NAME() AS running_as;
SELECT HAS_PERMS_BY_NAME('dbo.Employees','OBJECT','SELECT') AS can_read_employees,
       HAS_PERMS_BY_NAME('dbo.Salaries','OBJECT','SELECT') AS can_read_salaries;
SELECT TOP 2 * FROM dbo.Employees;
REVERT;
-- Run this denied test separately; if execution aborts, run REVERT separately.
EXECUTE AS USER = 'support_user';
SELECT TOP 2 * FROM dbo.Salaries; -- Expected error 229
REVERT;

-- Part 3: Test HR user
EXECUTE AS USER = 'hr_user';
SELECT USER_NAME() AS running_as;
SELECT HAS_PERMS_BY_NAME('dbo.Employees','OBJECT','SELECT') AS can_read_employees,
       HAS_PERMS_BY_NAME('dbo.Salaries','OBJECT','SELECT') AS can_read_salaries;
SELECT TOP 2 * FROM dbo.Employees;
SELECT TOP 2 * FROM dbo.Salaries;
SELECT HAS_PERMS_BY_NAME('dbo.Employees','OBJECT','SELECT') AS employees_select,
 HAS_PERMS_BY_NAME('dbo.Employees','OBJECT','INSERT') AS employees_insert,
 HAS_PERMS_BY_NAME('dbo.Employees','OBJECT','UPDATE') AS employees_update,
 HAS_PERMS_BY_NAME('dbo.Salaries','OBJECT','SELECT') AS salaries_select,
 HAS_PERMS_BY_NAME('dbo.Salaries','OBJECT','INSERT') AS salaries_insert,
 HAS_PERMS_BY_NAME('dbo.Salaries','OBJECT','UPDATE') AS salaries_update;
REVERT;

-- Part 3: Test analyst user
EXECUTE AS USER = 'analyst_user';
SELECT USER_NAME() AS running_as;
SELECT HAS_PERMS_BY_NAME('dbo.Employees','OBJECT','SELECT') AS can_read_employees,
       HAS_PERMS_BY_NAME('dbo.Salaries','OBJECT','SELECT') AS can_read_salaries;
SELECT TOP 2 * FROM dbo.Employees;
REVERT;
-- Run separately and capture error 229
EXECUTE AS USER = 'analyst_user';
SELECT TOP 2 * FROM dbo.Salaries; -- Expected error 229
REVERT;

-- Part 4: DENY overrides inherited GRANT
SELECT USER_NAME() AS CurrentDatabaseUser;
ALTER ROLE db_datareader ADD MEMBER support_user;
EXECUTE AS USER = 'support_user';
SELECT HAS_PERMS_BY_NAME('dbo.Salaries','OBJECT','SELECT') AS can_read_salaries;
REVERT;
-- Run separately and capture error 229
EXECUTE AS USER = 'support_user';
SELECT TOP 2 * FROM dbo.Salaries; -- Expected error 229
REVERT;
-- Cleanup, run in administrator context
ALTER ROLE db_datareader DROP MEMBER support_user;

-- Part 5: Audit reports
SELECT r.name AS role_name, m.name AS member_name
FROM sys.database_role_members AS rm
JOIN sys.database_principals AS r ON r.principal_id=rm.role_principal_id
JOIN sys.database_principals AS m ON m.principal_id=rm.member_principal_id
ORDER BY r.name;
SELECT pr.name AS who, pe.state_desc AS grant_or_deny,
 pe.permission_name, OBJECT_NAME(pe.major_id) AS on_what
FROM sys.database_permissions AS pe
JOIN sys.database_principals AS pr ON pr.principal_id=pe.grantee_principal_id
WHERE pr.name NOT IN ('public','dbo')
ORDER BY pr.name;

