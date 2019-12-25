SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[First_Day_Month]
(@date date)
RETURNS datetime
AS
BEGIN
     
	RETURN  dateadd(day,1-datepart(day,@date), convert(date,@date))


END
GO