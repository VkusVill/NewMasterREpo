SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		OD
-- Create date: 2019-04-23
-- Description:	Получение обеденной карты продавцов
-- =============================================
CREATE FUNCTION [dbo].[BonusCard_obed] 
()
RETURNS char(7)
AS
BEGIN
	
	RETURN '4806534'

END
GO