SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		OD
-- Create date: 2016-02-16
-- Description:	Перенос информации об ошибках в таблицу на сервере rv-sql01
/*

EXEC [dbo].[err_jobs_add_trigger] 1

*/


-- =============================================


CREATE PROCEDURE [dbo].[err_jobs_add_trigger] 
  @id_job int
AS
BEGIN	
	SET NOCOUNT ON

  DECLARE @getdate    datetime = getdate(),
          @sql	      nvarchar(max),
          @temp_table nchar(36),
          @cn         int = 0,
		  @job_name   varchar(500) = com.dbo.Object_Name_for_err(@@procid,db_id()),
		  @srv_name   VARCHAR(100)    = com.dbo.Get_Server_Name() ,
  		  @Main_srv_name VARCHAR(100) = com.dbo.Get_Main_Server_Name()
		   
		 
  if OBJECT_ID('tempdb..#inserted') is not null drop table #inserted		   
  SELECT * 
  INTO #inserted
  FROM jobs..error_jobs 

 IF EXISTS(SELECT * FROM #inserted)
 BEGIN
	  SET @temp_table = REPLACE(CONVERT(char(36), NEWID()), '-', '_')

	  WHILE @cn<=5
	  BEGIN   
		  BEGIN TRY
	   
					SET @sql = '
					select *   into Temp_tables..[' + @temp_table + '] ' +
				   'from #inserted'
			   
					EXEC sp_executeSQL @sql	
			  
					SET @sql = '
					  EXEC( ''select * into Temp_tables.dbo.[' + @temp_table + ']  from '+@srv_name+'.Temp_tables.dbo.[' 
					  + @temp_table + '] '') at '+@Main_srv_name
				 
					EXEC sp_executeSQL @sql
			   
					SET @sql = '
					  EXEC('' 
						  INSERT INTO jobs..error_jobs (
				  job_name, 
				  message, 
				  number_step,
				  run_date,
				  run_time,
				  date_add,
				  query_err,
				  id_job,
				  SrvName
				)
						  SELECT 
				  '''''+@srv_name+' '''' + job_name, 
				  message, 
				  number_step,
				  run_date,
				  run_time,
				  date_add,
				  query_err,
				  id_job,'
				  + CHAR(39) + CHAR(39) + @srv_name + CHAR(39) + CHAR(39) + '
						  FROM Temp_tables.dbo.[' + @temp_table + ']
						  
					 '') at '+@Main_srv_name

			--PRINT @sql

			--RETURN
					EXEC sp_executeSQL @sql	
						
					SET @sql =
					  'drop table Temp_tables..[' + @temp_table + ']
					   EXEC( ''drop table Temp_tables.dbo.[' + @temp_table + ']'') at '+@Main_srv_name
				  
					EXEC sp_executeSQL @sql
				
					DELETE  FROM jobs..error_jobs 
					FROM  jobs..error_jobs AS er 
						INNER JOIN #inserted AS i 
						  ON er.id_err=i.id_err
				
					BREAK
		  END TRY
		  BEGIN CATCH
			  IF CASE WHEN CHARINDEX('вызвала взаимоблокировку ресурсов', ERROR_MESSAGE(), 1) > 0 
						OR CHARINDEX('Текущая транзакция не может быть зафиксирована', ERROR_MESSAGE(), 1) > 0 THEN 1 ELSE 0 END = 1
			  BEGIN
				  INSERT INTO jobs..Jobs_log ([id_job],[number_step],[duration]) 
				  SELECT @id_job , 11, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 

				  SELECT   @getdate = getdate(), 
					@cn = @cn + 1
			  END
			  ELSE
			  BEGIN
				  SET @sql='exec(''INSERT INTO jobs.dbo.error_jobs (job_name, message, number_step, id_job,SrvName )
				  SELECT '''''+@job_name+''''',  ERROR_MESSAGE(), 12, ' +RTRIM(@id_job)+', '''''+@srv_name+''''''') at '+@Main_srv_name
				  EXEC sp_executeSQL @sql
				  RETURN
			  END	
		  END CATCH
	  END
END
END
GO