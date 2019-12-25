SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		OD
-- Create date: 2019-05-22
-- Description:	Обновление вспомогательных таблиц на 03 сервере 1 раз в 5мин
--select * from jobs..jobs_reestr where ProcedureName like '%Update_Tables_every_5min%'
--select * from jobs..jobs_union where job_Name like '%Update_Tables_every_5min%'

-- =============================================
CREATE PROCEDURE [dbo].[Update_Tables_every_5min]
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
    
  exec jobs..Update_Postavka_CurDay  @id_job


  insert into jobs.dbo.Jobs_log([id_job], [number_step], [duration]) 
  select @id_job, 20, DATEDIFF(MILLISECOND, @getdate, GETDATE()) 
  select @getdate = getdate()
 
  exec jobs..Update_Tov_bez_ostatkov_for_LP  @id_job


  insert into jobs.dbo.Jobs_log([id_job], [number_step], [duration]) 
  select @id_job, 30, DATEDIFF(MILLISECOND, @getdate, GETDATE()) 
  

 exec jobs..Update_Tovar_BuyerOrder @id_job


  insert into jobs.dbo.Jobs_log([id_job], [number_step], [duration]) 
  select @id_job, 40, DATEDIFF(MILLISECOND, @getdate, GETDATE()) 
  
END
GO