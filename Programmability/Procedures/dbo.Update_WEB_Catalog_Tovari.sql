SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:  	OD
-- Create date: 2019-12-25
-- Description:	Обновление таблицы vv03..WEB_Catalog_Tovari  на srv-sql03
-- select * from jobs..jobs_union where job_name like '%%' order by date_add desc
-- =============================================
CREATE PROCEDURE [dbo].[Update_WEB_Catalog_Tovari] 
@id_job int
AS
BEGIN
  SET NOCOUNT ON

  --declare @id_job as int=0
  DECLARE @job_name varchar(1000) = com.dbo.Object_name_for_err(@@procid, DB_ID())
			,@msg VARCHAR(max)

 
  
  IF OBJECT_ID('tempdb..#WEB_Catalog_Tovari') IS NOT NULL
    DROP TABLE #WEB_Catalog_Tovari

	SELECT [id_tov],
    [Name_tov],
    [id_group],
    [Group_name],
    [id_group_parent],
    [Parent_Name],
    [id_group_parent1],
    [Parent_name_1],
    [CпецЦена],
    [При покупке],
    [CпецЦена Описание],
    [rn_gr],
    [rn_gr_par],
    [rn_gr_par1],
    [rn_tov],
    [sp_price_date_to],
    spec_tov 
	INTO #WEB_Catalog_Tovari
	FROM OPENQUERY([SRV-SQL01],'
  SELECT
    w.[id_tov],
    [Name_tov],
    [id_group],
    [Group_name],
    [id_group_parent],
    [Parent_Name],
    [id_group_parent1],
    [Parent_name_1],
    [CпецЦена],
    [При покупке],
    [CпецЦена Описание],
    [rn_gr],
    [rn_gr_par],
    [rn_gr_par1],
    [rn_tov],
    [sp_price_date_to],
    spec_tov 
  FROM m2.dbo.WEB_Catalog_Tovari w
  INNER JOIN Reports..Price_1C_tov AS pr
    ON w.id_tov = pr.id_tov')

  UPDATE #WEB_Catalog_Tovari
  SET [CпецЦена] = a.[CпецЦена],
      [При покупке] = a.[При покупке],
      [CпецЦена Описание] = a.[CпецЦена Описание],
      [sp_price_date_to] = a.[sp_price_date_to]
  --select *
  FROM #WEB_Catalog_Tovari AS t
  INNER JOIN (SELECT
    id_tov,
    ISNULL([CпецЦена], 0) [CпецЦена],
    ISNULL([При покупке], 0) [При покупке],
    [CпецЦена Описание],
    [sp_price_date_to]
  FROM #WEB_Catalog_Tovari WITH (NOLOCK)
  WHERE ISNULL([CпецЦена], 0) <> 0
  OR ISNULL([При покупке], 0) <> 0) a
    ON t.id_tov = a.id_tov
  WHERE ISNULL(t.[CпецЦена], 0) <> a.CпецЦена
  OR ISNULL(t.[При покупке], 0) <> a.[При покупке]

  CREATE INDEX ind1 ON #WEB_Catalog_Tovari  (id_tov,id_group,id_group_parent,id_group_parent1)

  IF EXISTS(SELECT 1
    FROM (SELECT
      [id_tov],
      [Name_tov],
      [id_group],
      [Group_name],
      [id_group_parent],
      [Parent_Name],
      [id_group_parent1],
      [Parent_name_1],
      [CпецЦена],
      [При покупке],
      [CпецЦена Описание],
      [rn_gr],
      [rn_gr_par],
      [rn_gr_par1],
      [sp_price_date_to],
      spec_tov
    FROM #WEB_Catalog_Tovari
    UNION ALL
    SELECT
      [id_tov],
      [Name_tov],
      [id_group],
      [Group_name],
      [id_group_parent],
      [Parent_Name],
      [id_group_parent1],
      [Parent_name_1],
      [CпецЦена],
      [При покупке],
      [CпецЦена Описание],
      [rn_gr],
      [rn_gr_par],
      [rn_gr_par1],
      [sp_price_date_to],
      spec_tov
    FROM [vv03].[dbo].[WEB_Catalog_Tovari] with(nolock)) a
    GROUP BY [id_tov],
             [Name_tov],
             [id_group],
             [Group_name],
             [id_group_parent],
             [Parent_Name],
             [id_group_parent1],
             [Parent_name_1],
             [CпецЦена],
             [При покупке],
             [CпецЦена Описание],
             [rn_gr],
             [rn_gr_par],
             [rn_gr_par1],
             [sp_price_date_to],
             spec_tov
    HAVING COUNT(*) <> 2)
BEGIN
	
		 -- SELECT * FROM #WEB_Catalog_Tovari ORDER BY id_tov
	  WHILE 1 = 1
	  BEGIN
	  BEGIN TRY
  
    		update b
    		set  b.[CпецЦена]=a.[CпецЦена]
				, b.[При покупке]=a.[При покупке]
				, b.[CпецЦена Описание]=a.[CпецЦена Описание]
				, b.Parent_Name=a.Parent_Name
				, b.Name_tov=a.Name_tov
				, b.Group_name=a.Group_name
				, b.spec_tov =a.spec_tov
				, b.sp_price_date_to=a.sp_price_date_to
				, b.rn_tov=a.rn_tov
				, b.rn_gr=a.rn_gr
				, b.rn_gr_par1=a.rn_gr_par1
				, b.rn_gr_par=a.rn_gr_par
				, b.Parent_name_1=a.Parent_name_1
    		--select *
			from  #WEB_Catalog_Tovari a
    		INNER join  vv03.dbo.WEB_Catalog_Tovari b (nolock)
				on a.id_tov=b.id_tov
					AND a.id_group=b.id_group
					AND (a.id_group_parent=b.id_group_parent  OR (a.id_group_parent IS NULL AND b.id_group_parent IS NULL))
					AND (a.id_group_parent1=b.id_group_parent1 OR (a.id_group_parent1 IS NULL AND b.id_group_parent1 IS NULL) )
    		where a.[CпецЦена]<>b.[CпецЦена] 
				or a.[При покупке]<>b.[При покупке] 
				or ISNULL(a.Parent_Name,'')<>ISNULL(b.Parent_Name,'')
				OR a.Name_tov<>b.Name_tov
				OR a.Group_name<>b.Group_name
				OR a.[CпецЦена Описание]<> b.[CпецЦена Описание]
				or ISNULL(a.Parent_name_1,'')<>ISNULL(b.Parent_name_1,'')
				OR a.spec_tov<> b.spec_tov
				OR ISNULL(a.sp_price_date_to,'19000101')<>ISNULL(b.sp_price_date_to,'19000101')
				OR a.rn_tov<> b.rn_tov
				OR ISNULL(a.rn_gr_par1,0)<>ISNULL(b.rn_gr_par1,0)
				OR ISNULL(a.rn_gr,0)<>ISNULL(b.rn_gr,0)
    
    		insert into vv03.dbo.WEB_Catalog_Tovari ( [id_tov],[Name_tov],[id_group],[Group_name],[id_group_parent]
    													,[Parent_Name],[id_group_parent1],[Parent_name_1],[CпецЦена],[При покупке],[CпецЦена Описание]
    														,[rn_gr],[rn_gr_par],[rn_gr_par1],[rn_tov],[sp_price_date_to]
    														, spec_tov)
    		select 	a.[id_tov],	a.[Name_tov],a.[id_group],a.[Group_name],a.[id_group_parent],a.[Parent_Name],a.[id_group_parent1],a.[Parent_name_1],
    					a.[CпецЦена],a.[При покупке],a.[CпецЦена Описание],a.[rn_gr],a.[rn_gr_par],a.[rn_gr_par1],a.[rn_tov],a.[sp_price_date_to],a.spec_tov
    		from  #WEB_Catalog_Tovari a
    		left join  vv03.dbo.WEB_Catalog_Tovari b 
				on a.id_tov=b.id_tov
					AND a.id_group=b.id_group
					AND (a.id_group_parent=b.id_group_parent  OR (a.id_group_parent IS NULL AND b.id_group_parent IS NULL))
					AND (a.id_group_parent1=b.id_group_parent1 OR (a.id_group_parent1 IS NULL AND b.id_group_parent1 IS NULL) )

    		where b.id_tov is null
    
    		delete from vv03.dbo.WEB_Catalog_Tovari
			--select *
    		from vv03.dbo.WEB_Catalog_Tovari a
    		left join  #WEB_Catalog_Tovari b 
												on a.id_tov=b.id_tov
					AND a.id_group=b.id_group
					AND (a.id_group_parent=b.id_group_parent  OR (a.id_group_parent IS NULL AND b.id_group_parent IS NULL))
					AND (a.id_group_parent1=b.id_group_parent1 OR (a.id_group_parent1 IS NULL AND b.id_group_parent1 IS NULL) )
			where b.id_tov is null
    
  

            BREAK
	  END TRY
	  BEGIN CATCH
		IF ERROR_NUMBER() <> 1205 --вызвала взаимоблокировку
		BEGIN
		  SET @msg=ERROR_MESSAGE()
		  EXEC com.dbo.jobs_error_ins @job_name=@job_name, @number_step=10, @id_job=@id_job, @message=@msg
		  RETURN
		END
	  END CATCH
	  END --while	

    IF EXISTS(SELECT 1
    FROM (SELECT
      [id_tov],
      [Name_tov],
      [id_group],
      [Group_name],
      [id_group_parent],
      [Parent_Name],
      [id_group_parent1],
      [Parent_name_1],
      [CпецЦена],
      [При покупке],
      [CпецЦена Описание],
      [rn_gr],
      [rn_gr_par],
      [rn_gr_par1],
      [sp_price_date_to],
      spec_tov
    FROM #WEB_Catalog_Tovari
    UNION ALL
    SELECT
      [id_tov],
      [Name_tov],
      [id_group],
      [Group_name],
      [id_group_parent],
      [Parent_Name],
      [id_group_parent1],
      [Parent_name_1],
      [CпецЦена],
      [При покупке],
      [CпецЦена Описание],
      [rn_gr],
      [rn_gr_par],
      [rn_gr_par1],
      [sp_price_date_to],
      spec_tov
    FROM [vv03].[dbo].[WEB_Catalog_Tovari] with(nolock)) a
    GROUP BY [id_tov],
             [Name_tov],
             [id_group],
             [Group_name],
             [id_group_parent],
             [Parent_Name],
             [id_group_parent1],
             [Parent_name_1],
             [CпецЦена],
             [При покупке],
             [CпецЦена Описание],
             [rn_gr],
             [rn_gr_par],
             [rn_gr_par1],
             [sp_price_date_to],
             spec_tov
    HAVING COUNT(*) <> 2)
  BEGIN
    EXEC com.dbo.jobs_error_ins @job_name= @job_name,
        @message='Расхождения в обновлении данных о заказах покупателя на 03 сервере.',
        @number_step=20,
        @id_job=@id_job
  END
END 
DROP TABLE #WEB_Catalog_Tovari

END
GO