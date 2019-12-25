SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:      OD
-- Create date: 2018-12-25
-- Description: Обновление [vv03].[dbo].[Tovar_full_analog] --полные аналоги

-- =============================================
CREATE PROCEDURE [dbo].[Update_Tovar_full_analog]
  @id_job  int
AS
BEGIN  
  SET NOCOUNT ON;
  
  declare
    @getdate as datetime = getdate(),
    @job_name as varchar(100) = com.dbo.Object_name_for_err(@@procID,db_id())


BEGIN TRY
    IF OBJECT_ID ('tempdb..#Tovar_full_analog') is not null drop table #Tovar_full_analog

    CREATE TABLE #Tovar_full_analog(
    	id_tov1 numeric(10, 0) NULL,
	    Name_tov1 varchar(150) NULL,
    	id_tov2 numeric(10, 0) NULL,
	    Name_tov2 varchar(150) NULL,
	    Ref binary(16) NOT NULL
    )
	INSERT INTO #Tovar_full_analog (id_tov1,Name_tov1,id_tov2,Name_tov2,Ref  )
	SELECT id_tov1,Name_tov1,id_tov2,Name_tov2,Ref  
	FROM [srv-sql01].[Reports].dbo.vw_tovar_full_analog
    
        
      MERGE INTO vv03.dbo.tovar_full_analog as t
      USING #Tovar_full_analog as t1
       ON t.id_tov1=t1.id_tov1
		AND t.id_tov2=t1.id_tov2
		AND t.Ref=t1.Ref
	  WHEN NOT MATCHED BY TARGET	
	  THEN  INSERT (id_tov1,Name_tov1,id_tov2,Name_tov2,Ref  )
			VALUES (t1.id_tov1,t1.Name_tov1,t1.id_tov2,t1.Name_tov2,Ref)
	  WHEN NOT MATCHED BY SOURCE
	  THEN  DELETE
	  WHEN MATCHED 
		AND ( t.Name_tov1<>t1.Name_tov1
			OR
			  t.Name_tov2<>t1.Name_tov2
			  )
	  THEN UPDATE SET t.Name_tov1=t1.Name_tov1
					 ,t.Name_tov2=t1.Name_tov2; 		  	
	  	
    if OBJECT_ID ('tempdb..#Tovar_full_analog') is not null drop table #Tovar_full_analog
    
  END TRY
  BEGIN CATCH
  
      INSERT INTO jobs.dbo.error_jobs(job_name, message, number_step, id_job)
      SELECT @job_name, ERROR_MESSAGE(), 100, @id_job

  END CATCH
  

 
END
GO