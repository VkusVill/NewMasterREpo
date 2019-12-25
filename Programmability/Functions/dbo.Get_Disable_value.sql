SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		OD
-- Create date: 2017-12-07
-- Description:	Получение значения столбца is_disable таблицы jobs..disable_tbl
				--BOT_Set_LP - установка ЛП в БОТЕ блокируется на момент утреннего пересчета дат ЛП
-- =============================================
CREATE FUNCTION [dbo].[Get_Disable_value]
(
	@type_name as varchar(50)
)
RETURNS bit
AS
BEGIN
	DECLARE @res bit, @date_update as datetime, @max_time_minute as int

    select @res=is_disable
		, @date_update=d.date_update 
		, @max_time_minute=d.max_time_minute
	from jobs..disable_tbl as d 
	where d.Type_disable=@type_name

	set @res=isnull(@res,0)

	if @res=1
	begin
	  if datediff(minute,@date_update, getdate())>@max_time_minute
		 set @res=0
	end

	return @res
END
GO