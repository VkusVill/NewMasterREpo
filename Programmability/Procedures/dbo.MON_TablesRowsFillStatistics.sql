SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		Васильев Михаил
-- МОНИТОРИНГ Заполнение статистики количества строк в таблицах
-- =============================================
CREATE PROCEDURE [dbo].[MON_TablesRowsFillStatistics]	  
  @id_job int
AS
BEGIN	
  SET NOCOUNT ON
  DECLARE @DBName     varchar(255),
          @TableName  varchar(255),
          @sql        varchar(2000),
          @RowCount   bigint,
          @getdate    datetime = GETDATE()

  
  INSERT INTO jobs.dbo.jobs_log (id_job, number_step, duration)
  SELECT @id_job, 10, DATEDIFF(MILLISECOND, @getdate, GETDATE())

  SET  @getdate = GETDATE()

  -- Заполнение списка таблиц

  TRUNCATE TABLE Jobs.dbo.MON_TablesListTmp

  DECLARE cur_dc CURSOR LOCAL FAST_FORWARD FOR
    SELECT  
      [name]
    FROM master.sys.databases
    ORDER BY name

  OPEN cur_dc
  
  FETCH NEXT FROM cur_dc INTO @DBName

  WHILE @@FETCH_STATUS = 0   
  BEGIN   
    IF @DBName NOT IN (
                        'distribution',
                        'master',
                        'model',
                        'msdb',
                        'tempdb',
                        'IzbenkaFin',
                        'IzbenkaUNF',
                        'Temp_tables'
                      )
    BEGIN
      SET @sql = 'USE [' + @DBName + ']'
                  + ' 
                    INSERT INTO Jobs.dbo.MON_TablesListTmp(
                      DBName,
                      TableName
                    )
                    SELECT '
                  + CHAR(39) + @DBName + CHAR(39) + ',
                     TABLE_SCHEMA + ' + CHAR(39) + '.' + CHAR(39) + ' + TABLE_NAME 
                     FROM INFORMATION_SCHEMA.TABLES
                     WHERE TABLE_TYPE = ''BASE TABLE''
                     ORDER BY TABLE_NAME
                  '
      EXEC(@sql) 

    END
    --PRINT @sql

    FETCH NEXT FROM cur_dc INTO @DBName
  END   

  CLOSE cur_dc
  DEALLOCATE cur_dc

  INSERT INTO jobs.dbo.jobs_log (id_job, number_step, duration)
  SELECT @id_job, 20, DATEDIFF(MILLISECOND, @getdate, GETDATE())

  SET  @getdate = GETDATE()

  -- Очистка данных об удаленных таблицах
  DELETE FROM Jobs.dbo.MON_TablesRowCountsArhiv
  WHERE ISNULL(RowCountCurrentDay, 0) = 0
      AND
        ISNULL(RowCountOldDay1, 0) = 0
      AND
        ISNULL(RowCountOldDay2, 0) = 0
      AND
        ISNULL(RowCountOldDay3, 0) = 0
      AND
        ISNULL(RowCountOldDay4, 0) = 0
      AND
        ISNULL(RowCountOldDay5, 0) = 0
      AND
        ISNULL(RowCountOldDay6, 0) = 0

  -- "Сдвиг" данных на 1 день
  IF NOT EXISTS ( SELECT 1 
                  FROM Jobs.dbo.MON_TablesRowCountsArhiv 
                  WHERE DateLastUpdate = CAST(GETDATE() AS date)
                )
    UPDATE Jobs.dbo.MON_TablesRowCountsArhiv
    SET RowCountOldDay1 = RowCountCurrentDay, 
        RowCountOldDay2 = RowCountOldDay1,
        RowCountOldDay3 = RowCountOldDay2,
        RowCountOldDay4 = RowCountOldDay3,
        RowCountOldDay5 = RowCountOldDay4,
        RowCountOldDay6 = RowCountOldDay5

  INSERT INTO jobs.dbo.jobs_log (id_job, number_step, duration)
  SELECT @id_job, 30, DATEDIFF(MILLISECOND, @getdate, GETDATE())

  SET  @getdate = GETDATE()

  DECLARE cur_dc CURSOR LOCAL FAST_FORWARD FOR
    SELECT 
      DBName, 
      TableName
    FROM Jobs.dbo.MON_TablesListTmp
    ORDER BY DBName, TableName

  OPEN cur_dc
  
  FETCH NEXT FROM cur_dc INTO @DBName, @TableName

  WHILE @@FETCH_STATUS = 0   
  BEGIN   
    IF NOT EXISTS(  SELECT 1 
                    FROM Jobs.dbo.MON_TablesRowCountsArhiv
                    WHERE DBName = @DBName
                        AND
                          TableName = @TableName
                  )
      INSERT INTO Jobs.dbo.MON_TablesRowCountsArhiv(
        DBName,
        TableName
      )
      SELECT
        @DBName, 
        @TableName

    SET @sql = 
      'USE [' + @DBName + '] '
      + ' UPDATE Jobs.dbo.MON_TablesRowCountsArhiv '
      + ' SET RowCountCurrentDay = (  
                                    SELECT SUM (row_count)
                                    FROM sys.dm_db_partition_stats
                                    WHERE object_id=OBJECT_ID(' + CHAR(39) + @TableName + CHAR(39) + ')
                                    AND
                                      (index_id=0 OR index_id=1)
                                  ),
          DateLastUpdate = GETDATE()     
          WHERE DBName = ' + CHAR(39) + @DBName + CHAR(39)
      +     ' AND 
                TableName = ' + CHAR(39) + @TableName + CHAR(39)

    EXEC(@sql)

    FETCH NEXT FROM cur_dc INTO @DBName, @TableName
  END   

  CLOSE cur_dc
  DEALLOCATE cur_dc

  INSERT INTO jobs.dbo.jobs_log (id_job, number_step, duration)
  SELECT @id_job, 40, DATEDIFF(MILLISECOND, @getdate, GETDATE())

  -- Очистка таблиц удаленных
  DELETE FROM Jobs.dbo.MON_TablesRowCountsArhiv
  WHERE DateLastUpdate < DATEADD(day, -7, GETDATE()) -- Если данные не обновлялись более 7 дней, считаем таблицу из БД удаленной
END
GO