SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		OD, Rytik
-- Create date: 2018-10-29
-- Description:	Обновление вспомогательных таблиц на 03 сервере 1 раз в час
--select * from jobs..jobs_reestr where ProcedureName like '%Update_Tables%'
--select * from jobs..jobs where job_Name like '%Update_Tables_1H%'

-- =============================================
CREATE PROCEDURE [dbo].[Update_Tables_Once_Hour]
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
  --------------------------------Обновим таблицу tt_action------------------------------------------------
  exec jobs..Update_tt_action  @id_job


  insert into jobs.dbo.Jobs_log([id_job], [number_step], [duration]) 
    select @id_job, 20, DATEDIFF(MILLISECOND, @getdate, GETDATE()) 
  --------------------------------Обновим таблицу tt_action------------------------------------------------
  exec jobs..Update_Tovar_full_analog   @id_job


  insert into jobs.dbo.Jobs_log([id_job], [number_step], [duration]) 
  select @id_job, 30, DATEDIFF(MILLISECOND, @getdate, GETDATE()) 
  --------------------------------Обновим таблицу vv03..WEB_Catalog_Tovari-----------------------------------------
   exec jobs..Update_WEB_Catalog_Tovari  @id_job -- Надо убрать транзакции


  insert into jobs.dbo.Jobs_log([id_job], [number_step], [duration]) 
  select @id_job, 40, DATEDIFF(MILLISECOND, @getdate, GETDATE())  
 
END
GO