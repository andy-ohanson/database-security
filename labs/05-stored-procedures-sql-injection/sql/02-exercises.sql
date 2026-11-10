-- Run one section at a time and save actual results. GO is a client separator.
-- Preflight: confirm the database and inspect fictional fixture identifiers.
SELECT DB_NAME() AS DatabaseName, USER_NAME() AS DatabaseUser;
SELECT EmployeeID, FullName, Department FROM app.Employees ORDER BY EmployeeID;
SELECT COUNT(*) AS BaselineEmployeeCount FROM app.Employees;
GO

-- Part 1: procedure succeeds, direct salary access fails.
-- Catch the expected error so the session can REVERT normally.
EXECUTE AS USER = 'support_user';
BEGIN TRY
    EXEC app.usp_GetPayBand @EmployeeID = 1;
    -- Nested batch ensures a permission error is catchable here.
    EXEC sys.sp_executesql N'SELECT * FROM sensitive.Salaries;';
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
REVERT;
SELECT USER_NAME() AS RestoredDatabaseUser;
GO

-- Part 2: capture both result grids and row counts reported by the client.
EXEC app.usp_FindEmployee_UNSAFE @Name = N'Amara Okafor';
GO
EXEC app.usp_FindEmployee_UNSAFE @Name = N''' OR 1=1 --';
GO

-- Part 3: numeric expression injection needs no quote character.
EXEC app.usp_GetEmployee_UNSAFE @EmployeeID = N'1';
GO
EXEC app.usp_GetEmployee_UNSAFE @EmployeeID = N'1 OR 1=1';
GO

-- Part 4: the same text is now treated as data.
EXEC app.usp_FindEmployee_SAFE @Name = N'Amara Okafor';
GO
EXEC app.usp_FindEmployee_SAFE @Name = N''' OR 1=1 --';
GO
EXEC app.usp_GetEmployee_SAFE @EmployeeID = 1;
GO
-- Expected conversion error: capture the client's actual error.
EXEC app.usp_GetEmployee_SAFE @EmployeeID = '1 OR 1=1';
GO
