# Stored Procedures and SQL Injection

## Prerequisites

An isolated Azure SQL course database with fictional data, the course Lab 5 setup completed, and an administrator connection with the required database permissions. No connection secrets are supplied by this repository.

The instructor setup is not redistributed here. It creates:

- `app`, `sensitive`, and `reporting` schemas owned by `dbo`.
- `app.Employees` with EmployeeID INT, FullName NVARCHAR(100), Department NVARCHAR(60), and OfficePhone VARCHAR(20).
- `sensitive.Salaries` with EmployeeID INT and Salary MONEY.
- Three fictional employees: Amara Okafor (ID 1), Bao Nguyen (ID 2), and Carla Silva (ID 3), with salaries 62000, 58000, and 71000 respectively.
- `support_role` with SELECT on the app schema and DENY SELECT on sensitive.
- `support_user WITHOUT LOGIN`, a member of support_role.
- HR and analyst roles and users, reporting views, and additional permissions used by the course model.

This package depends on that setup; it is not a standalone database installer.

## Run order

1. Confirm you are connected to the intended lab database, not master.
2. Run [01-procedures.sql](sql/01-procedures.sql).
3. Run [02-exercises.sql](sql/02-exercises.sql) one labeled section at a time. Review result grids and expected errors. If interrupted during impersonation, run REVERT in the same connection.
4. After capturing results, run [03-cleanup.sql](sql/03-cleanup.sql). The final verification should return NULL for both unsafe procedure IDs when run as administrator.

GO is a client batch separator supported by the VS Code SQL Server extension. In a client that does not support it, execute batches separately.

## Identity and request flow

The database client authenticates to Azure SQL using credentials managed outside this repository. The lab test users have no logins or passwords; EXECUTE AS changes the database execution context, and REVERT restores it.

For the pay-band test, support_user receives procedure execution permission through support_role. The procedure's static query follows the common ownership chain to read salary data and returns only an employee ID, name, and band. A separate direct salary query checks the user's permissions and fails.

For injection tests, the administrator calls the unsafe procedures. They concatenate values into command text and execute it. The safe versions use static SQL, so supplied values do not become SQL syntax. No application login service, JWT, refresh token, or token storage is implemented.

## Evidence limits

The root README summarizes observed lab results. Raw evidence remains in the private course submission. Successful DROP commands were captured; a separate post-cleanup NULL result has not been independently reviewed.
