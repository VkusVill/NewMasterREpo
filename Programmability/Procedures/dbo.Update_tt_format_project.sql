SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:      Rytik
-- Create date: 2018-10-29
-- Description: Обновление vv03..tt_format_project

-- =============================================
CREATE PROCEDURE [dbo].[Update_tt_format_project]
  @id_job  int
AS
BEGIN  
  SET NOCOUNT ON;
  
  declare
   
    @getdate as datetime = getdate(),
    @job_name as varchar(100) = 'jobs..Update_tt_format_project',
    @temp_table as nchar(36) 


  begin try
    if OBJECT_ID ('tempdb..#tt_format_project') is not null drop table #tt_format_project

    create table #tt_format_project(
	    [tt_format] [int] NOT NULL,
	    [project] [varchar](2) NOT NULL,
	    [format_name] [varchar](100) NULL,
	    [descr_format] [varchar](1000) NULL,
	    [TM] [varchar](50) NULL,
	    [Load_sr_Checks_Checkline_add_trigger] [tinyint] NULL,
	    [is_MarketPlace] [bit] NULL,
	    [email] [varchar](500) NOT NULL,
	    [SummForLP] [tinyint] NULL,
    )

  insert into #tt_format_project
  select tt_format, project, format_name, descr_format, tm, load_sr_checks_checkline_add_trigger, is_marketPlace, email_tt_format, summForLP
  from [SRV-SQL01].Reports.dbo.tt_format_project 
                

  

    begin tran
      truncate table vv03.dbo.tt_format_project
        
      insert into vv03.dbo.tt_format_project(tt_format, project, format_name, descr_format, tm, load_sr_checks_checkline_add_trigger, is_marketPlace, email_tt_format, summForLP)
        select tt_format, project, format_name, descr_format, tm, load_sr_checks_checkline_add_trigger, is_marketPlace, email, summForLP
          from #tt_format_project
    commit tran 
    
  end try
  begin catch
  
      insert into jobs.dbo.error_jobs(job_name, message, number_step, id_job)
      select @job_name, ERROR_MESSAGE(), 100, @id_job

  end catch
  

 
END
GO