SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================  
-- Author:  OD  
-- Create date: 2019-06-02  
-- Description: Отправление сообщения об ошибки распределения в бот в группу Распределение  
-- =============================================  
CREATE PROCEDURE [dbo].[Send_Notification_Bot_Group]  
    
 @name varchar(1000),  
 @msg varchar(1000)=null  
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
    
  declare @job_name varchar(500)=com.dbo.Object_name_for_err(@@Procid,DB_ID())  
   ,@id_job int=400100  
   ,@id_group bigint  
  
  set @id_group=  master.dbo.BOT_Get_idGroup(@name)  
  
  IF isnull(@id_group,0)=0  
    return -1  
      
  BEGIN TRY  
        
   IF @id_group=-357925557  
   BEGIN  
     IF EXISTS (SELECT 1   
       FROM [Telegram].[dbo].[outbox_telegram] with(nolock)  
       WHERE [BOT_id]=2   
      AND [user_id]=@id_group  
      AND [message]=@msg  
      AND [add_date]>=convert(date,getdate()))  
        RETURN 0  
   END  
   
   INSERT INTO [Telegram].[dbo].[outbox_telegram]  
        ([bot_id],[user_id],[incoming_message],[message],[keyboard_id],[keyboard_parameter]  
        ,[message_type],[add_date])  
   
   SELECT 2 [bot_id]  
      ,@id_group [user_id] --Группа распределение  
      ,0 [incoming_message]  
      ,@msg  
      ,0  
      ,''  
      ,0  
      ,GETDATE()  
      return 0   
     
  END TRY  
  BEGIN CATCH  
    INSERT INTO jobs..error_jobs(id_job, job_name, date_add, message)  
 SELECT @id_job,@Job_name, getdate(),ERROR_MESSAGE()  
  END CATCH  
END
GO