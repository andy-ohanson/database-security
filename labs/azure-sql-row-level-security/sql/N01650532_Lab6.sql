-- Part 1.1: Schema, table and index
CREATE SCHEMA clinic;
GO

CREATE TABLE clinic.Appointments
(
    AppointmentID INT IDENTITY PRIMARY KEY,
    PatientName NVARCHAR(100) NOT NULL,
    DoctorName SYSNAME NOT NULL,
    ApptDate DATE NOT NULL
);

CREATE INDEX IX_Appointments_Doctor
    ON clinic.Appointments (DoctorName);
GO

-- Part 1.2: Test users and permissions
CREATE USER dr_okafor WITHOUT LOGIN;
CREATE USER dr_nguyen WITHOUT LOGIN;
CREATE USER dr_newstarter WITHOUT LOGIN;
CREATE USER office_admin WITHOUT LOGIN;

CREATE ROLE office_manager;

ALTER ROLE office_manager
    ADD MEMBER office_admin;

GRANT SELECT, INSERT, UPDATE, DELETE
ON clinic.Appointments
TO dr_okafor, dr_nguyen, dr_newstarter, office_admin;
GO

/* =========================================================================
   CPAN 363 - DATABASE SECURITY
   LAB 6 STANDARD DATA - appointments for the Row-Level Security lab

   WHAT THIS IS
   -----------------------------------------------------------------------
   Step 1.3 of Lab 6 gives you five appointments and says "add more rows".
   Run this script instead, so that everyone in the class has exactly the
   same data and the same numbers to compare:

       dr_okafor      12 appointments
       dr_nguyen       8 appointments
       total          20 appointments
       dr_newstarter   0 appointments  (deliberately - see Part 3.3)

   WHEN TO RUN IT
   -----------------------------------------------------------------------
   After steps 1.1 and 1.2 (the table and the users exist), and BEFORE
   Part 2 (before you create the security policy).

   Already ran the five-row INSERT from step 1.3? That is fine. Those five
   rows are part of this set, so the script adds only the fifteen missing.
   It is safe to run more than once - it never adds the same row twice.

   Made-up patients only. Never put real personal information in a lab database.
   ========================================================================= */

SET NOCOUNT ON;

-- Stop if the table has not been created yet.
IF OBJECT_ID(N'clinic.Appointments', N'U') IS NULL
BEGIN
    RAISERROR(N'clinic.Appointments does not exist yet. Do Lab 6 step 1.1 first, then run this script.', 16, 1);
    RETURN;
END;

-- Stop if the Row-Level Security policy is already switched on. With the policy
-- on, the administrator sees zero rows, so this script could not tell which
-- rows already exist and would add duplicates.
IF EXISTS (SELECT 1 FROM sys.security_policies WHERE is_enabled = 1)
BEGIN
    RAISERROR(N'A security policy is switched on. Run this script before Part 2, or first run: ALTER SECURITY POLICY sec.AppointmentPolicy WITH (STATE = OFF);', 16, 1);
    RETURN;
END;

-- The standard set. The first five rows are the ones printed in step 1.3.
DECLARE @std TABLE (PatientName NVARCHAR(100), DoctorName SYSNAME, ApptDate DATE);
INSERT INTO @std (PatientName, DoctorName, ApptDate) VALUES
 (N'Patient A', N'dr_okafor', '2026-11-02'),
 (N'Patient B', N'dr_okafor', '2026-11-03'),
 (N'Patient C', N'dr_okafor', '2026-11-04'),
 (N'Patient D', N'dr_nguyen', '2026-11-02'),
 (N'Patient E', N'dr_nguyen', '2026-11-05'),
 (N'Patient F', N'dr_okafor', '2026-11-05'),
 (N'Patient G', N'dr_nguyen', '2026-11-06'),
 (N'Patient H', N'dr_okafor', '2026-11-06'),
 (N'Patient I', N'dr_okafor', '2026-11-09'),
 (N'Patient J', N'dr_nguyen', '2026-11-09'),
 (N'Patient K', N'dr_okafor', '2026-11-10'),
 (N'Patient L', N'dr_okafor', '2026-11-11'),
 (N'Patient M', N'dr_nguyen', '2026-11-12'),
 (N'Patient N', N'dr_okafor', '2026-11-12'),
 (N'Patient O', N'dr_okafor', '2026-11-13'),
 (N'Patient P', N'dr_nguyen', '2026-11-16'),
 (N'Patient Q', N'dr_okafor', '2026-11-16'),
 (N'Patient R', N'dr_nguyen', '2026-11-17'),
 (N'Patient S', N'dr_okafor', '2026-11-18'),
 (N'Patient T', N'dr_nguyen', '2026-11-19');

