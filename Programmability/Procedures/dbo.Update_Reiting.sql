SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		OD
-- Create date: 2017-08-31
-- Description:	Обновление оценки по товару
--exec jobs..Update_Reiting 5                             
--select * from jobs..jobs_union where job_name like '%Update_Reiting%' order by date_add desc
-- =============================================
CREATE PROCEDURE [dbo].[Update_Reiting]
@id_jobs as int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

declare @s as nvarchar(4000)
if OBJECT_ID ('tempdb..#reiting') is not null drop table #reiting   

create table #reiting([id_tov] [int] NOT NULL,
	[id_kontr] [int] NULL,
	[колво] [int] null,
	[reiting_avg] [decimal](15, 2) NOT NULL,
	[reiting] [decimal](15, 2) NOT NULL,
	[Доля5] [decimal](15, 2), 
	[Доля12] [decimal](15, 2),
	[ДоляПост] [decimal](15, 2),
	[date_max] [datetime], 
	[date_min] [datetime]
	)

set @s='exec(''

EXEC	 [SMS_REPL].[dbo].[reiting]
		@date1 = null
		,@Load_03_srv=1'') at [srv-sql01]'
exec sp_executesql @s

insert into #reiting(id_tov,id_kontr,колво,reiting_avg,reiting,Доля5,Доля12,ДоляПост,date_min,date_max)
select r.id_tov,r.id_kontr,r.колво,r.reiting_avg,r.reiting,r.Доля5,r.Доля12,r.ДоляПост,r.date_min,r.date_max
			from [srv-sql01].Reports.dbo.reiting_tov as r with(nolock)
		
--select * from #reiting


	merge into vv03..tovar_kontr_reiting as r
    using #reiting as t
      on t.id_tov=r.id_tov and isnull(t.id_kontr,0)= isnull(r.id_kontr,0)
    when not matched by target then
      insert 
      ( [id_tov]
      ,[id_kontr]
      ,[qty]
      ,[reiting_avg]
      ,[reiting]
      ,[date_update]     
      )
      values( t.[id_tov]
      ,t.[id_kontr]
      ,t.[колво]
      ,t.[reiting_avg]
      ,t.[reiting]
      ,getdate())
     when not matched by source then
        delete 
     when matched 
       and (t.reiting<>r.reiting or t.reiting_avg<>r.reiting_avg or ISNULL(t.колво,0)<> ISNULL(r.qty,0))
			
	    then
	      update set r.reiting=t.reiting,
					r.reiting_avg=t.reiting_avg,
					r.qty=t.колво,
					r.date_update = getdate();



drop table #reiting

--declare @s as nvarchar(4000)

if OBJECT_ID ('tempdb..#reiting_Shop') is not null drop table #reiting_Shop   

create table #reiting_Shop([ShopNo] [int] NOT NULL,
	[колво] [int] null,
	[reiting_avg] [decimal](15, 2) NOT NULL,
	[reiting] [decimal](15, 2) NOT NULL,
	[Доля5] [decimal](15, 2), 
	[Доля12] [decimal](15, 2),
	[ДоляПост] [decimal](15, 2),
	[date_max] [datetime], 
	[date_min] [datetime]
	)


set @s='exec(''
DECLARE	@date as datetime=dateadd(day,1,getdate())

EXEC	 [SMS_REPL].[dbo].[reiting_Shop]
		@date1 = @date'') at [srv-sql01]'
insert into #reiting_Shop(ShopNo,колво,reiting_avg,reiting,Доля5,Доля12,ДоляПост,date_min,date_max)
exec sp_executesql @s


merge into vv03..Shop_reiting as t
using #reiting_Shop as r 
	on t.ShopNo=r.ShopNo
when not matched by target
then insert (ShopNo, reiting, reiting_avg, Qty)
	  values( r.ShopNo , r.reiting , r.reiting_avg , r.колво)	
when not matched by source 
then delete
when matched and (t.reiting<>r.reiting or t.reiting_avg<>r.reiting_avg or ISNULL(t.Qty,0)<> ISNULL(r.колво,0))
then update set t.reiting=r.Reiting, t.reiting_avg=r.reiting_avg, t.Qty=r.колво
;


drop table #reiting_Shop
END
GO