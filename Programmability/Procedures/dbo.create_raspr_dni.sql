SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- 2019-09-19 OD переименовала, чтобы понять откуда идет вызов, смотрим где упадет
-- =============================================
CREATE PROCEDURE [dbo].[create_raspr_dni]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

insert into jobs..Jobs
        ([job_name]
      ,[prefix_job])
select 'reports..create_raspr_dni' , 0      

END
GO