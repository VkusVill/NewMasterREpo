SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		OSeliv
-- Create date: 2019-07-10
-- Description:	 убрать закрытые магазины из избранных
--select * from jobs..jobs_reestr where ProcedureName like '%RemoveClosedTTfromChosen%'
--select * from jobs..jobs where job_Name like '%RemoveClosedTTfromChosen%'

-- =============================================
CREATE PROCEDURE [dbo].[RemoveClosedTTfromChosen]
@id_job  int = 0
AS
BEGIN	
	SET NOCOUNT ON;
	
  declare
   
    @getdate as datetime = getdate(),
	@job_name as varchar(100) =  com.dbo.Object_name_for_err(@@procID,db_id()),
    @temp_table as nchar(36) 

  insert into jobs.dbo.Jobs_log([id_job], [number_step], [duration]) 
  select @id_job, 10, DATEDIFF(MILLISECOND, @getdate, GETDATE()) 
  select @getdate = getdate()
    
	set dateformat Ymd

  if object_id('tempdb..#shops') is not null drop table #shops

  --- координаты открытых и закрытых магазинов
	select	N, 
		adress, 
		Shirota, 
		dolgota, 
		case статус when 'Открыт' then 1 
			when 'Закрыт' then 0
		end stat
	into #shops
	from vv03..tt where Shirota+Dolgota > 0 and tt_format in (2, 12) and статус in ('Открыт', 'Закрыт')
--select * from #shops where adress like '%Митинская%'

--- переписываем избранные магазины из настроек, в которых есть закрытые магазины, вырезаем их, берем Ш и Д
	if object_id('tempdb..#nshop') is not null drop table #nshop
	select top 500 
	number, 
	chosen_shops, 
	shopno, 
	Shirota,
	Dolgota,
	--replace(chosen_shops + ',', shopno + ',', '')  shopstr 
	(select item + ',' from telegram.dbo.SplitStr(chosen_shops, ',') where item != sh.shopno for xml path('')) shopstr
	into #nshop
	from vv03..Cards_Settings s
	cross apply (select item shopno from telegram.dbo.SplitStr(chosen_shops, ',')) sh
	cross apply (select shirota, dolgota from #shops where stat = 0 and N = shopNo) cls
	where len(chosen_shops) > 1 --and exists (select 1 from #shops where stat = 1 and N = shopNo)

	-- если есть такие - апдейтим настройки.. ближайший магазин и оповещения утром надо доделать
	if exists (select * from #nshop)
	begin 
		/*
		declare @R float(8) = 6367450

		select ns.*, op.*
		from #nshop ns
		cross apply 
			(select top 1 * from 
				(select N, adress, master.dbo.CoordinatesToDistance(Shirota, Dolgota, ns.Shirota, ns.Dolgota) as [distance] 
				from #shops where stat = 1
				) t order by row_number() over (order by distance)
			 ) op
			 
		select * from #nshop where number = '6417849' 
		select * from vv03..Cards_Settings cs where number = '6417849' 
		*/
		update cs
		set chosen_shops = iif(len(shopstr) > 0, left(shopstr, len(shopstr) - 1), '')
		from vv03..Cards_Settings cs
		join #nshop s on s.number = cs.number and cs.chosen_shops = s.chosen_shops
		--where cs.number = '6417849' 

		insert into jobs..buffer_outbox_mp 
					([oneSignalToken]
					,[Heading_message]
					,[Message]
					,[Type_message]
					,[date_message]
					,[number]
					)
		select 
				  OneSignalToken
				, number
				, 'Cожалеем, закрылся ваш избранный магазин по адресу ' + adress + '.'
				, 0
				, convert(varchar(8), getdate(), 112) + ' 09:00:00'
				, '0233591' -- number
		from #nshop ns
		cross apply (select adress from #shops where N = ns.shopno) sh
		cross apply (select onesignaltoken from vv03..cards where number = ns.number and len(onesignaltoken) > 0) t

	end
  
  insert into jobs..Jobs_log ([id_job],[number_step],[duration]) 
  select @id_job , 50, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
  select @getdate = getdate()

END
GO