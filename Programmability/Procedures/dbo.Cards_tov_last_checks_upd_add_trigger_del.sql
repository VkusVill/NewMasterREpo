SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:  	OD
-- Create date: 2017-05-18
-- Description:	
--select * from jobs..jobs where job_name='jobs..Cards_tov_last_checks_upd_add_trigger'
-- =============================================
CREATE PROCEDURE [dbo].[Cards_tov_last_checks_upd_add_trigger_del] @id_job AS int
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements.
  SET NOCOUNT ON;

  DECLARE @getdate AS datetime = GETDATE()

  --!!!!Рассчитывается только для пользователей с телеграм
  IF OBJECT_ID('tempdb..#inserted') IS NOT NULL
    DROP TABLE #inserted

  SELECT
    [number],
    param1 [tov_str],
    id [row_uid],
    [id_telegram] 
  INTO #inserted
  FROM [jobs].[dbo].[Jobs_add_trigger]
  WHERE date_add >= CONVERT(date, DATEADD(DAY, -3, GETDATE()))
  AND [procedure_name] = 'jobs..Cards_tov_last_checks_upd_add_trigger'

  INSERT INTO jobs..Jobs_log ([id_job], [number_step], [duration])
    SELECT
      @id_job,
      10,
      DATEDIFF(MILLISECOND, @getdate, GETDATE())
  SELECT
    @getdate = GETDATE()

  --insert into #inserted ([number], [tov_str] , [row_uid] ,[id_telegram])
  -- select '0001757','20835~1~78~14010|248~1~48~20|151~1~50~114|20324~2~240~13490|15433~1~36~271|647~1~0~1|20549~1~26.4~13802|21035~1~88.2~13990|',NEWID(),304177731  
  IF OBJECT_ID('tempdb..#Cards_tov_tt') IS NOT NULL
    DROP TABLE #Cards_tov_tt
  SELECT
    ctt.number,
    ctt.tov_last_checks INTO #Cards_tov_tt
  FROM vv03..Cards_tov_tt AS ctt WITH (NOLOCK)
  WHERE number IN (SELECT DISTINCT
    number
  FROM #inserted)



  IF OBJECT_ID('tempdb..#tov_cur_check') IS NOT NULL
    DROP TABLE #tov_cur_check
  CREATE TABLE #tov_cur_check (
    id_tov int,
    par2 int
  )
  IF OBJECT_ID('tempdb..#tov_Cards_check') IS NOT NULL
    DROP TABLE #tov_Cards_check
  CREATE TABLE #tov_Cards_check (
    id_tov int,
    par2 int
  )

  --declare @id_jobs as int=4060
  DECLARE @number AS char(7),
          @tov_str AS varchar(max),
          @tov_str_res AS varchar(max),
          @tov_str_Cards AS varchar(max),
          @res AS varchar(max),
          @id_telegram AS bigint



  INSERT INTO jobs..Jobs_log ([id_job], [number_step], [duration])
    SELECT
      @id_job,
      20,
      DATEDIFF(MILLISECOND, @getdate, GETDATE())
  SELECT
    @getdate = GETDATE()

  BEGIN TRY
    DECLARE crs_Cards_tov_last_checks_upd CURSOR FOR
    SELECT DISTINCT
      [number],
      [tov_str],
      id_telegram
    FROM #inserted
    OPEN crs_Cards_tov_last_checks_upd

    FETCH crs_Cards_tov_last_checks_upd INTO @number, @tov_str, @id_telegram

    WHILE @@FETCH_STATUS <> -1
    BEGIN
      SET @tov_str_res = ''
      SET @tov_str_res = ISNULL(Loyalty.dbo.Get_Tov_str_by_PN_Str(@tov_str), '')
      SELECT
        @tov_str_Cards = tov_last_checks
      FROM #Cards_tov_tt
      WHERE number = @number
      --товары в новом чеке
      DELETE FROM #tov_cur_check
      INSERT INTO #tov_cur_check
      EXEC vv03.dbo.pars_strings @tov_str_res,
                                 @tov_str_res
      --товары в чеках за последние 3 дня
      DELETE FROM #tov_Cards_check
      INSERT INTO #tov_Cards_check
      EXEC vv03.dbo.pars_strings @tov_str_Cards,
                                 @tov_str_Cards

      SELECT
        @res = SUBSTRING((SELECT
          ',' + RTRIM(id_tov)
        FROM (SELECT
          id_tov
        FROM #tov_Cards_check
        UNION
        SELECT
          id_tov
        FROM #tov_cur_check) a
        FOR xml PATH (''))
        , 2, 2000)
      UPDATE vv03..Cards_tov_tt WITH (ROWLOCK)
      SET tov_last_checks = @res
      FROM vv03..Cards_tov_tt
      WHERE number = @number
      AND tov_last_checks <> @res
      --select @tov_str_res, @tov_str,@tov_str_Cards, @res



      INSERT INTO jobs..Jobs_log ([id_job], [number_step], [duration])
        SELECT
          @id_job,
          30,
          DATEDIFF(MILLISECOND, @getdate, GETDATE())
      SELECT
        @getdate = GETDATE()
    --обработка акции
    BEGIN TRY
      DECLARE @year_month AS int

      SELECT
        @year_month = Telegram.dbo.Next_month_year(GETDATE())



      IF EXISTS (SELECT
          *
        FROM Telegram..BOT_Action_50_SKU AS ba WITH (NOLOCK)
        WHERE number = @number
        AND Year_month = @year_month
        AND ISNULL(is_active, 0) = 1)
      BEGIN



        INSERT INTO jobs..Jobs_log ([id_job], [number_step], [duration])
          SELECT
            @id_job,
            40,
            DATEDIFF(MILLISECOND, @getdate, GETDATE())
        SELECT
          @getdate = GETDATE()
        EXEC telegram.[dbo].sp_Action_50_SKU_Recalc_Check_after @number = @number,
                                                                @id_telegram = @id_telegram,
                                                                @tov_str = @tov_str_res,
                                                                @year_month = @year_month


        INSERT INTO jobs..Jobs_log ([id_job], [number_step], [duration])
          SELECT
            @id_job,
            50,
            DATEDIFF(MILLISECOND, @getdate, GETDATE())
        SELECT
          @getdate = GETDATE()

      END
    END TRY
    BEGIN CATCH
      INSERT INTO jobs..error_jobs (job_name, number_step, message, id_job)
        SELECT
          'Cards_tov_last_checks_upd_add_trigger',
          11,
          ERROR_MESSAGE(),
          @id_job
    END CATCH

      FETCH NEXT FROM crs_Cards_tov_last_checks_upd INTO @number, @tov_str, @id_telegram
    END

    CLOSE crs_Cards_tov_last_checks_upd
    DEALLOCATE crs_Cards_tov_last_checks_upd

    DELETE FROM [jobs].[dbo].[Jobs_add_trigger]
      FROM [jobs].[dbo].[Jobs_add_trigger] AS c
      INNER JOIN #inserted i
        ON c.id = i.row_uid
        AND c.[procedure_name] = 'jobs..Cards_tov_last_checks_upd_add_trigger'

  END TRY
  BEGIN CATCH
    INSERT INTO jobs..error_jobs (job_name, number_step, message, id_job)
      SELECT
        'jobs..Cards_tov_last_checks_upd_add_trigger',
        100,
        ERROR_MESSAGE(),
        @id_job
  END CATCH


  INSERT INTO jobs..Jobs_log ([id_job], [number_step], [duration])
    SELECT
      @id_job,
      60,
      DATEDIFF(MILLISECOND, @getdate, GETDATE())
  SELECT
    @getdate = GETDATE()

  IF OBJECT_ID('tempdb..#inserted') IS NOT NULL
    DROP TABLE #inserted
  IF OBJECT_ID('tempdb..#Cards_tov_tt') IS NOT NULL
    DROP TABLE #Cards_tov_tt
  IF OBJECT_ID('tempdb..#tov_cur_check') IS NOT NULL
    DROP TABLE #tov_cur_check
  IF OBJECT_ID('tempdb..#tov_Cards_check') IS NOT NULL
    DROP TABLE #tov_Cards_check

END
GO