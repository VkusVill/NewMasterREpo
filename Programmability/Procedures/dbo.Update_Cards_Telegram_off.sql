SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		OD
-- Create date: 2017-09-27
-- Description:	Обновление заблокированных телеграм карт
-- OD 2019-10-03 Добавила номер бота, от которого отказался пользователь.
--select * from jobs..jobs_union where job_name like '%Update_Cards_Telegram_off%'
-- =============================================
CREATE PROCEDURE [dbo].[Update_Cards_Telegram_off]
@id_job as int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	declare @job_name varchar(500) = com.dbo.Object_name_for_err(@@procid,db_id())

if OBJECT_ID('tempdb..#telegram_blocked') is not null drop table #telegram_blocked
if OBJECT_ID('tempdb..#res') is not null drop table #res

BEGIN TRY  
  
	select *
	into #telegram_blocked
	from
	(  
	SELECT  user_id
		, err_message
		, add_date
		, bot_id
		, ROW_NUMBER()over (partition by user_id, bot_id order by add_date desc)rn
	FROM [Telegram].[dbo].[outbox_telegram] with(nolock))	a
	WHERE a.rn=1 
		and  a.err_message  in('[403] Forbidden: user is deactivated', '[403] Forbidden: bot was blocked by the user')
    

     --Определим тех, кто заблокировал бот Вкусвилл
	 select c.number
		, n.user_id 
		, n.add_date 
		, n.bot_id 
	 into #res
	 from #telegram_blocked n 
		inner join vv03..cards as c with(nolock)
			on n.user_id=c.telegram_id
	 where n.bot_id=1		 
		

		
		
	--пока вновим записи в таблицу vv03..cards_telegram_off минуя триггер, потому что в триггер попадают старые карты после переноса данных
	insert into vv03..cards_telegram_off 
		(number
		,telegram_id
		,type_add
		,date_add
		,bot_id)
	select number
		,user_id 
		,1
		,add_date 
		,bot_id
	from #res n 
	
	insert into vv03..cards_telegram_off 
		(number
			,telegram_id
			,type_add
			,date_add
			,bot_id)
	select isnull(c.number,'')
		,user_id 
		,1
		,add_date 
		,n.bot_id 
	 from #telegram_blocked n 
		left join vv03..cards as c with(nolock)
			on n.user_id=c.telegram_id
        left join vv03..cards_telegram_off as o 
			on o.telegram_id=n.user_id
				 and o.bot_id=n.bot_id
	 where n.bot_id<>1 and o.telegram_id is null
	 
	 	
	declare @s as nvarchar(4000), @temp_table as nvarchar(36)
	select @temp_table= replace(convert(char(36),NEWID()) , '-' , '_')
  
	SET @s  =
	  'select *   into Temp_tables..[' + @temp_table + '] ' +
	  'from #res'
	EXEC sp_executeSQL @s 
  
	SET @s  = '
	  EXEC( ''select * into Temp_tables.dbo.[' + @temp_table + ']  from [SRV-SQL03].Temp_tables.dbo.[' + @temp_table + '] '') at [SRV-SQL01]'
 
	EXEC sp_executeSQL @s 


	SET @s  = '
	 EXEC('' update loyalty..customer  set telegram_id=0, only_telegram_sms=0
	   from Temp_tables.dbo.[' + @temp_table + '] n 
		inner join loyalty..customer as c  
			on n.user_id=c.telegram_id	
		

 
	 '') at [SRV-SQL01]
	' 

	exec sp_executeSQL @s 		  


			
	SET @s  =
	  'drop table Temp_tables..[' + @temp_table + ']
	   EXEC( ''drop table Temp_tables.dbo.[' + @temp_table + ']'') at [SRV-SQL01]  '
  
	EXEC sp_executeSQL @s

	update [Telegram].[dbo].[outbox_telegram] set err_message=null
	--select *
	from [Telegram].[dbo].[outbox_telegram] as o 
		inner join #telegram_blocked as r 
			on o.user_id=r.user_id
	where o.err_message is not null		
	 
END TRY
BEGIN CATCH
	 insert into jobs..error_jobs(id_job, job_name, number_step, message)
	 select @id_job, @job_name, 100, ERROR_MESSAGE()
END CATCH
drop table #res
drop table #telegram_blocked



END
GO