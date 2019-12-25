SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[jobs_take_new] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
SET NOCOUNT ON;
SET ANSI_WARNINGS On;

declare @current_execution_status int = 0
declare @threads as int, @threads_2 int , @date_exec datetime, @datediff int

select @threads = master.dbo.minz(100,
case avg (case cntr_type when 1073939712 then cntr_value end ) when 0 then 0 else 
100.0 *  sum (case cntr_type when 537003264 then cntr_value end ) /
avg (case cntr_type when 1073939712 then cntr_value end ) end)
from sys.dm_os_performance_counters (nolock)
where object_name = 'SQLServer:Resource Pool Stats' and cntr_type  in ( 537003264, 1073939712)
and counter_name not in ('Avg Disk Read IO (ms) Base','Avg Disk Write IO (ms) Base')

if @threads <= 80 
begin
	declare @getdate datetime = getdate() , @getdate_init datetime = getdate()
	, @count_take int
	declare @s as nvarchar(max) , @working_job as int =0 , @i as int 
	DECLARE @ParmDefinition nvarchar(500) -- передача параметра в sp_executesql
	, @execution_status as int

	Declare @kolvo int -- колво заданий для выполняния

	Select @kolvo= master.dbo.maxz(isnull(COUNT(*) ,0), 60),
	@i = isnull(COUNT(*),0)
	from jobs..Jobs j (nolock)
	left join jobs..type_jobs tj (nolock) on tj.job_name=j.job_name

	left join -- чтобы не было запущено заданий с таким же prifix
	  (Select job_name , prefix_job
	   from jobs..Jobs  with (nolOCK)
	   where date_take is not null and date_exc is null) j_pr 
	  on j.job_name=j_pr.job_name and j.prefix_job=j_pr.prefix_job

	where date_take is null 
	and date_add <GETDATE() -- будущие задания могут быть в таблице
	and ISNULL( tj.is_active ,1 ) =1

	and j_pr.job_name is null

	if @i = 0
	return

	--declare @delay as char(12) 

	create table #working_job
	(working_job int , date_add datetime)

	--Select @delay  = '00:00:0' + rtrim( master.dbo.maxz(floor(100.0 * 5 / @i  ) /100  - 0.1, 0.1))

	while @kolvo>=60
	begin

	set @count_take = 0

	-- посчитать, сколько заданий нужно запускать
	Select @i = ceiling(master.dbo.minz(1.0 * COUNT(*) / 2,60))
	from jobs..Jobs j (nolock)
	left join jobs..type_jobs tj (nolock) on tj.job_name=j.job_name

	left join -- чтобы не было запущено заданий с таким же prifix
	  (Select job_name , prefix_job
	   from jobs..Jobs  with (nolOCK)
	   where date_take is not null and date_exc is null) j_pr 
	  on j.job_name=j_pr.job_name and j.prefix_job=j_pr.prefix_job

	where date_take is null 
	and date_add <GETDATE() -- будущие задания могут быть в таблице
	and ISNULL( tj.is_active ,1 ) =1
	and j_pr.job_name is null





	insert into jobs..Jobs_log ([id_job],[number_step],[duration] , par1) 
	select -1 , 0, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) , @kolvo
	select @getdate = getdate()

	if (select @i) >0  
	begin


	while  (select @i) >0 
	begin



		-- найти самое раннее завершенное  задание
		select @working_job=0 , @date_exec = null
		select @working_job = isnull(f.rn,0) , @date_exec = date_exec
		from
		(
		select b.rn , j.date_exc date_exec ,--isnull(j.date_exc,{d'2014-01-01'}) , 
		ROW_NUMBER () over (order by isnull(j.date_exc,{d'2014-01-01'}) ) rn2 
		from 
		(select top 60  row_number() over (order by id_job) rn
		from jobs..jobs  with (TABLOCKX) ) b

		left join
		( select j.working_job , max( j.date_exc) date_exc  
		 from jobs..jobs j with (TABLOCKX)  
		 where j.date_exc is not null
		 group by j.working_job
		) j
		 on j.working_job=b.rn

		left join

		(select j.working_job
		from jobs..jobs j with (TABLOCKX)  
		where j.date_take is not null and j.date_exc is null
		)c on c.working_job = b.rn

		left join #working_job wj on b.rn= wj.working_job


		where c.working_job is null and wj.working_job is  null 
		) f
		where f.rn2=1 and date_exec < DATEADD(millisecond,-500,getdate())






		if (select @working_job) > 0 -- значит нашли задание
		begin


			if @date_exec > DATEADD(second,-2,getdate())
			begin

				set @datediff = DATEDIFF(millisecond,@date_exec,getdate())
				SET @ParmDefinition = N'@current_execution_status_out int  OUTPUT'
				Set @s = '
				SELECT @current_execution_status_out= convert(int,current_execution_status)
				FROM OPENROWSET(''SQLNCLI'', ''Server=localhost;Trusted_Connection=yes;'', 
				''EXEC MSDB.dbo.sp_help_job @job_name = ''''я_job|'  + RTRIM(@working_job) + ''''', @job_aspect = ''''JOB'''' 
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
							 )
							)

				'')   '

				EXEC sp_executesql @S  , @ParmDefinition , @current_execution_status_out = @current_execution_status OUTPUT 

				insert into jobs..Jobs_log ([id_job],[number_step],[duration],par1 , par2 , par3) 
				select -1 , 31, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) , @working_job , @current_execution_status  , @datediff
				select @getdate = getdate()

			end
			else set @current_execution_status  = 4

			--print @S
			--print @current_execution_status

			if @current_execution_status  = 4
			begin
				-- запуск заданий

				select @threads = master.dbo.minz(100,
				case avg (case cntr_type when 1073939712 then cntr_value end ) when 0 then 0 else 
				100.0 *  sum (case cntr_type when 537003264 then cntr_value end ) /
				avg (case cntr_type when 1073939712 then cntr_value end ) end)
				from sys.dm_os_performance_counters (nolock)
				where object_name = 'SQLServer:Resource Pool Stats' and cntr_type  in ( 537003264, 1073939712)
				and counter_name not in ('Avg Disk Read IO (ms) Base','Avg Disk Write IO (ms) Base')

				if @threads <= 80 
				begin

					insert into #working_job 
					select  @working_job , GETDATE()

					Select @S = ' EXEC msdb.dbo.sp_start_job N''я_job|'  + RTRIM(@working_job) + ''''
					--запустить задание
					EXEC sp_executesql @S
					--print @S

					insert into jobs..Jobs_log ([id_job],[number_step],[duration],par1 , par2) 
					select -1 , 2, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) , @working_job , @count_take
					select @getdate = getdate()

				end

			end
			 set @current_execution_status = 0
			select  @count_take =  @count_take + 1

			/**
			if not exists 
			(select *
			from jobs..Jobs_log (nolock) 
			where id_job = -1 and number_step =4 and date_add > DATEADD(minute,-1,getdate()) and par2 is not null)

			select @threads_2 = count(*)
			from sys.dm_os_threads (nolock)


			insert into jobs..Jobs_log ([id_job],[number_step],[duration],par2 , par1  ) 
			select -1 , 4, DATEDIFF(MILLISECOND , @getdate ,GETDATE()),@threads_2  , @threads 
			select @getdate = getdate()

			**/
			--WAITFOR DELAY @delay
			select @getdate = getdate() 

		end



		select @i=@i -1

	end



	end

	if  @count_take > 5 --@getdate_init > DATEADD(minute,-2,getdate())
	begin
		Select @kolvo= COUNT(*)
		from jobs..Jobs j
		left join jobs..type_jobs tj on tj.job_name=j.job_name

		left join -- чтобы не было запущено заданий с таким же prifix
		  (Select job_name , prefix_job
		   from jobs..Jobs  with (nolOCK)
		   where date_take is not null and date_exc is null) j_pr 
		  on j.job_name=j_pr.job_name and j.prefix_job=j_pr.prefix_job

		where date_take is null 
		and date_add <GETDATE() -- будущие задания могут быть в таблице
		and ISNULL( tj.is_active ,1 ) =1
		and j_pr.job_name is null


		if @kolvo>=60
		begin
			--WAITFOR DELAY '00:00:01'
			--select @getdate = getdate()
			delete from #working_job
			where date_add < DATEADD(second,-2,getdate())

			Select @kolvo= COUNT(*)
			from jobs..Jobs j
			left join jobs..type_jobs tj on tj.job_name=j.job_name

			left join -- чтобы не было запущено заданий с таким же prifix
			  (Select job_name , prefix_job
			   from jobs..Jobs  with (nolOCK)
			   where date_take is not null and date_exc is null) j_pr 
			  on j.job_name=j_pr.job_name and j.prefix_job=j_pr.prefix_job

			where date_take is null 
			and date_add <GETDATE() -- будущие задания могут быть в таблице
			and ISNULL( tj.is_active ,1 ) =1
			and j_pr.job_name is null


		end
	end
	else
		select @kolvo = 1


	end

	drop table #working_job
end
END
GO