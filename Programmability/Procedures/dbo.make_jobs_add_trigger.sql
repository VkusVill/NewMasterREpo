SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		OD
-- Create date: 2017-09-08
-- Description:	Обработка буферной таблицы заданий
-- =============================================
CREATE PROCEDURE [dbo].[make_jobs_add_trigger]
	@id_job as int 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

declare @proc_name as varchar(100)
declare crs_job  cursor for
select distinct [procedure_name] from jobs..jobs_add_trigger as j with(nolock)
open crs

fetch from crs_job into @proc_name
while @@FETCH_STATUS<>-1
begin
	fetch next from crs_job into @proc_name

end    

close crs_job
deallocate crs_job
END
GO