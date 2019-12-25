SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:      Rytik
-- Create date: 2018-10-29
-- Description: Обновление vv03..tt_action

-- =============================================
CREATE PROCEDURE [dbo].[Update_tt_action]
  @id_job  int
AS
BEGIN  
  SET NOCOUNT ON;
  
  declare
    @strSQL as nvarchar(4000),
    @getdate as datetime = getdate(),
    @job_name as varchar(100) = 'jobs..Update_tt_action',
    @temp_table as nchar(36) 


  begin try
    if OBJECT_ID ('tempdb..#tt_action') is not null drop table #tt_action

    create table #tt_action(
    	id_tov numeric(10, 0) NULL,
	    shopNo numeric(5, 0) NOT NULL,
	    action_for_quantity int NULL,
	    discount numeric(15, 2) NULL,
	    quantity_for_discount numeric(10, 3) NULL,
	    price_special numeric(15,2) NULL
    )

    set @strSQL = 
       'insert into #tt_action
        exec (''select tov._Fld760 as id_tov,
                       tt._Fld2756 as shopNo,
                       case when specPr._Fld6515RRef = 0x917A7A03BCE798EB4A8746EDAB9BF0AD then 1 -- при покупке от штук
                            when specPr._Fld6515RRef = 0xA7DC4D5CABD648F8427AF95BC29980B3 then 0 -- скидка по карте
                       end as action_for_quantity,
                       max(case when specPr._Fld6515RRef = 0xA7DC4D5CABD648F8427AF95BC29980B3
                                  then specPr._Fld6223
                                  else CONVERT(decimal(15,2), 100 - specPr._Fld6223 * 100 / pr.Price) end) as discount,
                       max(specPr._Fld6222) AS quantity_for_discount,
                       max(case when specPr._Fld6515RRef = 0xA7DC4D5CABD648F8427AF95BC29980B3
                                  then CONVERT(decimal(15,2), (100 - specPr._Fld6223) / 100 * pr.Price)
                                  else RTRIM(specPr._Fld6223) end) as price_special
                  from IzbenkaFin.dbo._Reference29_VT6217 specPr WITH(NOLOCK)
                 inner join IzbenkaFin.dbo._Reference42 tt WITH(NOLOCK)
                         on specPr._Fld6672RRef = tt._IDRRef
                 inner join IzbenkaFin.dbo._Reference29 tov WITH(NOLOCK)
                         on specPr._Reference29_IDRRef = tov._IDRRef
                 inner join Reports.dbo.Price_1C_tov as pr
                         on tov._Fld760 = pr.id_tov
                 where specPr._Fld6220 <= dateadd(year, 2000, getdate())
                   and convert(date, specPr._Fld6221) >= dateadd(year, 2000, getdate())
                   and tt._Fld2756 <> 999
                 group by tov._Fld760,
                          tt._Fld2756,
                          specPr._Fld6515RRef
                '') at [SRV-SQL01]'

    exec sp_executeSQl @strSQL 


    begin tran
      truncate table vv03.dbo.tt_action
        
      insert into vv03.dbo.tt_action(id_tov, shopNo, action_for_quantity, discount, quantity_for_discount)
        select id_tov, shopNo, action_for_quantity, discount, quantity_for_discount
          from #tt_action
    commit tran 
    
  end try
  begin catch
  
      insert into jobs.dbo.error_jobs(job_name, message, number_step, id_job)
      select @job_name, ERROR_MESSAGE(), 12, @id_job

  end catch
  

 
END
GO