SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
create FUNCTION [dbo].[without_digit] 
(
@t nvarchar(max)
)
RETURNS nvarchar(max)
AS
BEGIN

return replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(@t,'0',' ')
,'1',' '),'2',' '),'3',' '),'4',' '),'5',' '),'6',' '),'7',' '),'8',' '),'9',' ')

END
GO