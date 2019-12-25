SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:      OSeliv
-- Create date: 2019-06-25
-- Description: Обновление vv03..tovar_barcode

-- =============================================
CREATE PROCEDURE [dbo].[Update_TovarBarcode]
  @id_job  int
AS
BEGIN  
  SET NOCOUNT ON;
  
  declare
    @strSQL as nvarchar(4000),
    @getdate as datetime = getdate(),
    @job_name as varchar(100) = 'jobs..Update_TovarBarcode'


begin try

    if OBJECT_ID ('tempdb..#tovbc') is not null drop table #tovbc

    create table #tovbc(
    		  barcode varchar(15) not null
			, id_tov int not null 
			, id_kontr int 
			, hashsum as checksum(id_tov, barcode, id_kontr)
			)

    insert into #tovbc
    exec ('select [Штрих-код], id_tov, id_kontr from Reports..Tovar_BarCode where len([Штрих-код])>5 and id_tov is not null') at [srv-sql01]

	


      update bc 
	  set barcode = s.barcode
		, id_tov = s.id_tov
		, id_kontr =  s.id_kontr
	  from vv03.dbo.tovar_barcode bc
	  cross apply 
		 (select  id_tov, barcode, id_kontr
				from #tovbc where barcode = bc.barcode and hashsum != bc.Hashsum) s
      
	    
		insert into vv03.dbo.tovar_barcode 
				( id_tov, barcode, id_kontr)
		 select id_tov, barcode, id_kontr
         from #tovbc t
	  	 where not exists (select 1 from vv03.dbo.tovar_barcode where barcode = t.barcode)
      
	  delete bc
	  from vv03.dbo.tovar_barcode bc
	  where not exists (select 1 from #tovbc where barcode = bc.barcode) 
    
  end try
  begin catch
  
     insert into jobs.dbo.error_jobs(job_name, message, number_step, id_job)
      select @job_name, ERROR_MESSAGE(), 80, @id_job

  end catch
  
 
END
GO