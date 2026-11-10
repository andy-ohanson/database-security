-- Run after 00-instructor-setup.sql in your course Azure SQL database.
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
GO

-- Intentionally vulnerable teaching example. Remove after evidence capture.
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

-- Intentionally vulnerable teaching example. Remove after evidence capture.
CREATE OR ALTER PROCEDURE app.usp_GetEmployee_UNSAFE
    @EmployeeID NVARCHAR(20)
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX) =
        N'SELECT * FROM app.Employees WHERE EmployeeID = ' + @EmployeeID;
    EXEC (@sql);
END;
GO

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

CREATE OR ALTER PROCEDURE app.usp_GetEmployee_SAFE
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM app.Employees WHERE EmployeeID = @EmployeeID;
END;
GO
