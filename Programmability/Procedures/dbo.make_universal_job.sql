SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[make_universal_job] 
@working_job as int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

BEGIN TRY

declare @getdate datetime  = getdate()
create table #idjob (id_job int)

/**
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
BEGIN TRANSACTION
update [jobs].[dbo].[working_jobs]  with (TABLOCKX)
set [take_date] = GETDATE() 
where working_job= @working_job
COMMIT TRANSACTION
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
**/


--declare @working_job as int =1

--declare @delay as char(12) = '00:00:0' + rtrim(1.0 * convert(int,rand() *1000)/100)
--select  @delay
-- сделать паузу, чтоб задания запускать равномерно
--select @delay




declare @id_job int  -- 435
, @threads as int

declare @s as nvarchar(max)
DECLARE @ParmDefinition nvarchar(500) -- передача параметра в sp_executesql
Declare @kolvo int =null -- количество записей 
DECLARE @S_2 as nvarchar(4000)

Declare @i as int =0

while @i<=2
begin

select @i=@i+1

Select @id_job = null

select @threads =  master.dbo.minz(100,
case avg (case cntr_type when 1073939712 then cntr_value end ) when 0 then 0 else
100.0 * sum (case cntr_type when 537003264 then cntr_value end ) /
avg (case cntr_type when 1073939712 then cntr_value end ) end)
from sys.dm_os_performance_counters (nolock)
where object_name = 'SQLServer:Resource Pool Stats' and cntr_type  in ( 537003264, 1073939712)
and counter_name not in ('Avg Disk Read IO (ms) Base','Avg Disk Write IO (ms) Base')

-- если загрузка более 60%, то не выполнять jobs
if @threads > 80 
begin

insert into jobs..Jobs_log ([id_job],[number_step],[duration],working_job , par1)
select 1 , 1, DATEDIFF(MILLISECOND , @getdate ,GETDATE())  , 0 , @threads

--EXEC [master].dbo.sp_WhoIsActive 
--@DESTINATION_TABLE = 'reports.dbo.whoisactive';

--WAITFOR DELAY '00:00:05'

return
end



-- определить уникальный номер  @id_job, чтоб его больше никто не взял
--SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
--BEGIN TRANSACTION 


delete from #idjob

update jobs..Jobs  
set 
   date_take = GETDATE() , working_job = @working_job
output b.id_job
into #idjob   

--select *
from jobs j with (tablockx , index (PK_Jobs))
inner join 
(select  a.id_job --MIN(j.id_job - case when j.job_name='m2..make_rasp_new' then end)
from 
(select j.id_job , j.job_name ,
ROW_NUMBER() over (order by case when j.job_name='m2..make_rasp_new' then 0 else 1 end , j.id_job) rn
from jobs..Jobs j  with (tablockx)
left join jobs..type_jobs tj  with (tablockx) on tj.job_name=j.job_name 

 left join -- чтобы не было запущено заданий с таким же prifix
  (Select job_name , prefix_job
   from jobs..Jobs  with (tablockx)
   where date_take is not null and date_exc is null) j_pr 
  on j.job_name=j_pr.job_name and j.prefix_job=j_pr.prefix_job

where j.date_take is null and j.working_job is null
and j_pr.job_name is null
and ISNULL( tj.is_active ,1 ) =1  
and not (j.job_name in ('reports..send_email_results','reports..Report_Statistica_Pokazatel' ) and @threads>60)

) a
where a.rn=1
) b on b.id_job = j.id_job

select @id_job = id_job
from #idjob

/**
if @id_job is not null

UPDATE
  jobs..Jobs  
set 
   date_take = GETDATE() , working_job = @working_job
from jobs with (rowlock , index (PK_Jobs))
where id_job = @id_job
**/

--COMMIT TRANSACTION
--SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

--WAITFOR DELAY @delay
--select @getdate = getdate() 


 
--select @threads = count(*)
--from sys.dm_os_threads (nolock)

--update jobs..jobs 
--set threads = @threads
--where id_job = @id_job


insert into jobs..Jobs_log ([id_job],[number_step],[duration],working_job , par1 , par2 ,par3)
select 1 , 1, DATEDIFF(MILLISECOND , @getdate ,GETDATE())  , @working_job , @threads , @id_job , @i
select @getdate = getdate() 



if (@id_job) is not null
begin
--select @id_job




