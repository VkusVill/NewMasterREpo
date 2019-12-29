SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- +++АК SHEP 2019.01.14 ИП-00017103.04:
-- заменил в "@text char(16) = 'add_зак_покуп'" 16 на 64
-- Change:     OD 2019-01-31 оптимизировала запрос добавления планов продаж, добавила доп фильтры на вложенные запросы. 

-- Author:		SHEP / Шевченко Павел
-- Create date: 16.10.2019
-- Description:	ИП-00017103.39. Если таблица #osn_har была пустая, в товарный ассортимент магазина позиция не добавлялась (((
--				Беру первую попавшуюся активную характеристику из созданной функции TovCharacteristicsByShopNo()
-- =============================================
CREATE PROCEDURE [dbo].[add_assortiment_tov_tt]
 @id_tov int
,@id_tt int
,@text varchar(64) = 'add_зак_покуп' 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

declare @id_job as int =100320
		,@job_name varchar(100)='m2..add_assortiment_tov_tt'
		,@getdate datetime =getdate()

--Declare @id_tov int = 22272,@id_tt int = 12096,@text char(16) = 'add_зак_покуп' 


BEGIN TRY
  
	Declare @тип int 

	select @тип = a.тип 
	from
	(Select top 1 with ties
				_Fld3961 тип 
			From IzbenkaFin.dbo._InfoRg3957 as Tov_Assortiment (nolock)
			where Tov_Assortiment.id_tt_1C = @id_tt and Tov_Assortiment.id_tov_1C = @id_tov
		    order by ROW_NUMBER() over (partition by Tov_Assortiment.id_tov_1C , Tov_Assortiment.id_tt_1C  
									  order by  Tov_Assortiment._Period desc, _Fld3961 )
		  ) a
	      
	if ISNULL(@тип,1)=1  
	--Завести  товар в магазин
	begin

	  INSERT INTO jobs..Jobs_log (id_job, number_step, duration, par1,par2, par3)
	  SELECT @id_job, 10, DATEDIFF(MILLISECOND, @getdate, GETDATE()), @id_tt, @id_tov, substring(@text,1,50)
	  SET @getdate = GETDATE()


		if OBJECT_ID('tempdb..#add_tovar2') is not null drop table #add_tovar2
		create table #add_tovar2 (id_tt int,  id_tov int , tt_ref binary(16), tov_ref binary(16))
		truncate table #add_tovar2

		insert into #add_tovar2 (id_tt,id_tov, tt_ref,tov_ref) 
		select tt.id_TT 
			, t.id_tov 
			, tt.Ref 
			, t.Ref
		from M2..Tovari t 
			inner join M2..tt on tt.id_TT = @id_tt 
		where t.id_tov = @id_tov



		if OBJECT_ID('tempdb..#osn_har') is not null drop table #osn_har
		create table #osn_har (tov_ref binary(16), har_ref binary(16))

		insert into #osn_har (tov_ref,har_ref)
		select top 1 with ties _Fld3959RRef , _Fld3960RRef 
		from(  select top 1 with ties _Fld3958RRef 
									, _Fld3959RRef 
									, _Fld3960RRef
									, _Fld3961
			   From IzbenkaFin.dbo._InfoRg3957 i
				  inner join (select distinct tov_ref from #add_tovar2 ) a 
					on i._Fld3959RRef = a.tov_ref
			   order by ROW_NUMBER() over (partition by _Fld3958RRef,_Fld3959RRef  order by _Period desc)
			  ) a
		where _Fld3961 =0
		group by _Fld3959RRef , _Fld3960RRef
		order by ROW_NUMBER() over (partition by _Fld3959RRef   order by COUNT(*) desc)

		-- +++АК SHEP 2019.10.16 ИП-00017103.39:
		IF (SELECT COUNT(*) FROM #osn_har) = 0
		BEGIN
			DECLARE @ShopNo int
			SELECT @ShopNo = tt.N
			FROM M2.dbo.TT tt (NOLOCK)

			INSERT INTO #osn_har (tov_ref,har_ref)
			SELECT TOP 1 tovchar.TovRef, tovchar.CharactRef
			FROM SMS_REPL.dbo.TovCharacteristicsByShopNo(@id_tov, @ShopNo) tovchar
		END
		-- ---АК SHEP 2019.10.16

		delete from IzbenkaFin.dbo._InfoRg3957
		from #add_tovar2 a
			inner join #osn_har o on a.tov_ref = o.tov_ref
			inner join IzbenkaFin.dbo._InfoRg3957 i 
				on i._Fld3958RRef = a.tt_ref 
					and i._Fld3959RRef = a.tov_ref 
					and i._Period >=  dateadd(year,2000,CONVERT(date,getdate()))


		-- ввести в ассортимент
		insert into IzbenkaFin.dbo._InfoRg3957
			  ([_Period]
			  ,[_Fld3958RRef]
			  ,[_Fld3959RRef]
			  ,[_Fld3960RRef]
			  ,[_Fld3961]
			  ,[_Fld6975]
			  ,[_Fld7283]
			  ,[_Fld6585]
			  ,[_Fld7150RRef]
			  ,[_Fld7604]
			  ,[_Fld9556]
			  ,[_Fld17345])
		select dateadd(year,2000,CONVERT(date,getdate()))
			, a.tt_ref 
			, a.tov_ref 
			, o.har_ref
			, 0 
			, 0 
			, a.id_tt 
			, dateadd(year,2000,getdate())
			, 0xA520001FC68B8D1311E0DCA7C7689DB3 
			, @text
			, 0
			, 0
		from #add_tovar2 a
		inner join #osn_har o on a.tov_ref = o.tov_ref
			left join IzbenkaFin.dbo._InfoRg3957 i 
				on i._Fld3958RRef = a.tt_ref 
					and i._Fld3959RRef = a.tov_ref 
					and i._Period =  dateadd(year,2000,CONVERT(date,getdate()))
		where i._Period is null


	  INSERT INTO jobs..Jobs_log (id_job, number_step, duration, par1,par2, par3)
	  SELECT @id_job, 20, DATEDIFF(MILLISECOND, @getdate, GETDATE()), @id_tt, @id_tov, substring(@text,1,50)
	  SET @getdate = GETDATE()


--Declare @id_tov int = 22272,@id_tt int = 12096,@text char(16) = 'add_зак_покуп' 

		if OBJECT_ID('tempdb..#skl') is not null drop table #skl
		create table #skl (_Fld2883RRef binary(16)
						, _Fld5934RRef binary(16))
						
		insert into #skl (_Fld2883RRef,_Fld5934RRef )
		select top 1 with ties _Fld2883RRef  --торговая точка
							, _Fld5934RRef   --склад
		from IzbenkaFin.._InfoRg2881 as R (nolock)
		group by r._Fld2883RRef , _Fld5934RRef
		order by ROW_NUMBER() over (partition by _Fld2883RRef order by COUNT(*) desc)

    create unique clustered index ind1 on #skl (_Fld2883RRef,_Fld5934RRef)  

	select d._Fld3269 [_Fld3269]
			, a.tt_ref [_Fld2883RRef]
			, a.tov_ref [_Fld2884RRef]
			, ras._Fld4909RRef 
			, 1 [_Fld2885]
			, pr._Fld2892 
			, skl._Fld5934RRef 
			, 0x00000000000000000000000000000000 [_Fld7470RRef]
			, 0xA520001FC68B8D1311E0DCA7C7689DB3 [_Fld11393RRef]			
		into #add_plan
		--select *
		from (select distinct r._Fld3269 --дата
			  from IzbenkaFin.._InfoRg2881 as R (nolock) --план продаж по дням недели
			  ) d
			inner join #add_tovar2 a on 1=1
			inner join  #skl skl on skl._Fld2883RRef = a.tt_ref
			inner join (select top 1 with ties _Fld2884RRef --номенклатура
								, r._Fld5934RRef            --склад
								, r._Fld4909RRef            --расчетчик
						from IzbenkaFin.._InfoRg2881 as R (nolock)
							inner join #skl s 
								on s._Fld2883RRef = r._Fld2883RRef      --торговая точка
									and s._Fld5934RRef=r._Fld5934RRef   --склад
							inner join #add_tovar2 as a  on a.tov_ref=r._Fld2884RRef		
						group by _Fld2884RRef, r._Fld5934RRef, r._Fld4909RRef
						order by ROW_NUMBER() over (partition by _Fld2884RRef, r._Fld5934RRef order by COUNT(*) desc)
						) ras 
				on ras._Fld2884RRef=a.tov_ref               --номенклатура
					and ras._Fld5934RRef = skl._Fld5934RRef --склад

			inner join (select top 1 with ties _Fld2884RRef --номенклатура
											, r._Fld2892    --цена
						from IzbenkaFin.._InfoRg2881 as R (nolock) 
						   inner join #add_tovar2 as a on a.tov_ref=r._Fld2884RRef
						where _Fld2892 >0
						group by _Fld2884RRef, r._Fld2892 
						order by ROW_NUMBER() over (partition by _Fld2884RRef  order by COUNT(*) desc)
						) pr 
						on pr._Fld2884RRef = a.tov_ref
	
	  INSERT INTO jobs..Jobs_log (id_job, number_step, duration, par1,par2, par3)
	  SELECT @id_job, 30, DATEDIFF(MILLISECOND, @getdate, GETDATE()), @id_tt, @id_tov, substring(@text,1,50)
	  SET @getdate = GETDATE()

		-- добавить планы продаж
		insert into IzbenkaFin.._InfoRg2881
			   ([_Fld3269]
			  ,[_Fld2883RRef]
			  ,[_Fld2884RRef]
			  ,[_Fld4909RRef]
			  ,[_Fld2885]
			  ,[_Fld2892]
			  ,[_Fld5934RRef]
			  ,[_Fld7470RRef]
			  ,[_Fld11393RRef]			  )
		select a.[_Fld3269]
			, a.[_Fld2883RRef]
			, a.[_Fld2884RRef]
			, a.[_Fld4909RRef] 
			, a.[_Fld2885]
			, a.[_Fld2892] 
			, a.[_Fld5934RRef] 
			, a.[_Fld7470RRef]
			, a.[_Fld11393RRef]			
		from  #add_plan a  
			left join IzbenkaFin.._InfoRg2881 i 
				on i._Fld3269	= a._Fld3269 
					and	i._Fld2883RRef	= a._Fld2883RRef 
					and	i._Fld2884RRef = a._Fld2884RRef 
		where i._Fld3269 is null  



	  INSERT INTO jobs..Jobs_log (id_job, number_step, duration, par1,par2, par3)
	  SELECT @id_job, 40, DATEDIFF(MILLISECOND, @getdate, GETDATE()), @id_tt, @id_tov, substring(@text,1,50)
	  SET @getdate = GETDATE()

	end

END TRY
BEGIN CATCH
  INSERT INTO jobs..error_jobs(id_job, job_name, number_step, date_add, message)
  SELECT @id_job,@job_name, 100, GETDATE(), ERROR_MESSAGE()
END CATCH
END
GO