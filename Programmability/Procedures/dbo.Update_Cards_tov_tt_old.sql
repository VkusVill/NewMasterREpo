SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		OD
-- Create date: 2017-03-21
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Update_Cards_tov_tt_old]
@id_job as int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

if OBJECT_ID('tempdb..#inserted') is not null  drop table #inserted

SELECT  [number]
      ,[ShopNo]
      ,[row_uid]
      ,[date_add]
into #inserted      
FROM [jobs].[dbo].[Cards_ShopNo_upd]  with(tablockx)


--declare @id_job as int=123456
declare @number as char(7), @ShopNo as int
declare @Shop_str as varchar(max)
 

declare crs_Cards_ShopNo_upd cursor for
  select distinct number,ShopNo from #inserted where number<>'' and isnull(shopNo,0)<>0
open crs_Cards_ShopNo_upd

fetch crs_Cards_ShopNo_upd into @number, @ShopNo

while @@FETCH_STATUS<>-1
begin

	if OBJECT_ID('tempdb..#t') is not null  drop table #t
	select @Shop_str=tt 
	from vv03..cards_tov_tt as c with(nolock)
	where number=@number

	select @Shop_str=ISNULL(@Shop_str,'')

	select _ShopNo
	into #t
	from
		(select _ShopNo,row_number() over (partition by 0 order by (select 0)) rn
		from (select cast('<r><c>'+replace(@shop_str,',','</c><c>')+'</c></r>' as xml) ShopNo
				)t
			cross apply(select x.z.value('.', 'int') _ShopNo from ShopNo.nodes('/r/c') x(z))q)q1
			
			
	if not exists(select * from #t where _shopno=@ShopNo)
	begin
	  insert into #t (_ShopNo) values(@ShopNo)
		select  @Shop_str= SUBSTRING(convert(nvarchar(max),
		(select  ',' + rtrim(a._ShopNo )
		FROM #t a where _shopNo<>0
		FOR XML PATH(''),TYPE ))  , 2,10000 ) 
	  begin try	
	      select @number,@Shop_str
		  update vv03..cards_tov_tt  with(rowlock)	set tt=@Shop_str
		  where number=@number
		  if @@ROWCOUNT=0
		  begin
		   INSERT INTO [vv03].[dbo].[Cards_tov_tt]
				   ([number],[tt])
			VALUES
				   (@number,@Shop_str)
		  end
	  end try
	  begin catch
		insert into jobs..error_jobs (number_step, job_name, id_job, message)
		select 100,'vv03..Update_Cards_tov_tt', @id_job, @number+RTRIM(@ShopNo)+ ERROR_MESSAGE()
	  end catch
	end 
	
	fetch next from crs_Cards_ShopNo_upd into @number,@Shopno

end

close crs_Cards_ShopNo_upd
deallocate crs_Cards_ShopNo_upd

delete from jobs..Cards_ShopNo_upd
from Cards_ShopNo_upd as c inner join #inserted i on c.row_uid=i.row_uid

END
GO