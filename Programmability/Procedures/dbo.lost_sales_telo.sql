SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		Андрей Кривенко
-- Create date: 
-- Description:	Расчет потерянных
-- 20191113 MV - Добавлено обновление Lost_sales_01 на 06 сервере в VV06
-- OD 2019-11-17 обновление Lost_sales_01 на 06 через Jobs иначе утреннее блокируется утреннее распределение
--select * from jobs..Jobs as j with(nolock) where j.job_name like '%create_%' and date_exc  is null
--select * from jobs..Jobs_union as j with(nolock) where j.job_name like '%create_lost%' order by date_add desc
-- =============================================

CREATE PROCEDURE [dbo].[lost_sales_telo]
  @date1  date,
  @date2  date,
  @id_job int
AS
BEGIN  
  SET NOCOUNT ON

  --DECLARE @job_name varchar(100) = com.dbo.Object_name_for_err(@@procid, DB_ID())

  /*
2016-04-27
Добавить столбец id_kontr_fp  фактическая поставка
[14:32:29] Andy Krivenko: последняя поставка, включая день продажи
лучше td_move, продавцы могли поправить
*/

  -- если @date1 менее или равно {d'2019-03-09'} и @date2 более {d'2019-03-09'}, то от @date1 отнять 4 дня
  SET @date1 = CASE WHEN @date1 <= '20190309' AND @date2 > '20190309' THEN DATEADD(DAY, -4, @date1)
                 ELSE @date1
               END

  --declare @date1 date = {d'2019-05-07'} , @date2 date = {d'2019-05-07'}, @id_job as int = 112718,@job_name varchar(100)='test'
  DECLARE @getdate datetime = GETDATE()

  TRUNCATE TABLE m2.dbo.Lost_sales_temp_01

  -- взять из 1С остатки товаров на конец каждого ЛУ
  IF OBJECT_ID('tempdb..#dates') IS NOT NULL
    DROP TABLE #dates

  SELECT DISTINCT
    DATEADD(YEAR, 2000, CONVERT(date, ch.CloseDate)) AS date_ch
  INTO #dates
  FROM SMS_REPL.dbo.Checks AS ch WITH(NOLOCK) 
  WHERE CONVERT(date, ch.CloseDate) BETWEEN @date1 AND @date2
        AND CONVERT(date, ch.CloseDate) NOT BETWEEN '20190306' AND '20190309'

  INSERT INTO jobs.dbo.Jobs_log ([id_job], [number_step], [duration], par3)
  SELECT
    @id_job,
    10,
    DATEDIFF(MILLISECOND, @getdate, GETDATE()),
    CONVERT(varchar(10), @date1, 120) + ' - ' + CONVERT(varchar(10), @date2, 120)

  SET @getdate = GETDATE()

  IF OBJECT_ID('tempdb..#1C_ost') IS NOT NULL
    DROP TABLE #1C_ost

  SELECT
    DATEADD(YEAR, -2000, date_ch) date,
    TT_Skladi.id_TT,
    Goods._Fld760 AS id_tov,
    kolvo
  INTO #1C_ost
  FROM (  SELECT
            date_ch,
            _Fld3246RRef,
            _Fld3247RRef,
            SUM(a.kolvo) AS kolvo
          FROM ( SELECT
                  dates.date_ch,
                  Amounts._Fld3246RRef,
                  Amounts._Fld3247RRef,
                  CONVERT( real,
                           Amounts._Fld3250 * (CASE WHEN ISNULL(Measurements._Fld178, 0) = 0 THEN 1
                                                 ELSE Measurements._Fld178
                                               END
                                              )
                         ) AS kolvo
                FROM IzbenkaFin.dbo._AccumRgT3252 AS Amounts WITH (NOLOCK)
                LEFT JOIN IzbenkaFin.dbo._Reference21 AS Measurements WITH (NOLOCK)
                  ON Amounts._Fld3249RRef = Measurements._IDRRef
                INNER JOIN #dates dates
                  ON 1 = 1
                WHERE Amounts._Period IN (  SELECT
                                              MAX(Amounts._Period)
                                            FROM IzbenkaFin.dbo._AccumRgT3252 AS Amounts WITH (NOLOCK)
                                          )
                UNION ALL
                SELECT
                  dates.date_ch,
                  Amounts._Fld3246RRef,
                  Amounts._Fld3247RRef,
                  CONVERT(real,
                          SUM( Amounts._Fld3250 * (CASE WHEN ISNULL(Measurements._Fld178, 0) = 0 THEN 1
                                                        ELSE Measurements._Fld178
                                                     END
                                                    ) * CASE Amounts._RecordKind WHEN 0 THEN -1 ELSE 1 END
                             )
                         ) AS kolvo
                FROM IzbenkaFin.dbo._AccumRg3245 AS Amounts WITH (NOLOCK)
                LEFT JOIN IzbenkaFin.dbo._Reference21 AS Measurements WITH (NOLOCK)
                  ON Amounts._Fld3249RRef = Measurements._IDRRef
                INNER JOIN #dates dates
                  ON CONVERT(date, Amounts._Period) > dates.date_ch -- на вечер остатки
                GROUP BY dates.date_ch,
                         Amounts._Fld3246RRef,
                         Amounts._Fld3247RRef
              ) AS a
            GROUP BY date_ch,
                     _Fld3246RRef,
                     _Fld3247RRef
     ) Amounts
  INNER JOIN (  SELECT
                TT._Fld758 AS id_TT,
                Storages._IDRRef AS SkladSsilka,
                Storages._Fld3349RRef AS VidSklada
              FROM IzbenkaFin.dbo._Reference1321 AS Storages WITH (NOLOCK)
              INNER JOIN IzbenkaFin.dbo._Reference42 AS TT WITH (NOLOCK)
                ON Storages._IDRRef = TT._Fld3281RRef
            ) AS TT_Skladi
    ON Amounts._Fld3246RRef = TT_Skladi.SkladSsilka
  LEFT JOIN IzbenkaFin.dbo._Reference29 AS Goods WITH (NOLOCK)
    ON Amounts._Fld3247RRef = Goods._IDRRef
  WHERE Goods._Fld760 IS NOT NULL

  --select *
  --from #1C_ost
  --where id_tt=333 and id_tov=46

  EXEC com.dbo.jobs_log_ins @id_job, 20, @getdate OUTPUT  

  CREATE UNIQUE CLUSTERED INDEX ind1 ON #1C_ost (date, id_TT, id_tov)

  CREATE INDEX ind2 ON #1C_ost (date, id_TT)

  -- удалить все дни, когда не было операций по остаткам в 1С
  DELETE FROM ost
  FROM #1C_ost AS ost
  LEFT JOIN ( SELECT
                TT_Skladi.id_TT,
                DATEADD(YEAR, -2000, amounts.date_ch) AS date
              FROM ( SELECT DISTINCT
                           dates.date_ch,
                           Amounts._Fld3246RRef
                    FROM IzbenkaFin.dbo._AccumRg3245 AS Amounts WITH (NOLOCK)
                    INNER JOIN #dates dates
                      ON CONVERT(date, Amounts._Period) = dates.date_ch -- операции за день
                  ) amounts
              INNER JOIN ( SELECT
                            TT._Fld758 AS id_TT,
                            Storages._IDRRef AS SkladSsilka,
                            Storages._Fld3349RRef AS VidSklada
                          FROM IzbenkaFin.dbo._Reference1321 AS Storages WITH (NOLOCK)
                          INNER JOIN IzbenkaFin.dbo._Reference42 AS TT WITH (NOLOCK)
                            ON Storages._IDRRef = TT._Fld3281RRef
                        ) AS TT_Skladi
                  ON amounts._Fld3246RRef = TT_Skladi.SkladSsilka
              ) a
    ON  a.id_TT = ost.id_TT
       AND 
        a.date = ost.date
  WHERE a.id_TT IS NULL

  EXEC com.dbo.jobs_log_ins @id_job, 30, @getdate OUTPUT

  -- добавить просто запись + time_0
  --declare @date1 as date = {d'2014-06-13'} , @date2 as date = {d'2014-06-13'} 
  --declare @datenow as datetime = getdate() -- дата начала

  --declare @date1 as date = getdate() , @date2 as date = getdate() 
  IF OBJECT_ID('tempdb..#tovari') IS NOT NULL
    DROP TABLE #tovari

  IF OBJECT_ID('tempdb..#tt') IS NOT NULL
    DROP TABLE #tt

  SELECT
    id_tov,
    bez_ostatkov
  INTO #tovari
  FROM m2.dbo.Tovari

  SELECT
    id_TT,
    tt_format,
    N
  INTO #tt
  FROM m2.dbo.tt

  IF OBJECT_ID('tempdb..#ins_ls') IS NOT NULL
    DROP TABLE #ins_ls

  CREATE TABLE #ins_ls (
    date_ch   date,
    id_tt_cl  int,
    id_tov_cl int,
    time_0    time,
    sales     real,
    sales_q   real,
    N         int
  )

  --delete from #ins_ls
  INSERT INTO #ins_ls 
  SELECT
    a.date_ch,
    a.id_tt_cl,
    a.id_tov_cl,
    a.time_0,
    a.sales,
    a.sales_q,
    tt.N
  FROM (  SELECT
            chl.date_ch,
            chl.id_tt_cl,
            chl.id_tov_cl,
            MAX(chl.time_ch) AS time_0,
            SUM(CASE WHEN chl.BaseSum > 0 THEN chl.Quantity * chl.znak ELSE 0 END) AS sales,
            COUNT(CASE WHEN chl.BaseSum > 0 THEN chl.Quantity ELSE NULL END) AS sales_q
          FROM SMS_UNION.dbo.CheckLine AS chl WITH (NOLOCK)
          WHERE chl.date_ch BETWEEN @date1 AND @date2
                AND chl.date_ch NOT BETWEEN '20190306' AND '20190309'
                AND ABS(chl.Quantity) < 20
                AND chl.id_tt_cl IS NOT NULL
                AND chl.id_tov_cl IS NOT NULL
                AND chl.time_ch IS NOT NULL
                AND chl.znak IS NOT NULL
                AND ISNULL(chl.id_discount_chl, 0) <> 6 --продажи по зеленому ценнику
          GROUP BY chl.date_ch,
                   chl.id_tt_cl,
                   chl.id_tov_cl
        ) AS a
  INNER JOIN #tovari AS t
    ON  t.id_tov = a.id_tov_cl
       AND 
        ISNULL(t.bez_ostatkov, 0) = 0
  INNER JOIN #tt tt
    ON tt.id_TT = a.id_tt_cl

  DROP TABLE #tovari

  CREATE UNIQUE CLUSTERED INDEX ind1
  ON #ins_ls (
               id_tov_cl,
               id_tt_cl,
               date_ch
             )

  -----------------------------------------------------------------------------------------------------------------------------

  -- новое - удалить пару из полных аналогов 
  -- ищем дни, когда на 1 ТТ более 1 товара с общим id_tov_osnovn
  -- и схлопывем их в один товар, с наибольшей продажей (по весу)
  CREATE TABLE #tz(
    id_tov_Osnovn  int,
    id_tov_Zadvoen int,
    koef           real
  )

  INSERT INTO #tz (
    id_tov_Osnovn,
    id_tov_Zadvoen,
    koef
  )
  SELECT
    t.id_tov_Osnovn,
    t.id_tov_Zadvoen,
    t2.Ves / t1.Ves
  FROM Reports.dbo.tov_poln_zamenyaem t
  INNER JOIN m2.dbo.Tovari t1
    ON t1.id_tov = t.id_tov_Osnovn
  INNER JOIN m2.dbo.Tovari t2
    ON t2.id_tov = t.id_tov_Zadvoen

  CREATE UNIQUE CLUSTERED INDEX ind1 ON #tz (id_tov_Zadvoen)

  --
  IF OBJECT_ID('tempdb..#zadv_tov') IS NOT NULL
    DROP TABLE #zadv_tov

  CREATE TABLE #zadv_tov(
    date_ch   date,
    id_tt_cl  int,
    id_tov    int,
    id_tov_cl int,
    q         real,
    koef      real,
    time_0    time
  )

  INSERT INTO #zadv_tov (
    date_ch,
    id_tt_cl,
    id_tov,
    id_tov_cl,
    q,
    koef,
    time_0
  )
  SELECT
    date_ch,
    id_tt_cl,
    id_tov,
    id_tov_cl,
    q,
    koef,
    time_0
  FROM ( SELECT
          i.date_ch,
          i.id_tt_cl,
          ISNULL(tz.id_tov_Osnovn, i.id_tov_cl) id_tov,
          i.id_tov_cl,
          i.sales / ISNULL(tz.koef, 1) q,
          tz.koef,
          i.time_0,
          ROW_NUMBER() OVER (PARTITION BY
                               i.date_ch,
                               i.id_tt_cl,
                               ISNULL(tz.id_tov_Osnovn, i.id_tov_cl)
                             ORDER BY i.sales / ISNULL(tz.koef, 1) DESC,
                                      tz.koef,
                                      i.time_0
                            ) AS rn
        FROM #ins_ls AS i
        LEFT JOIN #tz AS tz
          ON i.id_tov_cl = tz.id_tov_Zadvoen
      ) AS a
  WHERE a.rn > 1

  -- удаление
  DELETE FROM i
  FROM #ins_ls AS i
  INNER JOIN #zadv_tov z
    ON i.date_ch = z.date_ch
       AND i.id_tt_cl = z.id_tt_cl
       AND i.id_tov_cl = z.id_tov_cl

  -- добавить удаленные товары их задвоений
  --select  *, 
  UPDATE #ins_ls
  SET
    time_0 = CASE WHEN z.time_0 > i2.time_0 THEN z.time_0 ELSE i2.time_0 END,
    sales = i2.sales + z.q * ISNULL(i.koef, 1),
    sales_q = i2.sales_q + z.q * ISNULL(i.koef, 1)
  FROM #ins_ls i2
  INNER JOIN ( SELECT
                i.date_ch,
                i.id_tt_cl,
                ISNULL(tz.id_tov_Osnovn, i.id_tov_cl) id_tov,
                i.id_tov_cl,
                tz.koef
              FROM #ins_ls i
              LEFT JOIN #tz tz
                ON i.id_tov_cl = tz.id_tov_Zadvoen
            ) AS i
    ON i.date_ch = i2.date_ch
       AND i.id_tt_cl = i2.id_tt_cl
       AND i.id_tov_cl = i2.id_tov_cl
  INNER JOIN ( SELECT
                z.date_ch,
                z.id_tt_cl,
                z.id_tov,
                SUM(z.q) q,
                MAX(z.time_0) time_0 -- уже в базовом весе
              FROM #zadv_tov z
              GROUP BY z.date_ch,
                       z.id_tt_cl,
                       z.id_tov
            ) z
    ON i.date_ch = z.date_ch
       AND i.id_tt_cl = z.id_tt_cl
       AND i.id_tov = z.id_tov

  -----------------------------------------------------------------------------------------------------------------------------
  DROP TABLE #zadv_tov

  INSERT INTO m2.dbo.Lost_sales_temp_01 (
    date_ls,
    id_tt_ls,
    id_tov_ls,
    time_0,
    sales_fact,
    sales_q,
    shopno_ls
  )
  SELECT
    a.date_ch,
    a.id_tt_cl,
    a.id_tov_cl,
    a.time_0,
    a.sales,
    a.sales_q,
    a.N
  FROM #ins_ls a

  EXEC com.dbo.jobs_log_ins @id_job, 40, @getdate OUTPUT

  -- проставить, если ли  в матрице и какой контрагент в матрице
  IF OBJECT_ID('tempdb..price#') IS NOT NULL
    DROP TABLE #price

  SELECT 
    *
  INTO #price
  FROM m2.dbo.Price

  -- новое АК - убрать статус 2 и 3
  CREATE CLUSTERED INDEX ind1 ON #price (id_tov, id_tt)

  --declare @date1 as date = {d'2014-08-04'},  @date2 as date = {d'2014-08-04'}	

  ----------------------------------------------------------------------------------------------
  IF OBJECT_ID('tempdb..#ls_2') IS NOT NULL
    DROP TABLE #ls_2

  SELECT
    *
  INTO #ls_2
  FROM ( SELECT
          ls.date_ls,
          ls.id_tt_ls,
          ls.id_tov_ls,
          pr.cena,
          pr.id_kontr,
          ROW_NUMBER() OVER (PARTITION BY
                               ls.date_ls,
                               ls.id_tt_ls,
                               ls.id_tov_ls
                             ORDER BY pr.date_pr DESC
                            ) rn
        FROM m2.dbo.Lost_sales_temp_01 AS ls WITH (INDEX(IX_Lost_sales_temp), NOLOCK)
        INNER JOIN #price pr
          ON ls.id_tt_ls = pr.id_tt
             AND ls.id_tov_ls = pr.id_tov
             AND ls.date_ls >= pr.date_pr
        WHERE ls.date_ls BETWEEN @date1 AND @date2
      ) a
  WHERE a.rn = 1

  UPDATE m2.dbo.Lost_sales_temp_01
  SET id_kontr_matrix = CASE  WHEN a.cena > 0 AND Tovari.ЕстьАктХар = 1 THEN kontr.id_ul_post
                              ELSE NULL
                        END,
    is_matrix = CASE WHEN a.cena > 0 AND Tovari.ЕстьАктХар = 1 THEN 1 ELSE 0 END,
    price_ls = a.cena
  FROM m2.dbo.Lost_sales_temp_01 AS ls WITH (INDEX(IX_Lost_sales_temp), ROWLOCK)
  INNER JOIN #ls_2 a
    ON ls.date_ls = a.date_ls
       AND ls.id_tt_ls = a.id_tt_ls
       AND ls.id_tov_ls = a.id_tov_ls
  INNER JOIN m2.dbo.kontr WITH(NOLOCK)
    ON kontr.id_kontr = a.id_kontr
  INNER JOIN m2.dbo.Tovari WITH(NOLOCK)
    ON Tovari.id_tov = a.id_tov_ls
  WHERE ls.id_kontr_matrix <> CASE  WHEN a.cena > 0 AND Tovari.ЕстьАктХар = 1 THEN kontr.id_ul_post
                                    ELSE NULL
                              END
          OR ls.is_matrix <> CASE WHEN a.cena > 0 AND Tovari.ЕстьАктХар = 1 THEN 1 ELSE 0 END        

  DROP TABLE #ls_2

  EXEC com.dbo.jobs_log_ins @id_job, 90, @getdate OUTPUT

  IF OBJECT_ID('tempdb..#ch') IS NOT NULL
    DROP TABLE #ch

  SELECT
    CONVERT(date, ch.CloseDate) AS date,
    ch.ShopNo,
    COUNT(*) колво
  INTO #ch
  FROM SMS_UNION.dbo.Checks AS ch WITH (NOLOCK)
  WHERE ch.BaseSum > 0
        AND CONVERT(date, ch.CloseDate) BETWEEN @date1 AND @date2
  GROUP BY CONVERT(date, ch.CloseDate),
           ch.ShopNo

  EXEC com.dbo.jobs_log_ins @id_job, 100, @getdate OUTPUT

  -- добавить товары из матрицы, но по которым нет продаж

  ----------------------------------------------------------------------------------------------	
  CREATE INDEX ind1 ON #ch (date, ShopNo)

  IF OBJECT_ID('tempdb..#ls11') IS NOT NULL
    DROP TABLE #ls11

  IF OBJECT_ID('tempdb..#pr1') IS NOT NULL
    DROP TABLE #pr1

  SELECT DISTINCT
    ls.date_ls,
    ls.id_tt_ls,
    ls.shopno_ls
  INTO #ls11
  FROM m2.dbo.Lost_sales_temp_01 AS ls WITH (NOLOCK, INDEX(IX_Lost_sales_temp))
  WHERE ls.date_ls BETWEEN @date1 AND @date2

  SELECT
    ls.date_ls,
    ls.id_tt_ls,
    ls.shopno_ls,
    pr.id_tov,
    pr.id_kontr,
    pr.cena,
    ROW_NUMBER() OVER (PARTITION BY ls.date_ls, ls.id_tt_ls, pr.id_tov ORDER BY pr.date_pr DESC) rn
  INTO #pr1
  FROM #price AS pr
  INNER JOIN #ls11 ls
    ON ls.date_ls >= pr.date_pr
       AND ls.id_tt_ls = pr.id_tt

  CREATE UNIQUE CLUSTERED INDEX ind1 ON #pr1 (date_ls, id_tt_ls, id_tov)

  INSERT INTO m2.dbo.Lost_sales_temp_01 (
    date_ls,
    id_tt_ls,
    id_tov_ls,
    id_kontr_matrix,
    checks_2,
    price_ls,
    is_matrix,
    shopno_ls
  )
  SELECT
    a.date_ls,
    a.id_tt_ls,
    a.id_tov,
    kontr.id_ul_post,
    b.колво,
    a.cena,
    1,
    tt.N
  FROM #pr1 AS a
  LEFT JOIN #tz tz0
    ON a.id_tov = tz0.id_tov_Zadvoen
  INNER JOIN m2.dbo.kontr WITH(NOLOCK)
    ON kontr.id_kontr = a.id_kontr
  INNER JOIN m2.dbo.Tovari WITH(NOLOCK)
    ON Tovari.id_tov = a.id_tov
       AND ISNULL(Tovari.bez_ostatkov, 0) = 0
  INNER JOIN m2.dbo.tt WITH(NOLOCK)
    ON tt.id_TT = a.id_tt_ls
       AND tt.is_active = 1
       AND tt.type_tt = 'торговая'
  LEFT JOIN ( SELECT
                ls.*,
                ISNULL(tz.id_tov_Osnovn, ls.id_tov_ls) id_tov
              FROM m2.dbo.Lost_sales_temp_01 (NOLOCK) ls
              LEFT JOIN #tz tz
                ON ls.id_tov_ls = tz.id_tov_Zadvoen
            ) AS ls
    ON ls.date_ls = a.date_ls
       AND ls.id_tt_ls = a.id_tt_ls
       AND ls.id_tov = ISNULL(tz0.id_tov_Osnovn, a.id_tov)
  INNER JOIN #ch b
    ON b.date = a.date_ls
       AND b.ShopNo = a.shopno_ls
  WHERE a.rn = 1
        AND Tovari.ЕстьАктХар = 1
        AND a.cena > 0
        AND ls.date_ls IS NULL

  DROP TABLE #price
  DROP TABLE #pr1
  DROP TABLE #ls11
  DROP TABLE #tz
  DROP TABLE #ch

  EXEC com.dbo.jobs_log_ins @id_job, 120, @getdate OUTPUT

  --	declare @date1 as date = {d'2015-11-01'} , @date2 as date = {d'2015-11-08'} 
  DECLARE @date_ch date

  IF OBJECT_ID('tempdb..#lu_VV') IS NOT NULL
    DROP TABLE #lu_VV

  CREATE TABLE #lu_VV (
    Дата    date,
    id_tov  int,
    id_tt   int           NULL,
    ShopNo  int,
    Kon_ost decimal(15, 3)
  )

  DECLARE crs CURSOR FOR
    SELECT
      DATEADD(YEAR, -2000, date_ch) date_ch
    FROM #dates
    ORDER BY date_ch

  OPEN crs

  FETCH crs INTO @date_ch

  WHILE @@FETCH_STATUS = 0
  BEGIN
    INSERT INTO #lu_VV (
      Дата,
      id_tov,
      ShopNo,
      Kon_ost
    )
    SELECT
      @date_ch,
      b.id_tov,
      b.ShopNo,
      SUM(b.Kon_ost) КонОст
    FROM (SELECT
            [id_tov],
            ShopNo_rep ShopNo,
            -SUM( CASE  WHEN atd.closedate >= DATEADD(DAY, 1, @date_ch) THEN atd.q * znak
                        ELSE 0
                  END
                ) AS Kon_ost
          FROM [SMS_REPL].[dbo].[All_td_docs_centr] AS atd
          WHERE atd.closedate >= @date_ch
                AND atd.Confirm_type IN ( 0, 1 )
          GROUP BY [id_tov],
                   ShopNo_rep
          UNION ALL
          SELECT
            tos.id_tov,
            tos.ShopNo_rep,
            tos.Ost_kon
          FROM SMS_REPL.dbo.TD_ost AS tos WITH(NOLOCK) 
    ) b
    GROUP BY b.id_tov,
             b.ShopNo

    FETCH NEXT FROM crs INTO @date_ch
  END

  CLOSE crs
  DEALLOCATE crs

  UPDATE #lu_VV
  SET id_tt = tt.id_TT
  FROM #lu_VV lu
  INNER JOIN m2.dbo.tt
    ON lu.ShopNo = tt.N

  EXEC com.dbo.jobs_log_ins @id_job, 130, @getdate OUTPUT

  IF OBJECT_ID('tempdb..#ls_upd') IS NOT NULL
    DROP TABLE #ls_upd

  SELECT
    ls.date_ls,
    ls.id_tt_ls,
    ls.id_tov_ls,
    ISNULL((CASE WHEN lu_vv.Kon_ost IS NULL THEN ost.kolvo ELSE lu_vv.Kon_ost END), 0) AS ko
  INTO #ls_udp
  FROM m2.dbo.Lost_sales_temp_01 AS ls
  INNER JOIN m2.dbo.tt
    ON tt.id_TT = ls.id_tt_ls
  LEFT JOIN ( SELECT DISTINCT 
                date, 
                id_TT 
              FROM #1C_ost) AS ost_d
    ON ost_d.date = ls.date_ls
       AND ost_d.id_TT = ls.id_tt_ls
  LEFT JOIN #1C_ost ost
    ON ost.date = ls.date_ls
       AND ost.id_TT = ls.id_tt_ls
       AND ost.id_tov = ls.id_tov_ls
  LEFT JOIN #lu_VV lu_vv
    ON ls.date_ls = lu_vv.Дата
       AND ls.id_tt_ls = lu_vv.id_tt
       AND ls.id_tov_ls = lu_vv.id_tov
  WHERE ABS(konost_ls - ISNULL((CASE WHEN lu_vv.Kon_ost IS NULL THEN ost.kolvo ELSE lu_vv.Kon_ost END), 0)) > 0.001
        AND ls.date_ls BETWEEN @date1 AND @date2

  DROP TABLE #1C_ost
  DROP TABLE #lu_VV

  EXEC com.dbo.jobs_log_ins @id_job, 150, @getdate OUTPUT

  ----------------------------------------------------------------------------------------------
  UPDATE m2.dbo.Lost_sales_temp_01 WITH (ROWLOCK)
  SET konost_ls = ls_udp.ko
  FROM m2.dbo.Lost_sales_temp_01 AS ls WITH (INDEX(IX_Lost_sales_temp))
  INNER JOIN #ls_udp AS ls_udp
    ON ls.date_ls = ls_udp.date_ls
       AND ls.id_tt_ls = ls_udp.id_tt_ls
       AND ls.id_tov_ls = ls_udp.id_tov_ls

  DROP TABLE #ls_udp

  EXEC com.dbo.jobs_log_ins @id_job, 160, @getdate OUTPUT

  -- проставить контрагента
  --declare @date1 as date = {d'2016-04-28'},  @date2 as date = {d'2016-04-28'}
  IF OBJECT_ID('tempdb..#ch_man') IS NOT NULL
    DROP TABLE #ch_man

  SELECT
    *
  INTO #ch_man
  FROM (SELECT
          a.date_ch,
          a.id_tt_cl,
          a.id_tov_cl,
          a.id_kontr,
          a.sales_fact_scan,
          ROW_NUMBER() OVER (PARTITION BY a.date_ch, a.id_tt_cl, a.id_tov_cl ORDER BY колво DESC) rn
        FROM ( SELECT
                chl.date_ch,
                chl.id_tt_cl,
                chl.id_tov_cl,
                ISNULL(chl.id_kontr, 0) AS id_kontr,
                COUNT(*) AS колво,
                SUM(chl.Quantity * chl.znak) AS sales_fact_scan
              FROM SMS_UNION.dbo.CheckLine AS chl WITH (INDEX(IX_CheckLine_3), NOLOCK)
              WHERE chl.date_ch BETWEEN @date1 AND @date2
                  AND chl.OperationType_cl IN ( 1, 3 )
                  AND ISNULL(chl.id_kontr, 0) <> 0
              GROUP BY chl.date_ch,
                       chl.id_tt_cl,
                       chl.id_tov_cl,
                       ISNULL(chl.id_kontr, 0)
            ) a
      ) b
  WHERE b.rn = 1

  --drop table #kontr
  EXEC com.dbo.jobs_log_ins @id_job, 190, @getdate OUTPUT

  ----------------------------------------------------------------------------------------------
  CREATE INDEX ind1 ON #ch_man (date_ch, id_tt_cl, id_tov_cl)

  UPDATE m2.dbo.Lost_sales_temp_01
  SET id_kontr_ls = b.id_kontr,
      sales_fact_scan = b.sales_fact_scan
  FROM m2.dbo.Lost_sales_temp_01 AS ls WITH(ROWLOCK)
  LEFT JOIN #ch_man AS b
    ON b.date_ch = ls.date_ls
       AND b.id_tt_cl = ls.id_tt_ls
       AND b.id_tov_cl = ls.id_tov_ls
  WHERE (
          ISNULL(ls.id_kontr_ls, 0) <> ISNULL(b.id_kontr, 0)
          OR ISNULL(ls.sales_fact_scan, 0) <> ISNULL(b.sales_fact_scan, 0)
        )
        AND 
          ls.date_ls BETWEEN @date1 AND @date2

  EXEC com.dbo.jobs_log_ins @id_job, 200, @getdate OUTPUT

  DROP TABLE #ch_man

  IF OBJECT_ID('tempdb..#ch_20') IS NOT NULL
    DROP TABLE #ch_20

  IF OBJECT_ID('tempdb..#bb') IS NOT NULL
    DROP TABLE #bb

  CREATE TABLE #ch_20 (
    Time_ch time,
    ShopNo  int,
    date_ch date
  )

  INSERT INTO #ch_20
  SELECT
    CONVERT(time, ch.CloseDate) Time_ch,
    ch.ShopNo,
    CONVERT(date, CloseDate) date_ch
  FROM SMS_UNION.dbo.Checks ch WITH (NOLOCK)
  WHERE ch.BaseSum > 0
      AND 
        ch.CloseDate BETWEEN @date1 AND DATEADD(DAY, 1, @date2)

  CREATE CLUSTERED INDEX ind1 ON #ch_20 (date_ch, ShopNo, Time_ch)

  CREATE TABLE #bb (
    date_ls   date,
    id_tt_ls  int,
    id_tov_ls int,
    checks_1  int,
    checks_2  int
  )

  INSERT INTO #bb
  SELECT
    ls.date_ch,
    ls.id_tt_cl,
    ls.id_tov_cl,
    ISNULL(COUNT(CASE WHEN ch.Time_ch <= ls.time_0 THEN 1 ELSE NULL END), 0) checks_1,
    ISNULL(COUNT(CASE WHEN ch.Time_ch > ls.time_0 THEN 1 ELSE NULL END), 0) checks_2
  FROM #ins_ls AS ls
  INNER JOIN #ch_20 AS ch
    ON ls.date_ch = ch.date_ch
       AND ls.N = ch.ShopNo
  GROUP BY ls.date_ch,
           ls.id_tt_cl,
           ls.id_tov_cl

  CREATE CLUSTERED INDEX ind_bb ON #bb (date_ls, id_tt_ls, id_tov_ls)

  UPDATE m2.dbo.Lost_sales_temp_01 WITH (ROWLOCK)
  SET
    checks_1 = b.checks_1,
    checks_2 = b.checks_2
  FROM m2.dbo.Lost_sales_temp_01 AS ls
  INNER JOIN #bb AS b
    ON b.date_ls = ls.date_ls
       AND b.id_tt_ls = ls.id_tt_ls
       AND b.id_tov_ls = ls.id_tov_ls
  WHERE ls.checks_1 <> b.checks_1
        OR ls.checks_2 <> b.checks_2

  DROP TABLE #ch_20
  DROP TABLE #bb

  EXEC com.dbo.jobs_log_ins @id_job, 220, @getdate OUTPUT

  DROP TABLE #ins_ls

  IF OBJECT_ID('tempdb..#ls_period') IS NOT NULL
    DROP TABLE #ls_period

  SELECT
    date_ls,
    id_tt_ls,
    id_tov_ls,
    sales_fact,
    checks_1,
    konost_ls,
    checks_2,
    sales_q
  INTO #ls_period
  FROM m2.dbo.Lost_sales_temp_01 AS ls WITH(NOLOCK)
  UNION ALL
  SELECT
    date_ls,
    id_tt_ls,
    id_tov_ls,
    sales_fact,
    checks_1,
    konost_ls,
    checks_2,
    sales_q
  FROM m2.dbo.Lost_sales_01 AS ls WITH(NOLOCK)
  WHERE ls.date_ls < @date1
        AND ls.date_ls >= DATEADD(DAY, -7, @date2)

  CREATE INDEX ind_ls_period ON #ls_period (date_ls, id_tt_ls, id_tov_ls)
  INCLUDE (sales_fact, checks_1, konost_ls, checks_2, sales_q)

  -- считаем частоту по дням и откидываем все значения более 3 раз от среднего по всем tt
  IF OBJECT_ID('tempdb..#aa') IS NOT NULL
    DROP TABLE #aa

  SELECT
    ls.date_ls,
    ls.id_tt_ls,
    ls.id_tov_ls,
    CASE WHEN ( a.частота < сред.частота * 3
              AND a.частота > сред.частота / 3
           )
           OR ls.sales_fact = 0 THEN ls.sales_fact -- значит бере фатические продажи
        ELSE (ls.checks_1 + CASE WHEN ls.konost_ls >= 0.1 THEN ls.checks_2 ELSE 0 END) / 10 * сред.частота
    END sales_ls
  INTO #aa
  FROM m2.dbo.Lost_sales_temp_01 ls
  INNER JOIN #tt AS tt WITH (NOLOCK)
    ON tt.id_TT = ls.id_tt_ls
  INNER JOIN ( SELECT
                date_ls,
                ls.id_tt_ls,
                ls.id_tov_ls,
                SUM(ls.sales_fact) / SUM(ls.checks_1 + CASE WHEN ls.konost_ls >= 0.1 THEN ls.checks_2 ELSE 0 END) * 10 частота
              FROM #ls_period ls
              WHERE ls.checks_1 + CASE WHEN ls.konost_ls >= 0.1 THEN ls.checks_2 ELSE 0 END > 0
                    AND ISNULL(ls.sales_q, 0) > 1 -- 2 -- OD 2017-04-17
              GROUP BY date_ls,
                       ls.id_tt_ls,
                       ls.id_tov_ls
              HAVING SUM(ls.checks_1 + CASE WHEN ls.konost_ls >= 0.1 THEN ls.checks_2 ELSE 0 END) > 30
            ) AS a
    ON a.date_ls = ls.date_ls
       AND a.id_tt_ls = ls.id_tt_ls
       AND a.id_tov_ls = ls.id_tov_ls
  INNER JOIN (  SELECT
                  tt.tt_format,
                  ls.id_tov_ls,
                  SUM(ls.sales_fact) / SUM(ls.checks_1 + CASE WHEN ls.konost_ls >= 0.1 THEN ls.checks_2 ELSE 0 END) * 10 частота
                FROM #ls_period ls
                INNER JOIN #tt AS tt WITH (NOLOCK)
                  ON tt.id_TT = ls.id_tt_ls
                WHERE ls.checks_1 + CASE WHEN ls.konost_ls >= 0.1 THEN ls.checks_2 ELSE 0 END > 0
                      AND ISNULL(ls.sales_q, 0) > 1 -- 2 -- OD 2017-04-17
                GROUP BY tt.tt_format,
                         ls.id_tov_ls
                HAVING SUM(ls.checks_1 + CASE WHEN ls.konost_ls >= 0.1 THEN ls.checks_2 ELSE 0 END) > 30
              ) AS сред
    ON сред.tt_format = tt.tt_format
       AND сред.id_tov_ls = ls.id_tov_ls
  WHERE sales_ls <> CASE WHEN ( a.частота < сред.частота * 3
                                 AND a.частота > сред.частота / 3
                               )
                           OR ls.sales_fact = 0 THEN ls.sales_fact -- значит бере фатические продажи
                      ELSE (ls.checks_1 + CASE WHEN ls.konost_ls >= 0.1 THEN ls.checks_2 ELSE 0 END) / 10 * сред.частота
                    END

  CREATE UNIQUE CLUSTERED INDEX ind1 ON #aa (date_ls, id_tt_ls, id_tov_ls)

  UPDATE m2.dbo.Lost_sales_temp_01
  SET sales_ls = a.sales_ls -- исправить
  FROM m2.dbo.Lost_sales_temp_01 AS ls
  INNER JOIN #aa a
    ON ls.date_ls = a.date_ls
       AND ls.id_tt_ls = a.id_tt_ls
       AND ls.id_tov_ls = a.id_tov_ls

  DROP TABLE #aa

  EXEC com.dbo.jobs_log_ins @id_job, 230, @getdate OUTPUT

  -- считаем частоту по дням и откидываем все значения более 2 раз от среднего по tt

  ----------------------------------------------------------------------------------------------
  IF OBJECT_ID('tempdb..#aaa') IS NOT NULL
    DROP TABLE #aaa

  --  select ls.date_ls 
  --	, ls.id_tt_ls 
  --	, ls.id_tov_ls 
  --	, case when (a.частота< isnull(сред.частота,сред2.частота)*3 and  a.частота> isnull(сред.частота,сред2.частота)/3) or ls.sales_fact = 0 
  --		   then ls.sales_fact -- значит бере фатические продажи
  --		   else (ls.checks_1 + case when ls.konost_ls>=0.1 then ls.checks_2 else 0 end ) /10 * isnull(сред.частота,сред2.частота)  end sales_ls
  --into #aaa
  --from m2..lost_sales_temp_01 ls

  --inner join #tt as tt with (nolock) on tt.id_TT =ls.id_tt_ls

  --inner join (select date_ls 
  --				, ls.id_tt_ls 
  --				, ls.id_tov_ls 
  --				, SUM (ls.sales_fact )  / SUM ( ls.checks_1 + case when ls.konost_ls>=0.1 then ls.checks_2 else 0 end )  * 10 частота
  --			from
  --				(
  --				select date_ls,id_tt_ls,id_tov_ls, sales_fact,checks_1,konost_ls,checks_2, sales_q
  --				from m2..lost_sales_temp_01 as ls with(nolock) 
  --				union All
  --				select date_ls,id_tt_ls,id_tov_ls, sales_fact,checks_1,konost_ls,checks_2, sales_q
  --				from m2..lost_sales_01 as ls with(nolock, index(IX_Lost_sales_4))
  --				where ls.date_ls < @date1	and ls.date_ls >= DATEADD(day,-7, @date2) 	
  --				) ls

  --			where ls.checks_1 + case when ls.konost_ls>=0.1 then ls.checks_2 else 0 end >0
  --			and isnull(ls.sales_q,0) >1  -- 2 -- OD 2017-04-17
  --			group by date_ls , ls.id_tt_ls , ls.id_tov_ls 
  --			having sum(ls.checks_1 + case when ls.konost_ls>=0.1 then ls.checks_2 else 0 end) >30
  --			) a on a.date_ls=ls.date_ls 
  --					and a.id_tt_ls=ls.id_tt_ls 
  --					and a.id_tov_ls=ls.id_tov_ls

  --left join (	select ls.id_tt_ls 
  --				, ls.id_tov_ls 
  --				, SUM (ls.sales_fact )  / SUM ( ls.checks_1 + case when ls.konost_ls>=0.1 then ls.checks_2 else 0 end )  * 10 частота
  --			from 	(
  --					select date_ls,id_tt_ls,id_tov_ls, sales_fact,checks_1,konost_ls,checks_2, sales_q
  --					from m2..lost_sales_temp_01 as ls with(nolock) 
  --					union All
  --					select date_ls,id_tt_ls,id_tov_ls, sales_fact,checks_1,konost_ls,checks_2, sales_q
  --					from m2..lost_sales_01 as ls with(nolock, index(IX_Lost_sales_4))
  --					where ls.date_ls < @date1
  --					and ls.date_ls >= DATEADD(day,-7, @date2)	
  --					) ls

  --			where ls.checks_1 + case when ls.konost_ls>=0.1 then ls.checks_2 else 0 end >0
  --			group by   ls.id_tt_ls ,ls.id_tov_ls 
  --			having sum(ls.checks_1 + case when ls.konost_ls>=0.1 then ls.checks_2 else 0 end) >30
  --			and sum(ls.sales_fact)>20
  --			)  сред on сред.id_tov_ls=a.id_tov_ls
  --				and  сред.id_tt_ls=a.id_tt_ls

  --inner join
  --(select  tt.tt_format 
  --	, ls.id_tov_ls 
  --	, SUM (ls.sales_fact )  / SUM ( ls.checks_1 + case when ls.konost_ls>=0.1 then ls.checks_2 else 0 end )  * 10 частота
  --from (	select date_ls,id_tt_ls,id_tov_ls, sales_fact,checks_1,konost_ls,checks_2, sales_q
  --		from m2..lost_sales_temp_01 as ls with(nolock)
  --		union All
  --		select date_ls,id_tt_ls,id_tov_ls, sales_fact,checks_1,konost_ls,checks_2, sales_q
  --		from m2..lost_sales_01 as ls with(nolock, index(IX_Lost_sales_4))
  --		where ls.date_ls <@date1	
  --		and ls.date_ls >= DATEADD(day,-7, @date2) 	
  --		) ls	

  --	inner join #tt as tt with (nolock) on tt.id_TT =ls.id_tt_ls

  --where ls.checks_1 + case when ls.konost_ls>=0.1 then ls.checks_2 else 0 end >0
  --group by  tt.tt_format , ls.id_tov_ls 
  --having sum(ls.checks_1 + case when ls.konost_ls>=0.1 then ls.checks_2 else 0 end) >30
  --)  сред2 on  сред2.tt_format = tt.tt_format 
  --	and  сред2.id_tov_ls=a.id_tov_ls

  --where sales_ls <> 
  --case when (a.частота< isnull(сред.частота,сред2.частота)*3 and  a.частота> isnull(сред.частота,сред2.частота)/3)
  -- or ls.sales_fact = 0 
  --   then ls.sales_fact -- значит бере фатические продажи
  --else (ls.checks_1 + case when ls.konost_ls>=0.1 then ls.checks_2 else 0 end ) /10 * isnull(сред.частота,сред2.частота)  end
  SELECT
    ls.date_ls,
    ls.id_tt_ls,
    ls.id_tov_ls,
    CASE WHEN ( a.частота < ISNULL(сред.частота, сред2.частота) * 3
                AND a.частота > ISNULL(сред.частота, сред2.частота) / 3
              )
            OR ls.sales_fact = 0 THEN ls.sales_fact -- значит берем фатические продажи
      ELSE (ls.checks_1 + CASE WHEN ls.konost_ls >= 0.1 THEN ls.checks_2 ELSE 0 END) / 10
              * ISNULL(сред.частота, сред2.частота)
    END AS sales_ls
  INTO #aaa
  FROM m2.dbo.Lost_sales_temp_01 AS ls
  INNER JOIN #tt AS tt WITH (NOLOCK)
    ON tt.id_TT = ls.id_tt_ls
  INNER JOIN ( SELECT
                  date_ls,
                  ls.id_tt_ls,
                  ls.id_tov_ls,
                  SUM(ls.sales_fact) / SUM(ls.checks_1 + CASE WHEN ls.konost_ls >= 0.1 THEN ls.checks_2 ELSE 0 END) * 10 частота
                FROM #ls_period AS ls
                WHERE ls.checks_1 + CASE WHEN ls.konost_ls >= 0.1 THEN ls.checks_2 ELSE 0 END > 0
                      AND ISNULL(ls.sales_q, 0) > 1 -- 2 -- OD 2017-04-17
                GROUP BY date_ls,
                         ls.id_tt_ls,
                         ls.id_tov_ls
                HAVING SUM(ls.checks_1 + CASE WHEN ls.konost_ls >= 0.1 THEN ls.checks_2 ELSE 0 END) > 30
              ) AS a
    ON a.date_ls = ls.date_ls
       AND a.id_tt_ls = ls.id_tt_ls
       AND a.id_tov_ls = ls.id_tov_ls
  LEFT JOIN ( SELECT
                ls.id_tt_ls,
                ls.id_tov_ls,
                SUM(ls.sales_fact) / SUM(ls.checks_1 + CASE WHEN ls.konost_ls >= 0.1 THEN ls.checks_2 ELSE 0 END) * 10 частота
              FROM #ls_period AS ls
              WHERE ls.checks_1 + CASE WHEN ls.konost_ls >= 0.1 THEN ls.checks_2 ELSE 0 END > 0
              GROUP BY ls.id_tt_ls,
                       ls.id_tov_ls
              HAVING SUM(ls.checks_1 + CASE WHEN ls.konost_ls >= 0.1 THEN ls.checks_2 ELSE 0 END) > 30
                     AND SUM(ls.sales_fact) > 20
            ) AS сред
    ON сред.id_tov_ls = a.id_tov_ls
       AND сред.id_tt_ls = a.id_tt_ls
  INNER JOIN ( SELECT
                tt.tt_format,
                ls.id_tov_ls,
                SUM(ls.sales_fact) / SUM(ls.checks_1 + CASE WHEN ls.konost_ls >= 0.1 THEN ls.checks_2 ELSE 0 END) * 10 частота
              FROM #ls_period AS ls
              INNER JOIN #tt AS tt WITH (NOLOCK)
                ON tt.id_TT = ls.id_tt_ls
              WHERE ls.checks_1 + CASE WHEN ls.konost_ls >= 0.1 THEN ls.checks_2 ELSE 0 END > 0
              GROUP BY tt.tt_format,
                       ls.id_tov_ls
              HAVING SUM(ls.checks_1 + CASE WHEN ls.konost_ls >= 0.1 THEN ls.checks_2 ELSE 0 END) > 30
            ) AS сред2
    ON сред2.tt_format = tt.tt_format
       AND сред2.id_tov_ls = a.id_tov_ls
  WHERE sales_ls <> CASE WHEN ( a.частота < ISNULL(сред.частота, сред2.частота) * 3
                                 AND a.частота > ISNULL(сред.частота, сред2.частота) / 3
                               )
                           OR ls.sales_fact = 0 THEN ls.sales_fact -- значит бере фатические продажи
                      ELSE (ls.checks_1 + CASE WHEN ls.konost_ls >= 0.1 THEN ls.checks_2 ELSE 0 END) / 10
                        * ISNULL(сред.частота, сред2.частота)
                    END

  CREATE UNIQUE CLUSTERED INDEX ind1 ON #aaa (date_ls, id_tt_ls, id_tov_ls)

  EXEC com.dbo.jobs_log_ins @id_job, 235, @getdate OUTPUT 

  UPDATE m2.dbo.Lost_sales_temp_01
  SET sales_ls = a.sales_ls -- исправить
  FROM m2.dbo.Lost_sales_temp_01 AS ls
  INNER JOIN #aaa a
    ON ls.date_ls = a.date_ls
       AND ls.id_tt_ls = a.id_tt_ls
       AND ls.id_tov_ls = a.id_tov_ls

  DROP TABLE #aaa

  IF OBJECT_ID('tempdb..#ls_period') IS NOT NULL
    DROP TABLE #ls_period

  EXEC com.dbo.jobs_log_ins @id_job, 240, @getdate OUTPUT

  IF OBJECT_ID('tempdb..#ch_first') IS NOT NULL
    DROP TABLE #ch_first

  SELECT
    chl.id_tov_cl id_tov_ls,
    MIN(chl.date_ch) перв_продажа
  INTO #ch_first
  FROM SMS_UNION.dbo.CheckLine AS chl WITH(NOLOCK) 
  GROUP BY chl.id_tov_cl

  EXEC com.dbo.jobs_log_ins @id_job, 260, @getdate OUTPUT

  CREATE INDEX ind1 ON #ch_first (id_tov_ls, перв_продажа)

  IF OBJECT_ID('tempdb..#ned_back_tt') IS NOT NULL
    DROP TABLE #ned_back_tt

  SELECT
    ls.id_tt_ls,
    ls.id_tov_ls,
    SUM(ls.sales_ls) / SUM(ls.checks_1 + CASE WHEN ls.konost_ls >= 0.1 THEN ls.checks_2 ELSE 0 END) * 10 частота
  INTO #ned_back_tt
  FROM (  SELECT
            *
          FROM m2.dbo.Lost_sales_temp_01 AS ls WITH(NOLOCK)
          UNION ALL
          SELECT
            *
          FROM m2.dbo.Lost_sales_01 AS ls WITH(NOLOCK)
          WHERE ls.date_ls < @date1
                AND ls.date_ls >= DATEADD(DAY, -7, @date2)
        ) AS ls
  INNER JOIN #ch_first ch_f
    ON ls.id_tov_ls = ch_f.id_tov_ls
       AND ls.date_ls >= ch_f.перв_продажа
  WHERE ls.checks_1 + CASE WHEN ls.konost_ls >= 0.1 THEN ls.checks_2 ELSE 0 END > 0
        AND
        (
          ls.konost_ls >= 0.1
          OR ls.sales_ls > 0.1
        )
  GROUP BY ls.id_tt_ls,
           ls.id_tov_ls
  HAVING SUM(ls.checks_1 + CASE WHEN ls.konost_ls >= 0.1 THEN ls.checks_2 ELSE 0 END) > 30
         AND SUM(ISNULL(ls.sales_q, 0)) > 5

  IF OBJECT_ID('tempdb..#ned_back') IS NOT NULL
    DROP TABLE #ned_back

  SELECT
    tt.tt_format,
    ls.id_tov_ls,
    SUM(ls.sales_ls) / SUM(ls.checks_1 + CASE WHEN ls.konost_ls >= 0.1 THEN ls.checks_2 ELSE 0 END) * 10 частота
  INTO #ned_back
  FROM (  SELECT
            *
          FROM m2.dbo.Lost_sales_temp_01 AS ls WITH(NOLOCK)
          UNION ALL
          SELECT
            *
          FROM m2.dbo.Lost_sales_01 AS ls WITH(NOLOCK)
          WHERE ls.date_ls < @date1
                AND ls.date_ls >= DATEADD(DAY, -7, @date2)
        ) AS ls
  INNER JOIN #tt AS tt WITH (NOLOCK)
    ON tt.id_TT = ls.id_tt_ls
  INNER JOIN #ch_first AS ch_f
    ON ls.id_tov_ls = ch_f.id_tov_ls
       AND ls.date_ls >= ch_f.перв_продажа
  WHERE ls.checks_1 + CASE WHEN ls.konost_ls >= 0.1 THEN ls.checks_2 ELSE 0 END > 0
        AND
        (
          ls.konost_ls >= 0.1
          OR ls.sales_ls > 0.1
        )
  GROUP BY tt.tt_format,
           ls.id_tov_ls
  HAVING SUM(ls.checks_1 + CASE WHEN ls.konost_ls >= 0.1 THEN ls.checks_2 ELSE 0 END) > 30
         AND SUM(ISNULL(ls.sales_q, 0)) > 5

  CREATE UNIQUE CLUSTERED INDEX ind1 ON #ned_back_tt (id_tov_ls, id_tt_ls)

  CREATE UNIQUE CLUSTERED INDEX ind1 ON #ned_back (tt_format, id_tov_ls)

  EXEC com.dbo.jobs_log_ins @id_job, 270, @getdate OUTPUT

  ----------------------------------------------------------------------------------------------
  UPDATE m2.dbo.Lost_sales_temp_01
  SET lost1 = CASE WHEN ls.konost_ls < 0.1
                   AND ls.is_matrix = 1 THEN
                ISNULL(ISNULL(ned_back_tt.частота, ned_back.частота), 0) * ls.checks_2 / 10
                ELSE 0
              END,
    chastota = ISNULL(ISNULL(ned_back_tt.частота, ned_back.частота), 0),
    type_chast = CASE WHEN ned_back_tt.частота IS NOT NULL THEN 1
                      WHEN ned_back.частота IS NOT NULL THEN 3
                      ELSE 0
                 END
  FROM m2.dbo.Lost_sales_temp_01 AS ls
  INNER JOIN #tt AS tt WITH (NOLOCK)
    ON tt.id_TT = ls.id_tt_ls
  INNER JOIN #ch_first ch_f
    ON ls.id_tov_ls = ch_f.id_tov_ls
       AND ls.date_ls >= ch_f.перв_продажа
  LEFT JOIN -- предыдущая неделя = базово
    #ned_back_tt ned_back_tt
    ON ned_back_tt.id_tov_ls = ls.id_tov_ls
       AND ned_back_tt.id_tt_ls = ls.id_tt_ls

  -- а теперь, если нет по ТТ, считаем по товарам по всем ТТ в среднем
  LEFT JOIN -- предыдущая неделя = базово
    #ned_back ned_back
    ON ned_back.tt_format = tt.tt_format
       AND ned_back.id_tov_ls = ls.id_tov_ls
  LEFT JOIN m2.dbo.Tovari AS tov WITH (NOLOCK)
    ON ls.id_tov_ls = tov.id_tov

  DROP TABLE #ch_first
  DROP TABLE #ned_back
  DROP TABLE #ned_back_tt
  DROP TABLE #tt

  EXEC com.dbo.jobs_log_ins @id_job, 271, @getdate OUTPUT

  UPDATE m2.dbo.Lost_sales_temp_01 WITH (ROWLOCK)
  SET id_kontr_fp = p.id_kontr,
      date_fp = p.date_post
  --select *
  FROM m2.dbo.Lost_sales_temp_01 AS ls
  INNER JOIN m2.dbo.Last_post AS p WITH (NOLOCK)
    ON ls.date_ls = p.date_ls
       AND ls.id_tt_ls = p.id_tt
       AND ls.id_tov_ls = p.id_tov
  WHERE ls.date_ls BETWEEN @date1 AND @date2
        AND
        (
          ls.id_kontr_fp <> p.id_kontr
          OR ls.date_fp <> p.date_post
          OR ls.id_kontr_fp IS NULL
          OR ls.date_fp IS NULL
        )

  EXEC com.dbo.jobs_log_ins @id_job, 320, @getdate OUTPUT

  UPDATE m2.dbo.Lost_sales_01
  SET
    [id_kontr_ls] = ls2.id_kontr_ls,
    [id_kontr_matrix] = ls2.[id_kontr_matrix],
    [is_matrix] = ls2.[is_matrix],
    [sales_ls] = ls2.[sales_ls],
    [sales_fact] = ls2.[sales_fact],
    [lost1] = ls2.[lost1],
    [time_0] = ls2.[time_0],
    [checks_1] = ls2.[checks_1],
    [checks_2] = ls2.[checks_2],
    [konost_ls] = ls2.[konost_ls],
    [price_ls] = ls2.[price_ls],
    [type_chast] = ls2.[type_chast],
    [chastota] = ls2.[chastota],
    [sales_q] = ls2.[sales_q],
    [id_kontr_fp] = ls2.[id_kontr_fp],
    [sales_fact_scan] = ls2.[sales_fact_scan],
    [date_fp] = ls2.[date_fp]
  FROM m2.dbo.Lost_sales_01 AS ls1
  INNER JOIN m2.dbo.Lost_sales_temp_01 AS ls2
    ON ls1.date_ls = ls2.date_ls
       AND ls1.id_tt_ls = ls2.id_tt_ls
       AND ls1.id_tov_ls = ls2.id_tov_ls
  WHERE ls1.lost1 <> ls2.lost1
      OR 
        ls1.[sales_ls] <> ls2.[sales_ls]
      OR 
        ls1.[checks_1] <> ls2.[checks_1]
      OR 
        ls1.[checks_2] <> ls2.[checks_2]
      OR 
        ls1.[price_ls] <> ls2.[price_ls]
      OR 
        ls1.[price_ls] IS NULL

  INSERT INTO m2.dbo.Lost_sales_01
  SELECT
    ls2.*
  FROM m2.dbo.Lost_sales_temp_01 AS ls2
  LEFT JOIN m2.dbo.Lost_sales_01 AS ls1
    ON ls1.date_ls = ls2.date_ls
       AND ls1.id_tt_ls = ls2.id_tt_ls
       AND ls1.id_tov_ls = ls2.id_tov_ls
  WHERE ls1.date_ls IS NULL

  DELETE FROM ls1
  FROM m2.dbo.Lost_sales_01 AS ls1
  LEFT JOIN m2.dbo.Lost_sales_temp_01 AS ls2
    ON ls1.date_ls = ls2.date_ls
       AND ls1.id_tt_ls = ls2.id_tt_ls
       AND ls1.id_tov_ls = ls2.id_tov_ls
  WHERE ls2.date_ls IS NULL
      AND 
        ls1.date_ls BETWEEN @date1 AND @date2

  EXEC com.dbo.jobs_log_ins @id_job, 330, @getdate OUTPUT


  -- Обновим Lost_sales_01 на 06 сервере
  DECLARE @sql nvarchar(1000)
	,@days1 int
	,@days2 int
  select @days1=com.dbo.Get_DaysCount(@date1)
	,@days2=com.dbo.Get_DaysCount(@date2)
  
  SET @sql = '
      EXEC( ''insert into jobs..jobs (job_name, prefix_job,number_1)
			  select ''''vv06.dbo.Lost_Sales_Update'''', ' + rtrim(@days1) +', ' + rtrim(@days2) +' '') at [SRV-SQL06]'

  --PRINT @sql

  EXEC sp_executeSQL @sql

  EXEC com.dbo.jobs_log_ins @id_job, 340, @getdate OUTPUT

END
GO