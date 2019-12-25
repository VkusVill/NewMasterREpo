SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		Roda
-- Create date: 14/02/2018
-- Description:	Для оферты Народный Гурман отправка с буферной таблицы [srv-sql01].jobs.dbo.Telegram_Mess_forNG
--				сообщений в телеграмм-бот по шаблону
-- считывает буферную таблицу с 01го сервера и отправляет сообщения в телеграм для тех клиентов, у которых:
-- - не отключена тематическая рассылка
-- - не было рассылки НГ за последнюю неделю
-- - и не отключена рассылка из НГ (статус is_active = 1 таблицы vv03..Mailing_forNG
-- Также процедура увеличивает счетчики отправок сообщений в таблице vv03..Mailing_forNG процедурой vv03..Mailing_forNG_QTY)
-- =============================================
/*
На сервере [srv-sql01] в процедуре jobs.[dbo].[sr_Checkline_add_trigger] идет обработка строк чеков (Checkline).
В процедуре реализован код отбора новинок для передачи их в буферную таблицу, из которой будут в дальнейшем отсылаться сообщения в телеграмм
Создана буферная таблица:
CREATE TABLE Telegram_Mess_forNG
(id int identity (1,1)   -- id
,FullName  nvarchar(255) -- Имя клиента
,DCard_Number nvarchar(50) -- номер дисконтной карты
,telegram_id    int NOT NULL -- id телеграмма
,id_tov         int  -- id товара
,Name_tov nvarchar(150) -- наименование товара
,BaseSum_tov money  -- стоимость товара
,non_food  bit
,date_add  datetime -- дата добавления
,IsEmployee bit  -- признак сотрудника для определения номера бота
);

2). На [srv-sql03] сервере в процедуру jobs.dbo.input_jobs_triggers добавлен код для вызова обработчика буферной таблицы.
При появлении записей в таблице Telegram_Mess_forNG будет добавлена запись в jobs..Jobs для вызова процедуры [jobs].[dbo].[Telegram_Mess_forNG].

23/03/2018
1. Изменена процедура jobs.[dbo].[Telegram_Mess_forNG], в которой группируются покупки в разрезе покупателей.
  В зависимости от кол-ва покупок отправляется либо 66 клавиатура (одна покупка), либо 116 клавиатура (несколько покупок)
  в соотв. с шаблоном текста сообщения.
2. В условие отбора товаров добавлена проверка активности товара в таблице vv03.dbo.Mailing_forNG.
 Теперь даже если товар не является новинкой, но поле is_active=1, то рассылка будет осуществленна 
 (при выполнении остальных условий, ранее внедренных)

07/05/2018
Для автоматической рассылки "Народный гурман" сделать ограничение по количеству отправляемых сообщений.
По умолчанию 300
roda 28/03/2019 по просьбе  Фельдман изменено умолчание на 150
-- =============================================
-- Author:		Roda
-- Create date: 21/05/2018
-- Description: ИП-00018762.01 Сделать автоматическую рассылку предложений "Народный гурман" в мобильное приложение "Вкусвилл"

*/
-- exec [jobs].[dbo].[Telegram_Mess_forNG_1] 0
-- =============================================

