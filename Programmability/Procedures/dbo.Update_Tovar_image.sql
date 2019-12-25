SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:      OSeliv
-- Create date: 2019-06-25
-- Description: Обновление vv03..tovar_image

-- =============================================
CREATE PROCEDURE [dbo].[Update_Tovar_image]
  @id_job  int
AS
BEGIN  
  SET NOCOUNT ON;
  
  declare
    @strSQL as nvarchar(4000),
    @getdate as datetime = getdate(),
    @job_name as varchar(100) = 'jobs..Update_tovar_image'


begin try

    if OBJECT_ID ('tempdb..#tovimg') is not null drop table #tovimg

    create table #tovimg(
    		  id_tov int not null
			, ordr tinyint not null 
			, short_name varchar(200) 
			, photourl varchar(150)
			, [name] varchar(50)
			, ext varchar(10)
			, main bit not null
			, mini_photo varchar(150)
			, big_photo varchar(150)
			, hashsum as checksum([id_tov],[ordr],[mini_photo],[big_photo],[name],[main])

			)

    insert into #tovimg
    exec ('select [id_tov]
				, [ordr]
				, [short_name]
				, [photourl]
				, [name]
				, [ext]
				, [main]
				, [mini_photo]
				, big_photo
			from [M2].[dbo].[tovar_images]') at [srv-sql01]

	-- select * from #tovimg order by 1


      update i 
	  set short_name = s.[short_name]
		, [photourl] = s.[photourl]
		, [name] =  s.[name]
		, [ext] = s.[ext]
		, [main] = s.[main]
		, [mini_photo] = s.[mini_photo]
		, [big_photo] = s.[big_photo]
	  from vv03.dbo.tovar_images i
	  cross apply 
		 (select  [short_name]
				, [photourl]
				, [name]
				, [ext]
				, [main] 
				, [mini_photo]
				, big_photo
				from #tovimg where id_tov = i.id_tov and ordr = i.ordr and hashsum != i.Hashsum) s
      
	    
		insert into vv03.dbo.tovar_images 
				( [id_tov]
				, [ordr]
				, [short_name]
				, [photourl]
				, [name]
				, [ext]
				, [main]
				, [mini_photo]
				, big_photo
				)
		 select [id_tov]
				, [ordr]
				, [short_name]
				, [photourl]
				, [name]
				, [ext]
				, [main]
				, [mini_photo]
				, big_photo
          from #tovimg t
	  	  where not exists (select 1 from vv03.dbo.tovar_images where id_tov = t.id_tov and ordr = t.ordr)
      
	  delete i
	  from vv03.dbo.tovar_images i
	  where not exists (select 1 from #tovimg where id_tov = i.id_tov and ordr = i.ordr) 
    
  end try
  begin catch
  
     insert into jobs.dbo.error_jobs(job_name, message, number_step, id_job)
      select @job_name, ERROR_MESSAGE(), 80, @id_job

  end catch
  
 
END
GO