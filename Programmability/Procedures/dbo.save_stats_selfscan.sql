SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:      Rytik
-- Create date: 2019-05-27
-- Description: Сохранение истории "Сканируй сам"
-- =============================================

CREATE PROCEDURE [dbo].[save_stats_selfscan] @id bigint
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE
    @id_job        AS int          = 10550,
    @getdate       AS datetime     = GETDATE(),
    @error_message AS varchar(MAX) = '',
    @job_name      AS varchar(100) = com.dbo.Object_name_for_err(@@procID, DB_ID())

  BEGIN TRY
    INSERT INTO Loyalty.dbo.stats_selfscan (
      number,
      date_add,
      cashID,
      cashCheckNo,
      isProcessed,
      isCardVerified,
      params
    )
    SELECT
      SUBSTRING(PARAMS, 5, 7),
      DateTimeAdd,
      CashID,
      CashCheckNo,
      IsProcessed,
      IsCardVerified,
      PARAMS
    FROM Frontol.dbo.MobileOrderHold AS moh
    WHERE PARAMS LIKE '{1%'
  END TRY
  BEGIN CATCH
    SET @error_message = ERROR_MESSAGE()

    INSERT INTO Telegram.dbo.Telegram_log (
      [id_job],
      [number_step],
      [duration]
    )
    SELECT
      @id_job,
      100,
      DATEDIFF(SECOND, @getdate, GETDATE())

    INSERT jobs.dbo.error_jobs (
      id_job,
      job_name,
      message,
      number_step
    )
    SELECT
      @id_job,
      @job_name,
      @error_message,
      100
  END CATCH
END
GO