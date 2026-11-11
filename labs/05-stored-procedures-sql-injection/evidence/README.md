# Evidence checklist

This document is an observed database result.

The repository shows evidence images by default. Publish only reviewed, redacted copies deliberately.

| Capture | Expected on fresh fixture | Actual result / private capture reference |
| --- | --- | --- |
| Setup report | All checks OK | 01-part1.png |
| Support pay-band procedure | Employee 1, Amara Okafor, Band B | 02-part1.png |
| Support direct salary read | Permission denied | 03-part1.png |
| Unsafe name, normal | 1 row | 01-part2.png / 02-part2.png |
| Unsafe name, injection | 3 rows | 03-part2.png |
| Unsafe ID, normal | 1 row | 01-part3.png / 02-part3.png |
| Unsafe ID, injection | 3 rows | 03-part3.png |
| Safe name, normal | 1 row | 01-part4.png / 02-part4.png |
| Safe name, same injection | 0 rows | 02b-part4.png |
| Safe ID, normal | 1 row | 03b-part4.png |
| Safe ID, same injection | Conversion error | 03c-part4.png |
| Cleanup | Both unsafe procedure IDs NULL | Completeted 01-part5.png |

## Explanations after running

- Part 1.3: why the support user can get a pay band but cannot get a salary?
The support user can get a pay band because its role has EXECUTE permission on the stored procedure, and ownership chaining allows the procedure to read the salary table while returning only the pay band. The user cannot read actual salaries directly because its role is explicitly denied SELECT permission on the sensitive schema.

- Part 2.4: how the text payload changes the query and row count.
The unsafe procedure joins the supplied name directly into the SQL command. The injected quote closes the name value, OR 1=1 makes the condition true for every row, and -- comments out the remaining quote. This changes the query’s meaning instead of searching for a literal name. As a result, the injected search returned all three employees instead of only Amara Okafor.

- Part 4.4: explaining why the parameter cannot be injected
The fixed procedures use parameters directly in static SQL, so the supplied values cannot change the query’s structure. The name procedure treats the injection text as a literal name and returns no matches, while the integer parameter rejects 1 OR 1=1 with a conversion error. A procedure parameter alone is not enough to prevent injection if its value is later concatenated into executable SQL.
![Safe employee search returning zero rows](images/02b-part4.png)

- Part 5.2: how did the role model (RBAC) you built in Labs 3 and 4 limit what an attacker could have done here? 
The role model limited users to the permissions needed for their jobs, reducing the damage an attacker could cause through SQL injection. For example, the support role could read employee information but was denied direct access to the sensitive salary table. Injection would still be restricted by the permissions of the execution context; because these injection tests ran as the administrator, they had broader access than a support user would.

## Part 5.1: search-procedure checklist

| Check | UNSAFE name search | SAFE name search |
| --- | --- | --- |
| Joins input with a plus sign? | Yes | No |
| Uses EXEC(@sql)? | Yes | No |
| Uses a parameter? | Yes, but concatenates its value | Yes, used directly as data |
| Correct data type used? | NVARCHAR(100) suits names; this does not fix concatenation | NVARCHAR(100) suits names |
| Could this be injected? | Yes | These inputs cannot change the static query |

The numeric pair illustrates the separate data-type improvement: unsafe NVARCHAR(20) input versus safe INT input.

## Private course submission

Combine every SQL command actually run, including setup, retries, and cleanup, into the required StudentID_Lab5.sql file. Prepare the report only after evidence capture. Include the authorized-use statement from the handout and have the student supply their own name, ID, signature, and date after confirming it is true. Do not put those personal details in the public portfolio.
