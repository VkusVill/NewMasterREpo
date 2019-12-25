SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- 20190206 RV Обработка записей в outbox_buffer
-- =============================================
CREATE PROCEDURE [dbo].[input_jobs_triggers_20190709] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

declare @getdate datetime = getdate()



--Пересчет полей vv03..DTT
if (select case when a.колво1  >0 and b.колво2=0 then 1 else 0 end
  from 
(select колво1 from openquery([srv-sql01],' Select COUNT(*) колво1
from jobs..Recalc_DTT (nolock)') ) a
inner join
(Select COUNT(*) колво2
from jobs..Jobs (nolock) j
where job_name = 'jobs..Recalc_DTT_add_trigger'
and j.date_exc is null) b on 1=1) =1

insert into jobs..Jobs (
       [job_name]
      ,[prefix_job] )
SELECT 'jobs..Recalc_DTT_add_trigger', 0

insert into jobs..Jobs_log ([id_job],[number_step],[duration]) 
select 0 , 405, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
select @getdate = getdate()


/*

if (select case when a.колво1  >0 and b.колво2=0 then 1 else 0 end
  from 
(Select COUNT(*) колво1
from [jobs].[dbo].[Cards_tov_last_checks_upd]) a
inner join
(Select COUNT(*) колво2
from jobs..Jobs (nolock) j
where job_name = 'jobs..Cards_tov_last_checks_upd_add_trigger'
and j.date_exc is null) b on 1=1) =1

insert into jobs..Jobs (
       [job_name]
      ,[prefix_job] )
SELECT 'jobs..Cards_tov_last_checks_upd_add_trigger', 0

insert into jobs..Jobs_log ([id_job],[number_step],[duration]) 
select 0 , 406, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
select @getdate = getdate()

*/

if (select case when a.колво1  >0 and b.колво2=0 then 1 else 0 end
  from 
(Select COUNT(*) колво1
from [jobs].[dbo].[Poll_add_trigger]) a
inner join
(Select COUNT(*) колво2
from jobs..Jobs (nolock) j
where job_name = 'jobs..Poll_send_add_trigger'
and j.date_exc is null) b on 1=1) =1

insert into jobs..Jobs (
       [job_name]
      ,[prefix_job] )
SELECT 'jobs..Poll_send_add_trigger', 0



insert into jobs..Jobs_log ([id_job],[number_step],[duration]) 
select 0 , 406, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
select @getdate = getdate()


-- Народный Гурман
if (select case when a.колво1  >0 and b.колво2=0 then 1 else 0 end
  from 
(Select COUNT(*) колво1
from [srv-sql01].[jobs].[dbo].[Telegram_Mess_forNG]) a -- буферная таблица
inner join
(Select COUNT(*) колво2
from jobs..Jobs (nolock) j
where job_name = 'jobs..Telegram_Mess_forNG' -- обработчик буферной таблицы
and j.date_exc is null) b on 1=1) =1

	insert into jobs..Jobs (
		   [job_name]
		  ,[prefix_job] )
	select 'jobs..Telegram_Mess_forNG' , 0


insert into jobs..Jobs_log ([id_job],[number_step],[duration]) 
select 0 , 406, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
select @getdate = getdate()



-- Обработка записей в outbox_buffer
if (select case when a.колво1 > 0 and b.колво2 = 0 then 1 else 0 end
      from (select COUNT(*) колво1
              from jobs.dbo.outbox_buffer) a -- буферная таблица
     inner join
           (select COUNT(*) колво2
              from jobs.dbo.Jobs (nolock) j
             where job_name = 'jobs..outbox_buffer_send' -- обработчик буферной таблицы
               and j.date_exc is null) b
       on 1 = 1) = 1

	insert into jobs..Jobs (
		   [job_name]
		  ,[prefix_job] )
	select 'jobs..outbox_buffer_send', 0




insert into jobs..Jobs_log ([id_job],[number_step],[duration]) 
select 0 , 407, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
select @getdate = getdate()


declare @proc_name as varchar(100)
		, @s as nvarchar(4000)

declare crs_job  cursor for
select distinct [procedure_name] from [jobs].[dbo].[Jobs_add_trigger] 
where isnull(server_name,'[srv-sql03]')='[srv-sql03]'
open crs_job

fetch from crs_job into @proc_name
while @@FETCH_STATUS<>-1
begin

    set @s='if (select case when a.колво1  >0 and b.колво2=0 then 1 else 0 end
		  from 
		(Select COUNT(*) колво1
		from [jobs].[dbo].[Jobs_add_trigger] where [procedure_name]='''+ @proc_name+''') a
		inner join
		(Select COUNT(*) колво2
		from jobs..Jobs (nolock) j
		where job_name = '''+ @proc_name+'''
		and j.date_exc is null) b on 1=1) =1

		insert into jobs..Jobs (
			   [job_name]
			  ,[prefix_job] )
		SELECT '''+ @proc_name+''', 0'
   --print @s
   exec sp_executesql @s
	
	fetch next from crs_job into @proc_name
end    

close crs_job
deallocate crs_job


insert into jobs..Jobs_log ([id_job],[number_step],[duration]) 
select 0 , 408, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
select @getdate = getdate()


--обработки, связанные с учетом купленных товаров
--				1-заполнение списка товаров в последних чеках
--              2-пересчет списка товаров в акции Разнообразное питание			
--              3-учет товаров, купленных по подписке
if (select case when a.колво1  >0 and b.колво2=0 then 1 else 0 end
  from 
(Select COUNT(*) колво1
from [jobs].[dbo].[Tovar_after_Check_add_trigger]) a
inner join
(Select COUNT(*) колво2
from jobs..Jobs (nolock) j
where job_name = 'jobs..Tovar_after_Check'
and j.date_exc is null) b on 1=1) =1

insert into jobs..Jobs (
       [job_name]
      ,[prefix_job] )
SELECT 'jobs..Tovar_after_Check', 0
END
GO