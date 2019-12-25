SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		OD
-- Create date: 2016-08-12
-- Description:	Обновление таблицы vv03..dtt
-- Change:      OD 201902-05 Добавлено обновление столбца Отгрузка ЮЛ
--   			OD 201902-11 Добавлено обновление столбца vozvrat_sum
-- =============================================
--select * from jobs..jobs where job_name like '%Recalc_DTT_add_trigger%' and date_exc is null
--select * from jobs..jobs_union where job_name like '%Recalc_DTT_add_trigger%' order by date_add desc

CREATE PROCEDURE [dbo].[Recalc_DTT_add_trigger_del]
@id_job	as int
--,@id_tt as int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

--declare @id_job as int=123456789
declare @getdate as datetime = getdate()
		,@job_name varchar(500)=master.dbo.Object_Name_for_err(@@Procid,DB_id())
 
Declare @temp_table as nchar(36) 
declare  @strТекстSQLЗапроса as nvarchar(4000)
  
if OBJECT_ID('tempdb..#inserted') is not null drop table #inserted 

CREATE TABLE #inserted(
	[id]				[bigint] ,
	[id_tt]				[int],
	[id_tov]			[int],
	[date_tt]			[date] ,
	[field_name]		[varchar](50),
	[q]					[decimal](15, 3),
	[akcia]				[decimal](15, 3),
	[Discount50_qty]	[decimal](15, 3),
	[Discount50]		[decimal](15, 2),
	[summa]				[decimal](15, 2)
	,[Shopno]			[int] null
	,[obed]				[decimal](15, 3)
	,[vozvrat_sum]      [decimal](15, 2)
	,[otgruzka_UL_sum]  [decimal](15, 2))
	

set @strТекстSQLЗапроса='EXEC(''
		select [id],[id_tt]
			,[id_tov]
			,[date_tt]
			,[field_name]
			,[q]
			,[akcia]
			,[Discount50_qty]
			,[Discount50]
			,[summa]
			,[ShopNo]
			,[obed] 
			,isnull([vozvrat_sum],0) [vozvrat_sum]
			,isnull([otgruzka_UL_sum],0) [otgruzka_UL_sum]
			
		from [jobs].[dbo].[Recalc_DTT_SRV_SQL01]
		'') at [srv-sql01]'
		

insert into #inserted( [id]
		,[id_tt]
		,[id_tov]
		,[date_tt]
		,[field_name]
		,[q]
        ,[akcia]
        ,[Discount50_qty]
        ,[Discount50]
        ,[summa] 
        ,[Shopno]
        ,[obed]
        ,[vozvrat_sum]
        ,[otgruzka_UL_sum])
exec sp_executesql  @strТекстSQLЗапроса
		

update #inserted set id_tt=tt.id_tt
from #inserted as i inner join vv03..tt as tt with(nolock) on tt.N=i.ShopNo
where isnull(i.Shopno,0)<>0

if OBJECT_ID('tempdb..#dtt') is not null drop table #dtt


select  id_tt
	, id_tov
	, date_tt
	, post
	, digust
	, spisanie
	, spisanie_kach
	, boi
	, spisanie_dost
	, akcia
	, discount50
	, discount50_qty
	, razniza
	, summa
	, quantity
	, vozvrat_pok
	, peremPlus
	, peremMinus
	, Complect
	, obed
	, otgruzka_UL  
	,[vozvrat_sum]
	,[otgruzka_UL_sum]
	, 0 tt_format_dtt
	, 0 id_group

