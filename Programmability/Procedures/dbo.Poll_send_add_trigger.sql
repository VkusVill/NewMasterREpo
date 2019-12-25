SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		OD
-- Create date: 2017-08-17
-- Description:	Рассылка опроса
-- =============================================
create PROCEDURE [dbo].[Poll_send_add_trigger]
@id_job as int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

if OBJECT_ID('tempdb..#inserted') is not null drop table #inserted
SELECT [telegram_id]
      ,[number]
      ,[id_poll]
      ,[bot_id]
  into #inserted 
  FROM [jobs].[dbo].[Poll_add_trigger] with(tablockx)
  where date_add>=CONVERT(date, dateadd(day,0,getdate()))
  
   declare @number as char(7), @telegram_id as bigint
		, @id_poll as int
		, @bot_id as int

  begin try
          
  declare crs_Poll_send cursor for
  select [telegram_id],[number],[id_poll],[bot_id]from #inserted
  open crs_Poll_send
  
  fetch crs_Poll_send into @telegram_id,@number,@id_poll,@bot_id
  
  while @@FETCH_STATUS<>-1
  begin          
    
		EXEC	 [telegram].[dbo].[Telegram_Poll_Send]
		@id_telegram = @telegram_id ,
		@number = @number ,
		@id_poll = @id_poll,  
		@bot_id =@bot_id 
		
		delete from [jobs].[dbo].[Poll_add_trigger]
		where telegram_id=@telegram_id and id_poll=@id_poll 
  
	fetch next from crs_Poll_send into @telegram_id,@number,@id_poll,@bot_id
  end
  
  close crs_Poll_send
  deallocate crs_Poll_send				
  


END TRY
  BEGIN CATCH
	
			insert into jobs.dbo.error_jobs
			(job_name , message , number_step , id_job)
			select 'jobs..Poll_send_add_trigger' , 
			rtrim(@id_poll) + ' ' +  rtrim(@telegram_id) + ERROR_MESSAGE() , 100 , @id_job
			
  END CATCH 
  if OBJECT_ID('tempdb..#inserted') is not null drop table #inserted





END
GO