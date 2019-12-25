SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:  	OD
-- Create date: 2019-06-19
-- Description:	Обновление таблицы Tovar_BuyerOrder  на srv-sql03
-- select * from jobs..jobs_union where job_name like '%%' order by date_add desc
-- =============================================
CREATE PROCEDURE [dbo].[Update_Tovar_BuyerOrder] 
@id_job int
AS
BEGIN
  SET NOCOUNT ON

  --declare @id_job as int=0
  DECLARE @job_name varchar(1000) = com.dbo.Object_name_for_err(@@procid, DB_ID())

  IF OBJECT_ID('tempdb..#Tovar_BuyerOrder ') IS NOT NULL
    DROP TABLE #Tovar_BuyerOrder 

  SELECT
    BonusCard number
	, date_order
	, ShopNo
	, id_tov
	, quantity 
	, NOrder
	, SecretSanta
  INTO #Tovar_BuyerOrder 
  FROM OPENQUERY([srv-sql01],
  '	SELECT
    tdm.bonuscard,
    CAST(tdm.Date_proizv AS date) AS date_order,
    tdm.ShopNo_rep AS ShopNo,
    tdm.id_tov,
    SUM(CASE
      WHEN tdm.operation_type = 802 THEN 1
      ELSE -1
    END*tdm.Quantity) AS Quantity,
	clbo.NOrder,
    max(CASE WHEN ISNULL(clbo.Source, 0) IN (3,4) THEN 1 ELSE 0 END) AS SecretSanta
  FROM SMS_REPL.dbo.TD_move tdm (NOLOCK)
  INNER JOIN SMS_REPL.dbo.ClosedBuyersOrders802 clbo (NOLOCK)
  ON tdm.Id_doc = clbo.Id_doc

  WHERE
    tdm.operation_type IN (802, 803)
    AND tdm.Confirm_type = 1
  AND tdm.bonuscard is not null
    AND (CAST(tdm.Date_proizv AS date) between  convert(date,getdate()) and dateadd(day,7,convert(date,getdate()))
    OR CAST(ISNULL(clbo.StorageDate, ''19000101'') AS date) >= convert(date,getdate()))
  GROUP BY
    tdm.bonuscard,
    CAST(tdm.Date_proizv AS date),
  clbo.NOrder,
    tdm.ShopNo_rep,
    tdm.id_tov
  HAVING SUM(CASE
      WHEN tdm.operation_type = 802 THEN 1
      ELSE -1
    END*tdm.Quantity) <> 0')


  CREATE INDEX ind1 ON #Tovar_BuyerOrder  (number, date_order, ShopNo, id_tov,NOrder, SecretSanta)


  WHILE 1 = 1
  BEGIN
  BEGIN TRY

    MERGE INTO vv03..Tovar_BuyerOrder  t1
	USING #Tovar_BuyerOrder  t2
	  on t1.number=t2.number
	    and t1.date_order=t2.date_order
		and t1.ShopNo=t2.ShopNo
		and t1.id_tov=t2.id_tov
		AND t1.NOrder=t2.NOrder
    WHEN MATCHED AND ((t1.Quantity<>t2.Quantity) OR t1.SecretSanta<>t2.SecretSanta) THEN
	UPDATE SET t1.Quantity=t2.Quantity
			   ,t1.SecretSanta=t2.SecretSanta
			   ,t1.date_update=getdate()
    WHEN NOT MATCHED BY TARGET THEN
	INSERT (number, date_order, ShopNo, id_tov, quantity, date_update, NOrder, SecretSanta)
	VALUES (t2.number,  t2.date_order, t2.ShopNo, t2.id_tov, t2.Quantity, getdate(), t2.NOrder, t2.SecretSanta)
    WHEN NOT MATCHED BY SOURCE THEN
    DELETE ;  

    

    BREAK
  END TRY
  BEGIN CATCH
    IF ERROR_NUMBER() <> 1205 --вызвала взаимоблокировку
    BEGIN
      INSERT INTO jobs..error_jobs (job_name, message, number_step, id_job)
        SELECT
          @job_name,
          ERROR_MESSAGE(),
          10,
          @id_job
      RETURN
    END
  END CATCH
  END --while	

  IF EXISTS (SELECT
      1
    FROM (SELECT
      number
	, date_order
	, ShopNo
	, id_tov
	, quantity 
	, NOrder
	, SecretSanta 
    FROM vv03..Tovar_BuyerOrder 
    UNION ALL
    SELECT
      number
	, date_order
	, ShopNo
	, id_tov
	, quantity 
	, NOrder
	, SecretSanta 
    FROM #Tovar_BuyerOrder ) a
    group by number
	, date_order
	, ShopNo
	, id_tov
	, quantity 
	, NOrder
	, SecretSanta 
    HAVING COUNT(1) <> 2)
  BEGIN
    INSERT INTO jobs..error_jobs (job_name, message, number_step, id_job)
      SELECT
        @job_name,
        'Расхождения в обновлении данных о заказах покупателя на 03 сервере.',
        10,
        @id_job
  END

  DROP TABLE #Tovar_BuyerOrder 

END
GO