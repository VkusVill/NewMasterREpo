SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Update_DTT_data_03_del] 
	-- Add the parameters for the stored procedure here
@id_job		as int,
@id_tt as int,
@days		as int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
--id_job	job_name	working_job	date_add	date_take	date_exc	type_exec	prefix_job	number_1	number_2	number_3	job_init	threads
--134724023	Reports..Update_DTT_data                          	20	2016-02-14 18:02:56.583	2016-02-14 18:03:11.023	2016-02-14 18:03:11.337	1	271                                 	774	NULL	NULL	NULL	NULL

--declare @id_tt as int=10823  , @days as int =657 ,@id_job int =2 

create table #date_max (date_max date)

declare @Proect as int,
		@date as date = DATEADD(day,@days,{d'2014-01-01'}),
		@getdate as datetime = GETDATE(),
		@id_group as int

declare @ShopNo as int=0
DECLARE	@strТекстSQLЗапроса	nvarchar(max) -- , @ParmDefinition nvarchar(max)

 --определим группу 

--declare @date date = {d'2016-07-01'} , @id_tt int = 333 , @strТекстSQLЗапроса nvarchar(max) , @id_group int

select @id_group=gr.id_gr from [vv03].[dbo].[tt_date_id_gr] gr 
where [date]=@date and gr.id_TT=@id_tt




IF (@id_group is null)		
	
	SELECT @id_group=tt.id_group
		FROM vv03..tt (nolock) where tt.id_TT=@id_tt



select @ShopNo = tt.N,@Proect= tt.tt_format
FROM vv03..tt (nolock) where tt.id_TT= @id_tt

		
declare @date_max date



