SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:  	<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================

CREATE PROCEDURE [dbo].[clear_tables] @id_job int
AS
BEGIN
  SET NOCOUNT ON

  DECLARE
    @getdate    datetime     = GETDATE(),
    @job_name   varchar(500) = com.dbo.Object_name_for_err(@@ProcID, DB_ID()),
    @s          nvarchar(MAX),
    @table_del  nchar(50),
    @field_date nchar(50),
    @days_stay  int,
    @table_from nchar(50),
    @field_del  nchar(50),
    @field_from nchar(50),
    @rn         int,
    @is_1C      smallint,
    @text_sql   nvarchar(MAX)

  SELECT
    [table_del],
    [field_date],
    [days_stay],
    [table_from],
    [field_del],
    [field_from],
    is_1C,
    rn,
    text_sql
  INTO
    #table_clear
  FROM [jobs].[dbo].[Tables_clear]
  WHERE ISNULL(is_active, 1) = 1
  ORDER BY LEFT(table_del, CHARINDEX('.', table_del, 1) - 1)

  --перед очисткой перенос данных, требующих хранения, в отдельную таблицу
  INSERT INTO Frontol.dbo.MobileOrderHold_fix (
    [MobileOrderHoldID],
    [ItemGUID],
    [PARAMS],
    [IsProcessed],
    [IsCardVerified],
    [DateTimeAdd],
    [CashID],
    [CashCheckNo],
    [RemoteIP]
  )
  SELECT
    [MobileOrderHoldID],
    [ItemGUID],
    [PARAMS],
    [IsProcessed],
    [IsCardVerified],
    [DateTimeAdd],
    [CashID],
    [CashCheckNo],
    [RemoteIP]
  FROM Frontol.dbo.MobileOrderHold WITH (NOLOCK)
  WHERE [DateTimeAdd] < CONVERT(date,
                                DATEADD( DAY,
                                (
                                  SELECT TOP 1
                                         days_stay
                                  FROM #table_clear
                                  WHERE table_del LIKE 'frontol.%.MobileOrderHold %'
                                ),
                                         GETDATE()
                                       )
                               )
        AND RemoteIP LIKE '192.168.%'

  DECLARE crs CURSOR LOCAL FOR
  SELECT
    [table_del],
    [field_date],
    [days_stay],
    [table_from],
    [field_del],
    [field_from],
    is_1C,
    rn,
    text_sql
  FROM #table_clear

  OPEN crs

  FETCH crs
  INTO
    @table_del,
    @field_date,
    @days_stay,
    @table_from,
    @field_del,
    @field_from,
    @is_1C,
    @rn,
    @text_sql

  WHILE @@fetch_status = 0
  BEGIN
    BEGIN TRY
      IF (ISNULL(RTRIM(@field_date), '')) <> ''
        IF @is_1C = 0
          SET @s = N'SELECT 1 
			  WHILE @@ROWCOUNT <> 0
				DELETE TOP(5000) ' + RTRIM(@table_del) + N' 
				WHERE ' + RTRIM(@field_date) + N' < CONVERT(date, DATEADD(day, -' + RTRIM(@days_stay) + N', GETDATE()) )'
        ELSE
          SET @s = N'SELECT 1 
			  WHILE @@ROWCOUNT <> 0
				DELETE TOP(5000) ' + RTRIM(@table_del) + N' 
				WHERE ' + RTRIM(@field_date) + N' < CONVERT(date, DATEADD(day, -' + RTRIM(@days_stay)
                   + N', DATEADD(YEAR, 2000, GETDATE()))) '
      ELSE
        SELECT
          @s = N' SELECT 1
			WHILE @@ROWCOUNT <> 0
			  DELETE TOP(5000) ' + RTRIM(@table_del) + N' 
			FROM ' + RTRIM(@table_del) + N'  
			LEFT JOIN ' + RTRIM(@table_from) + N'  on ' + RTRIM(@table_del) + N'.' + RTRIM(a.name_st) + N' = '
               + RTRIM(@table_from) + N'.' + RTRIM(b.name_st)
               + CASE
                   WHEN ISNULL(RTRIM(a.par1), '') <> '' THEN
                     ' and ' + RTRIM(@table_del) + '.' + RTRIM(a.par1) + ' = ' + RTRIM(@table_from) + '.'
                     + RTRIM(b.par1)
                   ELSE
                     ''
                 END
               + CASE
                   WHEN ISNULL(RTRIM(a.par2), '') <> '' THEN
                     ' and ' + RTRIM(@table_del) + '.' + RTRIM(a.par2) + ' = ' + RTRIM(@table_from) + '.'
                     + RTRIM(b.par2)
                   ELSE
                     ''
                 END + N' WHERE ' + RTRIM(@table_from) + N'.' + RTRIM(b.name_st) + N' IS NULL'
        FROM jobs.dbo.types_stolb(@field_del) a ,
             jobs.dbo.types_stolb(@field_from) b

      IF @text_sql IS NOT NULL
        SET @s = RTRIM(@s) + N' AND ( ' + RTRIM(@text_sql) + N' )'

      EXEC sp_executesql @s

      INSERT INTO jobs..Jobs_log (
        [id_job],
        [number_step],
        [duration],
        par3
      )
      SELECT
        @id_job,
        @rn,
        DATEDIFF(MILLISECOND, @getdate, GETDATE()),
        @table_del

      SET @getdate = GETDATE()
    END TRY
    BEGIN CATCH
      INSERT INTO jobs..error_jobs (
        id_job,
        job_name,
        message,
        number_step,
        date_add
      )
      SELECT
        @id_job,
        @job_name,
        ERROR_MESSAGE(),
        @rn,
        GETDATE()
    END CATCH

    FETCH NEXT FROM crs
    INTO
      @table_del,
      @field_date,
      @days_stay,
      @table_from,
      @field_del,
      @field_from,
      @is_1C,
      @rn,
      @text_sql
  END

  CLOSE crs
  DEALLOCATE crs

  DROP TABLE #table_clear
END
GO