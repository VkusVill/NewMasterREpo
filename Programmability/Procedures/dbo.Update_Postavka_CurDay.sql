SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:  	OD
-- Create date: 2016-02-17
-- Description:	Обновление таблицы Postavka_CurDay на srv-sql03
-- select * from jobs..jobs_union where job_name like '%SRV_SQL03__Postavka_CurDay_upd%' order by date_add desc
-- =============================================
CREATE PROCEDURE [dbo].[Update_Postavka_CurDay] @id_job int
AS
BEGIN
  SET NOCOUNT ON

  --declare @id_job as int=0
  DECLARE @job_name varchar(1000) = com.dbo.Object_name_for_err(@@procid, DB_ID())

  IF OBJECT_ID('tempdb..#Postavka_CurDay') IS NOT NULL
    DROP TABLE #Postavka_CurDay

  SELECT
    id_tt,
    id_tov,
    qty_RO,
    qty_TD INTO #Postavka_CurDay
  FROM OPENQUERY([srv-sql01],
  'select a.id_tt
	, a.id_tov
	, convert(decimal(15,3),sum(a.qty_RO)) qty_RO
	, convert(decimal(15,3),sum(a.qty_TD)) qty_TD
from(	select id_tt, id_tov, post qty_TD, 0 qty_RO 
		from reports..DTT with(nolock)
		where date_tt=convert(date,getdate()) and post>0
		union all
		select TT_Id,Tovar_Id,0,p.Kolvo
		from SMS_IZBENKA..Postavka_curr_Sklad as p
		where TT_Id is not null
		)a
group by a.id_tt, a.id_tov') a


  CREATE INDEX ind1 ON #Postavka_CurDay (id_tt, id_tov)


  WHILE 1 = 1
  BEGIN
  BEGIN TRY

    UPDATE vv03..Postavka_CurDay
    SET Quantity_RO = ISNULL(a.Qty_RO, 0),
        Quantity_TD = ISNULL(a.Qty_TD, 0),
        Shopno = tt.N,
        date_last_upd = GETDATE()
    FROM vv03..Postavka_CurDay c
    INNER JOIN #Postavka_CurDay a
      ON a.id_tt = c.id_tt
      AND a.id_tov = c.Id_tov
    INNER JOIN vv03..tt WITH (NOLOCK)
      ON a.id_tt = tt.id_tt
    WHERE c.Quantity_RO <> a.Qty_RO
    OR c.Quantity_TD <> a.Qty_TD
    OR c.ShopNo <> tt.N

    INSERT INTO vv03..Postavka_CurDay ([id_tt], [ShopNo], [id_tov], [Quantity_RO], [Quantity_TD], [date_last_upd])
    SELECT
      a.[id_tt],
      tt.[N],
      a.[id_tov],
      ISNULL(a.[Qty_RO], 0),
      ISNULL(a.[Qty_TD], 0),
      GETDATE() [date_last_upd]
    FROM #Postavka_CurDay a
    INNER JOIN vv03..tt WITH (NOLOCK)
      ON a.id_tt = tt.id_tt
    LEFT JOIN vv03..Postavka_CurDay c
      ON a.id_tt = c.id_tt
      AND a.id_tov = c.id_tov
    WHERE c.id_tt IS NULL

    DELETE FROM vv03..Postavka_CurDay
    FROM vv03..Postavka_CurDay c
    LEFT JOIN #Postavka_CurDay a
      ON a.id_tt = c.id_tt
      AND a.id_tov = c.Id_tov
    WHERE a.id_tt IS NULL

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
      [id_tt],
      [ShopNo],
      [id_tov],
      [Quantity_RO],
      [Quantity_TD]
    FROM vv03..Postavka_CurDay
    UNION ALL
    SELECT
      a.[id_tt],
      tt.N,
      a.[id_tov],
      a.[Qty_RO],
      a.[Qty_TD]
    FROM #Postavka_CurDay a
    INNER JOIN vv03..tt WITH (NOLOCK)
      ON a.id_tt = tt.id_tt) a
    GROUP BY a.id_tt,
             a.id_tov,
             a.ShopNo,
             a.Quantity_RO,
             a.Quantity_TD
    HAVING COUNT(1) <> 2)
  BEGIN
    INSERT INTO jobs..error_jobs (job_name, message, number_step, id_job)
      SELECT
        @job_name,
        'Расхождения в обновлении данных о поставках текущего дня на 03 сервере.',
        10,
        @id_job
  END

  DROP TABLE #Postavka_CurDay

END
GO