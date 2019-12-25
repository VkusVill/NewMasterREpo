SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		OD
-- Create date: 2016-02-17
-- Description:	Обновление таблицы Tov_bez_ostatkov_for_LP на srv-sql03
-- select * from jobs..jobs_union where job_name like '%Tov_bez_ostatkov_for_LP' order by date_add desc
-- =============================================
CREATE PROCEDURE [dbo].[Update_Tov_bez_ostatkov_for_LP]
@id_job int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
--declare @id_job as int=0
 DECLARE 
    @job_name varchar(1000) =com.dbo.Object_name_for_err(@@procid,db_id())
   

if OBJECT_ID('tempdb..#Tov_bez_ostatkov_for_LP') is not null drop table #Tov_bez_ostatkov_for_LP

select id_tt
	, id_tov
into #Tov_bez_ostatkov_for_LP
from openquery([srv-sql01],
'select distinct d.id_tov , d.id_tt
 from Reports..DTT as d with(nolock)
 where d.id_tov in (select id_tov from m2..Tovari where bez_ostatkov=1) 
		 and date_tt>=DATEADD(day,-7,getdate()) and quantity>0')a


 create index ind1 on #Tov_bez_ostatkov_for_LP (id_tt, id_tov)
 

WHILE 1=1
begin
	begin try
		
			UPDATE vv03..Tov_bez_ostatkov_for_LP
				set  Shopno       = tt.N
					, date_last_upd=getdate()

			FROM vv03..Tov_bez_ostatkov_for_LP c 
				inner join #Tov_bez_ostatkov_for_LP a
					on a.id_tt= c.id_tt 
						and a.id_tov=c.Id_tov
			    inner join vv03..tt with(nolock)
				    on a.id_tt=tt.id_tt
			where  c.ShopNo <> tt.N
					
			insert into vv03..Tov_bez_ostatkov_for_LP ([id_tt],[ShopNo],[id_tov],[date_last_upd])
			select a.[id_tt],tt.[N],a.[id_tov], getdate()[date_last_upd]
			FROM #Tov_bez_ostatkov_for_LP a
			 	inner join vv03..tt with(nolock)
				    on a.id_tt=tt.id_tt
				left join vv03..Tov_bez_ostatkov_for_LP c 
				    on a.id_tt= c.id_tt 
				 	  and a.id_tov=c.id_tov			
			where   c.id_tt is null 
					
			delete from vv03..Tov_bez_ostatkov_for_LP
			FROM vv03..Tov_bez_ostatkov_for_LP c 
				left join #Tov_bez_ostatkov_for_LP a
				on a.id_tt= c.id_tt 
				and a.id_tov=c.Id_tov
			where a.id_tt is null

			  
		BREAK
	
	end try
	begin catch
		if ERROR_NUMBER()<>1205 --вызвала взаимоблокировку
		begin
			insert into jobs..error_jobs(job_name , message , number_step , id_job)
			select @job_name , ERROR_MESSAGE() , 10 , @id_job
			RETURN
		end
	end catch
end --while	

if exists(
select 1 
from (	select [id_tt]
			,[ShopNo]
			,[id_tov]
			
		from vv03..Tov_bez_ostatkov_for_LP
		union all
		select a.[id_tt]
			,tt.N
			,a.[id_tov]
			
		FROM #Tov_bez_ostatkov_for_LP a
				inner join vv03..tt with(nolock)
			    on a.id_tt=tt.id_tt) a
group by a.id_tt, a.id_tov, a.ShopNo
having count(1)<>2
)
begin
	insert into jobs..error_jobs(job_name , message , number_step , id_job)
	select @job_name ,'Расхождения в обновлении данных о продажах товаров без остатков для установки ЛП на 03 сервере.' , 10 , @id_job
end

drop table #Tov_bez_ostatkov_for_LP

END
GO