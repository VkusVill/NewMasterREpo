SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[make_new_jobs_from_reestr]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

declare @getdate datetime = getdate()
 
select top 10000 Row_number() over (order by date_add ) -1 rn 
into #a
from jobs..jobs_log (nolock)

 insert into jobs..Jobs_log ([id_job],[number_step],[duration]) 
select 0 , 501, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
select @getdate = getdate()

select j.job_name , max(convert(time,j.date_add)) date_add_max
into #c
from jobs..Jobs_union (nolock) j
where convert(date,j.date_add) = convert(date,getdate())
group by j.job_name

 insert into jobs..Jobs_log ([id_job],[number_step],[duration]) 
select 0 , 502, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
select @getdate = getdate()

select ProcedureName , rn , DATEADD(minute , rn*r_period_minute ,  [time_j_r]) time_work
into #b
FROM jobs..jobs_reestr
inner join #a a on rn*r_period_minute <= datediff(minute, [time_j_r] , [time_j_p_finish]) 
and rn*r_period_minute <= datediff(minute, [time_j_r] , convert(time,GETDATE()))
where is_active=1
and charindex(RTRIM(DATEPART(weekday,getdate())) ,
 case when isnull(RTRIM(weekdays),'')='' then '1234567' else weekdays end ,1 ) >0
and ( isnull(rtrim(monthdays),'')='' or 
isnull(rtrim(monthdays),'')='' or 
charindex( 
case when DATEPART(day,getdate())<10 then '0' else '' end + RTRIM(DATEPART(day,getdate()))
 , monthdays ,1 ) >0) 

 insert into jobs..Jobs_log ([id_job],[number_step],[duration]) 
select 0 , 503, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
select @getdate = getdate()


--DECLARE crs CURSOR LOCAL FOR

insert into jobs..Jobs 
(job_name , prefix_job )
select distinct rtrim(ProcedureName) ,0 
from 
(select ProcedureName ,  max( time_work ) max_time_work
from #b b 
where time_work <= convert(time,GETDATE())
group by ProcedureName) d 

left join #c c on c.job_name=d.ProcedureName and d.max_time_work<=c.date_add_max

left join jobs..Jobs j on j.job_name=d.ProcedureName and j.date_exc is null 

where c.date_add_max is null and j.job_name is null

/**
 OPEN crs
 FETCH crs INTO @ProcedureName
	
 WHILE NOT @@fetch_status = -1 
	BEGIN

insert into jobs..Jobs
(job_name , prefix_job )
select rtrim(@ProcedureName) , 0


    FETCH NEXT FROM crs INTO @ProcedureName
 
 END

 CLOSE crs
**/

drop table #a
drop table #c
drop table #b

 insert into jobs..Jobs_log ([id_job],[number_step],[duration]) 
select 0 , 504, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
select @getdate = getdate()


END
GO