into #dtt
from (select id_tt
		, id_tov
		, date_tt
		, sum(case when field_name='post' then  q else 0 end) post
		, sum(case when field_name='digust' then q else 0 end) digust
		, sum(case when field_name='spisanie' then q else 0 end) spisanie
		, sum(case when field_name='spisanie_kach' then q else 0 end) spisanie_kach
		, sum(case when field_name='boi' then q else 0 end) boi
		, sum(case when field_name='spisanie_dost' then q else 0 end) spisanie_dost
		, sum(akcia) akcia
		, sum(discount50) discount50
		, sum(discount50_qty) discount50_qty
		, sum(case when field_name='razniza' then q else 0 end)  razniza
		, sum(case when id_tov in (23169,23175) then 0                 --Обнуляем в DTT сумму подарочных карт
									   else summa end) summa
		, sum(case when field_name in ('quantity','obed') then q else 0 end)  quantity
		, sum(case when field_name='vozvrat_pok' then q else 0 end)  vozvrat_pok
		, sum(case when field_name='peremPlus' then q else 0 end) peremPlus
		, sum(case when field_name='peremMinus' then q else 0 end) peremMinus
		, sum(case when field_name='Complect' then q else 0 end) Complect
		, sum(obed) obed
		, sum(case when field_name='otgruzka_UL' then q else 0 end) otgruzka_UL
        , sum(vozvrat_sum ) vozvrat_sum
        , sum(otgruzka_UL_sum ) otgruzka_UL_sum
      
		from #inserted 
		group by  id_tt,id_tov,date_tt) b
where not (  [post]=0 
		and [digust]=0 
		and [spisanie]=0 
		and [spisanie_dost]=0 
		and [spisanie_kach]=0 
		and [boi]=0 
		and [akcia]=0 
		and [discount50]=0 
		and [discount50_qty]=0 
		and [razniza]=0 
		and [summa]=0 
		and [quantity]=0 
		and [vozvrat_pok]=0   
		and [peremPlus]=0 
		and [peremMinus]=0 
		and [complect]=0 
		and [obed]=0
        and [otgruzka_UL]=0
        and [vozvrat_sum]=0
        and [otgruzka_UL_sum]=0)



update #dtt set tt_format_dtt =tt.tt_format
		, id_group =isnull(isnull(tt_gr.id_gr, tt.id_group),0) 
from #dtt as dtt
	inner join vv03..tt as tt with(nolock)
		on dtt.id_tt=tt.id_tt
	left join vv03..tt_date_id_gr as tt_gr  with(nolock) 
		on tt_gr.date=dtt.date_tt 
			and tt_gr.id_tt=dtt.id_tt

--select * from #dtt where tt_format_dtt=7


declare @date_pr date

if OBJECT_ID('tempdb..#tt_format_price') is not null drop table #tt_format_price

create table #tt_format_price (date_pr date, tt_format int, id_tov int, price decimal(15,2))


declare crs_dtt_upd cursor for
select distinct date_tt
from #dtt

open crs_dtt_upd

fetch crs_dtt_upd into @date_pr

while @@FETCH_STATUS<>-1
begin
   insert into #tt_format_price(date_pr,tt_format,id_tov,price)
   select date_pr,tt_format,id_tov,price 
   from vv03.dbo.price_format_date (@date_pr)
  fetch next from crs_dtt_upd into @date_pr
end 

close crs_dtt_upd
deallocate crs_dtt_upd

create index ind_price_format on  #tt_format_price  (date_pr,tt_format,id_tov)

--select * from #tt_format_price

 
if OBJECT_ID('tempdb..#dt') is not null drop table #dt


select  id_tt
	, date_tt
	, post_sum
	, degust_sum
	, spisanie_sum
	, spisanie_kach_sum
	, boi_sum
	, spisanie_dost_sum
	, akcia_sum
	, discount50_sum
	, razniza_sum
	, summa
	, vozvrat_sum
	, peremPlus_sum
	, peremMinus_sum
	, obed_sum
	,otgruzka_UL_sum
	,tt_format 
	,id_group  

