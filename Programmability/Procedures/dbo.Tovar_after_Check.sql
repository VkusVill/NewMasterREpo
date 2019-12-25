SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		OD
-- Create date: 2019-02-28
-- Description:	Процедура запускает обработки связанные с учетом купленных товаров
--				1-заполнение списка товаров в последних чеках
--              2-пересчет списка товаров в акции Разнообразное питание			
--              3-учет товаров, купленных по подписке
--select  * from jobs..jobs as j with(nolock) where  job_name like '%jobs..Tovar_after_Check %' 
-- =============================================

CREATE PROCEDURE [dbo].[Tovar_after_Check] @id_job AS int
AS
BEGIN
  SET NOCOUNT ON;

  -- return  
  DECLARE
    @getdate  AS datetime  = GETDATE(),
    @job_name varchar(500) = com.dbo.Object_name_for_err(@@ProcID, DB_ID())

  IF OBJECT_ID('tempdb..#inserted') IS NOT NULL
    DROP TABLE #inserted

  SELECT
    [rowuid],
    [number],
    [cashid],
    [Checkno],
    [tov_str],
    [id_telegram],
    [date_add],
    ISNULL(Loyalty.dbo.Get_Tov_str_by_PN_Str(tov_str), '') tov_list,
    CONVERT(varchar(2000), NULL) tov_result
  INTO
    #inserted
  FROM [jobs].[dbo].[Tovar_after_Check_add_trigger]

  BEGIN TRY
    IF OBJECT_ID('tempdb..#Cards_tov_tt') IS NOT NULL
      DROP TABLE #Cards_tov_tt

    SELECT
      ctt.number,
      ctt.tov_last_checks
    INTO
      #Cards_tov_tt
    FROM vv03..Cards_tov_tt AS ctt WITH (NOLOCK)
    INNER JOIN #inserted i
      ON ctt.number = i.number

    UPDATE
      #inserted
    SET
      tov_result = vv03.dbo.UNION_Str_unique(i.tov_list, c.tov_last_checks, ',')
    --select *, vv03.dbo.union_str_unique(i.tov_list,c.tov_last_checks ,',') 
    FROM #inserted i
    LEFT JOIN #Cards_tov_tt AS c
      ON i.number = c.number

    UPDATE
      vv03..Cards_tov_tt
    SET
      tov_last_checks = i.tov_result
    --select ctt.number ,ctt.tov_last_checks ,i.tov_result, i.tov_list
    FROM vv03..Cards_tov_tt AS ctt WITH (NOLOCK)
    INNER JOIN #inserted i
      ON ctt.number = i.number
    WHERE ctt.tov_last_checks <> i.tov_result
          OR ctt.tov_last_checks IS NULL

    INSERT INTO [vv03].[dbo].[Cards_tov_tt] (
      [number],
      [tov_last_checks]
    )
    SELECT
      i.number,
      i.tov_result
    FROM vv03..Cards_tov_tt AS ctt WITH (NOLOCK)
    RIGHT JOIN #inserted i
      ON ctt.number = i.number
    WHERE ctt.number IS NULL

    DECLARE
      @number      AS char(7),
      @tov_str     AS varchar(MAX),
      @tov_str_res AS varchar(MAX),
      @res         AS varchar(MAX),
      @id_telegram AS bigint,
      @CashID      AS int,
      @CheckNo     AS int,
      @date_add    datetime,
      @id_subs     int

    -------------------------------обработаем подписку----------------------------------------------------
    BEGIN TRY
      --Добавим купленную подписку
      INSERT INTO Loyalty..subs_number (
        dateCreate,
        number,
        subsType,
        dateStart,
        dateFinish,
        paid,
        typePurchase,
        type_add
      )
      SELECT
        i.date_add,
        i.number,
        st.idType,
        CONVERT(date, DATEADD(DAY, 1, i.date_add)) dateStart,
        CONVERT(date, DATEADD(DAY, 31, i.date_add)) dateFinish,
        1 paid,
        1 typePurchase, --касса
        1 type_add      --касса
      FROM #inserted i
      INNER JOIN
      (
        SELECT
          id_tov,
          idType,
          s.durationDay
        FROM Loyalty..subs_type AS s WITH (NOLOCK)
        WHERE isActive = 1
      ) st
        ON (1 = 1)
      WHERE CHARINDEX(',' + RTRIM(st.id_tov) + ',', ',' + i.tov_list + ',', 1) = 1
    END TRY
    BEGIN CATCH
      INSERT INTO jobs..error_jobs (
        job_name,
        number_step,
        message,
        id_job
      )
      SELECT
        @job_name,
        10,
        'Покупка подписки' + ERROR_MESSAGE(),
        @id_job
    END CATCH

    --OD 2019-10-02 код перенесен в процедуру [Loyalty].[dbo].[spCard_CloseSubs], которая запускается из [spCardInfo_oplata_after_5]
    --   --Зафиксируем покупку товаров по подписке
    --   IF OBJECT_ID('tempdb..#tov_check') IS NOT NULL DROP TABLE #tov_check
    --   CREATE TABLE #tov_check(
    --   id_tov  int,
    --qty     decimal(15,3),
    --summa   decimal(15,2),
    --id_kontr int) 

    --   BEGIN TRY
    --	DECLARE crs_Tovar_after_Check_subs CURSOR FOR
    --	SELECT DISTINCT
    --	  i.[number],
    --	  i.[tov_str],
    --	  i.id_telegram,
    --	  i.[cashid],
    --	  i.[Checkno],
    --	  i.[date_add],
    --	  n.subsType
    --	FROM #inserted i
    --	  inner join Loyalty..subs_number as n with(nolock)
    --			 on i.number=n.number
    --	where  CONVERT(date,getdate() ) between n.dateStart and n.dateFinish 

    --	OPEN crs_Tovar_after_Check_subs

    --	FETCH crs_Tovar_after_Check_subs INTO @number, @tov_str, @id_telegram,@Cashid,@Checkno,@date_add,@id_subs

    --	WHILE @@FETCH_STATUS <> -1
    --	BEGIN

    --		--товары в новом чеке
    --		DELETE FROM #tov_check                           
    --		INSERT INTO #tov_check(id_tov,qty,summa,id_kontr)
    --		select id_tov,qty,summa,id_kontr 
    --		from Loyalty.dbo.Get_ListTovar_by_PN_Str_full(@tov_str)

    --	  insert into Loyalty..subs_use(CashID,CheckNo,date_sub,id_tov,idType,number, type_add)
    --	  select  @Cashid,@Checkno,@date_add, ch.id_tov,@id_subs , @number,1 --c с кассы
    --	  from #tov_check as ch
    --		inner join Loyalty..subs_typeProducts as p with(nolock)
    --			 on p.idType=@id_subs 
    --				and ch.id_tov=p.id_tov 
    --				and ch.summa=0

    --	  FETCH NEXT FROM crs_Tovar_after_Check_subs INTO @number, @tov_str, @id_telegram,@Cashid,@Checkno,@date_add,@id_subs
    --	END

    --	CLOSE crs_Tovar_after_Check_subs
    --	DEALLOCATE crs_Tovar_after_Check_subs
    --END TRY
    --BEGIN CATCH
    --	INSERT INTO jobs..error_jobs (job_name, number_step, message, id_job)
    --       SELECT @job_name, 11, @number + ' '  + @tov_str + ' '+ ERROR_MESSAGE(), @id_job
    --END CATCH

    ---обработаем акцию Разнообразное питание
    DECLARE @year_month AS int

    SELECT
      @year_month = Telegram.dbo.Next_month_year(GETDATE())

    BEGIN TRY
      DECLARE crs_Tovar_after_Check_action CURSOR FOR
      SELECT DISTINCT
             i.[number],
             i.[tov_list], --список купленных товаров через запятую
             i.id_telegram
      FROM #inserted i
      INNER JOIN Telegram..BOT_Action_50_SKU AS ba WITH (NOLOCK)
        ON i.number = ba.number
      WHERE ba.Year_month = @year_month
            AND ba.is_active = 1

      OPEN crs_Tovar_after_Check_action

      FETCH crs_Tovar_after_Check_action
      INTO
        @number,
        @tov_str,
        @id_telegram

      WHILE @@FETCH_STATUS <> -1
      BEGIN
        EXEC Telegram.[dbo].sp_Action_50_SKU_Recalc_Check_after
          @number = @number,
          @id_telegram = @id_telegram,
          @tov_str = @tov_str,
          @year_month = @year_month

        FETCH NEXT FROM crs_Tovar_after_Check_action
        INTO
          @number,
          @tov_str,
          @id_telegram
      END

      CLOSE crs_Tovar_after_Check_action
      DEALLOCATE crs_Tovar_after_Check_action
    END TRY
    BEGIN CATCH
      INSERT INTO jobs..error_jobs (
        job_name,
        number_step,
        message,
        id_job
      )
      SELECT
        @job_name,
        21,
        @number + ' ' + @tov_str + ' ' + ERROR_MESSAGE(),
        @id_job
    END CATCH

    DELETE FROM [jobs].[dbo].[Tovar_after_Check_add_trigger]
    --select *
    FROM [jobs].[dbo].[Tovar_after_Check_add_trigger] AS c
    INNER JOIN #inserted i
      ON c.[rowuid] = i.rowuid
  END TRY
  BEGIN CATCH
    INSERT INTO jobs..error_jobs (
      job_name,
      number_step,
      message,
      id_job
    )
    SELECT
      @job_name,
      100,
      ERROR_MESSAGE(),
      @id_job
  END CATCH
END
GO