-- если задание еще не прописано в тип, то прописать
if not exists 
(select *
from [jobs].[dbo].[type_jobs] tj
inner join jobs..Jobs j (nolock) on j.job_name= tj.job_name
where id_job=@id_job )

begin

select @S_2 = '
use ' + left( j.job_name, CHARINDEX('.',j.job_name,1)-1) + '
select @kolvo = count(*)-1
from INFORMATION_SCHEMA.PARAMETERS
where SPECIFIC_NAME = ''' + right (j.job_name,CHARINDEX('.',REVERSE(j.job_name),1)-1) + ''' '
from jobs..Jobs j (nolock) where id_job=@id_job

SET @ParmDefinition = N'@kolvo int  OUTPUT'
EXEC sp_executesql @S_2  ,@ParmDefinition , @kolvo = @kolvo OUTPUT

insert into [jobs].[dbo].[type_jobs]
      ([job_name]
      ,[max_time]
      ,[is_active]
      ,[parameters])
select RTRIM(j.job_name) , 900 , 1 , @kolvo
from jobs..Jobs j (nolock)
left join [jobs].[dbo].[type_jobs] tj on j.job_name= tj.job_name -- если еще ее не записали
where id_job=@id_job and tj.job_name is null
 
end
else -- значит просто взять колво параметров

select @kolvo = [parameters]
from [jobs].[dbo].[type_jobs] tj
inner join jobs..Jobs j (nolock) on j.job_name= tj.job_name
where id_job=@id_job



--insert into jobs..Jobs_log ([id_job],[number_step],[duration],working_job) select @id_job , 2, DATEDIFF(MILLISECOND , @getdate ,GETDATE())  , @working_job
--select @getdate = getdate() 


	select @s=
		' exec ' 
		+ RTRIM(jobs.job_name)+ '  ' 
		+ RTRIM(@id_job)  +
		+ case when @kolvo>=1 then  ' , ' 
		+ case when isnumeric(rtrim(jobs.prefix_job))=0 then '''' else '' end +
		isnull(RTRIM(jobs.prefix_job),'NULL' )  else '' end
		+ case when isnumeric(rtrim(jobs.prefix_job))=0 then '''' else '' end +		
		+ case when @kolvo>=2 then  ' ,  ' + isnull(RTRIM(jobs.number_1)  ,'NULL' )  else '' end
		+ case when @kolvo>=3 then  ' ,  ' + isnull(RTRIM(jobs.number_2)  ,'NULL' )  else '' end		
		+ case when @kolvo>=4 then  ' ,  ' + isnull(RTRIM(jobs.number_3)  ,'NULL' )  else '' end 
		from jobs..jobs (nolock)
		where id_job = @id_job
	
--select @S


BEGIN TRY
		 
EXEC sp_executesql @S
select @getdate = getdate() 

END TRY

BEGIN CATCH
select @getdate = getdate() 

 if (SELECT CHARINDEX('ожидает параметр', ERROR_MESSAGE() , 1) ) >1
 -- значит проблема с параметрами - обновить параметры
 begin
 
 select @S_2 = '
use ' + left( j.job_name, CHARINDEX('.',j.job_name,1)-1) + '
select @kolvo = count(*)-1
from INFORMATION_SCHEMA.PARAMETERS
where SPECIFIC_NAME = ''' + right (j.job_name,CHARINDEX('.',REVERSE(j.job_name),1)-1) + ''' '
from jobs..Jobs j (nolock) where id_job=@id_job

SET @ParmDefinition = N'@kolvo int  OUTPUT'
EXEC sp_executesql @S_2  ,@ParmDefinition , @kolvo = @kolvo OUTPUT

update [jobs].[dbo].[type_jobs]
set [parameters] = @kolvo
from [jobs].[dbo].[type_jobs] tj 
inner join jobs..Jobs j (nolock) on j.job_name= tj.job_name 
where id_job=@id_job 

 end


--select @threads = count(*)
--from sys.dm_os_threads (nolock)

-- отправить ошибку в таблицу ошибок
insert into jobs..error_jobs
(job_name , message ,   id_job , number_step)
select job_name , ERROR_MESSAGE() ,   @id_job  , @threads
from jobs..Jobs j (nolock) 
where id_job=@id_job 

--insert into jobs..Jobs_log ([id_job],[number_step],[duration],working_job) select @id_job , 50, DATEDIFF(MILLISECOND , @getdate ,GETDATE())  , @working_job
--select @getdate = getdate() 

