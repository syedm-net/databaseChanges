USE [OASIS_DEV]

/*
*	Created by		: Zahid
*	Date Created	: 02/23/2019
*	Description		: Stored procedure to get the list of offenders for given 
*					  Supervisor Id.
*
*	Modifications	:
*	------------------------------------------------------------
*	
*
*
*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = 'svc.GetOffernderListBySupervisorId')
BEGIN
    DROP PROCEDURE svc.GetOffernderListBySupervisorId
END
GO

CREATE PROCEDURE svc.GetOffernderListBySupervisorId
	@username VARCHAR(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @employeeId INT
	SELECT @employeeId = ID FROM HumanResources.Personnel (NOLOCK) WHERE ADUserID = LTRIM(RTRIM(@username))

	SELECT 
	o.LastName,
	o.FirstName,
	CASE
		WHEN o.IsActive  IS NOT NULL AND o.IsActive=0 THEN 'Inactive'
		WHEN (SELECT COUNT(1) FROM Offense.CourtCases (NOLOCK) ca WHERE ca.OffenderID = o.ID)=0 AND o.IsActive IS NULL THEN 'Unknown'
		WHEN (SELECT COUNT(1) FROM Offense.CourtCases (NOLOCK) ca WHERE ca.OffenderID = o.ID
	AND (ca.IsDeleted IS NULL OR ca.IsDeleted=0) AND ca.InactiveOn IS NULL)>0 THEN 'Active'
	ELSE 'Inactive'
	END AS [Status],
	o.LocalIdentificationNumber,
	o.DateOfBirth,
	o.Sex,
	o.Race_Code AS Race_Code,
	o.DPSSIDNumber,
	CASE WHEN o.DateOfDeath IS NULL
		THEN DATEDIFF(YEAR, o.DateOfBirth, GETDATE()) ELSE 
		DATEDIFF(YEAR, o.DateOfBirth, o.DateOfDeath) END AS 'Age',
	tf.SupervisionType AS FundingCode,
	CONCAT(a.StreetNumber,' ',a.StreetDirection,' ',a.StreetName ,' ',st.StreetTypeCode) AS 'StreetAddress' ,
	a.City,
	ct.CountyName as 'County',
	s.StateName as 'State',
	a.Zip,
	HumanResources.GetFullName(o.SupervisionOfficerID) AS Officer,
	e.UnitCode AS Unit,
	CASE
		WHEN (SELECT COUNT(1) FROM Offense.CourtCases (NOLOCK) ca WHERE ca.OffenderID = o.ID
		AND (ca.IsDeleted IS NULL OR ca.IsDeleted=0) AND ca.HasNonDisclosureOrder=1)>0 THEN CAST(1 AS BIT) 
		ELSE CAST(0 AS BIT) 
	END AS [HasNonDisclosure]
	
	FROM Offender.offenders (NOLOCK) o
	LEFT JOIN  Offender.OffenderFundingCodes (NOLOCK) f ON f.OffenderID = o.ID 
	LEFT JOIN [Types].[FundingCodeSupervisionTypes] (NOLOCK) tf ON tf.ID=f.SupervisionTypeID 
	LEFT JOIN  Offender.OffenderAddresses (NOLOCK) a ON a.OffenderID = o.ID 
		AND (a.ID = (SELECT TOP(1) ID FROM Offender.OffenderAddresses (NOLOCK)
		   WHERE OffenderID=o.ID
		   AND (IsDeleted = 0 OR IsDeleted IS NULL) 
		   AND InactiveOn IS NULL 
		   ORDER BY CASE WHEN AddressTypeID IS NULL THEN 1 ELSE 0 END, AddressTypeID,IsCurrentResidenceAddress DESC))
	LEFT JOIN [Types].[StreetTypes] (NOLOCK) st ON st.ID = a.StreetTypeID
	LEFT JOIN [Types].[Counties] (NOLOCK) ct ON ct.ID = a.CountyID
	LEFT JOIN [Types].[States] (NOLOCK) s ON s.ID = a.StateID
	LEFT JOIN  HumanResources.Personnel (NOLOCK) e ON e.ID = o.SupervisionOfficerID 
	LEFT JOIN  Offender.ProbationOfficerAssignment (NOLOCK) oa ON o.ID = oa.OffenderID  
	WHERE (o.IsActive = 1 OR o.IsActive IS NULL)
	AND oa.IsActive = 1
	AND (oa.IsDeleted IS NULL OR oa.IsDeleted=0) AND oa.InactiveOn IS NULL 
	AND e.ID = @employeeId

END
GO