into #dt
from (select id_tt
		, date_tt
		, max(tt_format_dtt) tt_format
		, max(id_group ) id_group
		, sum( post * isnull(pr_format.price , pr.Price)) post_sum
		, sum( digust * isnull(pr_format.price , pr.Price)) degust_sum
		, sum( spisanie* isnull(pr_format.price , pr.Price)) spisanie_sum
		, sum( spisanie_kach * isnull(pr_format.price , pr.Price)) spisanie_kach_sum
		, sum( boi * isnull(pr_format.price , pr.Price)) boi_sum
		, sum( spisanie_dost * isnull(pr_format.price , pr.Price)) spisanie_dost_sum
		, sum( akcia * isnull(pr_format.price , pr.Price)) akcia_sum
		, sum( discount50) discount50_sum
		, sum( razniza * isnull(pr_format.price , pr.Price))  razniza_sum
		, sum( summa) summa
		, sum( vozvrat_sum)  vozvrat_sum
		, sum( peremPlus * isnull(pr_format.price , pr.Price)) peremPlus_sum
		, sum( peremMinus * isnull(pr_format.price , pr.Price)) peremMinus_sum
		, sum( obed * isnull(pr_format.price , pr.Price)) obed_sum
		, sum( otgruzka_UL_sum) otgruzka_UL_sum
		from #dtt as d 
			inner join vv03..Price_1C_tov as pr with(nolock) 
				on d.id_tov=pr.id_tov
            left join #tt_format_price   as pr_format with(nolock)
			   on d.date_tt=pr_format.date_pr
			    and  d.id_tov=pr_format.id_tov 
				and d.tt_format_dtt =pr_format.tt_format
		group by  id_tt,date_tt) b

		
insert into jobs..Jobs_log ([id_job],[number_step],[duration]) select @id_job , 21, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
select @getdate = getdate()



---изменение DTT----

while 1=1
begin
 begin try	
	update vv03..DTT with(rowlock) set post = isnull(dtt.post,0)+d_upd.post
	,digust=isnull(dtt.digust,0)+d_upd.digust
	,spisanie=isnull(dtt.spisanie,0)+d_upd.spisanie
	,spisanie_kach=isnull(dtt.spisanie_kach,0)+d_upd.spisanie_kach
	,boi=isnull(dtt.boi,0)+d_upd.boi
	,spisanie_dost=isnull(dtt.spisanie_dost,0)+d_upd.spisanie_dost
	,akcia=isnull(dtt.akcia,0)+d_upd.akcia
	,discount50=isnull(dtt.discount50,0)+d_upd.discount50
	,discount50_qty=isnull(dtt.discount50_qty,0)+d_upd.discount50_qty
	,razniza=isnull(dtt.razniza,0)+d_upd.razniza
	,summa=isnull(dtt.summa,0)+d_upd.summa
	,quantity=isnull(dtt.quantity,0)+d_upd.quantity
	,vozvrat_pok=isnull(dtt.vozvrat_pok,0)+d_upd.vozvrat_pok
	,peremPlus=isnull(dtt.peremPlus,0)+d_upd.peremPlus
	,peremMinus=isnull(dtt.peremMinus,0)+d_upd.peremMinus
	,Complect=isnull(dtt.Complect,0)+d_upd.Complect
	,obed=isnull(dtt.obed,0)+d_upd.obed
	,otgruzka_UL=ISNULL(dtt.otgruzka_UL,0)+d_upd.otgruzka_UL
	,vozvrat_sum=ISNULL(dtt.vozvrat_sum,0)+d_upd.vozvrat_sum
	,otgruzka_UL_sum=ISNULL(dtt.otgruzka_UL_sum ,0)+d_upd.otgruzka_UL_sum
	,date_update = GETDATE()
	--select *
	from vv03..DTT as dtt 
		inner join #dtt as d_upd  
			on  dtt.date_tt=d_upd.date_tt 
				and dtt.id_tt=d_upd.id_tt 
				and dtt.id_tov=d_upd.id_tov 
    BREAK
 END TRY
  BEGIN CATCH

		if ERROR_NUMBER()=1205-- вызвала взаимоблокировку ресурсов
		begin
			-- запись в лог факта блокировки
			insert into jobs..Jobs_log ([id_job],[number_step],[duration]) 
			select @id_job , 11, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
			select @getdate = getdate()		
		end
		else
		begin

			insert into jobs..error_jobs(job_name , message , number_step , id_job)
			select @job_name , ERROR_MESSAGE() , 11 , @id_job
			-- прочая ошибка - выход  
			break
		 end

  END CATCH 