CREATE PROCEDURE [dbo].[Telegram_Mess_forNG] @id_job AS int
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE
    @telegram_id    int,
    @message        nvarchar(MAX),
    @return_value   int,
    @date           date,
    @id_tov         int,
    @DCard_Number   nvarchar(50),
    @kp             nvarchar(1000),
    @Bot_id         int,
    @keyboard_id    int,
    @sp_id_tov      varchar(1000),
    @OneSignalToken nvarchar(40)

  SET @date = GETDATE();

  BEGIN TRY
    IF OBJECT_ID('tempdb..#ins') IS NOT NULL
      DROP TABLE #ins

    IF OBJECT_ID('tempdb..#ins_116') IS NOT NULL
      DROP TABLE #ins_116

    SELECT
      t.id,
      t.FullName,
      t.DCard_Number,
      t.telegram_id,
      t.id_tov,
      t.Name_tov,
      t.BaseSum_tov,
      t.non_food,
      t.date_add,
      t.IsEmployee,
      t.OneSignalToken,
      ROW_NUMBER() OVER (PARTITION BY t.DCard_Number, t.id_tov ORDER BY t.id) rn
    INTO
      #ins
    FROM [SRV-SQL01].jobs.dbo.Telegram_Mess_forNG t

    --where t.DCard_Number in ('3258801','0739404', '4856765') -- в целях тестирования
    SELECT
      t5.id,
      t5.FullName,
      t5.DCard_Number,
      t5.telegram_id,
      t5.id_tov,
      t5.Name_tov,
      t5.BaseSum_tov,
      t5.non_food,
      t5.date_add,
      t5.IsEmployee,
      CASE
        WHEN t5.OneSignalToken IS NOT NULL THEN
          1
        ELSE
          SUM(LEN(CAST(t5.id_tov AS varchar)) + LEN(t5.Name_tov) + LEN(CAST(t5.BaseSum_tov AS varchar)) + 3) OVER (PARTITION BY t5.telegram_id ORDER BY t5.id)
      END c_lenrn,
      CASE
        WHEN t5.OneSignalToken IS NOT NULL THEN
          1
        ELSE
          ROW_NUMBER() OVER (PARTITION BY t5.telegram_id ORDER BY t5.id)
      END AS c_rn,
      CASE
        WHEN t5.OneSignalToken IS NOT NULL THEN
          1
        ELSE
          COUNT(1) OVER (PARTITION BY t5.telegram_id)
      END c_cnt,
      t5.is_active,
      t5.Qty_send,
      t5.pp,
      t5.qty_max,
      t5.OneSignalToken,
      t5.mini_photo_url
    INTO
      #ins_116
    FROM
    (
      SELECT
        t.id,
        t.FullName,
        t.DCard_Number,
        t.telegram_id,
        t.id_tov,
        t.Name_tov,
        t.BaseSum_tov,
        t.non_food,
        @date date_add,                 --t.date_add	
        t.IsEmployee,
        t.OneSignalToken,
                                        -- в целях тестирования
                                        /*,case when t.DCard_Number in (
					 '0585888' -- Анжелика
					,'0501841' -- Вера
					,'3244390' -- Ольга
					--,'4573000' -- Ксения
					,'0000864' -- Мария Фельдман
					,'4856765' -- Родин Александр
					,'4105536'
					)
					then t.OneSignalToken
					else null
					end			OneSignalToken
				*/
        ph.mini_photo_url,
        ng.Qty_send + ROW_NUMBER() OVER (PARTITION BY t.id_tov ORDER BY t.id_tov) pp,
        ng.is_active is_active,
        ng.Qty_send Qty_send,
        ng.date_deactivate,
        ISNULL(ng.Qty_max, 150) qty_max -- КОНСТАНТА 300 - МАКСИМАЛЬНОЕ КОЛИЧЕСТВО ОТПРАВЛЕНИЙ
      -- roda 28/03/2019 по просьбе  Фельдман изменено умолчание на 150
      FROM #ins t
      LEFT JOIN vv03.dbo.Mailing_forNG AS ng WITH (NOLOCK)
        ON ng.id_tov = t.id_tov
      LEFT JOIN [Telegram].[dbo].[BOT_Tovar_description] ph WITH (NOLOCK)
        ON ph.id_tov = t.id_tov
      WHERE 1 = 1
            AND t.rn = 1
            -- в целях тестирования
            AND t.telegram_id IS NOT NULL

            -- у которых не отключена тематическая рассылка
            AND EXISTS
      (
        SELECT
          1
        FROM vv03.[dbo].Cards AS c WITH (NOLOCK)
        LEFT JOIN vv03.[dbo].Cards_Settings AS cs WITH (NOLOCK)
          ON c.number = cs.number
        WHERE t.DCard_Number = c.number
              AND
              (
                cs.distribution_tema IS NULL
                OR cs.distribution_tema = 1
              )
      )
            -- убираем телеграммы, по которым были рассылки НГ за последнюю неделю
            AND NOT EXISTS
      (
        SELECT
          1
        FROM Telegram.dbo.[outbox_telegram] AS a1 WITH (NOLOCK)
        WHERE a1.keyboard_id IN ( 66, 116 )
              AND a1.send_date > DATEADD(DAY, -7, @date)
              AND a1.user_id = t.telegram_id
      )
            -- убираем МП, по которым были рассылки НГ за последнюю неделю
            AND NOT EXISTS
      (
        SELECT
          1
        FROM [Loyalty].[dbo].[app_gourmet_offers] a1 WITH (NOLOCK)
        WHERE a1.number = t.DCard_Number
              AND a1.date_end >= @date
      )

            -- и карта не в черном списке
            AND NOT EXISTS
      (
        SELECT
          1
        FROM [SRV-SQL01].IzbenkaFin.dbo._InfoRg14970 b1 WITH (NOLOCK)
        WHERE b1._Fld14971 = t.DCard_Number
              AND b1._Fld14972 = 1
      )

            --OD 2019-06-21 Исключить товары Закажи и Забери (весовые торты) из рассылки Народного гурмана
            AND t.id_tov NOT IN ( 26132, 26133, 26134 )
    ) t5
    WHERE ISNULL(t5.pp, 0) <= t5.qty_max
          AND ISNULL(t5.date_deactivate, DATEADD(DAY, 1, @date)) > @date
          AND ISNULL(t5.is_active, 1) = 1

    --select * from ins_116
    DECLARE cur CURSOR LOCAL FOR
    SELECT
      t3.telegram_id AS telegram_id,
      REPLACE(
               REPLACE(
                        REPLACE(
                                 REPLACE(
                                          REPLACE(
                                                   REPLACE(t3.c_text, '[Имя]', Loyalty.dbo.Correct_Name(t3.FullName)),
                                                   '[НаименованиеТовара]',
                                                   t3.sp_tov
                                                 ),
                                          '[СписокНовинок]',
                                          t3.sp_tov
                                        ),
                                 '[Сумма]',
                                 t3.BaseSum
                               ),
                        '[Номер]',
                        RTRIM(LTRIM(t3.DCard_Number))
                      ),
               '[АктивноДо]',
               t3.c_date
             ) AS Message,
      t3.kp AS kp,
      t3.keyboard_id AS keyboard_id,
      CASE WHEN t3.IsEmployee = 0 THEN 1 ELSE 3 END AS Bot_id,
      t3.sp_id_tov AS sp_id_tov
    FROM
    (
      SELECT DISTINCT
             t2.telegram_id telegram_id,
             t2.c_cnt c_cnt,
             t2.DCard_Number DCard_Number,
             t2.FullName FullName,
             mes.c_code c_code,
             mes.c_text c_text,
             t2.IsEmployee IsEmployee,
             CASE
               -- для одного товара 66 клавиатура
               WHEN t2.c_cnt = 1 THEN
                 CONVERT(varchar, t2.id_tov) + '|' + CONVERT(varchar, t2.BaseSum_tov) + '|'
                 + CONVERT(varchar, DATEADD(DAY, 7, t2.date_add), 112) + '235959'
               -- для нескольких товаров 116 клавиатура
               ELSE
             (
               SELECT
                 CAST(a.id_tov AS varchar) + '|' + a.Name_tov + '|' + CAST(a.BaseSum_tov AS varchar) + '|'
               FROM #ins_116 a
               WHERE a.c_lenrn < 1000 - 14
                     AND a.telegram_id = t2.telegram_id
                     AND a.c_rn <= 10
               FOR XML PATH('')
             ) + CONVERT(varchar, DATEADD(DAY, 7, t2.date_add), 112) + '235959'
             END AS kp,
             CASE
               WHEN t2.c_cnt = 1 THEN
                 t2.Name_tov
               ELSE
                 REVERSE(STUFF(REVERSE(
                               (
                                 SELECT
                                   a.Name_tov + ', '
                                 FROM #ins_116 a
                                 WHERE a.c_lenrn < 1000 - 14
                                       AND a.telegram_id = t2.telegram_id
                                       AND a.c_rn <= 10
                                 FOR XML PATH('')
                               )
                                      ),
                               1,
                               2,
                               ''
                              )
                        )
             END AS sp_tov,
             CASE
               WHEN t2.c_cnt = 1 THEN
                 CONVERT(varchar(10), t2.id_tov)
               ELSE
             (
               SELECT
                 CONVERT(varchar(10), a.id_tov) + ';'
               FROM #ins_116 a
               WHERE a.c_lenrn < 1000 - 14
                     AND a.telegram_id = t2.telegram_id
                     AND a.c_rn <= 10
               FOR XML PATH('')
             )
             END AS sp_id_tov,
             CASE
               WHEN t2.c_cnt = 1 THEN
                 CAST((CAST(t2.BaseSum_tov AS numeric(18, 2))) AS varchar)
               ELSE
                 '-'
             END AS BaseSum,
             CONVERT(nvarchar(10), DATEADD(DAY, 7, t2.date_add), 104) AS c_date,
             CASE WHEN t2.c_cnt = 1 THEN 66 ELSE 116 END AS keyboard_id,
             t2.OneSignalToken OneSignalToken
      FROM #ins_116 t2
      JOIN
      (
        SELECT
          m._Fld13975 c_text,
          m._Code c_code
        --,m.*
        FROM [SRV-SQL01].[IzbenkaFin].[dbo].[_Reference13974] m WITH (NOLOCK)
        WHERE m._Code IN ( '000000001', '000000002', '000000005' )
      ) AS mes
        ON (CASE
              WHEN t2.c_cnt = 1 THEN
        (CASE WHEN t2.non_food = 0 THEN '000000001' ELSE '000000002' END)
              ELSE
                '000000005'
            END
           ) = mes.c_code
      WHERE t2.OneSignalToken IS NULL
    ) t3

    OPEN cur

    FETCH NEXT FROM cur
    INTO
      @telegram_id,
      @message,
      @kp,
      @keyboard_id,
      @Bot_id,
      @sp_id_tov

    WHILE @@FETCH_STATUS = 0
    BEGIN
      /*select 'отправляем'
					,@telegram_id
					,@kp
					,@keyboard_id
					,@sp_id_tov
					,@message
				*/
      --if @DCard_Number in ('3258801','0739404', '4856765') -- в целях тестирования
      EXEC Telegram.[dbo].[Telegram_Message_Send]
        @id_job = 12,
        @id_telegram = @telegram_id, --45329325
        @Message = @message,
        @checknumber = NULL,
        @Cashid = NULL,
        @keyboard_id = @keyboard_id,
        @Bot_id = @Bot_id,
        @keyboard_parameter = @kp,
        @priority = 0,
        @type_send = 3

      FETCH NEXT FROM cur
      INTO
        @telegram_id,
        @message,
        @kp,
        @keyboard_id,
        @Bot_id,
        @sp_id_tov;
    END

    CLOSE cur;
    DEALLOCATE cur;

    -- добавляем пуш
    INSERT INTO [Telegram].[dbo].[outbox_MP] (
      [oneSignalToken],  -- токен
      [Heading_message], -- "Народный гурман"
      [Message],         -- "Вы купили новинку – Блины с творогом, 200 г, и теперь можете принять участие в акции "Народный гурман"!"
      [Type_message],    -- 4
      [date_send],
      [date_message],    -- текущая дата
      [Data_message],    -- то же, что в данные клавиатуры бота
      [number]           -- номер карты
    )
    SELECT
      t.OneSignalToken,
      N'Народный гурман',
      t.FullName + N', в магазине «ВкусВилл» вы купили уникальный товар – ' + t.Name_tov
      + N', и теперь можете принять участие в проекте "Народный гурман"!',
      4,
      '19000101',
      @date,
      CONVERT(varchar, t.id_tov) + '|' + CONVERT(varchar, t.BaseSum_tov) + '|'
      + CONVERT(varchar, DATEADD(DAY, 7, t.date_add), 112) + '235959',
      t.DCard_Number
    FROM #ins_116 t
    WHERE t.OneSignalToken IS NOT NULL;

    INSERT INTO [Loyalty].[dbo].[app_gourmet_offers] (
      number,         -- номер карты, строковый, обязательный
      id_tov,         -- идентификатор товара, целочисленный, обязательный
      name_tov,       -- наименование товара, строковое
      mini_photo_url, -- url маленького фото товара, строковое
      refound_sum,    -- возвращаемая сумма
      date_end,       -- срок действия предложения, дата
      offer_status    -- 0				
    )
    SELECT
      t.DCard_Number,
      t.id_tov,
      t.Name_tov,
      t.mini_photo_url,
      t.BaseSum_tov,
      DATEADD(DAY, 7, t.date_add),
      0
    FROM #ins_116 t

    --where t.oneSignalToken is not null;

    -- увеличиваем кол-во рассылок
    DECLARE cur_QTY CURSOR FOR SELECT id_tov FROM #ins_116

    OPEN cur_QTY

    FETCH NEXT FROM cur_QTY
    INTO
      @id_tov;

    WHILE @@FETCH_STATUS = 0
    BEGIN
      EXEC vv03..Mailing_forNG_QTY @id_tov

      --select '++', @id_tov
      FETCH NEXT FROM cur_QTY
      INTO
        @id_tov;
    END

    CLOSE cur_QTY;
    DEALLOCATE cur_QTY;
  END TRY
  BEGIN CATCH
    INSERT INTO jobs..error_jobs (
      job_name,
      number_step,
      message,
      id_job
    )
    SELECT
      'jobs..Telegram_Mess_forNG',
      1,
      ERROR_MESSAGE(),
      @id_job
  END CATCH

  DELETE p
  FROM [SRV-SQL01].[jobs].[dbo].[Telegram_Mess_forNG] AS p
  INNER JOIN #ins AS i
    ON p.id = i.id

  IF OBJECT_ID('tempdb..#ins') IS NOT NULL
    DROP TABLE #ins

  IF OBJECT_ID('tempdb..#ins_116') IS NOT NULL
    DROP TABLE #ins_116
END

--select top 100 * from jobs..error_jobs with(nolock)
GO