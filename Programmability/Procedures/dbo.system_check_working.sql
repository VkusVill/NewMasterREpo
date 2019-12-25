SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:  	<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[system_check_working]
AS
BEGIN  
  SET NOCOUNT ON
  SET ANSI_WARNINGS ON
  SET ANSI_NULLS ON

  BEGIN TRY
    DECLARE @s          nvarchar(max),
            @session_id int,
            @nvaMsg     nvarchar(200),
            @threads    int,
            @id_job     int = 33333,
            @getdate    datetime = GETDATE()

    INSERT INTO jobs..Jobs_log ([id_job], [number_step], [duration])
    SELECT @id_job, 10, DATEDIFF(MILLISECOND, @getdate, GETDATE())

    SET @getdate = GETDATE()

    SELECT
      @threads = AVG(par1)
    FROM jobs..Jobs_log(nolock)
    WHERE (
            (   
                number_step = 1
              AND 
                id_job > 0
            )
          OR 
            (   
                number_step = 4
              AND id_job = -1
             )
          )
        AND 
          date_add > DATEADD(MINUTE, -1, GETDATE())

    -- если загрузка более 90%, то не выполнять jobs
    IF @threads > 90
    BEGIN
      EXEC jobs.dbo.save_WhoIsActive

      SET @nvaMsg = 'Загрузка Сервера [srv-sql03] за последнюю минуту ' + RTRIM(@threads) + '%'

      --Отправка сообщений списку контактов

      SET @s = 'EXEC (''
				exec jobs..Send_notification_SMS_M1 ''''' + @nvaMsg + ''''', ''''system_check_working''''
				'') at [srv-sql01]'

      EXEC sp_executeSql @s
    END

    INSERT INTO jobs..Jobs_log ([id_job], [number_step], [duration])
    SELECT @id_job, 20, DATEDIFF(MILLISECOND, @getdate, GETDATE())

    SET @getdate = GETDATE()

    TRUNCATE TABLE jobs.dbo.whoisactive_1

    TRUNCATE TABLE jobs.dbo.whoisactive_2

    EXEC [master].dbo.sp_WhoIsActive @DESTINATION_TABLE = 'jobs.dbo.whoisactive_2',
                                     @output_column_list = '[dd hh:mm:ss.mss],[session_id],[start_time]'

    EXEC [master].dbo.sp_WhoIsActive @format_output = 0,
                                     @DESTINATION_TABLE = 'jobs.dbo.whoisactive_1';

    INSERT INTO jobs..Jobs_log ([id_job], [number_step], [duration])
    SELECT @id_job, 30, DATEDIFF(MILLISECOND, @getdate, GETDATE())

    SET @getdate = GETDATE()

    SELECT TOP 1
      CONVERT(nvarchar(128), 'Kill [srv-sql03]' + RTRIM(w.session_id) + ' ' + RTRIM(w.program_name)) job_name,
      w.sql_text sql_text,
      w.session_id 
    INTO #idjob
    FROM [jobs].[dbo].[WhoIsActive] AS w
    INNER JOIN [jobs].[dbo].[WhoIsActive] AS w2
      ON  w.session_id = w2.blocking_session_id
        AND 
          w.collection_time = w2.collection_time
    WHERE w.collection_time > { D '2016-07-01' }
        AND 
          --CONVERT(int, SUBSTRING(w2.[dd hh:mm:ss.mss], 7, 2) + 60 * SUBSTRING(w2.[dd hh:mm:ss.mss], 4, 2)) >= 5
                    CONVERT(int, SUBSTRING(w2.[dd hh:mm:ss.mss], CHARINDEX(':',w2.[dd hh:mm:ss.mss],1)+1, 2) 
                    +60*substring(w2.[dd hh:mm:ss.mss], CHARINDEX(':',w2.[dd hh:mm:ss.mss],1)-2, 2))  >= 5

        AND 
          w.blocking_session_id IS NULL
        AND 
          CASE
            WHEN CHARINDEX('insert ', CONVERT(nvarchar(max), w.sql_text), 1) > 0 AND
              CHARINDEX('select *', CONVERT(nvarchar(max), w.sql_text), 1) > 0 THEN 1
            ELSE 0
          END = 0

    IF EXISTS (SELECT * FROM #idjob)
    BEGIN -- значит есть зависшие сессии
      EXEC jobs.dbo.save_WhoIsActive

      SELECT
        @session_id = session_id
      FROM #idjob

      SET @s = 'kill ' + RTRIM(@session_id)

      EXEC sp_executesql @S

      INSERT INTO jobs..error_jobs (job_name, message)
      SELECT
        job_name,
        sql_text
      FROM #idjob

      SELECT
        @nvaMsg = CONVERT(nvarchar(128), 'kill [srv-sql03]' + RTRIM(sql_text))
      FROM #idjob

      --Отправка сообщений списку контактов

      SET @s = 'EXEC (''
				exec jobs..Send_notification_SMS_M1 ''''' + @nvaMsg + ''''', ''''system_check_working''''
				'') at [srv-sql01]'

      EXEC sp_executeSql @s
    END

    TRUNCATE TABLE #idjob

    INSERT INTO jobs..Jobs_log ([id_job], [number_step], [duration])
    SELECT @id_job, 40, DATEDIFF(MILLISECOND, @getdate, GETDATE())

    SET @getdate = GETDATE()    

    INSERT INTO #idjob
    SELECT
      CONVERT(nvarchar(128), 'Стух Индекс [srv-sql03]' + MAX(w.program_name)),
      MAX(CONVERT(nvarchar(max), w.sql_text)),
      0
    FROM [jobs].[dbo].[WhoIsActive] AS w
    WHERE --CONVERT(int, SUBSTRING(w.[dd hh:mm:ss.mss], 10, 2)) 
    convert(int,substring(w.[dd hh:mm:ss.mss], CHARINDEX('.',w.[dd hh:mm:ss.mss],1)-2, 2))> 10
        AND 
          w.blocking_session_id IS NULL
        AND 
          CONVERT(nvarchar(max), w.sql_text) <> ''
        AND 
          CHARINDEX('frontol.fmt', CONVERT(nvarchar(max), w.sql_text), 1) = 0
    GROUP BY LEFT(jobs.dbo.without_digit(CONVERT(nvarchar(max), w.sql_text)), 60)
    HAVING COUNT(*) > 20

    IF EXISTS (SELECT * FROM #idjob)
    BEGIN -- значит есть стухшие индексы
      EXEC jobs.dbo.save_WhoIsActive

      INSERT INTO jobs..error_jobs (job_name, message)
      SELECT
        job_name,
        sql_text
      FROM #idjob

      SELECT
        @nvaMsg = CONVERT(nvarchar(128), 'Стух Индекс [srv-sql03] ' + RTRIM(MAX(sql_text)))
      FROM #idjob

      --Отправка сообщений списку контактов

      SET @s = 'EXEC (''
				exec jobs..Send_notification_SMS_M1 ''''' + @nvaMsg + ''''', ''''system_check_working''''
				'') at [srv-sql01]'

      EXEC sp_executeSql @s
    END

    INSERT INTO jobs..Jobs_log ([id_job], [number_step], [duration])
    SELECT @id_job, 50, DATEDIFF(MILLISECOND, @getdate, GETDATE())

    SET @getdate = GETDATE()

    TRUNCATE TABLE #idjob

    INSERT INTO #idjob
    SELECT TOP 1
      CONVERT(nvarchar(128), 'СлонЗапрос [srv-sql03]' + (w.program_name)),
      (CONVERT(nvarchar(max), w.sql_text)),
      w.session_id
    FROM [jobs].[dbo].[WhoIsActive] AS w
    WHERE program_name IN ('1CV82 Server', '1C:Enterprise 8.2')
        AND 
         -- CONVERT(int, SUBSTRING(w.[dd hh:mm:ss.mss], 7, 2) + 60 * SUBSTRING(w.[dd hh:mm:ss.mss], 4, 2))
         CONVERT(int, SUBSTRING(w.[dd hh:mm:ss.mss], CHARINDEX(':',w.[dd hh:mm:ss.mss],1)+1, 2) 
		+60*substring(w.[dd hh:mm:ss.mss], CHARINDEX(':',w.[dd hh:mm:ss.mss],1)-2, 2))  >= 5
        AND 
          blocking_session_id IS NULL
        AND 
          LEN(RTRIM(w.sql_text)) > 5000

    IF EXISTS (SELECT * FROM #idjob)
    BEGIN -- значит есть стухшие индексы
      EXEC jobs.dbo.save_WhoIsActive

      SELECT
        @session_id = session_id
      FROM #idjob

      SET @s = 'kill ' + RTRIM(@session_id)

      EXEC sp_executesql @S

      INSERT INTO jobs..error_jobs (job_name, message)
      SELECT
        job_name,
        sql_text
      FROM #idjob

      SELECT
        @nvaMsg = CONVERT(nvarchar(128), 'СлонЗапрос [srv-sql03]' + RTRIM(MAX(sql_text)))
      FROM #idjob

      --Отправка сообщений списку контактов

      SET @s = 'EXEC (''
				exec jobs..Send_notification_SMS_M1 ''''' + @nvaMsg + ''''', ''''system_check_working''''
				'') at [srv-sql01]'

      EXEC sp_executeSql @s
    END

    INSERT INTO jobs..Jobs_log ([id_job], [number_step], [duration])
    SELECT @id_job, 60, DATEDIFF(MILLISECOND, @getdate, GETDATE())

    SET @getdate = GETDATE()

    DROP TABLE #idjob

    IF DATEPART(HOUR, GETDATE()) BETWEEN 8 AND 22
    BEGIN
      DECLARE @dur int = 0

      IF OBJECT_ID('tempdb..#mess') IS NOT NULL
        DROP TABLE #mess

      SELECT
        'Job [srv-sql03]' + RTRIM(t1.job_name) + ' вып уже ' + RTRIM(t1.dtdiff) + 'мин. ' [message],
        GETDATE() adddate,
        'Избенка' project,
        777 type_Bv INTO #mess
      FROM (  SELECT
                job_id,
                job_name,
                start_execution_date,
                DATEDIFF(MINUTE, start_execution_date, GETDATE()) AS dtdiff
              FROM OPENROWSET('SQLNCLI', 'Server=localhost;Trusted_Connection=yes;', 'exec msdb.dbo.sp_help_jobactivity
								           WITH RESULT SETS
					        ( 
					         (
					         session_id int,
 					        job_id						UNIQUEIDENTIFIER, 
 					        job_name					varchar(max),
 					        run_requested_date			datetime,
 					        run_requested_source		int,
 					        queued_date					datetime,
 					        start_execution_date		datetime,
 					        start_executed_step_id		int,
 					        last_executed_step_date		datetime,
 					        stop_execution_date         datetime,       
					        next_scheduled_run_date		datetime,
					        job_history_id				bigint,            
					        message						varchar(max),
					        run_status					int,
					        operator_id_emailed			int,
					        operator_id_netsent			int,
					        operator_id_paged			int	
        					 
					         )) ') AS derivedtbl_1
            ) AS t1
      INNER JOIN (  SELECT
                      job_id,
                      name,
                      originating_server
                    FROM OPENROWSET('SQLNCLI', 'Server=localhost;Trusted_Connection=yes;', 'exec msdb.dbo.sp_help_job @execution_status =0
										              WITH RESULT SETS
					              ( 
					               (
						              job_id						UNIQUEIDENTIFIER, 
						              originating_server			NVARCHAR(30), 
						              name						SYSNAME, 
						              [enabled]					TINYINT, 
						              [description]				NVARCHAR(512), 
						              start_step_id				INT, 
						              category					SYSNAME, 
						              [owner]						SYSNAME, 
						              notify_level_eventlog		INT, 
						              notify_level_email			INT, 
						              notify_level_netsend		INT, 
						              notify_level_page			INT, 
						              notify_email_operator		SYSNAME, 
						              notify_netsend_operator		SYSNAME, 
						              notify_page_operator		SYSNAME, 
						              delete_level				INT, 
						              date_created				DATETIME, 
						              date_modified				DATETIME, 
						              version_number				INT, 
						              last_run_date				INT, 
						              last_run_time				INT, 
						              last_run_outcome			INT, 
						              next_run_date				INT, 
						              next_run_time				INT, 
						              next_run_schedule_id		INT, 
						              current_execution_status	INT, 
						              current_execution_step		SYSNAME, 
						              current_retry_attempt		INT, 
						              has_step					INT, 
						              has_schedule				INT, 
						              has_target					INT, 
						              [type]						INT 
					               )	)		
					              ') AS derivedtbl_2
                  ) AS t2
        ON t1.job_id = t2.job_id
      WHERE (NOT (t1.job_name LIKE 'SRV-SQL03%'))
          AND 
            (t1.dtdiff > 30)
          AND 
            LEFT(t1.job_name, 2) <> 'я_'

      INSERT INTO jobs..Jobs_log ([id_job], [number_step], [duration])
      SELECT @id_job, 70, DATEDIFF(MILLISECOND, @getdate, GETDATE())

      SET @getdate = GETDATE()

      DECLARE @temp_table nchar(36)

      SET @temp_table = REPLACE(NEWID(), '-', '_')

      SET @s = 'select *   into Temp_tables..[' + @temp_table + '] ' + 'from #mess'

      EXEC sp_executeSQL @s

      SET @s = 'EXEC (''
				insert into IES..Outgoing ( Number,[Message],Project,type_BV )
				SELECT  b.Number,a.[Message],a.Project,a.type_BV  from [srv-sql03].Temp_tables.dbo.[' + @temp_table + '] as a
					inner join (SELECT ''''7''''+Phone_number number
				from jobs..Notification_Contact as nc with(nolock)
				where Type_Contact=''''system_check_working'''')b on (1=1)
				'') at [srv-sql01]'

      EXEC sp_executeSql @s

      SET @s = 'drop table Temp_tables..[' + @temp_table + '] '

      EXEC sp_executeSQL @s

      DROP TABLE #mess

      INSERT INTO jobs..Jobs_log ([id_job], [number_step], [duration])
      SELECT @id_job, 80, DATEDIFF(MILLISECOND, @getdate, GETDATE())

      SET @getdate = GETDATE()

      SELECT
        @dur = dtdiff
      FROM (  SELECT
                job_id,
                job_name,
                start_execution_date,
                DATEDIFF(MINUTE, start_execution_date, GETDATE()) AS dtdiff
              FROM OPENROWSET('SQLNCLI', 'Server=localhost;Trusted_Connection=yes;', 'exec msdb.dbo.sp_help_jobactivity @job_name = ''jobs_system_work'' 
									        WITH RESULT SETS
					        ( 
					         (
					         session_id int,
 					        job_id						UNIQUEIDENTIFIER, 
 					        job_name					varchar(max),
 					        run_requested_date			datetime,
 					        run_requested_source		int,
 					        queued_date					datetime,
 					        start_execution_date		datetime,
 					        start_executed_step_id		int,
 					        last_executed_step_date		datetime,
 					        stop_execution_date         datetime,       
					        next_scheduled_run_date		datetime,
					        job_history_id				bigint,            
					        message						varchar(max),
					        run_status					int,
					        operator_id_emailed			int,
					        operator_id_netsent			int,
					        operator_id_paged			int	
        					 
					         )) ') AS derivedtbl_1
            ) AS t1
      INNER JOIN (SELECT
        job_id,
        name,
        originating_server
      FROM OPENROWSET('SQLNCLI', 'Server=localhost;Trusted_Connection=yes;', 'exec msdb.dbo.sp_help_job @job_name = ''jobs_system_work'' , @execution_status =0
										WITH RESULT SETS
					( 
					 (
						job_id						UNIQUEIDENTIFIER, 
						originating_server			NVARCHAR(30), 
						name						SYSNAME, 
						[enabled]					TINYINT, 
						[description]				NVARCHAR(512), 
						start_step_id				INT, 
						category					SYSNAME, 
						[owner]						SYSNAME, 
						notify_level_eventlog		INT, 
						notify_level_email			INT, 
						notify_level_netsend		INT, 
						notify_level_page			INT, 
						notify_email_operator		SYSNAME, 
						notify_netsend_operator		SYSNAME, 
						notify_page_operator		SYSNAME, 
						delete_level				INT, 
						date_created				DATETIME, 
						date_modified				DATETIME, 
						version_number				INT, 
						last_run_date				INT, 
						last_run_time				INT, 
						last_run_outcome			INT, 
						next_run_date				INT, 
						next_run_time				INT, 
						next_run_schedule_id		INT, 
						current_execution_status	INT, 
						current_execution_step		SYSNAME, 
						current_retry_attempt		INT, 
						has_step					INT, 
						has_schedule				INT, 
						has_target					INT, 
						[type]						INT 
					 )	)') AS derivedtbl_2) AS t2
        ON t1.job_id = t2.job_id

      IF NOT EXISTS ( SELECT
                        *
                      FROM [jobs].[dbo].[Jobs_log] j (NOLOCK)
                      WHERE id_job = -1
                      AND j.date_add > DATEADD(MINUTE, -1, GETDATE())
                    )
        IF (  SELECT
                b.number_step
              FROM (  SELECT
                        j.number_step,
                        ROW_NUMBER() OVER (ORDER BY j.date_add DESC) rn
                      FROM [jobs].[dbo].[Jobs_log] j (NOLOCK)
                      WHERE id_job = 0
                    ) AS b
              WHERE b.rn = 1
            ) <> 79

          IF @dur > 10
          BEGIN
            SET @nvaMsg = 'jobs_system_work [srv-sql03] вып уже ' + RTRIM(@dur) + 'мин. и перезапущен'

            SET @s = 'EXEC (''
				              insert into IES..Outgoing( Number,[Message],Project,type_BV )
				              SELECT ''''7''''+Phone_number ,''''' + @nvaMsg + ''''', ''''Избенка'''',777
				              from jobs..Notification_Contact as nc with(nolock)
				              where Type_Contact=''''system_check_working''''
				              '') at [srv-sql01]'

            EXEC sp_executeSql @s

            SET @nvaMsg = 'jobs_system_work [srv-sql03] перезапущен'

            --Отправка сообщений списку контактов

            SET @s = 'EXEC (''
				              exec jobs..Send_notification_SMS_M1 ''''' + @nvaMsg + ''''', ''''system_check_working''''
				              '') at [srv-sql01]'

            EXEC sp_executeSql @s

            EXEC msdb.dbo.sp_stop_job N'jobs_system_work'

            EXEC jobs.dbo.save_WhoIsActive
          END

      INSERT INTO jobs..Jobs_log ([id_job], [number_step], [duration])
      SELECT @id_job, 90, DATEDIFF(MILLISECOND, @getdate, GETDATE())

      SET @getdate = GETDATE()

      SET @dur = 0

      SELECT
        @dur = AVG(a.duration)
      FROM (  SELECT
                [duration],
                ROW_NUMBER() OVER (ORDER BY date_add DESC) rn
              FROM [jobs].[dbo].[Jobs_log](nolock) jl
              WHERE ((id_job = -1
                  AND number_step = 2)
              OR (working_job IS NOT NULL
              AND number_step = 1))
              AND jl.date_add > DATEADD(MINUTE, -15, GETDATE())
            ) a
      WHERE a.rn <= 1000

      INSERT INTO jobs..Jobs_log ([id_job], [number_step], [duration])
      SELECT @id_job, 100, DATEDIFF(MILLISECOND, @getdate, GETDATE())

      SET @getdate = GETDATE()

      IF @dur > 1000
      BEGIN
        SET @nvaMsg = 'jobs [srv-sql03] очень медленно работает, скорость милисек : ' + RTRIM(@dur)

        --Отправка сообщений списку контактов

        SET @s = 'EXEC (''
				          exec jobs..Send_notification_SMS_M1 ''''' + @nvaMsg + ''''', ''''system_check_working''''
				          '') at [srv-sql01]'

        EXEC sp_executeSql @s

        EXEC jobs.dbo.save_WhoIsActive

        SET @s = 'EXEC (''
				  insert into [IES].[dbo].[Outgoing]
				  ( Number,[Message],AddDate,Project,type_BV )
				  SELECT ''''7''''+Phone_number,''''' + @nvaMsg + ''''' 
						  ,GETDATE() , ''''Избенка'''' , 777
				  from jobs..Notification_Contact as nc with(nolock)
				  where Type_Contact=''''system_check_working''''

				  '') at [srv-sql01]'

        EXEC sp_executeSql @s

        DBCC DBREINDEX ('jobs')
      END
      ELSE
      -- значит уже более 300 сек нет ни одной поставленной задачи
      IF EXISTS ( SELECT
                    MAX(j.id_job),
                    MAX(j.date_add)
                  FROM [jobs].[dbo].[Jobs] j
                  LEFT JOIN ( SELECT
                                j.job_name,
                                j.prefix_job,
                                j.id_job
                              FROM [jobs].[dbo].[Jobs] j
                              WHERE j.date_exc IS NULL
                                  AND 
                                    j.date_take IS NOT NULL
                            ) AS j1
                    ON  j.job_name = j1.job_name
                      AND 
                        j.prefix_job = j1.prefix_job
                      AND 
                        j.id_job <> j1.id_job
                  WHERE j1.job_name IS NULL
                  HAVING MAX(j.date_add) < DATEADD(SECOND, -600, GETDATE()))
      BEGIN
        EXEC jobs.dbo.save_WhoIsActive

        SET @nvaMsg = 'jobs [srv-sql03] встал'

        --Отправка сообщений списку контактов

        SET @s = 'EXEC (''
				          exec jobs..Send_notification_SMS_M1 ''''' + @nvaMsg + ''''', ''''system_check_working''''
				          '') at [srv-sql01]'

        EXEC sp_executeSql @s

        SET @s = 'EXEC (''
				  insert into [IES].[dbo].[Outgoing]
				  ( Number,[Message],AddDate,Project,type_BV )
				  SELECT ''''7''''+Phone_number,''''' + @nvaMsg + ''''' 
						  ,GETDATE() , ''''Избенка'''' , 777
				  from jobs..Notification_Contact as nc with(nolock)
				  where Type_Contact=''''system_check_working''''				
						
				'') at [srv-sql01]'

        EXEC sp_executeSql @s

        DBCC DBREINDEX ('jobs')
      END

      INSERT INTO jobs..Jobs_log ([id_job], [number_step], [duration])
      SELECT @id_job, 110, DATEDIFF(MILLISECOND, @getdate, GETDATE())

      SET @getdate = GETDATE()

      -- найти задания, которые уже 10 минут не могут обработаться

      DECLARE @count int = 0

      SELECT
        @count = COUNT(*)
      FROM [jobs].[dbo].[Jobs] j
      LEFT JOIN -- чтобы не было запущено заданий с таким же prifix
                ( SELECT
                    job_name,
                    prefix_job
                  FROM jobs..Jobs
                  WHERE date_take IS NOT NULL
                  AND date_exc IS NULL
                ) AS j_pr
        ON  j.job_name = j_pr.job_name
          AND 
            j.prefix_job = j_pr.prefix_job
      WHERE date_add < DATEADD(MINUTE, -10, GETDATE())
          AND 
            date_take IS NULL
          AND 
            j_pr.job_name IS NULL
      HAVING COUNT(*) > 0

      INSERT INTO jobs..Jobs_log ([id_job], [number_step], [duration])
      SELECT @id_job, 120, DATEDIFF(MILLISECOND, @getdate, GETDATE())

      SET @getdate = GETDATE()

      IF @count > 0
      BEGIN
        EXEC jobs.dbo.save_WhoIsActive

        SET @nvaMsg = RTRIM(@count) + ' заданий jobs [srv-sql03] не может уже 10 минут выполниться'

        --Отправка сообщений списку контактов

        SET @s = 'EXEC (''
				exec jobs..Send_notification_SMS_M1 ''''' + @nvaMsg + ''''', ''''system_check_working''''
				'') at [srv-sql01]'

        EXEC sp_executeSql @s

        SET @s = 'EXEC (''
				insert into IES..Outgoing( Number,[Message],Project,type_BV )
				SELECT ''''7''''+Phone_number ,''''' + @nvaMsg + ''''', ''''Избенка'''',777
				from jobs..Notification_Contact as nc with(nolock)
				where Type_Contact=''''system_check_working''''

				'') at [srv-sql01]'
        EXEC sp_executeSql @s
      END

      INSERT INTO jobs..Jobs_log ([id_job], [number_step], [duration])
      SELECT @id_job, 130, DATEDIFF(MILLISECOND, @getdate, GETDATE())

      SET @getdate = GETDATE()

      IF EXISTS ( SELECT
                    *
                  FROM [jobs].[dbo].[error_jobs] ej
                  WHERE CHARINDEX('Компонент Database Mail [srv-sql03] остановлен', ej.message, 1) > 0
                      AND 
                        ej.date_add > DATEADD(MINUTE, -5, GETDATE())
                )
      BEGIN
        --Отправка сообщений списку контактов

        SET @s = 'EXEC (''
				  exec jobs..Send_notification_SMS_M1 ''''' + @nvaMsg + ''''', ''''system_check_working''''
				  '') at [srv-sql01]'

        EXEC sp_executeSql @s
      END
    END
  END TRY
  BEGIN CATCH
    INSERT jobs..error_jobs (job_name, id_job, message, number_step)
    SELECT
      'system_check_working',
      1,
      ERROR_MESSAGE(),
      100
  END CATCH
END
GO