set @strТекстSQLЗапроса =  
'insert into #date_max 
exec 
( ''select dateadd(day,master.dbo.maxz(datediff(day,''''20140101'''',DATEADD(day,-122, GETDATE()))
, datediff(day,''''20140101'''', min(date_ch))),''''20140101'''') date_max from SMS_UNION..Checkline as cl with(nolock)
'') at [SRV-SQL01] 
'
exec sp_executeSQl @strТекстSQLЗапроса 
Select @date_max = dateadd(day,1,date_max) from #date_max

--set @strТекстSQLЗапроса = ' SET XACT_ABORT ON ; select @date_max = dateadd(day,master.dbo.maxz(datediff(day,''20140101'',DATEADD(day,-122, GETDATE()))
--, datediff(day,''20140101'', min(date_ch))),''20140101'') from SMS_UNION..Checkline as cl with(nolock) '
--exec [SRV-SQL01].master.dbo.sp_executeSQl @strТекстSQLЗапроса ,N'@date_max date output',@date_max=@date_max output; 
				
--select @id_group,@ShopNo, @date_max

if @Proect=2 and @date<@date_max
 return

delete from #date_max
set @strТекстSQLЗапроса =  
'insert into #date_max 
exec 
( ''select  dateadd(day,master.dbo.maxz(datediff(day,''''20140101'''',DATEADD(day,-122, GETDATE()))
, datediff(day,''''20140101'''', min(date_ch))),''''20140101'''') date_max  from SMS_izbenka..Checkline as cl with(nolock) 
'') at [SRV-SQL01] 
'
exec sp_executeSQl @strТекстSQLЗапроса 
Select @date_max = dateadd(day,1,date_max) from #date_max
drop table #date_max
--set @strТекстSQLЗапроса = 'SET XACT_ABORT ON ; select @date_max = dateadd(day,master.dbo.maxz(datediff(day,''20140101'',DATEADD(day,-122, GETDATE()))
--, datediff(day,''20140101'', min(date_ch))),''20140101'') from SMS_izbenka..Checkline as cl with(nolock) '
--exec [SRV-SQL01].master.dbo.sp_executeSQl @strТекстSQLЗапроса ,N'@date_max date output',@date_max=@date_max output; 

	
if @Proect=1 and @date< @date_max
 return
--select @id_group,@ShopNo, @date_max
 
  
insert into jobs..Jobs_log ([id_job],[number_step],[duration]) select @id_job , 10, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
select @getdate = getdate() 

  
  SELECT TOP 0 [date_tt]
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
      ,[vozvrat_pok]
	  ,[peremPlus] 
	  ,[peremMinus] 
      ,[summa]
      ,[quantity]
      ,[price]
      ,[complect]
      ,[date_update]
  INTO #dtt
  FROM [vv03].[dbo].[DTT] (nolock)



IF @Proect=2
BEGIN  --ВВ
  

/*
c 2015-11-04 Размер скидки будет зависеть от розничной цены товара:
До 300 руб - 50% скидка
От 300 до 500 руб - 40%
От 500 руб до 700 руб- 30%
Свыше 700 руб - 20%.
case when ISNULL(green_price,0) =1 then cl.Quantity * cl.znak else 0 end) 
*/
if @date<{d'2015-11-04'}
  begin
  set @strТекстSQLЗапроса = '


  INSERT INTO #dtt
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
	  ,[vozvrat_pok]      
	  ,[peremPlus] 
	  ,[peremMinus] 
      ,[summa]
      ,[quantity]
      ,[price]
      ,[complect]
      ,[date_update])
    exec (''
    SET XACT_ABORT ON ;
    SELECT
    ''''' + RTRIM(@date) + ''''' as date_tt
    ,' + RTRIM(@id_group) + ' as id_group
    ,' + RTRIM(@id_tt) + ' as id_tt
	,ISNULL(cl.id_tov_cl,0) as id_tov
	,0 as post
	,0 as digust
	,0 as spisanie
	,0 as spisanie_kach
	,0 as boi
	,0 as spisanie_dost
	,convert(real,sum(case when(cl.BaseSum =0 or cl.baseprice= 0.01) and ISNULL(cl.id_sms_tovar,0)=0 then (cl.Quantity * cl.znak) else 0 end )) as akcia
	,convert(real,sum(case when (cl.BaseSum =0 or cl.baseprice= 0.01) and ISNULL(cl.id_sms_tovar,0)<>0 then (cl.Quantity * cl.znak) else 0 end)) as akcia_sms
	,convert(real,sum(case when ABS (case when (cl.date_ch>{d''''2015-03-06''''}) then (cl.Price_retail  - cl.BasePrice * 2 )
										else (cl.BasePrice * cl.Quantity - cl.BaseSum * 2) end) <=1  and cl.BasePrice<>1 and cl.basesum<>0 and isnull(cl.id_sms_tovar,0)=0 then cl.BaseSum * cl.znak else 0 end)) as discount50		
	,convert(real,sum(case when ABS (case when  (cl.date_ch>{d''''2015-03-06''''})  then (cl.Price_retail  - cl.BasePrice * 2 )
										else (cl.BasePrice * cl.Quantity - cl.BaseSum * 2) end) <=1  and cl.BasePrice<>1 and cl.basesum<>0 and isnull(cl.id_sms_tovar,0)=0 then cl.Quantity * cl.znak else 0 end)) as discount50_qty 
	,convert(real,sum(case when ABS (case when  (cl.date_ch>{d''''2015-03-06''''})  then (cl.Price_retail  - cl.BasePrice * 2 )
										else (cl.BasePrice * cl.Quantity - cl.BaseSum * 2) end) <=1  and cl.BasePrice<>1 and cl.basesum<>0 and isnull(cl.id_sms_tovar,0)<>0 then cl.BaseSum * cl.znak else 0 end)) as discount50_sms		
	,convert(real,sum(case when ABS (case when  (cl.date_ch>{d''''2015-03-06''''}) then (cl.Price_retail  - cl.BasePrice * 2 )
										else (cl.BasePrice * cl.Quantity - cl.BaseSum * 2) end) <=1  and cl.BasePrice<>1 and cl.basesum<>0 and isnull(cl.id_sms_tovar,0)<>0 then cl.Quantity * cl.znak else 0 end)) as discount50_sms_qty 
	,0 as razniza
	,0 as  vozvrat_pok
	,0 as peremPlus
	,0 as peremMinus
	,convert(real,sum(case when cl.BasePrice<>0.01 AND (cl.BaseSum<>0)  then cl.BaseSum else 0 end  * cl.znak)) as summa
	,convert(real,sum(case when cl.BasePrice<>0.01 AND (cl.BaseSum<>0)  then cl.Quantity else 0 end  * cl.znak)) as Quantity
	,CONVERT(real,min( case when cl.date_ch>{d''''2015-03-06''''} then ISNULL(cl.price_retail,0)  else isnull(cl.BasePrice,0) end) ) Price
	,0 as complect
	,getdate() date_update
	FROM SMS_UNION.dbo.CheckLine cl with (index(IX_CheckLine_3), nolock) 
	WHERE cl.date_ch={d''''' + RTRIM(@date) + '''''} and cl.id_tt_cl =' + RTRIM(@id_tt) + ' and isnull(cl.id_tt_cl,0) not in (0,18099) 

	GROUP BY  cl.id_tov_cl
	'') at [SRV-SQL01] 
	'
  end
else
begin  
set @strТекстSQLЗапроса = '



    INSERT INTO #dtt
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
	  ,[vozvrat_pok]      
	  ,[peremPlus] 
	  ,[peremMinus] 
      ,[summa]
      ,[quantity]
      ,[price]
      ,[complect]
      ,[date_update])
    exec (''
    SET XACT_ABORT ON ;
    SELECT
    ''''' + RTRIM(@date) + ''''' as date_tt
    ,' + RTRIM(@id_group) + ' as id_group
    ,' + RTRIM(@id_tt) + ' as id_tt
	,ISNULL(cl.id_tov_cl,0) as id_tov
	,0 as post
	,0 as digust
	,0 as spisanie
	,0 as spisanie_kach
	,0 as boi
	,0 as spisanie_dost
	,convert(real,sum(case when (cl.BaseSum =0 or cl.baseprice= 0.01) and ISNULL(cl.id_sms_tovar,0)=0 then (cl.Quantity * cl.znak) else 0 end )) as akcia
	,convert(real,sum(case when (cl.BaseSum =0 or cl.baseprice= 0.01) and ISNULL(cl.id_sms_tovar,0)<>0 then (cl.Quantity * cl.znak) else 0 end)) as akcia_sms
	,convert(real,sum(case when cl.BasePrice in (1,0.01)  or cl.basesum=0 or isnull(cl.id_sms_tovar,0)<>0 then 0
		 else( case when ISNULL(green_price,0) =1 then cl.BaseSum * cl.znak else 0 end) end)) as discount50
		 
	,convert(real,sum(case when cl.BasePrice in (1,0.01) or cl.basesum=0 or isnull(cl.id_sms_tovar,0)<>0 then 0
			 else(case when ISNULL(green_price,0) =1 then cl.Quantity * cl.znak else 0 end) end)) as discount50_qty							


	,convert(real,sum(case when cl.BasePrice in (1,0.01) or cl.basesum=0 or isnull(cl.id_sms_tovar,0)=0 then 0
	 else( case when ISNULL(green_price,0) =1 then cl.BaseSum * cl.znak else 0 end)	end)) as discount50_sms
	 
	,convert(real,sum(case when cl.BasePrice in (1,0.01) or cl.basesum=0 or isnull(cl.id_sms_tovar,0)=0 then 0
		 else( case when ISNULL(green_price,0) =1 then cl.Quantity * cl.znak else 0 end)  
								end)) as discount50_sms_qty		
	,0 as razniza
	,0 as  vozvrat_pok
	,0 as peremPlus
	,0 as peremMinus
	,convert(real,sum(case when cl.BasePrice<>0.01 AND (cl.BaseSum<>0)  then cl.BaseSum else 0 end  * cl.znak)) as summa
	,convert(real,sum(case when cl.BasePrice<>0.01 AND (cl.BaseSum<>0)  then cl.Quantity else 0 end  * cl.znak)) as Quantity
	,CONVERT(real,min( ISNULL(cl.price_retail,0) ) ) Price
	,0 as complect
	,getdate() date_update
	FROM SMS_UNION.dbo.CheckLine cl with (index(IX_CheckLine_3), nolock) 
	WHERE cl.date_ch={d''''' + RTRIM(@date) + '''''} and cl.id_tt_cl =' + RTRIM(@id_tt) + ' and isnull(cl.id_tt_cl,0) not in (0,18099) 
	GROUP BY  cl.id_tov_cl
	'') at [SRV-SQL01] 
	'
	end	
exec sp_executeSQL @strТекстSQLЗапроса	

--print @strТекстSQLЗапроса	

insert into jobs..Jobs_log ([id_job],[number_step],[duration]) select @id_job , 20, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
select @getdate = getdate() 


--select * from #dtt

create table #spisania(id_tt int ,id_tov int, post decimal(15,3) null default 0
	, spisanie decimal(15,3) null default 0
	, spisanie_kach decimal(15,3) null default 0
	, digust decimal(15,3) null default 0
	, boi decimal(15,3) null default 0
	, spisanie_dost decimal(15,3) null default 0
	, vozvrat_pok decimal(15,3) null default 0
	, razniza decimal(15,3) null default 0
	, peremPlus decimal(15,3) null default 0
	, peremMinus decimal(15,3) null default 0
	, complect decimal(15,3) null default 0)

  

set @strТекстSQLЗапроса = '   


   INSERT INTO #spisania
		(id_tt, id_tov, post,spisanie,spisanie_kach,digust,boi,spisanie_dost,vozvrat_pok,razniza,peremMinus,peremPlus,complect)
   
   exec ( ''
   SET XACT_ABORT ON ;
    select ' + RTRIM(@id_tt) + ', td.id_tov
		,sum(case when td.operation_type in (400,401) then td.Quantity*znak else 0 end ) Post
		,-sum(case when td.operation_type in (102,112) then td.Quantity*znak else 0 end ) spisanie 
		,-sum(case when td.operation_type in (103,113) then td.Quantity*znak else 0 end ) spisanie_kach 
		,-sum(case when td.operation_type in (101,111) then td.Quantity*znak else 0 end ) digust 
   		,-sum(case when td.operation_type in (104,114) then td.Quantity*znak else 0 end ) boi 
		,-sum(case when td.operation_type in (105,115) then td.Quantity*znak else 0 end ) spisanie_dost
		,sum(case when td.operation_type in (201,211) then case when td.operation_type in (201) then 1 else -1 end*td.Quantity else 0 end ) vozvrat_pok 
		,sum(case when td.operation_type in (500,501,510,520,521) then td.Quantity*znak else 0 end ) razniza 
		,-sum(case when td.operation_type in (411) then td.Quantity*znak else 0 end ) peremMinus 
		,sum(case when td.operation_type in (410) then td.Quantity*znak else 0 end ) peremPlus 
		,sum(case when td.operation_type in (106,116) then td.Quantity*znak else 0 end ) complect 
   from SMS_REPL..TD_move as td with(nolock) inner join SMS_REPL..Types_Operation as t_o with(nolock)
		on td.operation_type=t_o.code_operation and t_o.table_operation=''''td_move'''' and t_o.field_operation=''''Operation_type_orig''''
		
   where td.ShopNo_rep=' + RTRIM(@ShopNo) + ' and CONVERT(date,closedate)={d''''' + RTRIM(@date) + '''''} and Confirm_type in (0,1)	and td.ShopNo_rep<>999	
    and   closedate<> CONVERT(date,closedate) 	 
   group by td.id_tov'') at [SRV-SQL01] '

  exec sp_executeSQL @strТекстSQLЗапроса	

set @strТекстSQLЗапроса = '   
   
   SET XACT_ABORT ON ;
   
   INSERT INTO #spisania
		(id_tt, id_tov, post,spisanie,spisanie_kach,digust,boi,spisanie_dost,vozvrat_pok,razniza,peremMinus,peremPlus,complect)
   exec ( ''select ' + RTRIM(@id_tt) + ', td.id_tov
		,sum(case when td.operation_type in (400,401) then td.Quantity*znak else 0 end ) Post
		,-sum(case when td.operation_type in (102,112) then td.Quantity*znak else 0 end ) spisanie 
		,-sum(case when td.operation_type in (103,113) then td.Quantity*znak else 0 end ) spisanie_kach 
		,-sum(case when td.operation_type in (101,111) then td.Quantity*znak else 0 end ) digust 
   		,-sum(case when td.operation_type in (104,114) then td.Quantity*znak else 0 end ) boi 
		,-sum(case when td.operation_type in (105,115) then td.Quantity*znak else 0 end ) spisanie_dost
		,sum(case when td.operation_type in (201,211) then case when td.operation_type in (201) then 1 else -1 end*td.Quantity else 0 end ) vozvrat_pok 
		,sum(case when td.operation_type in (500,501,510,520,521) then td.Quantity*znak else 0 end ) razniza 
		,-sum(case when td.operation_type in (411) then td.Quantity*znak else 0 end ) peremMinus 
		,sum(case when td.operation_type in (410) then td.Quantity*znak else 0 end ) peremPlus 
		,sum(case when td.operation_type in (106,116) then td.Quantity*znak else 0 end ) complect
   from SMS_IZBENKA_ARC..smsreplTD_move as td with(nolock) inner join SMS_REPL..Types_Operation as t_o with(nolock)
		on td.operation_type=t_o.code_operation and t_o.table_operation=''''td_move'''' and t_o.field_operation=''''Operation_type_orig''''

   where   td.ShopNo_rep=' + RTRIM(@ShopNo) + ' and CONVERT(date,closedate)  = {d''''' + RTRIM(@date) + '''''} and Confirm_type in (0,1)	and td.ShopNo_rep<>999	 
     and closedate<> CONVERT(date,closedate)
   group by td.id_tov
	'') at [SRV-SQL04] 
	'
	
exec sp_executeSQL @strТекстSQLЗапроса	

--print @strТекстSQLЗапроса

  UPDATE #dtt set post=s.post
					,digust=s.digust
					,spisanie= s.spisanie
					,spisanie_kach= s.spisanie_kach
					,boi = s.boi
					,spisanie_dost = s.spisanie_dost
					,vozvrat_pok = s.vozvrat_pok
					,razniza=s.razniza 
					,peremMinus=s.peremMinus
					,peremPlus=s.peremPlus
					,complect=s.complect
    FROM #dtt d inner join #spisania s ON d.id_tov=s.id_tov and d.id_tt=s.id_tt
    where (s.post<>0 or s.digust<>0 or s.spisanie<>0 or s.spisanie_kach<>0 or s.boi<>0 or s.vozvrat_pok<>0 or s.razniza<>0
    or s.peremMinus<>0 or s.peremPlus<>0 or s.spisanie_dost<>0 or s.complect<>0) 


insert into jobs..Jobs_log ([id_job],[number_step],[duration]) select @id_job , 50, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
select @getdate = getdate() 
				
		
				
    INSERT INTO #dtt
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
	  ,[vozvrat_pok] 
	  ,[peremPlus] 
	  ,[peremMinus] 
      ,[summa]
      ,[quantity]
      ,[price]
      ,[complect]
      ,[date_update])
    SELECT @date,@id_group,@id_tt,s.id_tov, post,digust,spisanie,spisanie_kach,boi,spisanie_dost
			,0,0,0,0,0,0,s.razniza, vozvrat_pok,s.peremPlus,s.peremMinus,0,0,0,s.complect,@getdate
    From #Spisania s inner join ( SELECT id_tov FROM #Spisania 
									EXCEPT
									SELECT id_tov FROM #dtt) a 	ON s.id_tov=a.id_tov
    where (s.post<>0 or s.digust<>0 or s.spisanie<>0 or s.spisanie_kach<>0 or s.boi<>0 or s.vozvrat_pok<>0 or s.razniza<>0
			or s.peremMinus<>0 or s.peremPlus<>0 or s.spisanie_dost<>0 or s.complect<>0)
    
insert into jobs..Jobs_log ([id_job],[number_step],[duration]) select @id_job , 51, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
select @getdate = getdate() 
    
    
	Drop table #Spisania


/**

	if EXISTS(SELECT * FROM #dtt d WHERE ISNULL(d.Price,0)=0)
		BEGIN

			
			select min( case when cl.date_ch>{d'2015-03-06'} then ISNULL(cl.price_retail,0)  else isnull(cl.BasePrice,0) end)  as price
				,cl.id_tov_cl as id_tov
			INTO #PR
			from SMS_UNION..CheckLine (nolock) cl inner join 
				(SELECT * FROM #dtt d WHERE ISNULL(d.Price,0)=0) d on cl.id_tov_cl=d.id_tov 
			where cl.date_ch=@date and cl.id_tt_cl=@id_tt and 
			(case when cl.date_ch>{d'2015-03-06'} 
			then ISNULL(cl.price_retail,0)  else isnull(cl.BasePrice,0) end)<>0 
			group by cl.id_tov_cl


			
			UPDATE #dtt   set Price=pr.Price
			FROM #dtt d inner join #PR pr 
								on  d.id_tov=pr.id_tov 
			WHERE ISNULL(d.Price,0)=0


			drop table #PR
		end

		insert into jobs..Jobs_log ([id_job],[number_step],[duration]) select @id_job , 52, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
		select @getdate = getdate() 
**/	

END
ELSE
BEGIN --Избенка


------


 if @date<{d'2016-02-02'}
 set @strТекстSQLЗапроса = '  
 
 SET XACT_ABORT ON ;
  
      INSERT INTO #dtt
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
      ,[vozvrat_pok]
	  ,[peremPlus] 
	  ,[peremMinus] 
      ,[summa]
      ,[quantity]
      ,[price]
      ,[complect]
      ,[date_update])
	exec ( ''SELECT 
	   {d''''' + RTRIM(@date) + '''''} date_tt
	  ,' + RTRIM(@id_group) + '
	  ,' + RTRIM(@id_tt) + ' id_tt
	  ,ISNULL(id_tov_cl,0) id_tov
	  ,convert(real,sum(Quantity * CASE cl.OperationType_cl WHEN 400 THEN  1 WHEN 401 THEN -1 ELSE 0 END)) AS post
      ,convert(real,sum(Quantity * CASE cl.OperationType_cl WHEN 101 THEN  1 WHEN 111 THEN -1 ELSE 0 END)) AS digust 
      ,convert(real,sum(Quantity * CASE cl.OperationType_cl WHEN 102 THEN  1 WHEN 112 THEN -1 ELSE 0 END)) AS spisanie  
      ,convert(real,sum(Quantity * CASE cl.OperationType_cl WHEN 103 THEN  1 WHEN 113 THEN -1 ELSE 0 END)) AS spisanie_kach
      ,convert(real,sum(Quantity * CASE cl.OperationType_cl WHEN 104 THEN  1 WHEN 114 THEN -1 ELSE 0 END)) AS boi
      
	  
	     ,convert(real,case when {d''''' + RTRIM(@date) + '''''} >{d''''2015-11-13''''}  then sum(Quantity * CASE cl.OperationType_cl WHEN 105 THEN  1 WHEN 115 THEN -1 ELSE 0 END)
					else 0 end) as spisanie_dost
      ,convert(real,sum(cl.Quantity * 
        case when {d''''' + RTRIM(@date) + '''''} >{d''''2015-11-13''''}  then (case when (cl.OperationType_cl in (1, 202,203,3) and (cl.BaseSum =0 or cl.baseprice= 0.01)) then 1 else 0 end)
         else (CASE WHEN cl.OperationType_cl in (115) and ISNULL(cl.id_sms_tovar,0)=0 then -1
										   WHEN (((cl.OperationType_cl in (105)) or (cl.OperationType_cl in (1, 202,203,3) and (cl.BaseSum =0 or cl.baseprice= 0.01))) 
												 and ISNULL(cl.id_sms_tovar,0)=0) then 1 else  0 end) end )) akcia
	  ,convert(real,sum(cl.Quantity * 
	    case when {d''''' + RTRIM(@date) + '''''} >{d''''2015-11-13''''}  then case when (cl.OperationType_cl in (1, 202,203,3) and(cl.BaseSum =0 or baseprice= 0.01))
												and ISNULL(cl.id_sms_tovar,0)<>0 then 1 else  0 end
	    else (CASE WHEN cl.OperationType_cl in (115) and ISNULL(cl.id_sms_tovar,0)<>0 then -1
										   WHEN (((cl.OperationType_cl in (105)) or (cl.OperationType_cl in (1, 202,203,3) and (cl.BaseSum =0 or cl.baseprice= 0.01))) 
												and ISNULL(cl.id_sms_tovar,0)<>0) then 1 else  0 end)end)) akcia_sms 

	  
	  ,convert(real,sum(BaseSum * CASE WHEN cl.OperationType_cl IN (1, 202, 203, 3)
		and ABS (cl.BasePrice * cl.Quantity - BaseSum * 2) <=1 and cl.BasePrice not in (1,0.01) and cl.BaseSum<>0  and ISNULL(cl.id_sms_tovar,0)=0 THEN  1  ELSE 0 END)) AS Discount50

	  
	  ,convert(real,sum(Quantity * CASE WHEN cl.OperationType_cl IN (1, 202, 203, 3)  AND 
		ABS (cl.BasePrice * cl.Quantity - BaseSum * 2) <=1  and cl.BasePrice not in (1,0.01) and cl.BaseSum <> 0 and ISNULL(cl.id_sms_tovar,0)=0 THEN  1 ELSE 0 END)) AS Discount50_qty 


	  ,convert(real,sum(BaseSum * CASE WHEN cl.OperationType_cl IN (1, 202, 203, 3)
		and ABS (cl.BasePrice * cl.Quantity - BaseSum * 2)  <=1  and cl.BasePrice not in (1,0.01) and cl.BaseSum<>0  and ISNULL(cl.id_sms_tovar,0)<>0 THEN  1  ELSE 0 END)) AS Discount50_sms

	  
	  ,convert(real,sum(Quantity * CASE WHEN cl.OperationType_cl IN (1, 202, 203, 3)  AND 
		ABS (cl.BasePrice * cl.Quantity - BaseSum * 2)  <=1  and cl.BasePrice not in (1,0.01) and cl.BaseSum <> 0 and ISNULL(cl.id_sms_tovar,0)<>0 THEN  1 ELSE 0 END)) AS Discount50_sms_qty 

	  ,CONVERT(real,sum(Quantity * CASE WHEN cl.OperationType_cl IN (500, 510,520) THEN 1 
                WHEN cl.OperationType_cl IN (501,521) THEN  -1 ELSE 0 END)) AS razniza	

		,CONVERT(real,sum(Quantity * CASE WHEN cl.OperationType_cl IN (201,211) THEN -1 ELSE 0 END)) as vozvrat_pok 
		,CONVERT(real,sum(Quantity * CASE WHEN cl.OperationType_cl IN (410) THEN 1 ELSE 0 END)) as peremPlus
		,CONVERT(real,sum(Quantity * CASE WHEN cl.OperationType_cl IN (411) THEN 1 ELSE 0 END)) as peremMinus
		,convert(real,sum(case when {d''''' + RTRIM(@date) + '''''} <{d''''2014-10-30''''} then (CASE WHEN cl.OperationType_cl in (1, 202,203,3,201,211) AND cl.BasePrice<>0.01 AND cl.BaseSum <> 0 then cl.BaseSum else 0 end)
														   else (CASE WHEN cl.OperationType_cl in (1, 202,203,3)  AND cl.BasePrice<>0.01 AND cl.BaseSum <> 0 then cl.BaseSum else 0 end) end)) summa
		,convert(real,sum(Quantity * case when {d''''' + RTRIM(@date) + '''''} <{d''''2014-10-30''''} then (CASE WHEN ((cl.OperationType_cl IN (1, 202, 203, 3,201) AND cl.BasePrice<>0.01 AND cl.BaseSum <> 0) ) or (cl.operationType_cl=211) THEN 1 ELSE 0 END)
																	  else (CASE WHEN (cl.OperationType_cl IN (1, 202, 203, 3) AND cl.BasePrice<>0.01 AND cl.BaseSum <> 0) THEN 1 ELSE 0 END) end)) AS quantity 

 
 	  ,CONVERT(real,max(cl.basePrice)) Price
 	  ,0 as complect
	  ,getdate() date_update
	  FROM [SMS_IZBENKA]..[CheckLine] cl with (index (ind2), nolock  ) 
	  where cl.date_ch =  {d''''' + RTRIM(@date) + '''''} and cl.id_tt_cl=' + RTRIM(@id_tt) + ' and (OperationType_cl > 0)and isnull(cl.id_tt_cl,0)<>0 
	    group by cl.id_tov_cl  	    
	'') at [SRV-SQL01] 
	'
	  
else if @date={d'2016-02-02'}
 set @strТекстSQLЗапроса = '  
 
 SET XACT_ABORT ON ;
  
      INSERT INTO #dtt
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
      ,[vozvrat_pok]
	  ,[peremPlus] 
	  ,[peremMinus] 
      ,[summa]
      ,[quantity]
      ,[price]
      ,[complect]
      ,[date_update])
	  exec ( ''SELECT 
	   {d''''' + RTRIM(@date) + '''''} date_tt
	  ,' + RTRIM(@id_group) + '
	  ,' + RTRIM(@id_tt) + ' id_tt
	  ,ISNULL(id_tov_cl,0) id_tov
	  ,convert(real,sum(Quantity * CASE cl.OperationType_cl WHEN 400 THEN  1 WHEN 401 THEN -1 ELSE 0 END)) AS post
      ,convert(real,sum(Quantity * CASE cl.OperationType_cl WHEN 101 THEN  1 WHEN 111 THEN -1 ELSE 0 END)) AS digust 
      ,convert(real,sum(Quantity * CASE cl.OperationType_cl WHEN 102 THEN  1 WHEN 112 THEN -1 ELSE 0 END)) AS spisanie  
      ,convert(real,sum(Quantity * CASE cl.OperationType_cl WHEN 103 THEN  1 WHEN 113 THEN -1 ELSE 0 END)) AS spisanie_kach
      ,convert(real,sum(Quantity * CASE cl.OperationType_cl WHEN 104 THEN  1 WHEN 114 THEN -1 ELSE 0 END)) AS boi
      
	  
	     ,convert(real,case when {d''''' + RTRIM(@date) + '''''} >{d''''2015-11-13''''} then sum(Quantity * CASE cl.OperationType_cl WHEN 105 THEN  1 WHEN 115 THEN -1 ELSE 0 END)
					else 0 end) as spisanie_dost
      ,convert(real,sum(cl.Quantity * 
        case when {d''''' + RTRIM(@date) + '''''} >{d''''2015-11-13''''} then (case when (cl.OperationType_cl in (1, 202,203,3) and (cl.BaseSum =0 or cl.baseprice= 0.01)) then 1 else 0 end)
         else (CASE WHEN cl.OperationType_cl in (115) and ISNULL(cl.id_sms_tovar,0)=0 then -1
										   WHEN (((cl.OperationType_cl in (105)) or (cl.OperationType_cl in (1, 202,203,3) and (cl.BaseSum =0 or cl.baseprice= 0.01))) 
												 and ISNULL(cl.id_sms_tovar,0)=0) then 1 else  0 end) end )) akcia
	  ,convert(real,sum(cl.Quantity * 
	    case when {d''''' + RTRIM(@date) + '''''} >{d''''2015-11-13''''} then case when (cl.OperationType_cl in (1, 202,203,3) and(cl.BaseSum =0 or baseprice= 0.01))
												and ISNULL(cl.id_sms_tovar,0)<>0 then 1 else  0 end
	    else (CASE WHEN cl.OperationType_cl in (115) and ISNULL(cl.id_sms_tovar,0)<>0 then -1
										   WHEN (((cl.OperationType_cl in (105)) or (cl.OperationType_cl in (1, 202,203,3) and (cl.BaseSum =0 or cl.baseprice= 0.01))) 
												and ISNULL(cl.id_sms_tovar,0)<>0) then 1 else  0 end)end)) akcia_sms 

	  
	  ,convert(real,sum(BaseSum * CASE WHEN cl.OperationType_cl IN (1, 202, 203, 3)
		and 		(ABS (cl.BasePrice * cl.Quantity - BaseSum * 2) <=1 or (ABS (cl.BasePrice * cl.Quantity - BaseSum /0.6) <=1))  
		 and cl.BasePrice not in (1,0.01) and cl.BaseSum<>0  and ISNULL(cl.id_sms_tovar,0)=0 THEN  1  ELSE 0 END)) AS Discount50

	  
	  ,convert(real,sum(Quantity * CASE WHEN cl.OperationType_cl IN (1, 202, 203, 3)  AND 
		(ABS (cl.BasePrice * cl.Quantity - BaseSum * 2) <=1 or (ABS (cl.BasePrice * cl.Quantity - BaseSum /0.6) <=1))  
		and cl.BasePrice not in (1,0.01) and cl.BaseSum <> 0 and ISNULL(cl.id_sms_tovar,0)=0 THEN  1 ELSE 0 END)) AS Discount50_qty 


	  ,convert(real,sum(BaseSum * CASE WHEN cl.OperationType_cl IN (1, 202, 203, 3)
		and 		(ABS (cl.BasePrice * cl.Quantity - BaseSum * 2) <=1 or (ABS (cl.BasePrice * cl.Quantity - BaseSum /0.6) <=1))  
		and cl.BasePrice not in (1,0.01) and cl.BaseSum<>0  and ISNULL(cl.id_sms_tovar,0)<>0 THEN  1  ELSE 0 END)) AS Discount50_sms

	  
	  ,convert(real,sum(Quantity * CASE WHEN cl.OperationType_cl IN (1, 202, 203, 3)  AND 
		(ABS (cl.BasePrice * cl.Quantity - BaseSum * 2) <=1 or (ABS (cl.BasePrice * cl.Quantity - BaseSum /0.6) <=1))  
		and cl.BasePrice not in (1,0.01) and cl.BaseSum <> 0 and ISNULL(cl.id_sms_tovar,0)<>0 THEN  1 ELSE 0 END)) AS Discount50_sms_qty 

	  ,CONVERT(real,sum(Quantity * CASE WHEN cl.OperationType_cl IN (500, 510,520) THEN 1 
                WHEN cl.OperationType_cl IN (501,521) THEN  -1 ELSE 0 END)) AS razniza	

		,CONVERT(real,sum(Quantity * CASE WHEN cl.OperationType_cl IN (201,211) THEN -1 ELSE 0 END)) as vozvrat_pok 
		,CONVERT(real,sum(Quantity * CASE WHEN cl.OperationType_cl IN (410) THEN 1 ELSE 0 END)) as peremPlus
		,CONVERT(real,sum(Quantity * CASE WHEN cl.OperationType_cl IN (411) THEN 1 ELSE 0 END)) as peremMinus
		,convert(real,sum(case when {d''''' + RTRIM(@date) + '''''} <{d''''2014-10-30''''} then (CASE WHEN cl.OperationType_cl in (1, 202,203,3,201,211) AND cl.BasePrice<>0.01 AND cl.BaseSum <> 0 then cl.BaseSum else 0 end)
														   else (CASE WHEN cl.OperationType_cl in (1, 202,203,3)  AND cl.BasePrice<>0.01 AND cl.BaseSum <> 0 then cl.BaseSum else 0 end) end)) summa
		,convert(real,sum(Quantity * case when {d''''' + RTRIM(@date) + '''''} <{d''''2014-10-30''''} then (CASE WHEN ((cl.OperationType_cl IN (1, 202, 203, 3,201) AND cl.BasePrice<>0.01 AND cl.BaseSum <> 0) ) or (cl.operationType_cl=211) THEN 1 ELSE 0 END)
																	  else (CASE WHEN (cl.OperationType_cl IN (1, 202, 203, 3) AND cl.BasePrice<>0.01 AND cl.BaseSum <> 0) THEN 1 ELSE 0 END) end)) AS quantity 


 	  ,CONVERT(real,max(cl.basePrice)) Price
 	  ,0 as complect
	  ,getdate() date_update
	  FROM [SMS_IZBENKA]..[CheckLine] cl with (index (ind2), nolock  ) 
	  where cl.date_ch =  {d''''' + RTRIM(@date) + '''''} and cl.id_tt_cl=' + RTRIM(@id_tt) + ' and (OperationType_cl > 0)and isnull(cl.id_tt_cl,0)<>0 
	   group by cl.id_tov_cl  	    
	'') at [SRV-SQL01] 
	'
	  
else if @date>{d'2016-02-02'}
 set @strТекстSQLЗапроса = '   
 
 SET XACT_ABORT ON ;
 
      INSERT INTO #dtt
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
      ,[vozvrat_pok]
	  ,[peremPlus] 
	  ,[peremMinus] 
      ,[summa]
      ,[quantity]
      ,[price]
      ,[complect]
      ,[date_update])
  exec ( ''SELECT 
	   {d''''' + RTRIM(@date) + '''''} date_tt
	  ,' + RTRIM(@id_group) + '
	  ,' + RTRIM(@id_tt) + ' id_tt
	  ,ISNULL(id_tov_cl,0) id_tov
	  ,convert(real,sum(Quantity * CASE cl.OperationType_cl WHEN 400 THEN  1 WHEN 401 THEN -1 ELSE 0 END)) AS post
      ,convert(real,sum(Quantity * CASE cl.OperationType_cl WHEN 101 THEN  1 WHEN 111 THEN -1 ELSE 0 END)) AS digust 
      ,convert(real,sum(Quantity * CASE cl.OperationType_cl WHEN 102 THEN  1 WHEN 112 THEN -1 ELSE 0 END)) AS spisanie  
      ,convert(real,sum(Quantity * CASE cl.OperationType_cl WHEN 103 THEN  1 WHEN 113 THEN -1 ELSE 0 END)) AS spisanie_kach
      ,convert(real,sum(Quantity * CASE cl.OperationType_cl WHEN 104 THEN  1 WHEN 114 THEN -1 ELSE 0 END)) AS boi
      
	  
	     ,convert(real,case when {d''''' + RTRIM(@date) + '''''} >{d''''2015-11-13''''} then sum(Quantity * CASE cl.OperationType_cl WHEN 105 THEN  1 WHEN 115 THEN -1 ELSE 0 END)
					else 0 end) as spisanie_dost
      ,convert(real,sum(cl.Quantity * 
        case when {d''''' + RTRIM(@date) + '''''} >{d''''2015-11-13''''} then (case when (cl.OperationType_cl in (1, 202,203,3) and (cl.BaseSum =0 or cl.baseprice= 0.01)) then 1 else 0 end)
         else (CASE WHEN cl.OperationType_cl in (115) and ISNULL(cl.id_sms_tovar,0)=0 then -1
										   WHEN (((cl.OperationType_cl in (105)) or (cl.OperationType_cl in (1, 202,203,3) and (cl.BaseSum =0 or cl.baseprice= 0.01))) 
												 and ISNULL(cl.id_sms_tovar,0)=0) then 1 else  0 end) end )) akcia
	  ,convert(real,sum(cl.Quantity * 
	    case when {d''''' + RTRIM(@date) + '''''} >{d''''2015-11-13''''} then case when (cl.OperationType_cl in (1, 202,203,3) and(cl.BaseSum =0 or baseprice= 0.01))
												and ISNULL(cl.id_sms_tovar,0)<>0 then 1 else  0 end
	    else (CASE WHEN cl.OperationType_cl in (115) and ISNULL(cl.id_sms_tovar,0)<>0 then -1
										   WHEN (((cl.OperationType_cl in (105)) or (cl.OperationType_cl in (1, 202,203,3) and (cl.BaseSum =0 or cl.baseprice= 0.01))) 
												and ISNULL(cl.id_sms_tovar,0)<>0) then 1 else  0 end)end)) akcia_sms 

	  
	  ,convert(real,sum(BaseSum * CASE WHEN cl.OperationType_cl IN (1, 202, 203, 3)
		and ABS (cl.BasePrice * cl.Quantity - BaseSum /0.6) <=1 and cl.BasePrice not in (1,0.01) and cl.BaseSum<>0  and ISNULL(cl.id_sms_tovar,0)=0 THEN  1  ELSE 0 END)) AS Discount50

	  
	  ,convert(real,sum(Quantity * CASE WHEN cl.OperationType_cl IN (1, 202, 203, 3)  AND 
		ABS (cl.BasePrice * cl.Quantity - BaseSum /0.6) <=1  and cl.BasePrice not in (1,0.01) and cl.BaseSum <> 0 and ISNULL(cl.id_sms_tovar,0)=0 THEN  1 ELSE 0 END)) AS Discount50_qty 


	  ,convert(real,sum(BaseSum * CASE WHEN cl.OperationType_cl IN (1, 202, 203, 3)
		and ABS (cl.BasePrice * cl.Quantity - BaseSum /0.6)  <=1  and cl.BasePrice not in (1,0.01) and cl.BaseSum<>0  and ISNULL(cl.id_sms_tovar,0)<>0 THEN  1  ELSE 0 END)) AS Discount50_sms

	  
	  ,convert(real,sum(Quantity * CASE WHEN cl.OperationType_cl IN (1, 202, 203, 3)  AND 
		ABS (cl.BasePrice * cl.Quantity - BaseSum /0.6)  <=1  and cl.BasePrice not in (1,0.01) and cl.BaseSum <> 0 and ISNULL(cl.id_sms_tovar,0)<>0 THEN  1 ELSE 0 END)) AS Discount50_sms_qty 

	  ,CONVERT(real,sum(Quantity * CASE WHEN cl.OperationType_cl IN (500, 510,520) THEN 1 
                WHEN cl.OperationType_cl IN (501,521) THEN  -1 ELSE 0 END)) AS razniza	

		,CONVERT(real,sum(Quantity * CASE WHEN cl.OperationType_cl IN (201,211) THEN -1 ELSE 0 END)) as vozvrat_pok 
		,CONVERT(real,sum(Quantity * CASE WHEN cl.OperationType_cl IN (410) THEN 1 ELSE 0 END)) as peremPlus
		,CONVERT(real,sum(Quantity * CASE WHEN cl.OperationType_cl IN (411) THEN 1 ELSE 0 END)) as peremMinus
		,convert(real,sum(case when {d''''' + RTRIM(@date) + '''''} <{d''''2014-10-30''''} then (CASE WHEN cl.OperationType_cl in (1, 202,203,3,201,211) AND cl.BasePrice<>0.01 AND cl.BaseSum <> 0 then cl.BaseSum else 0 end)
														   else (CASE WHEN cl.OperationType_cl in (1, 202,203,3)  AND cl.BasePrice<>0.01 AND cl.BaseSum <> 0 then cl.BaseSum else 0 end) end)) summa
		,convert(real,sum(Quantity * case when {d''''' + RTRIM(@date) + '''''} <{d''''2014-10-30''''} then (CASE WHEN ((cl.OperationType_cl IN (1, 202, 203, 3,201) AND cl.BasePrice<>0.01 AND cl.BaseSum <> 0) ) or (cl.operationType_cl=211) THEN 1 ELSE 0 END)
																	  else (CASE WHEN (cl.OperationType_cl IN (1, 202, 203, 3) AND cl.BasePrice<>0.01 AND cl.BaseSum <> 0) THEN 1 ELSE 0 END) end)) AS quantity 


 	  ,CONVERT(real,max(cl.basePrice)) Price
 	  ,CONVERT(real,sum(Quantity * CASE WHEN cl.OperationType_cl IN (106) THEN 1 
 										WHEN cl.OperationType_cl IN (116) THEN -1 ELSE 0 END)) as complect
	  ,getdate() date_update
	  FROM [SMS_IZBENKA]..[CheckLine] cl with (index (ind2), nolock  ) 
	  where cl.date_ch =  {d''''' + RTRIM(@date) + '''''} and cl.id_tt_cl=' + RTRIM(@id_tt) + ' and (OperationType_cl > 0)and isnull(cl.id_tt_cl,0)<>0 
	   group by cl.id_tov_cl  	    
	'') at [SRV-SQL01] 
	' 	   

------
/*

set @strТекстSQLЗапроса = '   
      INSERT INTO #dtt
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
      ,[vozvrat_pok]
	  ,[peremPlus] 
	  ,[peremMinus] 
      ,[summa]
      ,[quantity]
      ,[price]
      ,[date_update])
	  exec ( ''SELECT 
	   {d''''' + RTRIM(@date) + '''''} date_tt
	  ,' + RTRIM(@id_group) + '
	  ,' + RTRIM(@id_tt) + ' id_tt
	  ,ISNULL(id_tov_cl,0) id_tov
	  ,convert(real,sum(Quantity * CASE cl.OperationType_cl WHEN 400 THEN  1 WHEN 401 THEN -1 ELSE 0 END)) AS post
      ,convert(real,sum(Quantity * CASE cl.OperationType_cl WHEN 101 THEN  1 WHEN 111 THEN -1 ELSE 0 END)) AS digust 
      ,convert(real,sum(Quantity * CASE cl.OperationType_cl WHEN 102 THEN  1 WHEN 112 THEN -1 ELSE 0 END)) AS spisanie  
      ,convert(real,sum(Quantity * CASE cl.OperationType_cl WHEN 103 THEN  1 WHEN 113 THEN -1 ELSE 0 END)) AS spisanie_kach
      ,convert(real,sum(Quantity * CASE cl.OperationType_cl WHEN 104 THEN  1 WHEN 114 THEN -1 ELSE 0 END)) AS boi
      ,convert(real,case when  {d''''' + RTRIM(@date) + '''''} >{d''''2015-11-13''''} then sum(Quantity * CASE cl.OperationType_cl WHEN 105 THEN  1 WHEN 115 THEN -1 ELSE 0 END)
					else 0 end) as spisanie_dost
      ,convert(real,sum(cl.Quantity * 
        case when  {d''''' + RTRIM(@date) + '''''} > {d''''2015-11-13''''} then (case when (cl.OperationType_cl in (1, 202,203,3) and (cl.BaseSum =0 or cl.baseprice= 0.01)) then 1 else 0 end)
         else (CASE WHEN cl.OperationType_cl in (115) and ISNULL(cl.id_sms_tovar,0)=0 then -1
										   WHEN (((cl.OperationType_cl in (105)) or (cl.OperationType_cl in (1, 202,203,3) and (cl.BaseSum =0 or cl.baseprice= 0.01))) 
												 and ISNULL(cl.id_sms_tovar,0)=0) then 1 else  0 end) end )) akcia
	  ,convert(real,sum(cl.Quantity * 
	    case when  {d''''' + RTRIM(@date) + '''''} >{d''''2015-11-13''''} then case when (cl.OperationType_cl in (1, 202,203,3) and(cl.BaseSum =0 or baseprice= 0.01))
												and ISNULL(cl.id_sms_tovar,0)<>0 then 1 else  0 end
	    else (CASE WHEN cl.OperationType_cl in (115) and ISNULL(cl.id_sms_tovar,0)<>0 then -1
										   WHEN (((cl.OperationType_cl in (105)) or (cl.OperationType_cl in (1, 202,203,3) and (cl.BaseSum =0 or cl.baseprice= 0.01))) 
												and ISNULL(cl.id_sms_tovar,0)<>0) then 1 else  0 end)end)) akcia_sms 
	  ,convert(real,sum(BaseSum * CASE WHEN cl.OperationType_cl IN (1, 202, 203, 3)
		and ABS (cl.BasePrice * cl.Quantity - BaseSum /0.6) <=1 and cl.BasePrice not in (1,0.01) and cl.BaseSum<>0  and ISNULL(cl.id_sms_tovar,0)=0 THEN  1  ELSE 0 END)) AS Discount50
	  ,convert(real,sum(Quantity * CASE WHEN cl.OperationType_cl IN (1, 202, 203, 3)  AND 
		ABS (cl.BasePrice * cl.Quantity - BaseSum /0.6) <=1  and cl.BasePrice not in (1,0.01) and cl.BaseSum <> 0 and ISNULL(cl.id_sms_tovar,0)=0 THEN  1 ELSE 0 END)) AS Discount50_qty 
	  ,convert(real,sum(BaseSum * CASE WHEN cl.OperationType_cl IN (1, 202, 203, 3)
		and ABS (cl.BasePrice * cl.Quantity - BaseSum /0.6)  <=1  and cl.BasePrice not in (1,0.01) and cl.BaseSum<>0  and ISNULL(cl.id_sms_tovar,0)<>0 THEN  1  ELSE 0 END)) AS Discount50_sms
	  ,convert(real,sum(Quantity * CASE WHEN cl.OperationType_cl IN (1, 202, 203, 3)  AND 
		ABS (cl.BasePrice * cl.Quantity - BaseSum /0.6)  <=1  and cl.BasePrice not in (1,0.01) and cl.BaseSum <> 0 and ISNULL(cl.id_sms_tovar,0)<>0 THEN  1 ELSE 0 END)) AS Discount50_sms_qty 
	  ,CONVERT(real,sum(Quantity * CASE WHEN cl.OperationType_cl IN (500, 510,520) THEN 1 
                WHEN cl.OperationType_cl IN (501,521) THEN  -1 ELSE 0 END)) AS razniza	
		,CONVERT(real,sum(Quantity * CASE WHEN cl.OperationType_cl IN (201,211) THEN -1 ELSE 0 END)) as vozvrat_pok 
		,CONVERT(real,sum(Quantity * CASE WHEN cl.OperationType_cl IN (410) THEN 1 ELSE 0 END)) as peremPlus
		,CONVERT(real,sum(Quantity * CASE WHEN cl.OperationType_cl IN (411) THEN 1 ELSE 0 END)) as peremMinus
		,convert(real,sum(case when  {d''''' + RTRIM(@date) + '''''}<{d''''2014-10-30''''} then (CASE WHEN cl.OperationType_cl in (1, 202,203,3,201,211) AND cl.BasePrice<>0.01 AND cl.BaseSum <> 0 then cl.BaseSum else 0 end)
														   else (CASE WHEN cl.OperationType_cl in (1, 202,203,3)  AND cl.BasePrice<>0.01 AND cl.BaseSum <> 0 then cl.BaseSum else 0 end) end)) summa
		,convert(real,sum(Quantity * case when  {d''''' + RTRIM(@date) + '''''}<{d''''2014-10-30''''} then (CASE WHEN ((cl.OperationType_cl IN (1, 202, 203, 3,201) AND cl.BasePrice<>0.01 AND cl.BaseSum <> 0) ) or (cl.operationType_cl=211) THEN 1 ELSE 0 END)
																	  else (CASE WHEN (cl.OperationType_cl IN (1, 202, 203, 3) AND cl.BasePrice<>0.01 AND cl.BaseSum <> 0) THEN 1 ELSE 0 END) end)) AS quantity 
 	  ,CONVERT(real,max(cl.basePrice)) Price
	  ,getdate() date_update
	  FROM [SMS_IZBENKA]..[CheckLine] cl with (index (ind2), nolock  ) 
	  where cl.date_ch =  {d''''' + RTRIM(@date) + '''''} and cl.id_tt_cl=' + RTRIM(@id_tt) + ' and (OperationType_cl > 0)and isnull(cl.id_tt_cl,0)<>0 
	  group by cl.id_tov_cl  	    
	'') at [SRV-SQL01] 
	'
print @strТекстSQLЗапроса
*/	
exec sp_executeSQL @strТекстSQLЗапроса	

	  
insert into jobs..Jobs_log ([id_job],[number_step],[duration]) select @id_job , 60, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
select @getdate = getdate() 

	 delete FROM #dtt 
	 where [post]=0 and [digust]=0 and [spisanie]=0 and [spisanie_kach]=0 and [boi]=0 and [spisanie_dost]=0 and
	                  [akcia]=0 and [akcia_sms]=0 and [discount50]=0 and [discount50_qty]=0 and [discount50_sms]=0 and
					  [discount50_sms_qty]=0 and [razniza]=0 and [summa]=0 and [quantity] =0 and [vozvrat_pok]=0 and [peremPlus]=0
					  and [peremMinus]=0 and [complect]=0 
					  
					  

/**
	if EXISTS(SELECT * FROM #dtt d WHERE ISNULL(d.Price,0)=0 )
		BEGIN
		 
	--------------------------------------by date

		select max(cl.BasePrice) as price,cl.id_tov_cl as id_tov
			INTO #PR_IZ
			from SMS_IZBENKA..CheckLine (nolock) cl inner join 
				(SELECT * FROM #dtt d WHERE ISNULL(d.Price,0)=0 ) d on cl.id_tov_cl=d.id_tov 
			where cl.date_ch=@date  and cl.BasePrice<>0 
		group by cl.id_tov_cl
		
		insert into jobs..Jobs_log ([id_job],[number_step],[duration]) select @id_job , 63, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
		select @getdate = getdate() 
			
			UPDATE #dtt   set Price=pr.Price
			FROM #dtt d inner join #PR_IZ pr 
								on  d.id_tov=pr.id_tov 
			
			WHERE ISNULL(d.Price,0)=0
			
		insert into jobs..Jobs_log ([id_job],[number_step],[duration]) select @id_job , 64, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
		select @getdate = getdate() 

			drop table #PR_IZ

			
		end
**/							  
 
  end 
  

/*
--------------------------------------------------------------------------------------------------------------------------------------
IF (@date<CONVERT(date,dateadd(day,-7,getdate()))) and( exists(SELECT * FROM #dtt d WHERE ISNULL(d.Price,0)=0 ))
BEGIN
       
         
				select  pr.id_tov, pr.price, pr.id_tt  
				INTO #Price_period 
				from Reports..Price_1C_period pr inner join (
					select Pr.id_tov, Pr.id_tt, max(pr.period) period
					from Reports..Price_1C_period pr inner join 
						(SELECT id_tov,id_tt, date_tt FROM #dtt d WHERE ISNULL(d.Price,0)=0) d on d.id_tov=pr.id_tov and d.id_tt=pr.id_tt
					where d.date_tt >=Pr.period
					group by Pr.id_tov, Pr.id_tt ) t on Pr.id_tov=t.id_tov and pr.id_tt=t.id_tt and pr.period=t.period
				
				
		
	insert into jobs..Jobs_log ([id_job],[number_step],[duration]) select @id_job , 65, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
	select @getdate = getdate() 

				UPDATE #dtt   set Price=pr.Price
				FROM #dtt d inner join #Price_period pr 
									on  d.id_tov=pr.id_tov and d.id_tt=pr.id_tt 
			   WHERE ISNULL(d.Price,0)=0

	insert into jobs..Jobs_log ([id_job],[number_step],[duration]) select @id_job , 66, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
	select @getdate = getdate() 

				drop table #Price_period
        
end
------------------------------------------------------------------------------------------------------------------
*/

create table #Price (id_tov int , price int)
			   
If exists( select * FROM #dtt d WHERE ISNULL(d.Price,0)=0  )
  BEGIN
/*
                set @strТекстSQLЗапроса = ' 
                SET XACT_ABORT ON ; 
                insert INTO #Price 
				exec (''select  id_tov,price 
				from reports..price_tt(' + RTRIM(@id_tt) + ') pr  
	            '') at [SRV-SQL01] 
	            '
                exec sp_executeSQL @strТекстSQLЗапроса	
*/
	            insert INTO #Price(id_tov, price)
	            select id_tov, price
	            from (select id_tov, price
							, ROW_NUMBER() over (partition by id_tov order by period desc)rn
						from vv03.dbo.Price_period pr
						where (pr.id_tt=@id_tt or pr.id_tt is null) and Period<=@date)a
				where a.rn=1		
		                
                
				
				delete #Price
				from #Price pr
				where pr.id_tov in (select distinct id_tov FROM #dtt WHERE ISNULL(Price,0)<>0)
				
	

				UPDATE #dtt   set Price=pr.Price
				FROM #dtt d inner join #Price pr 
									on  d.id_tov=pr.id_tov
				WHERE ISNULL(d.Price,0)=0

insert into jobs..Jobs_log ([id_job],[number_step],[duration]) select @id_job , 68, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
select @getdate = getdate() 


				
				If exists( select * FROM #dtt d WHERE ISNULL(d.Price,0)=0 )
				BEGIN
					
                delete from #Price

                
                insert INTO #Price 
				select  id_tov, max(price )
				from vv03..Price_1C_tov pr 
				group by id_tov 
	            

			    delete #Price
				from #Price pr
				where pr.id_tov in (select distinct id_tov FROM #dtt WHERE ISNULL(Price,0)<>0)
					
					UPDATE #dtt  set Price=pr.Price
					FROM #dtt d inner join #Price pr   
										on  d.id_tov=pr.id_tov
					WHERE ISNULL(d.Price,0)=0


	
		end

insert into jobs..Jobs_log ([id_job],[number_step],[duration]) select @id_job , 69, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
select @getdate = getdate() 


END

drop table #Price




--select * from #dtt where id_tov in(14697)
	
IF YEAR(@date)>2014
BEGIN	
	
		
   begin
  
 
 		  DELETE FROM vv03..DTT
		  -- select *
		  FROM vv03..DTT as dtt with(rowlock) left JOIN #dtt d 
			 ON dtt.date_tt=d.Date_tt and dtt.id_tt=d.id_tt and dtt.id_tov=d.id_tov
		  where dtt.date_tt=@date and dtt.id_tt=@id_tt and d.id_tov is null



insert into jobs..Jobs_log ([id_job],[number_step],[duration]) select @id_job , 80, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
select @getdate = getdate() 

  -------------Изменяем
		 
		   UPDATE vv03..DTT with(rowlock)
		   SET id_group = @id_group
			  ,post = d.post
			  ,[digust] = d.digust
			  ,[spisanie] =d.spisanie
			  ,[spisanie_kach]=d.spisanie_kach
			  ,[boi] =d.boi
			  ,[spisanie_dost] = d.spisanie_dost
			  ,[akcia] = d.akcia
			  ,[akcia_sms] =d.akcia_sms
			  ,[discount50]=d.discount50
			  ,[discount50_qty]=d.discount50_qty
			  ,[discount50_sms] = d.discount50_sms
			  ,[discount50_sms_qty]=d.discount50_sms_qty
			  ,[razniza]=d.razniza
			  ,[vozvrat_pok]=d.vozvrat_pok
			  ,[peremPlus]=d.peremPlus
			  ,[peremMinus]=d.peremMinus
			  ,[summa]=d.summa
			  ,[quantity]=d.quantity
			  ,[price]=d.price
			  ,[Complect]=d.complect
			  ,[date_update] = GETDATE()
		  FROM vv03..DTT dtt (rowlock) INNER JOIN #dtt d 
			 ON dtt.date_tt=d.date_tt and dtt.id_tt=d.id_tt and dtt.id_tov=d.id_tov	
		  where isnull(dtt.post,0)<>isnull(d.post,0) 
			or isnull(dtt.digust,0)<> isnull(d.digust,0) 
			or isnull(dtt.spisanie,0)<> isnull(d.spisanie,0)	
			or isnull(dtt.spisanie_dost,0)<> isnull(d.spisanie_dost,0) 
			or isnull(dtt.spisanie_kach,0)<>isnull(d.spisanie_kach,0) 	
			or isnull(dtt.summa,0)<> isnull(d.summa,0) 
			or isnull(dtt.vozvrat_pok,0)<>isnull(d.vozvrat_pok,0)  
			or isnull(dtt.akcia,0)<> isnull(d.akcia,0)
			or isnull(dtt.akcia_sms,0)<> isnull(d.akcia_sms,0) 
			or isnull(dtt.boi,0)<> isnull(d.boi,0) 
			or isnull(dtt.discount50,0)<> isnull(d.discount50,0)
			or isnull(dtt.discount50_qty,0)<> isnull(d.discount50_qty,0) 
			or isnull(dtt.discount50_sms,0)<> isnull(d.discount50_sms,0)
			or isnull(dtt.discount50_sms_qty,0)<> isnull(d.discount50_sms_qty,0) 
			or isnull(dtt.peremMinus,0)<> isnull(d.peremMinus,0)
			or isnull(dtt.peremPlus,0)<> isnull(d.peremPlus,0) 
			or isnull(dtt.price,0)<> isnull(d.price,0) 
			or isnull(dtt.quantity,0)<> isnull(d.quantity,0)
			or isnull(dtt.razniza,0)<> isnull(d.razniza,0)
			or ISNULL(dtt.id_group,0)<> ISNULL(d.id_group,0)
			or ISNULL(dtt.complect,0)<> ISNULL(d.complect,0)

insert into jobs..Jobs_log ([id_job],[number_step],[duration]) select @id_job , 90, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
select @getdate = getdate() 



		  -------------Добавляем
		  INSERT INTO vv03..DTT with (rowlock)
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
			  ,[vozvrat_pok]
			  ,[peremPlus]
			  ,[peremMinus]
			  ,[summa]
			  ,[quantity]
			  ,[price]
			  ,[complect]
			  ,date_update)
		  SELECT d.[date_tt]
			  ,d.[id_group]
			  ,d.[id_tt]
			  ,d.[id_tov]
			  ,d.[post]
			  ,d.[digust]
			  ,d.[spisanie]
			  ,d.[spisanie_kach]
			  ,d.[boi]
			  ,d.[spisanie_dost]
			  ,d.[akcia]
			  ,d.[akcia_sms]
			  ,d.[discount50]
			  ,d.[discount50_qty]
			  ,d.[discount50_sms]
			  ,d.[discount50_sms_qty]
			  ,d.[razniza]
			  ,d.[vozvrat_pok]
			  ,d.[peremPlus]
			  ,d.[peremMinus]
			  ,d.[summa]
			  ,d.[quantity]
			  ,d.[price]
			  ,d.[complect]
			  ,@getdate
		  FROM #dtt  d left join  vv03..DTT as dtt with(rowlock) 
		    on d.date_tt=dtt.date_tt and d.id_tt=dtt.id_tt and d.id_tov=dtt.id_tov 
		  where dtt.id_tov is null

insert into jobs..Jobs_log ([id_job],[number_step],[duration]) select @id_job , 100, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
select @getdate = getdate() 


 
 end


		  


END 


  drop table #dtt 
  
  
END
GO