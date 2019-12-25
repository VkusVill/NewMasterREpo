SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
create FUNCTION [dbo].[compare_dates] 
(
@date1 as datetime,
@date2 as datetime,
@type as char(3)
)
RETURNS datetime
AS
BEGIN
	-- Declare the return variable here
	DECLARE @date as datetime
	
	Select @date = Case @type when 'max' then 
	  case when @date1>=@date2 then @date1 else @date2 end
	                          when 'min' then 
	  case when @date1<@date2 then @date1 else @date2 end
	                          else null end
	                          
  return @date	                          

END
GO