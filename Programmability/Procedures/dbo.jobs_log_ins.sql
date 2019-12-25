SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		  MV
-- Create date: 21.20.2019
-- Description:	Запись в лог
-- =============================================
CREATE PROCEDURE [dbo].[jobs_log_ins]
  @id_job       int,
  @number_step  bigint, 
  @getdate      datetime OUTPUT, -- Дата время для расчета продолжительности 
  @working_job  int = NULL, 
  @par1         int = NULL, 
  @par2         int = NULL, 
  @par3         char(50) = NULL, 
  @par4         char(50) = NULL  
AS
BEGIN	
	SET NOCOUNT ON
  DECLARE @duration int = DATEDIFF(MILLISECOND, @getdate, GETDATE())

  INSERT INTO jobs..Jobs_log (
    id_job, 
    number_step, 
    duration,      
    working_job, 
    par1, 
    par2, 
    par3, 
    par4
  )
  SELECT 
    @id_job,       
    @number_step,
    @duration,
    @working_job, 
    @par1, 
    @par2,         
    @par3,        
    @par4  
    
  SET @getdate = GETDATE()  
END
GO