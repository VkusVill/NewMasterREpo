SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		  Васильев М.Н.
-- Create date: 18.02.2019
-- Description:	Возвращает имя для таблицы времянки
-- =============================================
CREATE FUNCTION [dbo].[new_tmptbl] ()
RETURNS char(36)
AS
BEGIN	
	RETURN (SELECT REPLACE(CONVERT(char(36), v_newid), '-', '_')  FROM com.dbo.v_newid)
END
GO