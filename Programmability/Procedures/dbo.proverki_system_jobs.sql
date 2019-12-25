SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[proverki_system_jobs]
@id_job int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

declare @getdate datetime = getdate()



-- проверить, есть ли что в таблицах с данными из триггеров
exec jobs..input_jobs_triggers 


   
insert into jobs..Jobs_log ([id_job],[number_step],[duration]) 
select -3 , 5, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
select @getdate = getdate() 

-- запускать только если нет в этой минуте еще ни одного в логе с 50 :)
if not exists
(
select jl.id_job
from jobs..Jobs_log (nolock) jl
where jl.id_job=-3 and jl.number_step=59
and jl.date_add > dateadd(minute,-1,GETDATE())
)
begin

-- проверить, если ли новые задания jobs из jobs_reestr

exec jobs..make_new_jobs_from_reestr

insert into jobs..Jobs_log ([id_job],[number_step],[duration]) 
select -3 , 59, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) 
select @getdate = getdate() 

end


END
GO