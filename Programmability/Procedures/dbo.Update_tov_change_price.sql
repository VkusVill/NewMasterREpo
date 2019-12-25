SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:      Ruslan Muleev
-- Create date: 2019-01-11
-- Description: Обновление vv03..tov_change_price

-- =============================================
CREATE PROCEDURE [dbo].[Update_tov_change_price]
  @id_job  int
AS
BEGIN  
  SET NOCOUNT ON;
  
  declare
    @strSQL as varchar(5000),
    @getdate as datetime = getdate(),
    @job_name as varchar(100) = 'jobs..Update_tov_change_price',
    @temp_table as nchar(36) 


  begin try
  
    if OBJECT_ID ('tempdb..#tov_change_price') is not null drop table #tov_change_price

    create table #tov_change_price(
    	id_tov int NULL,
	    name_tov varchar(150) NULL,
	    new_price numeric(15, 2) NULL,
	    last_price numeric(15, 2) NULL,
	    date_change date null
    )
	
    set @strSQL =
    'if OBJECT_ID('+'''tempdb..##ReportsReport_Change_Price_test'''+') is not null 
	drop table ##ReportsReport_Change_Price_test 
if OBJECT_ID('+'''tempdb..#t'''+') is not null drop table #t  
select distinct t3._Fld760 id_tov
	, t3._IDRRef
	, T3._Description Товар
	, T1._Fld2713 Цена
	, t1._Fld2709RRef
	, T1._Period 
into #t
FROM          IzbenkaFin.dbo._InfoRg2707 t1  with(nolock)
	left JOIN  IzbenkaFin.dbo._Reference42 T2 WITH (NOLOCK) 
		ON T1._Fld2709RRef = T2._IDRRef 
	INNER JOIN IzbenkaFin.dbo._Reference29 T3 WITH (NOLOCK) 
		ON T1._Fld2710RRef = T3._IDRRef	
where 
T1._Active = 0x01 and t3._Fld3821=0
select distinct
	  a.id_tov
	, a.Товар as name_tov
	, a.Цена as price
	, a.ПредыдущаяЦена as last_price
	,CONVERT(date
	, case when YEAR(a._Period)>4000 then  DATEADD(YEAR, - 2000, a._Period) 
			else a._Period end, 105) date_change
from 
(select  t.* , _Fld2713 [ПредыдущаяЦена]
	, ROW_NUMBER()over( partition by t._IDRRef order by  t1._Period desc ) rn
 from #t t 
	left join IzbenkaFin.dbo._InfoRg2707 t1 
		on t._IDRRef=t1._Fld2710RRef 
			and t1._Period<t._Period 
			and  t1._Fld2709RRef=t._Fld2709RRef 
			and T1._Active = 0x01
	)a 
where a.rn=1 and a.Цена <> a.ПредыдущаяЦена 
and CONVERT(date, case when YEAR(a._Period)>4000 then  DATEADD(YEAR, - 2000, a._Period) 
			else a._Period end, 105) = CAST(getdate()as DATE)
drop table #t'

    insert into #tov_change_price
    exec (@strSQL) at [srv-sql01]

    begin tran
      truncate table vv03..Tov_change_price
        
     insert into vv03..Tov_change_price (id_tov,name_tov,new_price,last_price,date_change)
	 select id_tov,name_tov,new_price,last_price,date_change from #tov_change_price
    commit tran 
    
  end try
  
  begin catch
  
      insert into jobs.dbo.error_jobs(job_name, message, number_step, id_job)
      select @job_name, ERROR_MESSAGE(), 12, @id_job

  end catch 
END
GO