-- Add only the rows that are not already there.
INSERT INTO clinic.Appointments (PatientName, DoctorName, ApptDate)
SELECT s.PatientName, s.DoctorName, s.ApptDate
FROM   @std AS s
WHERE  NOT EXISTS (SELECT 1
                   FROM   clinic.Appointments AS a
                   WHERE  a.PatientName = s.PatientName
                     AND  a.DoctorName  = s.DoctorName
                     AND  a.ApptDate    = s.ApptDate);

DECLARE @added INT = @@ROWCOUNT;
PRINT CONCAT(N'Rows added just now: ', @added);

-- This is your step 1.3 capture. Expected: dr_nguyen 8, dr_okafor 12.
SELECT DoctorName, COUNT(*) AS how_many
FROM   clinic.Appointments
GROUP BY DoctorName
ORDER BY DoctorName;

-- If your numbers are higher than 12 and 8, you added rows of your own
-- earlier. That is fine - keep them, and report your own numbers in the lab.
SELECT CASE WHEN COUNT(*) = 20 THEN N'OK - standard data in place (20 rows)'
            ELSE CONCAT(N'You have ', COUNT(*), N' rows. Standard is 20; use your own counts in the lab.')
       END AS [Check]
FROM   clinic.Appointments;

-- Part 1.3: Baseline counts before RLS
SELECT DoctorName, COUNT(*) AS how_many
FROM clinic.Appointments
GROUP BY DoctorName
ORDER BY DoctorName;

SELECT COUNT(*) AS total_before_rls
FROM clinic.Appointments;
GO
-- Part 2.1: Create the security schema and function
CREATE SCHEMA sec;
GO

CREATE FUNCTION sec.fn_MyAppointments
(
    @DoctorName AS SYSNAME
)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT 1 AS allowed
    WHERE @DoctorName = USER_NAME()
       OR IS_ROLEMEMBER('office_manager') = 1;
GO

-- Part 2.2: Enable row filtering
CREATE SECURITY POLICY sec.AppointmentPolicy
    ADD FILTER PREDICATE
        sec.fn_MyAppointments(DoctorName)
        ON clinic.Appointments
    WITH (STATE = ON);
GO

-- Part 2.3: Confirm the policy is enabled
SELECT name, is_enabled
FROM sys.security_policies
WHERE name = N'AppointmentPolicy';

-- Part 3.1: Administrator count (expected: 0)
SELECT USER_NAME() AS current_user_name,
       COUNT(*) AS as_admin
FROM clinic.Appointments;

-- Doctor Okafor count (expected: 12)
EXECUTE AS USER = 'dr_okafor';

SELECT USER_NAME() AS current_user_name,
       COUNT(*) AS as_okafor
FROM clinic.Appointments;

-- Sample appointments: all must belong to dr_okafor
SELECT TOP (3)
    AppointmentID,
    PatientName,
    DoctorName
FROM clinic.Appointments
ORDER BY AppointmentID;

REVERT;

-- Doctor Nguyen count (expected: 8)
EXECUTE AS USER = 'dr_nguyen';

SELECT USER_NAME() AS current_user_name,
       COUNT(*) AS as_nguyen
FROM clinic.Appointments;

REVERT;
GO

-- Part 3.2: Office manager (expected: 20)
EXECUTE AS USER = 'office_admin';

SELECT USER_NAME() AS current_user_name,
       COUNT(*) AS as_manager
FROM clinic.Appointments;

REVERT;

-- Part 3.3: New starter (expected: 0)
EXECUTE AS USER = 'dr_newstarter';

SELECT USER_NAME() AS current_user_name,
       COUNT(*) AS as_new_starter
FROM clinic.Appointments;

REVERT;
GO

-- Part 4.1: Disable the policy
ALTER SECURITY POLICY sec.AppointmentPolicy
WITH (STATE = OFF);

EXECUTE AS USER = 'dr_okafor';

SELECT USER_NAME() AS current_user_name,
       COUNT(*) AS as_okafor_no_policy
FROM clinic.Appointments;

REVERT;

-- Part 4.2: Enable the policy again
ALTER SECURITY POLICY sec.AppointmentPolicy
WITH (STATE = ON);

EXECUTE AS USER = 'dr_okafor';

SELECT USER_NAME() AS current_user_name,
       COUNT(*) AS as_okafor_policy_restored
FROM clinic.Appointments;

REVERT;

-- Confirm the policy is enabled
SELECT name, is_enabled
FROM sys.security_policies
WHERE name = N'AppointmentPolicy';
GO