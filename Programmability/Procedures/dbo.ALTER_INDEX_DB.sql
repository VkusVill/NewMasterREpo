SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:  	OD
-- Последняя правка: Васильев М. 16.05.2018
-- Create date: 2018-05-04
-- Description:	Переиндексация таблиц БД
-- =============================================
CREATE PROCEDURE [dbo].[ALTER_INDEX_DB] 
  @db_name  varchar(100), 
  @table    varchar(1500) = '', --список таблиц,которые нужно обрабатывать, через зяпятую
  @table_ex varchar(500) = '' --таблицы исключения
AS
BEGIN  
  SET NOCOUNT ON

  DECLARE @sql          nvarchar(4000),
          @table_name varchar(500),
          @id_job     int = 1000,
          @job_name   varchar(500) = com.dbo.object_name_for_err(@@PROCID,DB_ID()),
          @getdate    datetime = GETDATE(),
          @n          tinyint

  SET @table = ISNULL(@table, '')

  IF @table <> ''
    SET @table = ',' + @table + ','

  SET @table_ex = ISNULL(@table_ex, '')

  IF @table_ex <> ''
    SET @table_ex = ',' + @table_ex + ','

if object_id('tempdb..#tbl_crs') is not null drop table #tbl_crs
create table #tbl_crs (sql_text          nvarchar(4000),table_name varchar(500))


  BEGIN TRY
    SET @sql = 'use  [' + @db_name + '] ; 


        SELECT DISTINCT 		
				''ALTER INDEX  ['' + rtrim(b.name)  +''] on ['' + rtrim(c.name)   + ''] '' + 
				CASE WHEN CONVERT(int, avg_fragmentation_in_percent) < 40 
				THEN ''REORGANIZE'' ELSE ''REBUILD'' END + '' ; '' sql_text, '','' + rtrim(c.name) + '','' table_name
				--select b.*
				FROM sys.dm_db_index_physical_stats (DB_ID(''' + @db_name + '''), NULL, NULL, NULL, NULL) AS a
				INNER JOIN sys.indexes AS b 
          ON  a.object_id = b.object_id 
            AND 
              a.index_id = b.index_id
			  INNER JOIN sys.objects c 
          ON b.object_id = c.object_id
				WHERE avg_fragmentation_in_percent >= 10 
            AND 
              b.index_id > 0'		

    insert into #tbl_crs (sql_text ,table_name )
    EXEC sp_executesql @sql

	DECLARE crs_db CURSOR FOR		
		SELECT 	sql_text, table_name from #tbl_crs
    OPEN crs_db

    FETCH crs_db INTO @sql, @table_name

    WHILE @@FETCH_STATUS = 0
    BEGIN
      IF  (   CHARINDEX(@table_name, @table, 1) = 1
            OR 
              @table = ''
          )
        AND 
          (CHARINDEX(@table_name, @table_ex, 1) = 0)
      BEGIN
        SET @n = 0

        WHILE @n < 5
        BEGIN
          SET @sql = 'use  [' + @db_name + '] ; ' + @sql

          BEGIN TRY
            EXEC sp_executesql @sql
            BREAK
          END TRY
          BEGIN CATCH
            IF ERROR_NUMBER() = 1205 -- Взаимоблокировка
            BEGIN
              SET @n = @n + 1              
            END
            ELSE
            BEGIN
              INSERT INTO jobs..error_jobs (id_job, job_name, message, number_step, date_add)
              SELECT 
                @id_job, 
                @job_name, 
                @table_name + ' ' + CAST(ERROR_NUMBER() AS varchar(20)) + ' ' + ERROR_MESSAGE(), 
                10, 
                GETDATE()

              BREAK
            END
          END CATCH
        END -- WHILE внутренний
      --select @sql
      END

      FETCH NEXT FROM crs_db INTO @sql, @table_name
    END -- WHILE курсора

    CLOSE crs_db
    DEALLOCATE crs_db

    DROP TABLE #tbl_crs
    
    INSERT INTO jobs..Jobs_log (id_job, number_step, duration, par3, par4)
    SELECT @id_job, 10, DATEDIFF(SECOND, @getdate, GETDATE()), @db_name, @table

    SET @sql = 'use [' + @db_Name + ']

		 DECLARE  @id int, 
              @sqlize int
		 SELECT @id = file_id, @sqlize = size--,*
		 FROM sys.database_files where type=1
		 
		 DBCC SHRINKFILE (@id, 0, TRUNCATEONLY) '

    EXEC sp_executesql @sql

  END TRY
  BEGIN CATCH
    INSERT INTO jobs..error_jobs (id_job, job_name, message, number_step, date_add)
    SELECT @id_job, @job_name, ERROR_MESSAGE(), 100, GETDATE()
  END CATCH
END
GO