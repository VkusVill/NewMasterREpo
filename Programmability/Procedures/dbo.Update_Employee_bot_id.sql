SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		OD
-- Create date: 2017-03-21
-- Description:	Перевод пользователей с входящими сообщениями от bot_id=3  на тестовый бот.
-- =============================================
CREATE PROCEDURE [dbo].[Update_Employee_bot_id]
@id_job as int
AS
BEGIN
  SET NOCOUNT ON;
  
  set @id_job = 10120
  
  declare
    @getdate as datetime = getdate()

  -- Перевод пользователей сотрудников на тестовый бот   
  update vv03..Cards with(rowlock)
     set id_bot = 3
    from vv03..cards
   where IsEmployee = 1
     and isnull(id_bot, 0) <> 3

  update vv03..Cards with(rowlock)
     set id_bot = 1
    from vv03..cards
   where isnull(IsEmployee, 0) = 0
     and isnull(id_bot, 1) <> 1

  insert into Telegram.dbo.Telegram_log([id_job], [number_step], [duration]) 
  select @id_job, 1, DATEDIFF(MILLISECOND, @getdate, GETDATE())

END
GO