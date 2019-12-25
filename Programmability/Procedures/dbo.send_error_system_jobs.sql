SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[send_error_system_jobs]
@name as char(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

/**
Create Table #JobHistory( 
  [instance_id]          int,
  [job_id]               uniqueidentifier,
  [job_name]             sysname,
  [step_id]              int,
  [step_name]            sysname,
  [sql_message_id]      int,
  [sql_severity]         int,
  [message]         nvarchar(max),
  [run_status]       int,     -- YYYYMMDD
  [run_date]       int,     -- YYYYMMDD
  [run_time]       int,     -- HHMMSS
  [run_duration] int,     -- HHMMSS
  [operator_emailed]         nvarchar(20), 
  [operator_netsent]         nvarchar(20), 
  [operator_paged]         nvarchar(20), 
  [retries_attempted]         int, 
  [server]               nvarchar(30) )  
  **/

Create Table #JobHistory
(
job_id  uniqueidentifier,
job_name  sysname,
step_id int,
step_name sysname,
step_uid uniqueidentifier,
date_created datetime,
date_modified datetime,
log_size float,
[log] nvarchar(max) )
 
Insert #JobHistory exec msdb.dbo.sp_help_jobsteplog @job_name = 'jobs_system_work' , @step_id=2

--Insert #JobHistory exec msdb.dbo.sp_help_jobhistory  @job_name = @name
--, @run_status = 0 , @oldest_first= 0 , @mode= 'Full'


insert into jobs..error_jobs
(job_name , message ,  number_step , id_job)
select job_name , [LOG] ,   max_step , 0
from #JobHistory r

left join 
(Select max(jl.number_step) max_step 
from Jobs_log (nolock) jl
where jl.id_job = 0 and jl.working_job is null ) a on 1=1





/**
if (select COUNT(*)
from jobs..error_jobs
where id_job=0 and date_add > DATEADD(minute,-5,getdate())) <2

begin
insert into A1_SMPP..OutboundSMS
( Number,[Message],ProviderIdx , SrcAddr )
SELECT '79257108802' , 'Job ' +  rtrim(@name) +  ' в ' + RTRIM(GETDATE())+ ' завершилось ошибкой' , 1 , 'Izbenka' 


insert into A1_SMPP..OutboundSMS
( Number,[Message],ProviderIdx , SrcAddr )
SELECT '79257861328' , 'Job ' +  rtrim(@name) +  ' в ' + RTRIM(GETDATE())+ ' завершилось ошибкой' , 1 , 'Izbenka' 


select master.dbo.sendSMS ( '+79257108802' , 'Job ' +  rtrim(@name) +  ' в ' + RTRIM(GETDATE())+ ' завершилось ошибкой')

select master.dbo.sendSMS ( '+79257861328' , 'Job ' +  rtrim(@name) +  ' в ' + RTRIM(GETDATE())+ ' завершилось ошибкой')

insert into [IES].[dbo].[Outgoing]
( Number,[Message],AddDate,Project,type_BV )

SELECT '79257108802' , 'Job ' +  rtrim(@name) +  ' в ' + RTRIM(GETDATE())+ ' завершилось ошибкой' 
,GETDATE() , 'Избенка' , 777


end
**/

END
GO