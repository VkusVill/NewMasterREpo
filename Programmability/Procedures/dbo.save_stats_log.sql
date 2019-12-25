SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:      Rytik
-- Create date: 2019-04-02
-- Description: Сохранение статистики по приложению
-- =============================================
CREATE PROCEDURE [dbo].[save_stats_log] 
  @id bigint
AS
BEGIN
  SET NOCOUNT ON

  DECLARE @id_job   int = 10530,
          @getdate  datetime = GETDATE(),
          @error_message varchar(max) = '',
          @job_name varchar(100) = com.dbo.Object_name_for_err(@@procID, DB_ID()),
          @mp       bit = 1

  BEGIN TRY   
    INSERT INTO [Temp_tables].dbo.stats_log_tmp (
      date_log,
      number,
      id_job,
      insSource
    )   
    SELECT
      CONVERT(date, date_add) AS date_log,
      RTRIM(tl.par3) AS number,
      tl.id_job,
      insSource    
    FROM telegram.dbo.telegram_log AS tl WITH (NOLOCK)
    WHERE tl.number_step = 1
        AND 
          tl.par3 != ''
        AND 
          LEN(tl.par3) = 7
        AND 
          date_add >= DATEADD(DAY, -1, CONVERT(date, GETDATE()))
        AND 
          date_add < CONVERT(date, GETDATE())
    GROUP BY  CONVERT(date, date_add),
              tl.par3,
              tl.id_job,
              insSource


    INSERT INTO loyalty.dbo.stats_log (
      date_log,
      number,
      id_job,
      insSource
    )
    SELECT 
      date_log,
      number,
      id_job,
      insSource
    FROM [Temp_tables].dbo.stats_log_tmp

    INSERT INTO [srv-sql06].Reports.dbo.stats_log (
      date_log,
      number,
      id_job,
      insSource
    )
    SELECT 
      date_log,
      number,
      id_job,
      insSource
    FROM [Temp_tables].dbo.stats_log_tmp

    TRUNCATE TABLE [Temp_tables].dbo.stats_log_tmp
  END TRY
  BEGIN CATCH
    SET @error_message = ERROR_MESSAGE()

    INSERT INTO Telegram.dbo.telegram_log ([id_job], [number_step], [duration], mp)
    SELECT @id_job, 100, DATEDIFF(SECOND, @getdate, GETDATE()), @mp

    INSERT jobs.dbo.error_jobs (id_job, job_name, message, number_step)
    SELECT @id_job, @job_name, @error_message, 100
  END CATCH
END
GO