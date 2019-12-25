SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		OD
-- Create date: 2019-12-23
-- Description:	Получение имени основного сервера
-- =============================================
CREATE FUNCTION [dbo].[Get_Main_Server_Name] 
()
RETURNS VARCHAR(100)
AS
BEGIN
	RETURN '[SRV-SQL01]'

END
GO