end -- while      

insert into jobs..Jobs_log ([id_job],[number_step],[duration]) select @id_job , 30, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
select @getdate = getdate() 		

--вставка----

while 1=1
begin
 begin try
	insert into [vv03].[dbo].[DTT]
		 ([date_tt]
           ,[id_group]
           ,[id_tt]
           ,[id_tov]
           ,[post]
           ,[digust]
           ,[spisanie]
           ,[spisanie_kach]
           ,[boi]
           ,[spisanie_dost]
           ,[akcia]
           ,[akcia_sms]
           ,[discount50]
           ,[discount50_qty]
           ,[discount50_sms]
           ,[discount50_sms_qty]
           ,[razniza]
           ,[summa]
           ,[quantity]
           ,[price]
           ,[date_update]
           ,[vozvrat_pok]
           ,[peremPlus]
           ,[peremMinus]
           ,[Complect]
           ,[obed]
           ,[tt_format_dtt]
           ,[otgruzka_UL]
           ,[vozvrat_sum] 
           ,[otgruzka_UL_sum])	
	 select d_upd.[date_tt]
           ,d_upd.[id_group]
           ,d_upd.[id_tt]
           ,d_upd.[id_tov]
           ,d_upd.[post]
           ,d_upd.[digust]
           ,d_upd.[spisanie]
           ,d_upd.[spisanie_kach]
           ,d_upd.[boi]
           ,d_upd.[spisanie_dost]
           ,d_upd.[akcia]
           ,0 [akcia_sms]
           ,d_upd.[discount50]
           ,d_upd.[discount50_qty]
           ,0 [discount50_sms]
           ,0 [discount50_sms_qty]
           ,d_upd.[razniza]
           ,d_upd.[summa]
           ,d_upd.[quantity]
           ,isnull(pr_format.price ,pr.Price) [price]
           ,getdate() [date_update]
           ,d_upd.[vozvrat_pok]
           ,d_upd.[peremPlus]
           ,d_upd.[peremMinus]
           ,d_upd.[Complect]          
           ,d_upd.[obed]
           ,d_upd.tt_format_dtt
           ,d_upd.[otgruzka_UL]
           ,d_upd.[vozvrat_sum]
           ,d_upd.[otgruzka_UL_sum]
	 from #dtt as d_upd 
		left join vv03..Price_1C_tov as pr with(nolock) 
			on d_upd.id_tov=pr.id_tov
		left join #tt_format_price  as pr_format with(nolock)
		    on  d_upd.date_tt=pr_format.date_pr
			    and d_upd.id_tov=pr_format.id_tov 
				and d_upd.tt_format_dtt=pr_format.tt_format 	 
		left join vv03..DTT as dtt 
			on dtt.date_tt=d_upd.date_tt 
				and dtt.id_tt=d_upd.id_tt 
				and dtt.id_tov=d_upd.id_tov  
	 where dtt.id_tov is null  
 
    
     BREAK

 END TRY
  BEGIN CATCH

		if ERROR_NUMBER()=1205-- вызвала взаимоблокировку ресурсов
		begin
			-- запись в лог факта блокировки
			insert into jobs..Jobs_log ([id_job],[number_step],[duration]) 
			select @id_job , 12, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
			select @getdate = getdate()		
		end
		else
		begin

			insert into jobs..error_jobs
			(job_name , message , number_step , id_job)
			select @job_name , ERROR_MESSAGE() , 12 , @id_job

			-- прочая ошибка - выход  
			 BREAK
		 end

  END CATCH 
end -- while 
        
