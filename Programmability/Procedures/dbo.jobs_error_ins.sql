SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
/*=============================================
Author:         Vl@d
Description:    
Date:           27/11/2019
============================================= */
CREATE PROCEDURE [dbo].[jobs_error_ins]
	@id_job			int,
	@job_name		sysname,
	@number_step	int = NULL,
	@message		nvarchar(max),
	@run_date		int = NULL,
	@run_time		int = NULL,
	@query_err		nvarchar(max) = NULL
AS
	
  SET NOCOUNT ON

  INSERT INTO jobs.dbo.error_jobs (
	id_job,
	job_name,
	message,
	run_date,
	run_time,
	number_step,
	query_err
	
  )
  SELECT
	@id_job,
	@job_name,
	@message,
	@run_date,
	@run_time,
	@number_step,
	@query_err
GO