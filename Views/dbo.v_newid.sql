﻿SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

 
CREATE VIEW [dbo].[v_newid] 
AS
 SELECT NEWID() AS v_newid
--и т.д. 
GO