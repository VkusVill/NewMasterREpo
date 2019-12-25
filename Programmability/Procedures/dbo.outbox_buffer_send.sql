SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:      RV
-- Create date: 2019-08-12
-- Description: Обработка таблицы outbox_buffer
-- =============================================
--select * from jobs..jobs where job_name like '%oubox_buffer_send%' and date_exc is null
--select * from jobs..jobs_union where job_name like '%oubox_buffer_send%' order by date_add desc

CREATE PROCEDURE [dbo].[outbox_buffer_send] @id_job AS int
AS
BEGIN
  SET NOCOUNT ON;

  BEGIN TRY
    DECLARE
      @getdate  AS datetime  = GETDATE(),
      @job_name varchar(500) = com.dbo.Object_name_for_err(@@Procid, DB_ID())

    IF OBJECT_ID('tempdb..#inserted') IS NOT NULL
      DROP TABLE #inserted

    CREATE TABLE #inserted
    (
      id bigint,
      number char(11),
      cashId bigint,
      checkNumber int,
      checkSumm decimal(15, 2),
      bonusSumm decimal(15, 2),
      typeMessage int,
      telegram_id bigint,         --@id_telegram
      OneSignalToken varchar(40),
      name varchar(255),          --@name
      sales_ost real,             --@Sales_ost
      bonus_ost real,             --@Bonus_ost
      shop_address varchar(1000), --@adress
      date_add datetime,
      tov_str nvarchar(MAX),
      discount decimal(15, 2),
      discount_proc int,
      bot_id int
    )

    INSERT INTO #inserted (
      id,
      number,
      cashId,
      checkNumber,
      checkSumm,
      bonusSumm,
      typeMessage,
      telegram_id,
      OneSignalToken,
      name,
      sales_ost,
      bonus_ost,
      shop_address,
      date_add,
      tov_str,
      discount,
      discount_proc,
      bot_id
    )
    SELECT
      b.id,
      RTRIM(b.number),
      b.cashId,
      b.checkNumber,
      b.checkSumm,
      b.bonusSumm,
      b.typeMessage,
      ISNULL(c.telegram_id, 0),
      c.OneSignalToken,
      Loyalty.dbo.Correct_Name(c.FullName),
      ISNULL(c.Sales_ost, 0),
      ISNULL(c.Bonus_ost, 0),
      Loyalty.dbo.Get_Ref_WEB_Shop(N),
      date_add,
      b.tov_str,
      b.discount,
      Loyalty.dbo.Card_Discount_Curr_month(RIGHT(RTRIM(b.number), 7)),
      ISNULL(c.id_bot, 1)
    FROM jobs.dbo.outbox_buffer AS b WITH (NOLOCK)
    LEFT JOIN vv03.dbo.Cards AS c WITH (NOLOCK)
      ON b.number = c.number
    LEFT JOIN vv03..ShopNo_CashID AS sc WITH (NOLOCK)
      ON sc.CashID = b.cashId
    LEFT JOIN vv03..tt AS tt WITH (NOLOCK)
      ON tt.N = sc.ShopNo

    --select top 100 *
    --from #inserted

    -- Отправка сообщения в мобильное приложение                   
    INSERT INTO Telegram.dbo.outbox_MP (
      oneSignalToken,
      Heading_message,
      Message,
      Type_message,
      date_message,
      date_send,
      Data_message,
      number
    )
    SELECT
      i.OneSignalToken,
      'Чек, ' + CONVERT(varchar, GETDATE(), 104) + ', ' + RTRIM(checkSumm) + 'р.',
      'Карта: ' + CONVERT(varchar(7), i.number) + '. Покупка: ' + RTRIM(checkSumm) + 'р. ' + ' Время '
      + CONVERT(varchar(5), date_add, 108) + CASE
                                               WHEN ISNULL(shop_address, '') <> '' THEN
                                                 ', ВкусВилл по адресу: ' + shop_address + '.'
                                               ELSE
                                                 ''
                                             END,
      i.typeMessage,
      GETDATE(),
      '19000101',
      RTRIM(cashId) + '|' + RTRIM(checkNumber) + '|' + CONVERT(varchar, GETDATE(), 112),
      i.number
    FROM #inserted AS i
    LEFT JOIN vv03.dbo.Cards_Settings AS cs WITH (NOLOCK)
      ON i.number = cs.number
    WHERE OneSignalToken != ''
          AND ISNULL(Send_check_BOT, 1) = 1

    --// ******* KasM 09-05-2019 *******
    --Перенос кода отправки сообщений в телеграмм из процедуры loyalty..spCardInfo_oplata_after_5
    IF OBJECT_ID('tempdb..#outboxTelegram') IS NOT NULL
      DROP TABLE #outboxTelegram

    CREATE TABLE #outboxTelegram
    (
      bot_id int,
      telegram_id bigint,
      message varchar(MAX),
      checkNumber int,
      cashId bigint,
      keyboard_parameter varchar(200)
    )

    INSERT INTO #outboxTelegram (
      bot_id,
      telegram_id,
      message,
      checkNumber,
      cashId,
      keyboard_parameter
    )
    SELECT
      bot_id,
      telegram_id,
      CASE
        WHEN i.bonusSumm <> 0
             AND i.checkSumm >= 0 THEN
          i.name + CASE WHEN i.name <> '' THEN ', о' ELSE 'О' END
          + CASE
              WHEN ISNULL(i.bonusSumm, 0) <> 0 THEN
                'плата бонусом ' + RTRIM(CONVERT(int, i.bonusSumm))
              ELSE
                ''
            END + 'р. '
        ELSE
          ''
      END + 'Карта: ' + CONVERT(varchar(7), i.number) + CASE
                                                          WHEN i.checkSumm >= 0 THEN
                                                            '. Покупка: '
                                                          ELSE
                                                            '. Отмена покупки: '
                                                        END + RTRIM(ABS(i.checkSumm)) + 'р. ' + ' Время '
      + CONVERT(varchar(5), GETDATE(), 108) + ', ' + CASE
                                                       WHEN ISNULL(i.shop_address, '') <> '' THEN
                                                         'ВкусВилл по адресу: ' + i.shop_address + '. '
                                                       ELSE
                                                         ' '
                                                     END + CASE
                                                             WHEN ISNULL(i.discount, 0) > 0 THEN
                                                               'Скидка по акции: ' + RTRIM(i.discount) + 'р. '
                                                             ELSE
      (CASE
         WHEN i.discount_proc > 0 THEN
           'По данному чеку скидка начислится бонусами, информация о них придет вам отдельным сообщением. '
         ELSE
           ''
       END
      )
                                                           END
      + CASE
          WHEN i.sales_ost > 0 THEN
            ' Покупки в Избенке с начала месяца:' + RTRIM(i.sales_ost) + 'р.'
          ELSE
            ''
        END + CASE
                WHEN i.checkSumm >= 0 THEN
                  ' Сумма бонусов на карте: ' + RTRIM(i.bonus_ost) + 'р.' + CHAR(10) --+ @Check_info 
                ELSE
                  ''
              END
      + CASE
          WHEN i.discount <> 0
               AND i.discount_proc <> 0 THEN
            CONVERT(varchar(MAX), ISNULL(Loyalty.dbo.Get_CheckInfo_by_PN_Str_discount(i.tov_str, i.discount_proc), ''))
          ELSE
            CONVERT(varchar(MAX), ISNULL(Loyalty.dbo.Get_CheckInfo_by_PN_Str_discount(i.tov_str, 0), ''))
        END + CASE
                WHEN i.checkSumm >= 0 THEN
                  CHAR(10) + ' Оцените, пожалуйста, как прошла ваша покупка:'
                ELSE
                  ''
              END,
      --WHEN i.checkSumm < 0 THEN CASE WHEN i.name <> '' 
      --							THEN i.name + ', б'
      --							ELSE 'Б'
      --						END + 'лагодарим вас за то, что вернули нам товары:'
      --						+ ISNULL(loyalty.dbo.Get_ListTovar_by_PN_Str(i.tov_str), '')
      --						+ CHAR(10) + 'Мы анализируем все возвраты покупателей. Это помогает нам совершенствовать продукты и давать оперативную обратную связь от покупателей - производителям.'
      --						+ CHAR(10) + 'Оцените, пожалуйста, как прошел возврат товара в магазине?'

      --			END as message
      checkNumber,
      cashId,
      CONVERT(
               varchar(200),
               '[' + RTRIM(cashId) + ']' + '[' + RTRIM(checkNumber) + ']' + '['
               + REPLACE(REPLACE(REPLACE(CONVERT(varchar(20), GETDATE(), 120), ':', ''), '-', ''), ' ', '') + ']'
             ) AS keyboard_parameter
    FROM #inserted i
    LEFT JOIN vv03..Cards_Settings AS c WITH (NOLOCK)
      ON c.number = i.number
    WHERE telegram_id <> 0
          AND
          (
            c.Send_check_BOT = 1
            OR c.Send_check_BOT IS NULL
          )
          AND ISNULL(tov_str, '') <> ''

    --and i.number <> '3389803'
    INSERT INTO [Telegram].[dbo].[outbox_telegram] (
      [bot_id],
      [user_id],
      [message],
      [add_date],
      CashCheckNo,
      CashID,
      keyboard_id,
      [disable_web_page_preview],
      keyboard_parameter,
      priority,
      type_distribusion
    )
    SELECT
      bot_id,
      telegram_id,
      message,
      GETDATE(),
      checkNumber,
      cashId,
      11,
      1,
      keyboard_parameter,
      1,
      0
    FROM #outboxTelegram
    WHERE ISNULL(message, '') <> ''
          AND ISNULL(telegram_id, 0) <> 0

    --DECLARE @id_telegram        int 
    --          ,@Message            varchar(max)
    --	,@Cashid             bigint
    --          ,@checknumber        int
    --	,@keyboard_parameter varchar(200)

    --   DECLARE CUR_t CURSOR LOCAL FORWARD_ONLY 
    --FOR
    -- SELECT   telegram_id, message, checkNumber, cashId, keyboard_parameter
    -- FROM     #outboxTelegram
    -- ORDER BY telegram_id

    --OPEN CUR_t
    --FETCH NEXT FROM CUR_t INTO @id_telegram, @Message, @checknumber, @Cashid, @keyboard_parameter

    --WHILE @@FETCH_STATUS <> 0
    --BEGIN
    --EXEC Telegram.[dbo].[Telegram_Message_Send] @id_job       = @id_job
    --										   ,@id_telegram  = @id_telegram
    --										   ,@Message      = @Message
    --										   ,@checknumber  = @checknumber
    --										   ,@Cashid       = @Cashid
    --										   ,@keyboard_id  = 11
    --										   ,@Bot_id       = 0
    --										   ,@disable_web_page_preview = 1
    --										   ,@keyboard_parameter = @keyboard_parameter
    --										   ,@priority     = 1
    --										   ,@type_send    = 0 --1-сервисная рассылка

    --FETCH NEXT FROM CUR_t INTO @id_telegram, @Message, @checknumber, @Cashid, @keyboard_parameter
    --END
    --CLOSE CUR_t
    --DEALLOCATE Cur_t
    --// ******* KasM 09-05-2019 *******
    INSERT INTO jobs..Jobs_log (
      [id_job],
      [number_step],
      [duration]
    )
    SELECT
      @id_job,
      10,
      DATEDIFF(MILLISECOND, @getdate, GETDATE())

    SELECT
      @getdate = GETDATE()
  END TRY
  BEGIN CATCH
    DECLARE @err nvarchar(MAX) = N'03 - outbox_buffer_send Err: ' + ERROR_MESSAGE()

    INSERT INTO jobs..error_jobs (
      job_name,
      number_step,
      [message],
      id_job
    )
    SELECT
      @job_name,
      1,
      @err,
      @id_job

    INSERT INTO Telegram.dbo.outbox_telegram (
      [user_id],
      [message],
      add_date,
      bot_id
    )
    SELECT
      '153848485',
      @err,
      GETDATE(),
      5

    --select*from [outbox_buffer_err]
    INSERT INTO [dbo].[outbox_buffer_err] --100 
    (
      id,
      number,
      cashId,
      checkNumber,
      checkSumm,
      bonusSumm,
      typeMessage,
      sendIn,
      date_add,
      tov_str,
      discount,
      err_msg,
      add_date,
      act
    )
    SELECT
      id,
      number,
      cashId,
      checkNumber,
      checkSumm,
      bonusSumm,
      typeMessage,
      100,
      date_add,
      tov_str,
      discount,
      @err,
      GETDATE(),
      'y'
    FROM #inserted

    DELETE FROM jobs.dbo.outbox_buffer
    WHERE id IN
          (
            SELECT id FROM [outbox_buffer_err]
          )
  END CATCH

  DELETE p
  FROM jobs.dbo.outbox_buffer AS p
  INNER JOIN #inserted AS i
    ON p.id = i.id
END
GO