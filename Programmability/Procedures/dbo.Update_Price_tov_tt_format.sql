SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		OD
-- Create date: 2019-03-07
-- Description:	Обновление vv06..Price_tov_tt_format ([srv-sql01].reports.dbo.Price_tov_tt_format)

-- =============================================
CREATE PROCEDURE [dbo].[Update_Price_tov_tt_format]
@id_job  int
AS
BEGIN	
	SET NOCOUNT ON;
declare @strТекстSQLЗапроса as nvarchar(4000)
declare @getdate as datetime =getdate()
		,@job_name as varchar(100)=com.dbo.Object_name_for_err(@@procID,db_id())

Declare @temp_table as nchar(36) 


--------------------------------Обновим таблицу Price_tov_tt_format------------------------------------------------

while 1=1
begin

	begin try
		if OBJECT_ID ('tempdb..#Price_tov_tt_format') is not null drop table #Price_tov_tt_format

		select [id_tov]
           ,[price]
           ,[tt_format]
		into #Price_tov_tt_format
		from [srv-sql01].Reports.dbo.Price_tov_tt_format
       
          MERGE INTO [vv03].[dbo].[Price_tov_tt_format] t1
          USING #Price_tov_tt_format t2
			ON t1.id_tov=t2.id_tov
				AND t1.tt_format=t2.tt_format
		  WHEN NOT MATCHED BY TARGET THEN	
          INSERT 
           ([id_tov]
           ,[price]
           ,[tt_format])
          VALUES ( t2.[id_tov]
           ,t2.[price]
           ,t2.[tt_format])
          WHEN MATCHED 
			AND t1.price <>t2.price THEN
		  UPDATE set t1.price=t2.price	
          WHEN NOT MATCHED BY SOURCE THEN
          DELETE ;
          
       
		
		BREAK
	end try
	begin catch

		if ERROR_NUMBER()=1205 --вызвала взаимоблокировку ресурсов',ERROR_MESSAGE(),1)>0
		begin

			insert into jobs..Jobs_log ([id_job],[number_step],[duration]) 
			select @id_job ,11, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
			select @getdate = getdate() 

		end
		else
		begin

			insert into jobs..error_jobs(job_name , message , number_step , id_job)
			select @job_name , ERROR_MESSAGE() , 12 , @id_job
			BREAK
		 end
	end catch
end --while	

if exists(
 SELECT [id_tov]
           ,[price]
           ,[tt_format]
        FROM (
         SELECT [id_tov]
           ,[price]
           ,[tt_format]
        FROM #Price_tov_tt_format      
        union all
         SELECT [id_tov]
           ,[price]
           ,[tt_format]
        FROM vv03..Price_tov_tt_format )a
        group by   [id_tov]
           ,[price]
           ,[tt_format]
      having COUNT(1)<>2          )
begin
  insert into jobs..error_jobs(id_job, job_name, number_step,message, date_add)
  select @id_job,@job_name,100, 'Расхождения в данных по ценам товаров по форматам 03 сервер ( vv03..Price_tov_tt_format)', GETDATE()
end      
IF OBJECT_ID ('tempdb..#Price_tov_tt_format') is not null drop table #Price_tov_tt_format



--------------------------------Обновим таблицу Price_tov_tt_format_period------------------------------------------------

while 1=1
begin

	begin try
		if OBJECT_ID ('tempdb..#Price_tov_tt_format_period') is not null drop table #Price_tov_tt_format_period

		create table #Price_tov_tt_format_period (
			[id_tov] int
           ,[price]  decimal(15,2)
           ,[tt_format] int
		   ,[date_pr] date)

		insert into #Price_tov_tt_format_period (id_tov,price, tt_format, date_pr) 
		select [id_tov]
           ,[price]
           ,[tt_format]
		   ,[date_pr]
		from [srv-sql01].Reports.dbo.Price_tov_tt_format_period
       
          MERGE INTO [vv03].[dbo].[Price_tov_tt_format_period] t1
          USING #Price_tov_tt_format_period t2
			ON t1.id_tov=t2.id_tov
				AND t1.tt_format=t2.tt_format
				AND t1.date_pr=t2.date_pr
		  WHEN NOT MATCHED BY TARGET THEN	
          INSERT 
           ([id_tov]
           ,[price]
           ,[tt_format]
		   ,[date_pr])
          VALUES ( t2.[id_tov]
           ,t2.[price]
           ,t2.[tt_format]
		   ,t2.[date_pr])
          WHEN MATCHED 
			AND t1.price <>t2.price THEN
		  UPDATE set t1.price=t2.price	
          WHEN NOT MATCHED BY SOURCE THEN
          DELETE ;
          
       
		
		BREAK
	end try
	begin catch

		if ERROR_NUMBER()=1205 --вызвала взаимоблокировку ресурсов',ERROR_MESSAGE(),1)>0
		begin

			insert into jobs..Jobs_log ([id_job],[number_step],[duration]) 
			select @id_job ,21, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
			select @getdate = getdate() 

		end
		else
		begin

			insert into jobs..error_jobs(job_name , message , number_step , id_job)
			select @job_name , ERROR_MESSAGE() , 22 , @id_job
			BREAK
		 end
	end catch
end --while	

if exists(
 SELECT [id_tov]
           ,[price]
           ,[tt_format]
		   ,[date_pr]
        FROM (
         SELECT [id_tov]
           ,[price]
           ,[tt_format]
		   ,[date_pr]
        FROM #Price_tov_tt_format_period      
        union all
         SELECT [id_tov]
           ,[price]
           ,[tt_format]
		   ,[date_pr]
        FROM vv03..Price_tov_tt_format_period )a
        group by   [id_tov]
           ,[price]
           ,[tt_format]
		   ,[date_pr]
      having COUNT(1)<>2          )
begin
  insert into jobs..error_jobs(id_job, job_name, number_step,message, date_add)
  select @id_job,@job_name,100, 'Расхождения в данных по всем ценам товаров по форматам  03 сервер ( vv03..Price_tov_tt_format_period)', GETDATE()
end      
IF OBJECT_ID ('tempdb..#Price_tov_tt_format_period') is not null drop table #Price_tov_tt_format_period



 
END
GO