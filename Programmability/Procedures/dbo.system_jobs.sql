SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[system_jobs]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	SET ANSI_WARNINGS On;
	SET NOCOUNT ON;



--<< Временное, для выявления проблем в работе мп.
-- Vl@d 24/12/2019

DECLARE 
	@d datetime = GetDate();
	--select @d = '20190123 22:04:10 '
IF EXISTS(select datepart(HOUR, @d) where datepart(HOUR, @d) between 18 and 22)
BEGIN
	IF EXISTS(select datepart(MINUTE, @d) where datepart(MINUTE, @d) between 0 and 4)
	BEGIN
		IF EXISTS(select datepart(SECOND, @d) where datepart(SECOND, @d) between 0 and 9)
		EXEC jobs.dbo.save_WhoIsActive
	END
END

-->>

		
declare @getdate datetime = getdate()
declare @unic_day int = datediff(second, convert(datetime,convert(date,getdate())) ,getdate())


declare @threads as int
  
select @threads = 
case avg (case cntr_type when 1073939712 then cntr_value end ) when 0 then 0 else 
100.0 *  sum (case cntr_type when 537003264 then cntr_value end ) /
avg (case cntr_type when 1073939712 then cntr_value end ) end
from sys.dm_os_performance_counters (nolock)
where object_name = 'SQLServer:Resource Pool Stats' and cntr_type  in ( 537003264, 1073939712)

if @threads <= 80 
begin




		BEGIN TRY
		  

		insert into jobs..jobs
		(job_name , prefix_job)
		select 'jobs..proverki_system_jobs' , 0
		from 
		(select  COUNT(*) колво
		from jobs..jobs j
		where j.job_name = 'jobs..proverki_system_jobs' and j.date_exc is null ) a
		where a.колво=0

		--запустить задания из реестра
		--exec jobs..make_new_jobs_from_reestr


		-- проверить jobs на завершение
		if not exists (select *
		from jobs..Jobs_log (nolock) jl
		where jl.id_job =0  and number_step = 61 and 
		date_add > DATEADD(minute,-2,getdate())  )

		begin

		--print 1
		exec jobs.dbo.clear_jobs_new


		insert into jobs..Jobs_log ([id_job],[number_step],[duration],par2) 
		select 0 , 61, DATEDIFF(MILLISECOND , @getdate ,GETDATE())  , @unic_day
		select @getdate = getdate() 

		end



		-- запустить новые jobs из jobs..jobs
		exec jobs.dbo.jobs_take_new 






		END TRY

		BEGIN CATCH

		insert into jobs..error_jobs
		(job_name , message ,  id_job , number_step)
		 SELECT 'system_jobs' , ERROR_MESSAGE() , 0 , 100 


		END CATCH
END
		-----перенесем информацию об ошибках на SRV-SQL01--------------------
		if (select case when a.колво1  >0 and b.колво2=0 then 1 else 0 end
		  from 
		(Select COUNT(*) колво1
		from jobs..error_jobs (nolock) ) a
		inner join
		(Select COUNT(*) колво2
		from jobs..Jobs (nolock) j
		where job_name = 'jobs..err_jobs_add_trigger'
		and j.date_exc is null) b on 1=1) =1

		insert into jobs..Jobs (
			   [job_name]
			  ,[prefix_job] )
		SELECT 'jobs..err_jobs_add_trigger', 0


END
GO