SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[nedely] 
(
@date as date
)
RETURNS int
AS
BEGIN

	RETURN floor(datediff(day, {d'2009-05-11'} , @date )/7)+1

END
GO