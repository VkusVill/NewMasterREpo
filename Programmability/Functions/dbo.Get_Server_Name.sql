SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		OD
-- Create date: 2019-12-23
-- Description:	Получение имени текущего сервера
-- =============================================
CREATE FUNCTION [dbo].[Get_Server_Name] 
()
RETURNS VARCHAR(100)
AS
BEGIN
	RETURN '['+@@servername+']'

END
GO