insert into jobs..Jobs_log ([id_job],[number_step],[duration]) select @id_job , 40, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
select @getdate = getdate() 





---изменение DTT----


while 1=1
begin
 begin try	
	update vv03..DT with(rowlock) set post_sum = isnull(dt.post_sum,0)+d_upd.post_sum
	,Degust_sum=isnull(dt.degust_sum,0)+d_upd.degust_sum
	,spisanie_sum=isnull(dt.spisanie_sum,0)+d_upd.spisanie_sum
	,spisanie_kach_sum=isnull(dt.spisanie_kach_sum,0)+d_upd.spisanie_kach_sum
	,boi_sum=isnull(dt.boi_sum,0)+d_upd.boi_sum
	,spisanie_dost_sum=isnull(dt.spisanie_dost_sum,0)+d_upd.spisanie_dost_sum
	,akcia_sum=isnull(dt.akcia_sum,0)+d_upd.akcia_sum
	,discount50_sum=isnull(dt.Discount50_sum,0)+d_upd.discount50_sum
	,razniza_sum=isnull(dt.razniza_sum,0)+d_upd.razniza_sum
	,summa=isnull(dt.summa,0)+d_upd.summa
	,vozvrat_sum=isnull(dt.vozvrat_sum,0)+d_upd.vozvrat_sum
	,peremPlus_sum=isnull(dt.peremPlus_sum,0)+d_upd.peremPlus_sum
	,peremMinus_sum=isnull(dt.peremMinus_sum,0)+d_upd.peremMinus_sum
	,obed_sum=isnull(dt.obed_sum,0)+d_upd.obed_sum
	,date_update = GETDATE()
	,otgruzka_UL_sum=ISNULL(dt.otgruzka_UL_sum,0)+d_upd.otgruzka_UL_sum 
	--select *
	from vv03..DT as dt 
		inner join #dt as d_upd  
			on  dt.date_tt=d_upd.date_tt 
				and dt.id_tt=d_upd.id_tt  
    BREAK

 END TRY
  BEGIN CATCH

		if ERROR_NUMBER()=1205-- вызвала взаимоблокировку ресурсов
		begin
			-- запись в лог факта блокировки
			insert into jobs..Jobs_log ([id_job],[number_step],[duration]) 
			select @id_job , 41, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
			select @getdate = getdate()		
		end
		else
		begin

			insert into jobs..error_jobs
			(job_name , message , number_step , id_job)
			select @job_name , ERROR_MESSAGE() , 41 , @id_job

			-- прочая ошибка - выход  
			BREAK
		 end

  END CATCH 
end -- while      

insert into jobs..Jobs_log ([id_job],[number_step],[duration]) select @id_job , 50, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
select @getdate = getdate() 		

--вставка----


