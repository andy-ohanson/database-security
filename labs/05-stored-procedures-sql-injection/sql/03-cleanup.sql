-- Run after collecting the unsafe-procedure evidence.
DROP PROCEDURE IF EXISTS app.usp_FindEmployee_UNSAFE;
DROP PROCEDURE IF EXISTS app.usp_GetEmployee_UNSAFE;
GO
-- Both identifiers should be NULL after cleanup, when checked as administrator.
SELECT OBJECT_ID(N'app.usp_FindEmployee_UNSAFE', N'P') AS UnsafeNameProcedure,
       OBJECT_ID(N'app.usp_GetEmployee_UNSAFE', N'P') AS UnsafeIDProcedure;
GO
