SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		OD
-- Create date: 2017-03-21
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Cards_ShopNo_upd_add_trigger_20190228]
@id_job as int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

if OBJECT_ID('tempdb..#inserted') is not null  drop table #inserted

SELECT  [number]
      , param2 [ShopNo] 
      , id [row_uid] 
      , [date_add]
into #inserted      
FROM [jobs].[dbo].[Jobs_add_trigger]  with(tablockx)
where procedure_name ='jobs..Cards_ShopNo_upd_add_trigger'


--declare @id_job as int=123456
declare @number as char(7), @ShopNo as int


declare crs_Cards_ShopNo_upd cursor for
  select distinct number,ShopNo from #inserted where number<>'' and isnull(shopNo,0)<>0
open crs_Cards_ShopNo_upd

fetch crs_Cards_ShopNo_upd into @number, @ShopNo

while @@FETCH_STATUS<>-1
begin

	 begin try
		if not exists (select *
		from vv03..cards_tov_tt as c with(nolock)
		where number=@number and   charindex(','+RTRIM(@shopno)+',', (',' + isnull(tt,'0')+','),1)>0 )
	
		begin

		   update vv03..cards_tov_tt  with(rowlock)	set tt=case when ISNULL(tt,'')='' then rtrim(@ShopNo) else RTRIM(@ShopNo)+',' +tt end
		   where number=@number
		   if @@ROWCOUNT=0
		   begin
		    INSERT INTO [vv03].[dbo].[Cards_tov_tt]  ([number],[tt])
			VALUES (@number,rtrim(@ShopNo))
		   end
		end  
	  end try
	  begin catch
		insert into jobs..error_jobs (number_step, job_name, id_job, message)
		select 100,'jobs..Cards_ShopNo_upd_add_trigger', @id_job, @number+RTRIM(@ShopNo)+ ERROR_MESSAGE()
	  end catch
	
	
	fetch next from crs_Cards_ShopNo_upd into @number,@Shopno

end

close crs_Cards_ShopNo_upd
deallocate crs_Cards_ShopNo_upd

delete from jobs..Jobs_add_trigger
from jobs..Jobs_add_trigger as c inner join #inserted i on c.id=i.row_uid
where c.[procedure_name]= 'jobs..Cards_ShopNo_upd_add_trigger'


END
GO