while 1=1
begin
 begin try
	INSERT INTO vv03.[dbo].[DT]
           ([Date_tt]
           ,[id_group]
           ,[id_tt]
           ,[Post_sum]
           ,[Degust_sum]
           ,[Spisanie_sum]
           ,[Spisanie_kach_sum]
           ,[Spisanie_dost_sum]
           ,[Boi_sum]
           ,[Akcia_sum]
           ,[Discount50_sum]
           ,[razniza_sum]
           ,[Vozvrat_sum]
           ,[PeremPlus_sum]
           ,[PeremMinus_sum]
           ,[Obed_sum]
           ,[Summa]
           ,[date_update]
           ,tt_format_dt
           ,[Otgruzka_UL_sum] )
	 select d_upd.[date_tt]
           ,d_upd.[id_group]
           ,d_upd.[id_tt]
           ,isnull(d_upd.[post_sum],0)
           ,isnull(d_upd.[degust_sum],0)
           ,isnull(d_upd.[spisanie_sum],0)
           ,isnull(d_upd.[spisanie_kach_sum],0)
           ,isnull(d_upd.[spisanie_dost_sum],0)
           ,isnull(d_upd.[boi_sum],0)
           ,isnull(d_upd.[akcia_sum],0)
           ,isnull(d_upd.[discount50_sum],0)
           ,isnull(d_upd.[razniza_sum],0)
           ,isnull(d_upd.[vozvrat_sum],0)
           ,isnull(d_upd.[peremPlus_sum],0)
           ,isnull(d_upd.[peremMinus_sum],0)
           ,isnull(d_upd.[obed_sum],0)
           ,isnull(d_upd.[summa],0)
           ,getdate() [date_update]
           ,d_upd.tt_format
           ,ISNULL(d_upd.otgruzka_UL_sum,0)
	 from #dt as d_upd 
		left join vv03..DT as dt 
			on  dt.date_tt=d_upd.date_tt 
				and dt.id_tt=d_upd.id_tt 
	 where dt.id_tt is null  
 
    
     BREAK

 END TRY
  BEGIN CATCH

		if ERROR_NUMBER()=1205-- вызвала взаимоблокировку ресурсов
		begin
			-- запись в лог факта блокировки
			insert into jobs..Jobs_log ([id_job],[number_step],[duration]) 
			select @id_job , 51, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
			select @getdate = getdate()		
		end
		else
		begin

			insert into jobs..error_jobs(job_name , message , number_step , id_job)
			select @job_name , ERROR_MESSAGE() , 51 , @id_job

			-- прочая ошибка - выход  
			 BREAK
		 end

  END CATCH 
end -- while 
        
insert into jobs..Jobs_log ([id_job],[number_step],[duration]) select @id_job , 60, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
select @getdate = getdate() 



--Declare @temp_table as nchar(36) ,  @strТекстSQLЗапроса as nvarchar(4000)

		
---------почистим буферную таблицу--------------------------------
select @temp_table= replace(convert(char(36),NEWID()) , '-' , '_')
  
SET @strТекстSQLЗапроса =  'select *   into Temp_tables..[' + @temp_table + '] ' +  'from #inserted'
EXEC sp_executeSQL @strТекстSQLЗапроса
  
SET @strТекстSQLЗапроса = '
  EXEC( ''select * into Temp_tables.dbo.[' + @temp_table + ']  from [SRV-SQL03].Temp_tables.dbo.[' + @temp_table + '] '') at [SRV-SQL01]'
EXEC sp_executeSQL @strТекстSQLЗапроса



while 1=1
begin
 begin try
	SET @strТекстSQLЗапроса = '
	 EXEC('' 
		delete from jobs..Recalc_DTT_SRV_SQL01
		from jobs..Recalc_DTT_SRV_SQL01 as dtt inner join Temp_tables.dbo.[' + @temp_table + '] i on dtt.id=i.id 
		 '') at [SRV-SQL01]	' 
	exec sp_executeSQL @strТекстSQLЗапроса		  
    BREAK

 END TRY
  BEGIN CATCH

		if ERROR_NUMBER()=1205-- вызвала взаимоблокировку ресурсов
		begin
			-- запись в лог факта блокировки
			insert into jobs..Jobs_log ([id_job],[number_step],[duration]) 
			select @id_job , 13, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
			select @getdate = getdate()		
		end
		else
		begin

			insert into jobs..error_jobs
			(job_name , message , number_step , id_job)
			select @job_name , ERROR_MESSAGE() , 13 , @id_job

			-- прочая ошибка - выход  
			 BREAK
		 end

  END CATCH 
end -- while 

			
SET @strТекстSQLЗапроса =
  'drop table Temp_tables..[' + @temp_table + ']
   EXEC( ''drop table Temp_tables.dbo.[' + @temp_table + ']'') at [SRV-SQL01]  '
EXEC sp_executeSQL @strТекстSQLЗапроса

if OBJECT_ID('tempdb..#tt_format_price') is not null drop table #tt_format_price
if OBJECT_ID('tempdb..#dtt') is not null drop table #dtt
if OBJECT_ID('tempdb..#dt') is not null drop table #dt
drop table #inserted
END
GO