-- проверить,если ошибка из-за обновления 1С конфигурации, которая потерла новые столбцы,
--то запустить его расчет и сделать повтор заданий через 10 минут
if (select 
max (case when 
          (CHARINDEX('Недопустимое имя столбца' , ERROR_MESSAGE() ,1) >0  
       and CHARINDEX(RTRIM(cn.Name_ins) ,ERROR_MESSAGE() ,1) >0 ) 
       then 1 else 0 end ) 
from  Reports..Create_new_field_1C (nolock) cn where cn.Type_ins = 'field'
 ) =1
 -- значит именно его и убрали
begin
if not exists (
   select * 
   from jobs..jobs (nolock) j
   where j.date_add >DATEADD (minute,-15,getdate()) 
   and j.job_name = 'reports..create_fields'
   )
-- не было запуска посление 15 минут - запустить   
insert into jobs..jobs
(job_name , prefix_job )
select 'reports..create_fields' , 0


if ( select COUNT(*)
from jobs..Jobs j1
inner join jobs..Jobs j2 on j1.job_init=j2.job_init 
where j2.id_job = @id_job ) <=2
-- значит уже было не более 3 запусков неуспеного первоначального (последний считается)

-- запустить через 10 минут
insert into jobs..Jobs (
      date_add
      ,[job_name]
      ,[prefix_job]
      ,[number_1]
      ,[number_2]
      ,[number_3]
      , job_init )
select DATEADD(minute,10,getdate())
      ,[job_name]
      ,[prefix_job]
      ,[number_1]
      ,[number_2]
      ,[number_3]
      ,ISNULL(job_init , id_job)
from jobs..Jobs
where id_job = @id_job            

else -- значит уже 3 неуспешных запуска

insert into [IES].[dbo].[Outgoing]
( Number,[Message],Project,type_BV )
select '79257108802' ,
convert(char(500), rtrim(j.[job_name]) 
+ ', '  + rtrim(j.id_job)  
+ ', ' + rtrim(j.prefix_job)  +  ' не может выполниться уже 3 раза')  ,
 'Избенка' , 777 
from jobs..Jobs (nolock) j
where id_job = @id_job  

--insert into jobs..Jobs_log ([id_job],[number_step],[duration],working_job) select @id_job , 51, DATEDIFF(MILLISECOND , @getdate ,GETDATE())  , @working_job
--select @getdate = getdate() 

end
else -- все прочие ошбки

-- если ошибка  
-- 'вызвала взаимоблокировку ресурсов'
-- 'необходимые ресурсы потоков'
-- 'изменилось с момента компиляции'
-- или название одного из столбцов при добавлении 
--если не более 3 повторений, то запустить еще раз Create_new_field_1C
if (select 
     case when (CHARINDEX('вызвала взаимоблокировку ресурсов' ,ERROR_MESSAGE() ,1) >0 
       or CHARINDEX('необходимые ресурсы потоков' , ERROR_MESSAGE() ,1) >0 
       or CHARINDEX('изменилось с момента компиляции' , ERROR_MESSAGE() ,1) >0        
       or CHARINDEX('ожидает параметр' , ERROR_MESSAGE() ,1) >0    
       or CHARINDEX('удалось выделить новую страницу' , ERROR_MESSAGE() ,1) >0    
       or CHARINDEX('Текущая транзакция не может' , ERROR_MESSAGE() ,1) >0 )
       and tj.restart_err=0  
        then 1 else 0 end 
       from jobs..Jobs j (nolock) 
       inner join  jobs..type_jobs tj on j.job_name=tj.job_name
       where id_job=@id_job

 ) =1


if ( select COUNT(*)
from jobs..Jobs j1
inner join jobs..Jobs j2 on j1.job_init=j2.job_init 
where j2.id_job = @id_job ) <=20
-- значит уже было не более 3 запусков неуспеного первоначального (последний считается)

insert into jobs..Jobs (
       [job_name]
      ,[prefix_job]
      ,[number_1]
      ,[number_2]
      ,[number_3]
      , job_init )
select [job_name]
      ,[prefix_job]
      ,[number_1]
      ,[number_2]
      ,[number_3]
      ,ISNULL(job_init , id_job)
from jobs..Jobs
where id_job = @id_job            

else -- значит уже 20 неуспешных запуска

insert into [IES].[dbo].[Outgoing]
( Number,[Message],Project,type_BV )
select '79257108802' ,
convert(char(500), rtrim(j.[job_name]) 
+ ', '  + rtrim(j.id_job)  
+ ', ' + rtrim(j.prefix_job)  +  ' не может выполниться уже 20 раз')  ,
 'Избенка' , 777 
