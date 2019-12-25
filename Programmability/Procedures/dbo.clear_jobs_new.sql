SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================

CREATE PROCEDURE [dbo].[clear_jobs_new]
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements.
  SET NOCOUNT ON;

  DECLARE @getdate datetime = GETDATE()
  DECLARE
    @name        AS char(100),
    @working_job AS int,
    @id_job      int
  DECLARE @datenow AS datetime = GETDATE()
  DECLARE
    @prefix_job AS int,
    @Name_r_z   AS varchar(200)
  DECLARE
    @ParmDefinition      nvarchar(500), -- передача параметра в sp_executesql
    @last_run_outcome    AS int,
    @s                   AS nvarchar(MAX),
    @stop_execution_date AS datetime,
    @execution_status    int

  INSERT INTO jobs..Jobs_log (
    [id_job],
    [number_step],
    [duration]
  )
  SELECT
    -2,
    1,
    DATEDIFF(MILLISECOND, @getdate, GETDATE())

  SELECT
    @getdate = GETDATE()

  /**
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
BEGIN TRANSACTION
update jobs..working_jobs with (TABLOCKX)
set end_date = GETDATE()
--select *
from jobs..working_jobs wj with (TABLOCKX) 
inner join 
(select j.working_job , j.date_exc  ,
ROW_NUMBER() over (partition by j.working_job order by id_job desc ) rn
from jobs..jobs j with (TABLOCKX) ) j on wj.working_job=j.working_job
where j.rn=1 and wj.end_date is null and date_exc is not null
and j.date_exc < DATEADD(minute,-10,getdate()) 
and wj.start_date < DATEADD(minute,-10,getdate()) 
-- не смог запуститься совсем и прошлой более 5 минут с запуска
COMMIT TRANSACTION
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

insert into jobs..Jobs_log ([id_job],[number_step],[duration]) select -2 , 2, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
select @getdate = getdate()
**/
  DECLARE crs CURSOR LOCAL FOR

  -- по заданиям, выполняются по jobs ( нет date_exec)
  SELECT
    id_job,
    'я_job|' + RTRIM(j.working_job),
    j.working_job
  FROM jobs..Jobs j
  WHERE j.working_job IS NOT NULL
        AND j.date_take IS NOT NULL
        AND j.date_exc IS NULL

  OPEN crs

  FETCH crs
  INTO
    @id_job,
    @name,
    @working_job

  WHILE NOT @@fetch_status = -1
  BEGIN   
    SELECT
      @execution_status = 0

    SELECT
      @s = 'SELECT @execution_status = a.current_execution_status
			FROM OPENROWSET(''SQLNCLI'', ''Server=localhost;Trusted_Connection=yes;'', 
			''exec msdb.dbo.sp_help_job @job_name = ''''я_job|' + RTRIM(@working_job)
           + ''''' , @job_aspect = ''''JOB''''
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
			'') a '

    SET @ParmDefinition = N'@execution_status int OUTPUT'

    EXEC sp_executesql
      @s,
      @ParmDefinition,
      @execution_status = @execution_status OUTPUT

    --select @execution_status
    INSERT INTO jobs..Jobs_log (
      [id_job],
      [number_step],
      [duration]
    )
    SELECT
      -2,
      20,
      DATEDIFF(MILLISECOND, @getdate, GETDATE())

    SELECT
      @getdate = GETDATE()

    IF
    (
      SELECT ISNULL(@execution_status, 0)
    ) <> 1 -- значит не выполняется

    --last_run_outcome int
    --Результат последнего выполнения задания:
    --0 = неуспешное выполнение
    --1 = Успешно
    --3 = Отменено
    --5 = Неизвестно

    -- если ошибка, то записать ее в error_job
    -- проставить exec и сделать копию задания
    BEGIN      
      -- значит завершилось ошибкой
      IF @last_run_outcome = 0
      BEGIN
        CREATE TABLE #JobHistory
        (
          [instance_id] int,
          [job_id] uniqueidentifier,
          [job_name] sysname,
          [step_id] int,
          [step_name] sysname,
          [sql_message_id] int,
          [sql_severity] int,
          [message] nvarchar(MAX),
          [run_status] int,   -- YYYYMMDD
          [run_date] int,     -- YYYYMMDD
          [run_time] int,     -- HHMMSS
          [run_duration] int, -- HHMMSS
          [operator_emailed] nvarchar(20),
          [operator_netsent] nvarchar(20),
          [operator_paged] nvarchar(20),
          [retries_attempted] int,
          [server] nvarchar(30)
        )

        INSERT #JobHistory
        EXEC msdb.dbo.sp_help_jobhistory
          @job_name = @name,
          @run_status = 0,
          @oldest_first = 0,
          @mode = 'Full'

        INSERT INTO jobs..Jobs_log (
          [id_job],
          [number_step],
          [duration]
        )
        SELECT
          -2,
          40,
          DATEDIFF(MILLISECOND, @getdate, GETDATE())

        SELECT
          @getdate = GETDATE()

        INSERT INTO jobs..error_jobs (
          job_name,
          message,
          run_date,
          run_time,
          number_step,
          id_job
        )
        SELECT
          job_name,
          message,
          run_date,
          run_time,
          max_step,
          @id_job
        FROM
        (
          SELECT
            job_name,
            message,
            run_date,
            run_time,
            max_step,
            ROW_NUMBER() OVER (ORDER BY run_date DESC, run_time DESC) rn
          FROM #JobHistory r
          LEFT JOIN
          (
            SELECT
              jl.number_step max_step,
              ROW_NUMBER() OVER (ORDER BY jl.date_add DESC) rn
            FROM Jobs_log (NOLOCK) jl
            WHERE jl.id_job = @id_job
                  AND jl.working_job IS NULL
          ) j2
            ON rn = 1
          WHERE CHARINDEX('Шаг завершился с ошибкой', message, 1) > 0
        ) a
        WHERE rn = 1

        INSERT INTO jobs..Jobs_log (
          [id_job],
          [number_step],
          [duration]
        )
        SELECT
          -2,
          50,
          DATEDIFF(MILLISECOND, @getdate, GETDATE())

        SELECT
          @getdate = GETDATE()

        --select @id_job 
        UPDATE
          jobs..Jobs
        SET
          type_exec = 0,
          date_exc = GETDATE()
        WHERE id_job = @id_job       

        -- если ошибка  
        -- 'вызвала взаимоблокировку ресурсов'
        -- 'необходимые ресурсы потоков'
        -- 'изменилось с момента компиляции'
        -- или название одного из столбцов при добавлении 
        --если не более 3 повторений, то запустить еще раз Create_new_field_1C
        IF
        (
          SELECT
            MAX( CASE
                   WHEN CHARINDEX('вызвала взаимоблокировку ресурсов', ERROR_MESSAGE(), 1) > 0
                        OR CHARINDEX('необходимые ресурсы потоков', ERROR_MESSAGE(), 1) > 0
                        OR CHARINDEX('изменилось с момента компиляции', ERROR_MESSAGE(), 1) > 0
                        OR CHARINDEX('ожидает параметр', ERROR_MESSAGE(), 1) > 0
                        OR CHARINDEX('удалось выделить новую страницу', ERROR_MESSAGE(), 1) > 0
                        OR CHARINDEX('Текущая транзакция не может', ERROR_MESSAGE(), 1) > 0 THEN
                     1
                   ELSE
                     0
                 END
               )
          FROM
          (
            SELECT
              message,
              ROW_NUMBER() OVER (ORDER BY run_date DESC, run_time DESC) rn
            FROM #JobHistory r
          ) a
          --left join Reports..Create_new_field_1C (nolock) cn on cn.Type_ins = 'field'
          WHERE a.rn = 1
        ) = 1
          IF
          (
            SELECT
              COUNT(*)
            FROM jobs..Jobs j1
            INNER JOIN jobs..Jobs j2
              ON j1.job_init = j2.job_init
            WHERE j2.id_job = @id_job
          ) <= 2
            -- значит уже было не более 3 запусков неуспеного первоначального (последний считается)
            INSERT INTO jobs..Jobs (
              [job_name],
              [prefix_job],
              [number_1],
              [number_2],
              [number_3],
              job_init
            )
            SELECT
              j.[job_name],
              [prefix_job],
              [number_1],
              [number_2],
              [number_3],
              ISNULL(job_init, id_job)
            FROM jobs..Jobs j
            INNER JOIN jobs..type_jobs tj
              ON j.job_name = tj.job_name
                 AND tj.restart_err = 0
            WHERE id_job = @id_job
        
        INSERT INTO jobs..Jobs_log (
          [id_job],
          [number_step],
          [duration]
        )
        SELECT
          -2,
          70,
          DATEDIFF(MILLISECOND, @getdate, GETDATE())

        SELECT
          @getdate = GETDATE()

        DROP TABLE #JobHistory
      END
      ELSE -- значит просто завершлось и нужно проставить время заверщения задания
        UPDATE
          jobs..Jobs
        SET
          date_exc = ISNULL(@stop_execution_date, GETDATE())
        WHERE id_job = @id_job

      --select @id_job
      INSERT INTO jobs..Jobs_log (
        [id_job],
        [number_step],
        [duration]
      )
      SELECT
        -2,
        80,
        DATEDIFF(MILLISECOND, @getdate, GETDATE())

      SELECT
        @getdate = GETDATE()
    END -- значит еще выполняется
    ELSE -- проверить время выполнения
    BEGIN

      --проверим, если задание send_email_result и выполняется более 30 мин, то остановливаем job И отправляем сообшение.
      IF EXISTS
      (
        SELECT
          *
        FROM jobs..Jobs (NOLOCK) j
        WHERE DATEDIFF(SECOND, j.date_take, GETDATE()) > 900
              AND j.id_job = @id_job
              AND j.job_name = 'reports..send_email_results'
      )
      BEGIN
        SELECT
          @prefix_job = CONVERT(int, prefix_job)
        FROM jobs..Jobs (NOLOCK) j
        WHERE j.id_job = @id_job

        SELECT
          @Name_r_z = RTRIM(Name_r_z)
        FROM Reports..r_zadanie AS r WITH (NOLOCK)
        WHERE N_r_z = @prefix_job

        SELECT
          @s = 'EXEC msdb.dbo.sp_stop_job N''я_job|' + RTRIM(@working_job) + ''''

        --остановить задание
        EXEC sp_executesql @s      
      END

      -- если более чем в 2 раза и у задания стоит тип restart_long_work=1 и не более 3 раз уже перегружался
      --, то прекратить задание 
      IF EXISTS
      (
        SELECT
          *
        FROM jobs..Jobs (NOLOCK) j
        LEFT JOIN jobs..type_jobs (NOLOCK) tj
          ON j.job_name = tj.job_name
        WHERE DATEDIFF(SECOND, j.date_take, GETDATE()) > ISNULL(tj.max_time, 900) * 2
              AND tj.restart_long_work = 1
              AND j.id_job = @id_job
      )
      BEGIN

        -- если было не 3 раза - прекращение
        IF
        (
          SELECT
            COUNT(*)
          FROM jobs..Jobs j1
          INNER JOIN jobs..Jobs j2
            ON j1.job_init = j2.job_init
          WHERE j2.id_job = @id_job
        ) <= 2
        -- значит уже было не более 3 запусков неуспеного первоначального (последний считается)
        BEGIN
          INSERT INTO jobs..Jobs_log (
            [id_job],
            [number_step],
            [duration]
          )
          SELECT
            -2,
            90,
            DATEDIFF(MILLISECOND, @getdate, GETDATE())

          SELECT
            @getdate = GETDATE()

          UPDATE
            jobs..Jobs
          SET
            date_exc = GETDATE(),
            type_exec = 0
          WHERE id_job = @id_job

          INSERT INTO jobs..Jobs_log (
            [id_job],
            [number_step],
            [duration]
          )
          SELECT
            -2,
            100,
            DATEDIFF(MILLISECOND, @getdate, GETDATE())

          SELECT
            @getdate = GETDATE()

          SELECT
            @s = 'EXEC msdb.dbo.sp_stop_job N''я_job|' + RTRIM(@working_job) + ''''

          --остановить задание
          EXEC sp_executesql @s

          INSERT INTO jobs..Jobs (
            [job_name],
            [prefix_job],
            [number_1],
            [number_2],
            [number_3],
            job_init
          )
          SELECT
            j.[job_name],
            [prefix_job],
            [number_1],
            [number_2],
            [number_3],
            @id_job
          FROM jobs..Jobs j
          INNER JOIN jobs..type_jobs tj
            ON j.job_name = tj.job_name
               AND tj.restart_err = 0
          WHERE id_job = @id_job

          INSERT INTO jobs..Jobs_log (
            [id_job],
            [number_step],
            [duration]
          )
          SELECT
            -2,
            110,
            DATEDIFF(MILLISECOND, @getdate, GETDATE())

          SELECT
            @getdate = GETDATE()
        END      
      END

    -- а теперь отправить сообщение о долгом времени выполнения
    -- по заданиям с restart_long_work=1 ждать двухкратного превышения времени
    -- по заданиям с restart_long_work=0 ждать однократного превышения времени   
    END

    FETCH NEXT FROM crs
    INTO
      @id_job,
      @name,
      @working_job
  END

  CLOSE crs
END
GO