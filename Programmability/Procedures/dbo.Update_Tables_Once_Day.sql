SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		OD, Rytik
-- Create date: 2019-02-01
-- Description:	Обновление вспомогательных таблиц на 03 сервере 1 раз в час
--select * from jobs..jobs_reestr where ProcedureName like '%Update_Tables%'
--select * from jobs..jobs where job_Name like '%Update_Tables%'

-- =============================================
CREATE PROCEDURE [dbo].[Update_Tables_Once_Day]
@id_job  int
AS
BEGIN	
	SET NOCOUNT ON;
	
  declare
   
    @getdate as datetime = getdate(),
		@job_name as varchar(100) =  com.dbo.Object_name_for_err(@@procID,db_id()),
    @temp_table as nchar(36) 

  insert into jobs.dbo.Jobs_log([id_job], [number_step], [duration]) 
  select @id_job, 10, DATEDIFF(MILLISECOND, @getdate, GETDATE()) 
  select @getdate = getdate()
    
  exec jobs..Update_tt_format_project  @id_job


  insert into jobs.dbo.Jobs_log([id_job], [number_step], [duration]) 
  select @id_job, 20, DATEDIFF(MILLISECOND, @getdate, GETDATE()) 
  select @getdate = getdate()
 
  exec jobs..Update_Price_tov_tt_format @id_job


  insert into jobs..Jobs_log ([id_job],[number_step],[duration]) 
  select @id_job , 70, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
  select @getdate = getdate()


  exec jobs..Update_Tovar_image @id_job
  
  insert into jobs..Jobs_log ([id_job],[number_step],[duration]) 
  select @id_job , 80, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
  select @getdate = getdate()

  exec jobs..Update_TovarBarcode @id_job
  
  insert into jobs..Jobs_log ([id_job],[number_step],[duration]) 
  select @id_job , 90, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
  select @getdate = getdate()

END
GO