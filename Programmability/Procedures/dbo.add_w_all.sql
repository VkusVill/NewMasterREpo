SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:  	Андрей Кривенко
-- Create date: 
-- Description:	Подготовка данных для распределений
-- OD 2019-11-18 Оптимизация шага 30
-- OD 2019-12-12 Оптимизация шага 91
-- MV 2019-12-28 Перевод на постоянные таблицы временные
-- =============================================
CREATE PROCEDURE [dbo].[add_w_all] 
  @id_job int = 104
AS
BEGIN
  SET NOCOUNT ON

  DECLARE @job_name     varchar(500) = com.dbo.Object_name_for_err(@@ProcID, DB_ID()),
          @getdate      datetime = GETDATE(),
          @Date_Current date = GETDATE(),
          @Date_Next    date = DATEADD(day, 1, GETDATE())

  IF OBJECT_ID('tempdb..#tt_add_w_all') IS NOT NULL
    DROP TABLE #tt_add_w_all

  SELECT
    tt.id_tt,
    N,
    CASE WHEN ISNULL(ct.type_v, 0) = 1 THEN 400 ELSE tt_format END AS tt_format,
    type_tt 
  INTO #tt_add_w_all
  FROM m2.dbo.tt
  LEFT JOIN m2.dbo.cohort_tt ct
    ON ct.id_tt = tt.id_TT

  CREATE INDEX int_tt ON #tt_add_w_all (id_tt, N)

  EXEC com.dbo.jobs_log_ins @id_job, 5, @getdate OUTPUT

  EXEC m2.dbo.make_tt_dynamic -- записать тт, у которых идет рост

  EXEC com.dbo.jobs_log_ins @id_job, 10, @getdate OUTPUT

  --drop table #dnined 
  CREATE TABLE #dnined (
    date_w date,
    type_pr int,
    Type_w int,
    Date_ch date,
    date_back_comp date
  )

  INSERT INTO #dnined
  SELECT
    *
  FROM m2.dbo.WorkingDaysAndWeekends
  WHERE [DATE_w] BETWEEN DATEADD(DAY, -35, GETDATE()) AND DATEADD(DAY, 5, GETDATE())

  CREATE UNIQUE CLUSTERED INDEX ind1 ON #dnined (date_w)

  -- найти день, на который смененный день похож.
  -- найти самый ранний день, когда была такая же пара между тремя дняи подряд с типом Вых (-1,0,+1) день
  -- если такой не найдет (например, выходной посреди недели) или 4 подряд выходной, то по двум (-1,0)
  -- если выходной в рабочий понедельник, то это будет прошлое воскресенье, тк суб, вс, пн совпадет с вс, пн, вт.
  -- если рабочая суботта, то прошлая пятница

  /**
  -- рассчитать по группе Супы выручку за прошлую неделю
  -- и посчитать нормативный коэф.
  SELECT t.id_tov 
  	, t.id_group
  INTO #tov_gr_2
  FROM m2..Tovari t 
  WHERE t.id_group = 10179  
  
  SELECT DTT.id_tt 
  	, tg2.id_group  --sum(DTT.summa) summa , 
  	, master.dbo.maxz(0, 56.5 - sum(DTT.summa) * 0.001 * 0.83)  * 0.01 НормПотер
  INTO #tt_pot
  FROM Reports..DTT_01 as dtt with (nolock)
  	inner join #tov_gr_2 tg2 on DTT.id_tov = tg2.id_tov
  WHERE dtt.tt_format_dtt=2 
  	and dtt.date_tt between dateadd(day,-7,CONVERT(date,getdate())) and dateadd(day,-1,CONVERT(date,getdate()))
  GROUP BY DTT.id_tt, tg2.id_group
  
  **/

  CREATE TABLE #dtt_s (
    id_tt int,
    id_tov int,
    date_tt date,
    q real,
    week_tt int,
    Вых int,
    summa int
  )
  
  EXEC com.dbo.jobs_log_ins @id_job, 20, @getdate OUTPUT

  IF OBJECT_ID('tempdb..#dtt_ls') IS NOT NULL
    DROP TABLE #dtt_ls

  SELECT
    a.id_tt,
    a.id_tov,
    a.date_tt,
    DATEPART(WEEKDAY, a.date_tt) AS w,-- день недели дня заменителя    
    SUM(q) q,
    SUM(a.q_lost) q_lost,
    SUM(a.summa) summa,
    SUM(sum_lost) sum_lost 
  INTO #dtt_LS
  FROM (SELECT
          ttk.id_tt,
          ttk.id_tov,
          ttk.date_tt date_tt,
          ISNULL(ttk.quantity - ttk.discount50_qty - ttk.discount50_sms_qty, 0) q,
          0 q_lost,
          ISNULL(ttk.summa - ttk.discount50, 0) summa,
          0 sum_lost,
          tt_format_dtt
        FROM Reports..DTT_01 ttk WITH (NOLOCK)
        WHERE ttk.date_tt >= DATEADD(DAY, -31, @Date_Current)
        AND ttk.date_tt < @Date_Current  

        UNION ALL

        SELECT
          ls.id_tt_ls,
          ls.id_tov_ls,
          ls.date_ls,
          0,
          ISNULL(ls.lost1, 0) q,
          0,
          ISNULL(ls.lost1 * ls.price_ls, 0),
          0
        FROM m2..Lost_sales_01 AS ls WITH (NOLOCK)
        WHERE ls.date_ls >= DATEADD(DAY, -31, @Date_Current)
        AND ls.date_ls < @Date_Current       
     ) AS a
  GROUP BY a.id_tt,
           a.id_tov,
           a.date_tt,
           DATEPART(WEEKDAY, a.Date_tt)
  HAVING SUM(q) > 0.1
  AND MAX(tt_format_dtt) <> 10

  INSERT INTO #dtt_s (id_tt, id_tov, date_tt, q, week_tt, Вых, summa)
  SELECT
    a.id_tt,
    a.id_tov,
    a.date_tt,
    a.q + a.q_lost * 0.5 q,
    a.w, -- день недели дня заменителя    
    d.type_pr Вых, -- тип дня по календарю выходных    
    a.summa + a.sum_lost * 0.5    
  FROM #dtt_ls AS a  
  INNER JOIN #dnined AS d
    ON a.date_tt = d.date_w

  IF OBJECT_ID('tempdb..#dtt_ls') IS NOT NULL
    DROP TABLE #dtt_ls

  EXEC com.dbo.jobs_log_ins @id_job, 30, @getdate OUTPUT

  CREATE CLUSTERED INDEX ind1 ON #dtt_s (date_tt, id_tt, id_tov)

  CREATE TABLE #dtt_s_z (
    id_tt int,
    date_tt date,
    sum_z int
  )

  INSERT INTO #dtt_s_z (id_tt, date_tt, sum_z)
  SELECT
    dtt.id_tt,
    dtt.date_tt,
    SUM(dtt.summa) Sum_z
  FROM reports.dbo.dt_01 AS dtt WITH (NOLOCK) 
  WHERE dtt.date_tt >= DATEADD(DAY, -31, @Date_Current)
  AND dtt.date_tt < @Date_Current
  AND dtt.date_tt NOT IN ('20181228', '20181229', '20181230', '20181231')
  AND dtt.date_tt NOT BETWEEN '20190306' AND '20190309'
  AND dtt.tt_format_dt <> 10  
  GROUP BY dtt.id_tt,
            dtt.date_tt
  HAVING SUM(dtt.summa) > 1000

  EXEC com.dbo.jobs_log_ins @id_job, 40, @getdate OUTPUT

  CREATE CLUSTERED INDEX ind1 ON #dtt_s_z (date_tt, id_tt)

  DELETE #dtt_s
  FROM #dtt_s dtt
  LEFT JOIN #dtt_s_z dz
    ON dtt.date_tt = dz.date_tt
    AND dtt.id_tt = dz.id_tt
  WHERE dz.date_tt IS NULL

  CREATE TABLE #tov (
    id_tov int,
    id_tov_pvz int,
    koef_pvz real
  )

  INSERT INTO #tov
  SELECT
    tp.id_tov_Zadvoen,
    tp.id_tov_Osnovn,
    CASE
      WHEN t.Ves <> t2.Ves AND
        (t.Ves = 1 OR
        t2.ves = 1) AND
        t.Ed_Izm <> t2.Ed_Izm THEN t.ves / t2.ves
      ELSE 1
    END AS koef_pvz
  FROM Reports.dbo.tov_poln_zamenyaem tp
  INNER JOIN M2.dbo.Tovari t
    ON t.id_tov = tp.id_tov_Zadvoen
  INNER JOIN M2.dbo.Tovari t2
    ON t2.id_tov = tp.id_tov_Osnovn
  WHERE ISNULL(tp.id_tov_Zadvoen, 0) <> tp.id_tov_Osnovn

  CREATE TABLE #complect (
    id_tov int,
    id_tov_sostav int,
    kolvo real
  )
  -- выбираем комплекты

  INSERT INTO #complect
  SELECT
    c.id_tov,
    c.id_tov_sostav,
    c.kolvo
  FROM [M2].[dbo].[complects](@Date_Next) c

  EXEC com.dbo.jobs_log_ins @id_job, 50, @getdate OUTPUT

  -- сложить по аналогам продажи с основными
  SELECT
    dt.id_tt,
    dt.id_tov,
    dt.date_tt,
    SUM(dt.q) q,
    dt.week_tt,
    dt.Вых,
    SUM(dt.summa) summa 
  INTO #dtt_s_2
  FROM (  SELECT
            dt.id_tt,
            tov.id_tov_pvz id_tov,
            dt.date_tt,
            dt.q * ISNULL(tov.koef_pvz, 1) q,
            dt.week_tt,
            dt.Вых,
            dt.summa * ISNULL(tov.koef_pvz, 1) summa
          FROM #dtt_s dt
          INNER JOIN #tov tov
            ON tov.id_tov = dt.id_tov

          UNION ALL

          SELECT
            dt.*
          FROM #dtt_s dt
          INNER JOIN (SELECT DISTINCT
                          tov.id_tov_pvz
                        FROM #tov tov
                     ) AS tov
            ON tov.id_tov_pvz = dt.id_tov
      ) AS dt
  GROUP BY dt.date_tt,
           dt.id_tt,
           dt.id_tov,
           dt.week_tt,
           dt.Вых

  -- не основные товары тоже оставить
  DELETE #dtt_s
  FROM #dtt_s dt
  INNER JOIN #tov tov
    ON tov.id_tov_pvz = dt.id_tov

  INSERT INTO #dtt_s
  SELECT
    *
  FROM #dtt_s_2

  EXEC com.dbo.jobs_log_ins @id_job, 60, @getdate OUTPUT

  ----------------------- по комплектам собрать продажи

  SELECT
    dtt.id_tt,
    c.id_tov,
    dtt.date_tt,
    SUM(dtt.q / c.kolvo) q,
    dtt.week_tt 
  INTO #comp
  FROM #dtt_s AS dtt
  INNER JOIN #complect AS c
    ON c.id_tov_sostav = dtt.id_tov
  WHERE c.kolvo > 0
  GROUP BY c.id_tov,
           dtt.id_tt,
           dtt.date_tt,
           dtt.week_tt

  UPDATE #dtt_s
  SET q = c.q + dtt.q
  FROM #comp AS c
  INNER JOIN #dtt_s AS dtt
    ON dtt.date_tt = c.date_tt
    AND dtt.id_tov = c.id_tov
    AND dtt.id_tt = c.id_tt

  INSERT INTO #dtt_s (id_tt, id_tov, date_tt, q, week_tt)
  SELECT
    c.id_tt,
    c.id_tov,
    c.date_tt,
    c.q,
    c.week_tt
  FROM #comp AS c
  LEFT JOIN #dtt_s AS dtt
    ON dtt.date_tt = c.date_tt
    AND dtt.id_tov = c.id_tov
    AND dtt.id_tt = c.id_tt
  WHERE dtt.date_tt IS NULL

  -----------------------------------------------------------------------------------------
  -- теперь по товарам, что производятся в магазине, но перемещаются на другие магазины
    
  CREATE TABLE #tt_perem (
    id_tt_from int,
    id_tt_where int
  )

  INSERT INTO #tt_perem    
  SELECT DISTINCT
    tt2.id_TT AS откуда,
    tt.id_TT AS куда  
  FROM [SMS_REPL].[dbo].[TD_move](nolock) td
  INNER JOIN m2.dbo.Tovari t
    ON t.id_tov = td.id_tov
    AND t.id_group = 10252  
  INNER JOIN #tt_add_w_all AS tt
    ON tt.N = td.ShopNo_rep
  INNER JOIN #tt_add_w_all AS tt2
    ON tt2.N = td.Corr_id_tt
    AND tt2.type_tt = 'торговая'
  WHERE td.operation_type IN (410)
      AND 
        CONVERT(date, td.closedate) = @Date_Next
      AND 
        td.Confirm_type = 1

  CREATE TABLE #tov_perem (
    id_tov int
  )

  INSERT INTO #tov_perem
  SELECT DISTINCT
    a.id_tov
  FROM M2.dbo.complectsInShop(@Date_Current) AS a
  INNER JOIN m2.dbo.Tovari t
    ON t.id_tov = a.id_tov_sostav
    AND t.id_group = 10252

  UPDATE #dtt_s
  SET q = d.q + a.q,
      summa = d.summa + a.summa
  --select *
  FROM #dtt_s AS d
  INNER JOIN (SELECT
                d.date_tt,
                d.id_tov,
                tt.id_tt_from,
                SUM(d.q) q,
                SUM(d.summa) summa
              FROM #dtt_s AS d
              INNER JOIN #tt_perem AS tt
                ON tt.id_tt_where = d.id_tt
              INNER JOIN #tov_perem t
                ON t.id_tov = d.id_tov
              GROUP BY d.date_tt,
                       d.id_tov,
                       tt.id_tt_from
             ) AS a
    ON a.date_tt = d.date_tt
    AND a.id_tov = d.id_tov
    AND a.id_tt_from = d.id_tt

  ----------------------------------------------------------
  EXEC com.dbo.jobs_log_ins @id_job, 70, @getdate OUTPUT

  CREATE TABLE #dn (
    id_tt int,
    dn int,
    ПроцДн int
  )

  INSERT INTO #dn
  SELECT
    TT._Fld758 id_tt,
    dates.dn,
    CASE dates.dn
      WHEN 1 THEN _Fld2899
      WHEN 2 THEN _Fld2900
      WHEN 3 THEN _Fld2901
      WHEN 4 THEN _Fld2902
      WHEN 5 THEN _Fld2903
      WHEN 6 THEN _Fld2904
      WHEN 7 THEN _Fld2905
    END AS ПроцДн
  FROM [IzbenkaFin].[dbo].[_InfoRg2895] AS Raspr (NOLOCK)
  INNER JOIN IzbenkaFin.dbo._Reference42 AS TT (NOLOCK)
    ON Raspr._Fld2897RRef = TT._IDRRef
  INNER JOIN (SELECT TOP 7
    ROW_NUMBER() OVER (ORDER BY date_add) dn
  FROM jobs..Jobs_log(nolock)) dates
    ON 1 = 1
  WHERE _Fld2898_RRRef = 0x00000000000000000000000000000000  

  IF OBJECT_ID('m2.dbo.W_All_Temp_Wall') IS NOT NULL
    DROP TABLE m2.dbo.W_All_Temp_Wall
  
  CREATE TABLE m2.dbo.W_All_Temp_Wall (
    [date_r] [date] NULL,
    [id_tt] [int] NULL,
    [id_tov] [int] NULL,
    [Fact] [real] NULL,
    [q] [real] NULL,
    [rn] [int] NULL,
    [date_add] [datetime] NULL,
    [rn_2] [int] NULL,
    [Date_f] [date] NULL,
    [вых] int,
    [rn3] int,
    [summa] int,
    [tt_format] int
  )

  INSERT INTO m2.dbo.W_All_Temp_Wall
  SELECT
    @Date_Next,
    w.id_tt,
    w.id_tov,
    w.Fact,
    w.q,
    w.rn,
    GETDATE(),
    w.rn_2,
    w.date_tt,
    w.Вых,
    w.rn3,
    w.summa,
    tt.tt_format
  FROM (SELECT
          v.id_tt,
          v.id_tov,
          v.date_tt,
          v.q * 1.0 * master.dbo.minz(1, ISNULL(dn2.ПроцДн / CASE dn.ПроцДн
                                                              WHEN 0 THEN 1.0 / 7
                                                              ELSE dn.ПроцДн
                                                            END, 1)) AS fact,
          v.q,
          v.Вых,
          ROW_NUMBER() OVER (PARTITION BY v.id_tt, v.id_tov, v.вых
          ORDER BY v.q * master.dbo.minz(1, ISNULL(dn2.ПроцДн / CASE dn.ПроцДн
                                                                  WHEN 0 THEN 1.0 / 7
                                                                  ELSE dn.ПроцДн
                                                                END, 1)) DESC) rn,
          ROW_NUMBER() OVER (PARTITION BY v.id_tt, v.id_tov, v.вых ORDER BY v.q DESC) rn_2,
          v.rn3,
          v.summa summa
        FROM (SELECT
                v.*,
                ROW_NUMBER() OVER (PARTITION BY v.id_tt, v.id_tov, v.вых ORDER BY v.date_tt DESC) rn3
              FROM #dtt_s v WITH (NOLOCK)
             ) AS v
        INNER JOIN #dnined AS d
          ON d.date_w = @Date_Next
        LEFT JOIN #dn AS dn (NOLOCK)
          ON dn.id_tt = v.id_tt
          AND dn.dn = v.week_tt
        LEFT JOIN #dn AS dn2 (NOLOCK)
          ON dn2.id_tt = v.id_tt
          AND dn2.dn = DATEPART(WEEKDAY, d.Date_ch)
        WHERE rn3 <= 10
      ) AS w
  INNER JOIN #tt_add_w_all AS tt WITH (NOLOCK)
    ON tt.id_TT = w.id_tt

  EXEC com.dbo.jobs_log_ins @id_job, 80, @getdate OUTPUT

  CREATE CLUSTERED INDEX [ClusteredIndex] ON m2.dbo.W_All_Temp_Wall
  (
    [id_tt] ASC,
    [id_tov] ASC,
    [Вых] ASC
  )

  EXEC com.dbo.jobs_log_ins @id_job, 90, @getdate OUTPUT
  -- новый кусок
  -- посчитать по группам 
  -- Сосиски.Сардельки.Колбаски	10147
  -- Колбаса вареная. Ветчина	10146
  -- Деликатесы	55
  -- также продажи в рублях по дням по каждой тт и найти также 2 Наиб * 1.35
  

  IF OBJECT_ID('m2.dbo.W_All_Temp_Tovgr') IS NOT NULL
    DROP TABLE m2.dbo.W_All_Temp_Tovgr

  CREATE TABLE  m2.dbo.W_All_Temp_Tovgr (
    id_tov int,
    id_group int,
    tt_format_group int
  )

  INSERT INTO m2.dbo.W_All_Temp_Tovgr
  SELECT
    t.id_tov,
    t.Group_raspr,
    g.tt_format_group
  FROM m2.dbo.Tovari AS t (NOLOCK)
  INNER JOIN [M2].[dbo].[Group_koef_raspr] AS g
    ON t.Group_raspr = g.id_group
    AND (g.[type_gr] = 'НормирПлПр'
    OR tt_format_group = 400)

  CREATE CLUSTERED INDEX CI ON m2.dbo.W_All_Temp_Tovgr (id_tov, tt_format_group)

  EXEC com.dbo.jobs_log_ins @id_job, 92, @getdate OUTPUT

  IF OBJECT_ID('m2.dbo.W_All_Koef_Gr') IS NOT NULL
    DROP TABLE m2.dbo.W_All_Koef_Gr	

  CREATE TABLE m2.dbo.W_All_Koef_Gr	 (
    вых int,
    id_tt int,
    rn int,
    id_group int,
    koef real
  )

  INSERT INTO m2.dbo.W_All_Koef_Gr	
  SELECT
    a.вых,
    a.id_tt,
    a.rn,
    a.id_group,
    b.summa_gr / a.summa_gr koef
  FROM (SELECT
          w.вых,
          w.id_tt,
          w.Date_f,
          t.id_group,
          SUM(w.summa) summa_gr,
          ROW_NUMBER() OVER (PARTITION BY w.вых, w.id_tt, t.id_group ORDER BY SUM(w.summa) DESC) rn
        FROM m2.dbo.W_All_Temp_Wall AS w
        INNER JOIN m2.dbo.W_All_Temp_Tovgr AS t
          ON w.id_tov = t.id_tov
          AND w.tt_format = t.tt_format_group
        GROUP BY w.вых,
                 w.id_tt,
                 w.Date_f,
                 t.id_group
        HAVING SUM(w.summa) > 0
      ) AS a   
  INNER JOIN (  SELECT
                  w.вых,
                  w.id_tt,
                  t.id_group,
                  SUM(w.Fact * pr.Price) summa_gr,
                  w.rn
                FROM m2.dbo.W_All_Temp_Wall AS w
                INNER JOIN m2.dbo.W_All_Temp_Tovgr AS t
                  ON w.id_tov = t.id_tov
                  AND w.tt_format = t.tt_format_group
                INNER JOIN reports..Price_1C_tov AS pr WITH (NOLOCK)
                  ON pr.id_tov = w.id_tov
                GROUP BY w.вых,
                         w.id_tt,
                         w.rn,
                         t.id_group
              ) AS b
    ON a.id_tt = b.id_tt
    AND a.вых = b.вых
    AND a.rn = b.rn
    AND a.id_group = b.id_group
  WHERE b.summa_gr / a.summa_gr > 1

  EXEC com.dbo.jobs_log_ins @id_job, 94, @getdate OUTPUT

  -- отнормировать план продаж
  --SELECT w.* , kg.koef
  UPDATE w
  SET Fact = w.Fact / kg.koef
  FROM m2.dbo.W_All_Temp_Wall AS w
  INNER JOIN m2.dbo.Tovari AS t WITH (NOLOCK)
    ON w.id_tov = t.id_tov
  INNER JOIN m2.dbo.W_All_Koef_Gr AS kg
    ON kg.id_tt = w.id_tt
    AND kg.вых = w.вых
    AND kg.rn = w.rn
    AND kg.id_group = t.id_group

  EXEC com.dbo.jobs_log_ins @id_job, 100, @getdate OUTPUT

  IF OBJECT_ID('m2.dbo.W_All_W3') IS NOT NULL
    DROP TABLE m2.dbo.W_All_W3  

  SELECT TOP 1 WITH TIES
    w1.id_tt,
    w1.id_tov,
    w1.вых,
    w1.rn,
    w2.Fact,
    w1.Fact - w2.Fact delta,
    w2.rn3 
  INTO m2.dbo.W_All_W3
  FROM m2.dbo.W_All_Temp_Wall AS w1
  INNER JOIN m2.dbo.W_All_Temp_Wall w2
    ON w1.id_tt = w2.id_tt
    AND w1.вых = w2.вых
    AND w1.id_tov = w2.id_tov
    AND w1.rn = w2.rn - 1
  WHERE w1.rn <= 4
  ORDER BY ROW_NUMBER() OVER (PARTITION BY w1.id_tt, w1.id_tov, w1.вых ORDER BY w1.Fact - w2.Fact DESC)

  CREATE CLUSTERED INDEX CI ON m2.dbo.W_All_W3 (id_tt, id_tov, Вых, rn3)
    
  EXEC com.dbo.jobs_log_ins @id_job, 105, @getdate OUTPUT
  
  TRUNCATE TABLE m2.dbo.w_all  

  EXEC com.dbo.jobs_log_ins @id_job, 110, @getdate OUTPUT

  -- для тт, которые не растут (нет в vv03..tt_dynamic с type_d=1), но при этом 'НормирПлПр' 
  INSERT INTO m2.dbo.w_all
  SELECT
    @Date_Next,
    w1.id_tt,
    w1.id_tov,
    w1.Fact,
    w1.q,
    ROW_NUMBER() OVER (PARTITION BY w1.id_tt, w1.id_tov ORDER BY w1.rn) + 1 rn,
    GETDATE(),
    w1.rn_2,
    w1.Date_f
  FROM m2.dbo.W_All_Temp_Wall AS w1
  LEFT JOIN m2.dbo.tt_dynamic AS td
    ON td.id_tt = w1.id_tt
    AND td.date_d = @Date_Current
    AND td.type_d = 1
  LEFT JOIN m2.dbo.W_All_Temp_Tovgr AS tg
    ON tg.id_tov = w1.id_tov
    AND tg.tt_format_group = w1.tt_format
  INNER JOIN (SELECT
                w3.id_tt,
                w3.id_tov,
                w3.вых,
                w3.Fact,
                w3.delta,
                w3.rn3,
                w3.rn,
                ROUND(ABS((w3.Fact - MIN(w1.Fact)) / w3.Fact), 2) koef2
              FROM m2.dbo.W_All_Temp_Wall AS w1
              INNER JOIN m2.dbo.W_All_W3 AS w3
                ON w1.id_tt = w3.id_tt
                AND w1.id_tov = w3.id_tov
                AND w1.вых = w3.вых
                AND ABS(w1.rn3 - w3.rn3) <= 2
              GROUP BY w3.id_tt,
                       w3.id_tov,
                       w3.вых,
                       w3.Fact,
                       w3.delta,
                       w3.rn3,
                       w3.rn
             ) AS w3
    ON w1.id_tt = w3.id_tt
    AND w1.id_tov = w3.id_tov
    AND w1.вых = w3.вых
    AND w1.rn >= w3.rn + 1
  INNER JOIN m2.dbo.temp_dnined AS d
    ON d.date_w = @Date_Next
  WHERE (
            d.type_pr = w1.вых
          AND 
            td.id_tt IS NULL
        )
      OR 
        tg.id_tov IS NULL  

  --order by w1.id_tt, w1.id_tov, w1.вых  ,w1.rn

  EXEC com.dbo.jobs_log_ins @id_job, 120, @getdate OUTPUT

  -- для растущих - брать самое больше значение на 2 месте
  INSERT INTO m2.dbo.w_all
  SELECT
    @Date_Next,
    w1.id_tt,
    w1.id_tov,
    w1.Fact,
    w1.q,   
    ROW_NUMBER() OVER (PARTITION BY w1.id_tt, w1.id_tov ORDER BY w1.q DESC) + 1 rn,
    GETDATE(),
    w1.rn_2,
    w1.Date_f   
  FROM m2.dbo.W_All_Temp_Wall AS w1
  LEFT JOIN m2.dbo.tt_dynamic td
    ON td.id_tt = w1.id_tt
    AND td.date_d = @Date_Current
    AND td.type_d = 1
  LEFT JOIN m2.dbo.W_All_Temp_Tovgr AS tg
    ON tg.id_tov = w1.id_tov
    AND tg.tt_format_group = w1.tt_format
  WHERE NOT (td.id_tt IS NULL
  OR tg.id_tov IS NULL)

  EXEC com.dbo.jobs_log_ins @id_job, 130, @getdate OUTPUT

  IF OBJECT_ID('tempdb..#w_all_01_rn') IS NOT NULL
    DROP TABLE #w_all_01_rn

  SELECT DISTINCT
    w.rn,
    w2.id_tov,
    w2.id_tt 
  INTO #w_all_01_rn
  FROM (SELECT DISTINCT
            rn
          FROM m2.dbo.w_all         
        ) AS w
          INNER JOIN (SELECT DISTINCT
            id_tt,
            id_tov
          FROM #dtt_s
        ) AS w2
    ON 1 = 1

  EXEC com.dbo.jobs_log_ins @id_job, 140, @getdate OUTPUT

  CREATE INDEX ind_w_all_01_rn ON #w_all_01_rn (rn, id_tt, id_tov)

  IF OBJECT_ID('tempdb..#ww_all') IS NOT NULL
    DROP TABLE #ww_all

  SELECT
    rn_rn.id_tov,
    rn_rn.id_tt,
    w2.fact,
    w2.q,
    rn_rn.rn,
    DATEADD(DAY, -rn_rn.rn, @Date_Current) date_f 
  INTO #ww_all
  FROM #w_all_01_rn AS rn_rn
  LEFT JOIN m2.dbo.w_all AS w
    ON w.rn = rn_rn.rn
    AND w.id_tov = rn_rn.id_tov
    AND w.id_tt = rn_rn.id_tt
    AND w.[date_r] = @Date_Next
  INNER JOIN (SELECT
                w.id_tt,
                w.id_tov,
                MIN(w.Fact) fact,
                MIN(w.q) q
              FROM m2.dbo.w_all AS w              
              GROUP BY w.id_tt,
                       w.id_tov
             ) AS w2
    ON rn_rn.id_tov = w2.id_tov
    AND rn_rn.id_tt = w2.id_tt
  WHERE w.rn IS NULL

  EXEC com.dbo.jobs_log_ins @id_job, 150, @getdate OUTPUT

  IF OBJECT_ID('tempdb..#w_all_01_rn') IS NOT NULL
    DROP TABLE #w_all_01_rn

  -- если нет номеров до 14, то добавить их с минимальным значением
  INSERT INTO m2.dbo.w_all (date_r, id_tov, id_tt, Fact, q, rn, date_f, date_add, rn_2)
  SELECT
    @Date_Next,
    *,
    GETDATE(),
    rn
  FROM #ww_all  

  EXEC com.dbo.jobs_log_ins @id_job, 160, @getdate OUTPUT

  --RETURN

  -- поменять топ и даун позиции по ММ для смены  ассортимента 
  EXEC m2.dbo.change_down_top_MM

  EXEC com.dbo.jobs_log_ins @id_job, 170, @getdate OUTPUT

  --exec vv03.[dbo].[add_w_all_split_status5]

  -- расчет максимального веса поставки
  EXEC m2.dbo.tt_zone_cap_delivery_add

  EXEC com.dbo.jobs_log_ins @id_job, 180, @getdate OUTPUT


  EXEC m2.dbo.tt_sostav_w_all

  EXEC com.dbo.jobs_log_ins @id_job, 190, @getdate OUTPUT

  IF OBJECT_ID('tempdb..#tt_add_w_all') IS NOT NULL
    DROP TABLE #tt_add_w_all
END
GO