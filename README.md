# Azure SQL Database Security

Hands-on Azure SQL security labs covering identity management, least privilege, access auditing, and SQL injection remediation.

## Lab index

| Lab | Security focus | Materials |
| --- | --- | --- |
| 02: Logins, Users and Microsoft Entra | Login mapping, contained users, external identity, access suspension | [Case study, SQL, and evidence](labs/02-logins-users-entra/README.md) |
| 03: Permissions and Roles | Least privilege, effective permissions, DENY versus inherited GRANT, access auditing | [Case study and SQL](labs/03-permissions-and-roles/README.md) |
| 05: Stored Procedures and SQL Injection | Ownership chaining, injection testing, typed parameters, remediation | [Case study and SQL](labs/05-stored-procedures-sql-injection/README.md) |
| 06: Row Level Security | Demonstrates row filtering, schema-bound functions, security policies | [Case study and SQL](labs/azure-sql-row-level-security/README.md) |


Each lab is a separate historical database snapshot. Do not replay Lab 3 over the completed Lab 5 environment.

## Lab 5: Security problem

Support staff need useful employee information without access to exact salaries. Separately, employee lookup procedures must prevent untrusted input from changing the SQL command.

## Work performed

- Implemented a pay-band procedure and granted execution to the support role.
- Tested ownership chaining: the procedure returned a pay band while a direct salary read was denied.
- Demonstrated text and numeric SQL injection in deliberately vulnerable procedures against fictional data.
- Implemented static queries with typed parameters and repeated the same inputs.
- Executed cleanup to remove both vulnerable procedures.

## Observed results

| Test | Observed outcome |
| --- | --- |
| Support-role pay-band lookup | Employee 1 returned Band B |
| Support-role direct salary read | Permission denied, error 229 |
| Unsafe name search: normal / injected | 1 row / 3 rows |
| Unsafe ID search: normal / injected | 1 row / 3 rows |
| Safe name search: normal / injected | 1 row / 0 rows |
| Safe ID search: normal / injected | 1 row / conversion error 8114 |
| Removal of unsafe procedures | DROP commands completed successfully |

Results were reviewed from the author's VS Code screenshots and course report. The signed report and raw screenshots are excluded because they contain personal and connection information. They are not reproduced as public evidence here.

## Implementation

See the [lab guide](labs/05-stored-procedures-sql-injection/README.md) for prerequisites, script order, and permission behavior.

**Tools:** Microsoft Azure SQL Database, T-SQL, Visual Studio Code with the SQL Server extension.

## Security decisions and limitations

- A narrow procedure returns a salary band instead of the salary value.
- Static ownership chaining depends on common ownership of the procedure and referenced tables.
- A procedure signature alone does not prevent injection: the vulnerable examples also accept parameters, then concatenate them into executable SQL.
- The name fix keeps input as a value in static SQL; the numeric fix additionally enforces an INT boundary.
- Injection demonstrations ran as the administrator. They do not prove support-user privilege escalation. An attack's impact depends on its execution context and permissions.
- This is a controlled learning exercise, not a production deployment or a general security assessment.
  
📁 [View SQL Injection report](docs/lab5-security-case-study.pdf)

## Attribution

Based on CPAN 363 Lab 5, Stored Procedures and SQL Injection. The course supplied the database scaffolding and procedure examples; this repository documents the implementation, execution, verification, and analysis performed during the lab, with AI assistance in preparation and documentation. Instructor PDFs, the original setup script, and the signed submission are excluded from this portfolio package.

### Lab 6 — Row-Level Security in Azure SQL Database

Implemented database-level row filtering so doctors can access only their own appointments, while an office manager can access all records.

**Skills demonstrated:** Azure SQL Database, T-SQL, schema-bound functions, security policies, role-based permissions, and user impersonation testing.

| User or test | Rows visible |
|---|---:|
| Administrator (`dbo`) | 0 |
| Doctor Okafor | 12 |
| Doctor Nguyen | 8 |
| Office manager | 20 |
| New doctor without appointments | 0 |
| Doctor Okafor with policy disabled | 20 |
| Doctor Okafor after policy restored | 12 |

**Key finding:** Row-Level Security also filters the database owner. Disabling the policy exposed all appointments to a user with table-level SELECT permission, demonstrating why policy administration must be restricted.

📁 [View Row-Level Security report](docs/lab6-row-level-security.pdf/)

## Detailed case study
📁 [View Permissions and Roles report](docs/lab3-security-case-study.pdf)


