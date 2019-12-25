SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:      OSeliv
-- Create date: 2019-08-06
-- Description: Обработка таблицы buffer_outbox_mp
-- =============================================
--select * from jobs..jobs where job_name like '%SendPush_FromBuffer%' and date_exc is null
--select * from jobs..jobs_union where job_name like '%SendPush_FromBuffer%' order by date_add desc
CREATE PROCEDURE [dbo].[SendPush_fromBuffer]
@id_job  as int
AS
BEGIN
  SET NOCOUNT ON;

  declare
    @getdate as datetime = getdate(),
    @job_name varchar(500) = com.dbo.Object_Name_for_err(@@Procid, DB_id())
   
  begin try 
   

   
    if OBJECT_ID('tempdb..#inserted') is not null drop table #inserted 

    
    select top 100
        b.id,
        b.number,
        b.Type_message,
        b.OneSignalToken,
        b.date_message,
		b.Heading_message,
		b.Message,
		b.Data_message,
		b.photo_url
	 into #inserted
      from jobs.dbo.buffer_outbox_mp as b (nolock)
	  where oneSignalToken != ''
	  and date_message <= getdate()  and datediff(mi, date_message, getdate()) < 20
	  order by id
     
     --select * from #inserted
        
    -- Отправка сообщения в мобильное приложение                   
    insert into Telegram.dbo.outbox_MP
          (oneSignalToken,
           Heading_message,
           Message,
           Type_message,
           date_message,
           date_send,
           Data_message,
           number,
		   photo_url)
      select i.oneSignalToken,
             i.Heading_message,
             i.[Message],
             i.Type_message,
             --getdate(),
			 date_message,
             '19000101',
             i.Data_message,
             i.number,
			 i.photo_url
       from #inserted as i
        left join vv03.dbo.Cards_Settings  cs (nolock)
          on i.number = cs.number
       and ISNULL(distribution_tema, 1) = 1
     


    delete bp 
      from buffer_outbox_mp  bp
      where exists (select 1 from #inserted where bp.id = id)

    insert into jobs..Jobs_log ([id_job],[number_step],[duration]) select @id_job , 10, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
    select @getdate = getdate()     

  end try
  begin catch
    insert into jobs..error_jobs(job_name, number_step,message, id_job)
    select @job_name, 1, ERROR_MESSAGE(), @id_job
  end catch

END
GO