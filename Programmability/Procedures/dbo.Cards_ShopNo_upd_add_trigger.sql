SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		OD
-- Create date: 2017-03-21
-- Description:	Обновление списка посещаемых магазинов после чека
--select  * from jobs..jobs as j with(nolock) where  job_name like '%Cards_ShopNo_upd_add_trigger%' 
-- =============================================
CREATE PROCEDURE [dbo].[Cards_ShopNo_upd_add_trigger]
@id_job as int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


DECLARE @getdate AS datetime = GETDATE()
         ,@job_name varchar(500)=com.dbo.Object_name_for_err(@@ProcID,db_id())    


if OBJECT_ID('tempdb..#inserted') is not null  drop table #inserted

SELECT  [number]
      , param2 [ShopNo] 
      , id [row_uid] 
      , [date_add]
      , CONVERT(varchar(max),null) ShopNo_res
INTO #inserted      
FROM [jobs].[dbo].[Jobs_add_trigger] 
WHERE [PROCEDURE_NAME] ='jobs..Cards_ShopNo_upd_add_trigger'

BEGIN TRY

	IF OBJECT_ID('tempdb..#Cards_tov_tt') IS NOT NULL  DROP TABLE #Cards_tov_tt
	  SELECT
		ctt.number,
		ctt.tt
	  INTO #Cards_tov_tt
	  FROM vv03..Cards_tov_tt AS ctt WITH (NOLOCK)
		INNER JOIN #inserted i
			on ctt.number=i.number
	  


	UPDATE #inserted SET ShopNo_res=vv03.dbo.union_str_unique(i.[ShopNo],c.tt ,',') 
	--select *, vv03.dbo.union_str_unique(i.[ShopNo],c.tt ,',') 
	FROM #inserted i
	  LEFT JOIN #Cards_tov_tt as c
		on i.number=c.number
	    
	    
	UPDATE vv03..Cards_tov_tt SET tt =i.ShopNo_RES
	--select ctt.number ,ctt.tt ,i.ShopNo_RES, i.ShopNo
	FROM vv03..Cards_tov_tt AS ctt WITH (NOLOCK)
		INNER JOIN #inserted i
			on ctt.number=i.number
	WHERE ctt.tt <> i.ShopNo_res or ctt.tt is null

	INSERT INTO [vv03].[dbo].[Cards_tov_tt]  ([number],[tt])
	SELECT  i.number  ,i.ShopNo_res
	FROM  (SELECT  number  ,max(ShopNo_res) ShopNo_res
		   from #inserted 
 	       group by number
	      )i
		LEFT JOIN  vv03..Cards_tov_tt AS ctt 
					on ctt.number=i.number
	WHERE  ctt.number is null



	DELETE FROM jobs..Jobs_add_trigger
	--select *
	FROM jobs..Jobs_add_trigger as c 
		inner join #inserted i on c.id=i.row_uid
	WHERE c.[procedure_name]= 'jobs..Cards_ShopNo_upd_add_trigger'


END TRY
BEGIN CATCH
    INSERT INTO jobs..error_jobs (job_name, number_step, message, id_job)
    SELECT @job_name, 100, ERROR_MESSAGE(), @id_job
END CATCH

END
GO