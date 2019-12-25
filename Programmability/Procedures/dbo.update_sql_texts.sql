SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[update_sql_texts]
@id_job int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

delete from jobs..sql_texts

SELECT name 
into #bases
FROM sys.sysdatabases
where name not in ( 'tempdb','master','model')
 
declare @getdate datetime = getdate()

Declare @base as char(50) , @s as nvarchar(500)

DECLARE crs CURSOR LOCAL FOR
 
SELECT name 
from #bases

 OPEN crs
 FETCH crs INTO @base
	
 WHILE NOT @@fetch_status = -1 
	BEGIN

--print @base

insert into jobs..Jobs_log ([id_job],[number_step],[duration],par3 ) 
select @id_job , 10, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) , @base 
select @getdate = getdate()

select @s  = 'use  [' + RTRIM(@base) + 
'] ; 
insert into jobs..sql_texts
select left(''' + RTRIM(@base) + ''',50), left(so.name,128) , text , so.xtype ,
row_number() over ( partition by so.name order by so.xtype ) rn  , isnull(so2.name,'''') , so.crdate
from syscomments sc
  inner join sysobjects so (nolock) on  sc.id = so.id 
  LEFT join sysobjects so2 (nolock) on so.parent_obj = so2.id
  '

EXEC sp_executesql @S



    FETCH NEXT FROM crs INTO @base
 END

CLOSE crs

drop table #bases


delete from [jobs].[dbo].[sql_texts_str]

declare @i as int=1 ,  @j as int=1  
      --,@base varchar(50)
      ,@name nvarchar(128)
      ,@xtype char(2)
      ,@rn int


DECLARE crs2 CURSOR LOCAL FOR
 
SELECT [base]
      ,[name]
      ,[xtype]
      ,[rn]
from jobs..sql_texts


 OPEN crs2
 FETCH crs2 INTO @base , @name, @xtype ,@rn
 
  WHILE NOT @@fetch_status = -1 
 begin

insert into jobs..Jobs_log ([id_job],[number_step],[duration],par3 , par4 ) 
select @id_job , 20, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) , @base, left(@name,50) 
select @getdate = getdate()


select @i =1 ,  @j =1 

while (select CHARINDEX(char(13),text,@i)
from jobs..sql_texts
where base= @base and name =  @name and xtype = @xtype and rn= @rn
) > 0
begin


insert into [jobs].[dbo].[sql_texts_str]
      ([base]
      ,[name]
      ,[text]
      ,[xtype]
      ,[rn]
      ,[rn_2])
select [base]
      ,[name]
      , SUBSTRING (text , @i , CHARINDEX(char(13),text,@i) - @i)
      ,[xtype]
      ,[rn]
      , @j
from jobs..sql_texts
where base= @base and name =  @name and xtype = @xtype and rn= @rn

select @i = CHARINDEX(char(13),text,@i) +1 ,  @j=  @j+1
from jobs..sql_texts
where base= @base and name =  @name and xtype = @xtype and rn= @rn

end

insert into [jobs].[dbo].[sql_texts_str]
      ([base]
      ,[name]
      ,[text]
      ,[xtype]
      ,[rn]
      ,[rn_2])
select [base]
      ,[name]
      , SUBSTRING (text , @i , 2000)
      ,[xtype]
      ,[rn]
      , @j
from jobs..sql_texts
where base= @base and name =  @name and xtype = @xtype and rn= @rn



    FETCH NEXT FROM crs2 INTO  @base , @name, @xtype ,@rn
 END

CLOSE crs2


END
GO