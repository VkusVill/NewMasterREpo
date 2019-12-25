SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		Васильев М.Н.
-- Create date: 10.10.2019
-- Description:	Возвращает номер кассы из CashId
-- =============================================
CREATE FUNCTION [dbo].[ShopNo_From_CashID] (
	@CashId int
)
RETURNS int
AS
BEGIN	
	DECLARE @No int

	--IF @CashID <= 99999
	--	SET @No = RIGHT(@CashId, 1)
	--ELSE
	--	SET @No = RIGHT(@CashId, 2)

  SET @No = LEFT(@CashId, LEN(@CashId) - 1)
		
	RETURN @No
END


/*

SELECT [dbo].[ShopNo_From_CashID](222332)

*/
GO