SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:  	<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
--select * from jobs..jobs as j with(nolock) where job_name like '%create_lost_sales%'

-- =============================================
CREATE PROCEDURE [dbo].[create_lost_sales] 
  @id_job int
AS
BEGIN  
  SET NOCOUNT ON

  DECLARE @date1    date,
          @date2    date,
          @Peres    int,
          @getdate  datetime = GETDATE(),
          @err      int,
          @job_name varchar(500) = com.dbo.Object_name_for_err(@@ProcID,DB_ID()) ,
		  @time_start time 
  
  SELECT @time_start=dateadd(minute,r_period_minute,time_j_r) from jobs..jobs_reestr as j with(nolock)
  WHERE ProcedureName='m2.dbo.create_lost_sales'
  
  SET @Peres = CASE
                  WHEN CONVERT(time, GETDATE()) < @time_start THEN 1
                  ELSE 0
                END

  IF  ( CASE
          WHEN  CONVERT(time, GETDATE()) < @time_start 
              OR
                DATEPART(HOUR, GETDATE()) BETWEEN 12 AND 22 THEN 1
          ELSE 0
        END
      ) = 1
  BEGIN -- значит нужно пересчитывать lostsales - либо в 7 утра, либо с 12 до 22 часов
    SELECT
      @date1 = GETDATE(),
      @date2 = GETDATE()
    -- по умолчанию дата начала и конца - сегодня

    IF (@Peres = 1) -- значит считаем за прошлые 7 дней
    BEGIN

      SELECT
        @date1 = DATEADD(DAY, -7, GETDATE()),
        @date2 = DATEADD(DAY, -1, GETDATE()) -- вчера
      --Запретим создание распределений до окончания пересчета потерянных
      INSERT INTO M2.dbo.raspr_disable ( raspr_disable,   number_step, id_job )
      SELECT     1,    1, @id_job

      -- удалить все потерянные за прошлые 7 дней
      --DELETE FROM M2..Lost_sales
      --WHERE date_ls >= @date1    

      WHILE 1 = 1
      BEGIN
      BEGIN TRY
        EXEC M2.dbo.lost_sales_telo @date1,
                                    @date2,
                                    @id_job
        BREAK
      END TRY
      BEGIN CATCH
        IF  CASE
              WHEN  CHARINDEX('вызвала взаимоблокировку ресурсов', ERROR_MESSAGE(), 1) > 0 
                  OR
                    CHARINDEX('Текущая транзакция не может быть зафиксирована', ERROR_MESSAGE(), 1) > 0 
                  OR
                    CHARINDEX('Connection may have been terminated by the server', ERROR_MESSAGE(), 1) > 0 THEN 1
              ELSE 0
            END = 1
          EXEC com.dbo.jobs_log_ins @id_job, 2222, @getdate OUTPUT
        ELSE
        BEGIN
          INSERT INTO jobs..error_jobs (job_name, message, number_step, id_job)
          SELECT @job_name, ERROR_MESSAGE(), 2222, @id_job

          EXEC [jobs].[dbo].[Send_notification] @Msg          = 'M2.dbo.create_lost_sales упал на расчете потерянных за прошедшие 7 дней', 
                                                @TypeContact  = 'create_lost_sales', 
                                                @FlagNoDouble = 1,
                                                @OutgoingTypeId = 4

          RETURN
        END
      END CATCH
      END --while		

      INSERT INTO M2.dbo.raspr_disable (raspr_disable, number_step, id_job )
      SELECT 1,2,@id_job
    END
    ELSE
    BEGIN
      --текущй день
      EXEC M2.dbo.lost_sales_telo @date1,
                                  @date2,
                                  @id_job
	  
    END
  END

  IF (@Peres = 1) -- значит утро - нужно пересчитать таблицу w_all для распределений
  BEGIN
    EXEC com.dbo.jobs_log_ins @id_job, 400, @getdate OUTPUT  

    WHILE 1 = 1
    BEGIN
      BEGIN TRY
        EXEC m2.dbo.add_w_all @id_job
      
        BREAK
      END TRY
      BEGIN CATCH
        IF CASE
            WHEN  CHARINDEX('вызвала взаимоблокировку ресурсов', ERROR_MESSAGE(), 1) > 0 
                OR
                  CHARINDEX('Текущая транзакция не может быть зафиксирована', ERROR_MESSAGE(), 1) > 0 
                OR
                  CHARINDEX('Connection may have been terminated by the server', ERROR_MESSAGE(), 1) > 0 THEN 1
            ELSE 0
          END = 1
        BEGIN
          EXEC com.dbo.jobs_log_ins @id_job, 3333, @getdate OUTPUT
        END
        ELSE
        BEGIN
          INSERT INTO jobs.dbo.error_jobs (job_name, message, number_step, id_job)
          SELECT @job_name, ERROR_MESSAGE(), 3333, @id_job

          EXEC [jobs].[dbo].[Send_notification] @Msg            = 'M2.dbo.create_lost_sales упал на exec m2.dbo.add_w_all_01 ', 
                                                  @TypeContact  = 'create_lost_sales', 
                                                  @FlagNoDouble = 1,
                                                  @OutgoingTypeId = 4 

          RETURN
        END
      END CATCH
    END --while   

    IF EXISTS(  SELECT 1
                FROM m2.dbo.w_all
                WHERE [DATE_r] = DATEADD(DAY, 1, CONVERT(date, GETDATE()))
              )
      INSERT INTO M2.dbo.raspr_disable (raspr_disable, number_step, id_job )
      SELECT  0,  3, @id_job
    ELSE
    BEGIN
      EXEC [jobs].[dbo].[Send_notification] @Msg          = 'ALARM! M2.dbo.create_lost_sales не смог заполнить m2..w_all', 
                                            @TypeContact  = 'create_lost_sales', 
                                            @FlagNoDouble = 1,
                                            @OutgoingTypeId = 4

      RETURN 5
    END

    WHILE 1 = 1
    BEGIN
      BEGIN TRY
        INSERT INTO m2.dbo.w_all_01
        SELECT *
        FROM m2.dbo.w_all WITH(NOLOCK)       

        BREAK
      END TRY
      BEGIN CATCH
        IF  CASE
              WHEN  CHARINDEX('вызвала взаимоблокировку ресурсов', ERROR_MESSAGE(), 1) > 0 
                  OR
                    CHARINDEX('Текущая транзакция не может быть зафиксирована', ERROR_MESSAGE(), 1) > 0 
                  OR
                    CHARINDEX('Connection may have been terminated by the server', ERROR_MESSAGE(), 1) > 0 THEN 1
              ELSE 0
            END = 1       
          EXEC com.dbo.jobs_log_ins @id_job, 4444, @getdate OUTPUT       
        ELSE
        BEGIN
          INSERT INTO jobs.dbo.error_jobs (job_name, message, number_step, id_job)
          SELECT @job_name, ERROR_MESSAGE(), 4444, @id_job

          EXEC [jobs].[dbo].[Send_notification] @Msg          = 'M2.dbo.create_lost_sales заполнил m2.dbo.w_all и упал на insert into m2.dbo.w_all_01', 
                                                @TypeContact  = 'create_lost_sales', 
                                                @FlagNoDouble = 1,
                                                @OutgoingTypeId = 4
          RETURN
        END
      END CATCH
    END --while   

    ---------Обновим текущие данные по средней частоте------------------------------

    INSERT INTO jobs.dbo.Jobs (     job_name,       prefix_job    )
    SELECT      'm2..update_lost_sales_cur',      0

    EXEC com.dbo.jobs_log_ins @id_job, 500, @getdate OUTPUT   

    -- обновим маржу частоту
    INSERT INTO jobs.dbo.Jobs (job_name, prefix_job)
    select  'reports.dbo.marge_chast_total', 1

    EXEC com.dbo.jobs_log_ins @id_job, 510, @getdate OUTPUT

	-- запустим проверку
    INSERT INTO jobs.dbo.Jobs (job_name, prefix_job)
    select  'M2..proverka_lost_sales_telo', 0

    EXEC com.dbo.jobs_log_ins @id_job, 520, @getdate OUTPUT	
  END
END
GO