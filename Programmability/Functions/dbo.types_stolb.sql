SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create FUNCTION [dbo].[types_stolb]
(	
@text as char(100)
)
RETURNS @res TABLE 
(
name_st  char(50) ,
par1  char(50) ,
par2  char(50) 
)

AS
begin

Declare @i as int =1 , @j as int =1 , @a as char(50) , @b as char(50) , @c as char(50)

select @j = charindex('|',@text,@i)
Select @a = case when @j>0 then substring(@text,@i , @j-@i) else @text end

Select @i = @j

select @j = charindex('|',@text,@i+1)
Select @b = case when @j>0 then substring(@text,@i+1 , @j-@i-1) else 
case when @i>0 then substring(@text,@i+1 , 10) else '' end end

Select @c = case when @j>0 then substring(@text,@j+1,10) else '' end

insert into @res
select @a , @b , @c

return 

end
GO