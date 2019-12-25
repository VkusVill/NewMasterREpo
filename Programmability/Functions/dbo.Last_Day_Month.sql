SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		OD
-- Create date: 2019-11-22
-- Description:	Последний день месяца
-- =============================================
create FUNCTION [dbo].[Last_Day_Month]
(@date date)
RETURNS date
AS
BEGIN
     
	RETURN  dateadd(month,1,dateadd(day,-datepart(day,@date), convert(date,@date)))


END
GO