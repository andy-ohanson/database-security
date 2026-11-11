-- Part 1: procedure succeeds, direct salary access fails.
-- 1.1
CREATE OR ALTER PROCEDURE app.usp_GetPayBand
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT e.EmployeeID, e.FullName,
           CASE WHEN s.Salary < 60000 THEN N'Band A'
                WHEN s.Salary < 70000 THEN N'Band B'
                ELSE N'Band C' END AS PayBand
    FROM app.Employees AS e
    JOIN sensitive.Salaries AS s ON s.EmployeeID = e.EmployeeID
    WHERE e.EmployeeID = @EmployeeID;
END;
GO
GRANT EXECUTE ON OBJECT::app.usp_GetPayBand TO support_role;

-- 1.2
EXECUTE AS USER = 'support_user';
    EXEC app.usp_GetPayBand @EmployeeID = 1;    
REVERT;

EXECUTE AS USER = 'support_user';
    EXEC sys.sp_executesql N'SELECT * FROM sensitive.Salaries;';   
REVERT;
SELECT USER_NAME() AS CurrentDatabaseUser;
GO

-- Intentionally vulnerable teaching example. Remove after evidence capture.
-- Part 2: 
-- 2.1
CREATE OR ALTER PROCEDURE app.usp_FindEmployee_UNSAFE
    @Name NVARCHAR(100)
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX);
    SET @sql = N'SELECT EmployeeID, FullName, Department
                 FROM app.Employees WHERE FullName = ''' + @Name + N'''';
    EXEC (@sql);
END;

GO

-- 2.2
EXEC app.usp_FindEmployee_UNSAFE @Name = N'Amara Okafor';
GO
-- 2.3
EXEC app.usp_FindEmployee_UNSAFE @Name = N''' OR 1=1 --';
GO

-- Intentionally vulnerable teaching example. Remove after evidence capture.
-- Part 3:
-- 3.1
CREATE OR ALTER PROCEDURE app.usp_GetEmployee_UNSAFE
    @EmployeeID NVARCHAR(20)
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX) =
        N'SELECT * FROM app.Employees WHERE EmployeeID = ' + @EmployeeID;
    EXEC (@sql);
END;
GO

-- 3.2
EXEC app.usp_GetEmployee_UNSAFE @EmployeeID = N'1';


-- 3.3
EXEC app.usp_GetEmployee_UNSAFE @EmployeeID = N'1 OR 1=1';
GO

-- Part 4: the same text is now treated as data.
-- 4.1   
CREATE OR ALTER PROCEDURE app.usp_FindEmployee_SAFE
    @Name NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT EmployeeID, FullName, Department
    FROM app.Employees
    WHERE FullName = @Name;
END;
GO

-- 4.2
EXEC app.usp_FindEmployee_SAFE @Name = N'Amara Okafor';
GO

EXEC app.usp_FindEmployee_SAFE @Name = N''' OR 1=1 --';
GO

-- 4.3
--4.3a
CREATE OR ALTER PROCEDURE app.usp_GetEmployee_SAFE
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM app.Employees WHERE EmployeeID = @EmployeeID;
END;
GO

-- 4.3b
EXEC app.usp_GetEmployee_SAFE @EmployeeID = 1;
GO


-- 4.3c

EXEC app.usp_GetEmployee_SAFE @EmployeeID = '1 OR 1=1';
GO

-- Part 5: cleanup
DROP PROCEDURE IF EXISTS app.usp_FindEmployee_UNSAFE;
DROP PROCEDURE IF EXISTS app.usp_GetEmployee_UNSAFE;
GO