SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		OD
-- Create date: 2017-12-07
-- Description:	Установка значения столбца is_disable таблицы jobs..disable_tbl
				--BOT_Set_LP - установка ЛП в БОТЕ блокируется на момент утреннего пересчета дат ЛП
-- =============================================
create procedure [dbo].[Set_Disable_value]

	@type_name as varchar(50)
	,@value as bit
AS
BEGIN
	DECLARE @res bit, @date_update as datetime

    update jobs..Disable_tbl
	set  is_disable=@value
		, date_update=getdate()
	from jobs..disable_tbl as d 
	where d.Type_disable=@type_name

	set @res=@@ROWCOUNT

	return @res
END
GO