from jobs..Jobs (nolock) j
where id_job = @id_job  


-- проставить, что плохо завершились
update jobs..jobs
set date_exc = GETDATE() , type_exec=0
where id_job = @id_job

--insert into jobs..Jobs_log ([id_job],[number_step],[duration],working_job) select @id_job , 53, DATEDIFF(MILLISECOND , @getdate ,GETDATE())  , @working_job
--select @getdate = getdate() 
 
 /**
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
BEGIN TRANSACTION
update [jobs].[dbo].[working_jobs]  with (TABLOCKX)
set [end_date] = GETDATE() 
where working_job= @working_job
COMMIT TRANSACTION
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
 **/
 
return

END CATCH;


--insert into jobs..Jobs_log ([id_job],[number_step],[duration],working_job) 
--select @id_job , 3, DATEDIFF(MILLISECOND , @getdate ,GETDATE())  , @working_job
--select @getdate = getdate() 

-- новый алгоритм - проставить выполнение всем еще не взятым заданиям с те ми же параметрами

select a.id_job
into #j
from
(select j.id_job
from jobs..jobs (rowlock) j
inner join
(select j.job_name , j.prefix_job , j.date_take,
isnull(j.number_1,0) number_1 , isnull(j.number_2,0) number_2 , isnull(j.number_3,0) number_3
from jobs..jobs (rowlock) j
where id_job = @id_job ) ja on j.job_name=ja.job_name and j.prefix_job=ja.prefix_job and
isnull(j.number_1,0) =ja.number_1 and isnull(j.number_2,0) = ja.number_2 and isnull(j.number_3,0) = ja.number_3
where j.working_job is null and j.date_add>ja.date_take

union all

select j.id_job
from jobs..jobs (rowlock) j
inner join 
(select working_job , id_job 
from jobs..jobs (rowlock)
where id_job = @id_job) wj 
on wj.working_job=j.working_job and j.id_job<>wj.id_job
where j.date_exc is not null
) a

insert into jobs..Jobs_log ([id_job],[number_step],[duration],working_job) 
select 1 , 40, DATEDIFF(MILLISECOND , @getdate ,GETDATE())  , @working_job
select @getdate = getdate() 

--SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
--BEGIN TRANSACTION 

Declare @err int= 1 
while @err=1
begin

begin try
 
delete jobs..jobs
from jobs..jobs j  with (rowlock)
inner join #j j2 on j.id_job = j2.id_job

update jobs..jobs  with (rowlock)
set date_exc = GETDATE()
where id_job = @id_job

 select @err=0
 
 END TRY
  BEGIN CATCH

 if case when (CHARINDEX('вызвала взаимоблокировку ресурсов',ERROR_MESSAGE(),1)>0 
 or CHARINDEX('Текущая транзакция не может быть зафиксирована',ERROR_MESSAGE(),1)>0 )
 then 1 else 0 end =1
begin

insert into jobs..Jobs_log ([id_job],[number_step],[duration]) 
select 1 , 211, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
select @getdate = getdate() 

end
else
begin
insert into jobs..error_jobs
(job_name , message , number_step , id_job)
select 'jobs..make_universal_job' , ERROR_MESSAGE() , 211 , 1
  
 return
 end
  
  END CATCH

  
end

--COMMIT TRANSACTION
--SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

insert into jobs..Jobs_log ([id_job],[number_step],[duration],working_job) 
select 1 , 41, DATEDIFF(MILLISECOND , @getdate ,GETDATE())  , @working_job
select @getdate = getdate() 

drop table #j

--insert into jobs..Jobs_log ([id_job],[number_step],[duration],working_job) select @id_job , 4, DATEDIFF(MILLISECOND , @getdate ,GETDATE())  , @working_job
--select @getdate = getdate() 

end

end

END TRY

BEGIN CATCH

-- отправить ошибку в таблицу ошибок
insert into jobs..error_jobs
(job_name , message ,   id_job)
select 'jobs..make_universal_job' , ERROR_MESSAGE() ,  @working_job 

end catch
 
 /**
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
BEGIN TRANSACTION
update [jobs].[dbo].[working_jobs]  with (TABLOCKX)
set [end_date] = GETDATE() 
where working_job= @working_job
COMMIT TRANSACTION
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
**/

drop table #idjob
 
END
GO