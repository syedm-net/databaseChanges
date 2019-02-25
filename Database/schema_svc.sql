USE [OASIS_DEV]

/*
*	Created by		: Abc
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
IF NOT EXISTS (SELECT  schema_name
FROM    information_schema.schemata
WHERE   schema_name = 'svc'
)
BEGIN
     EXEC sp_executesql N'CREATE SCHEMA svc'
END
GO