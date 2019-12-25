SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE VIEW [dbo].[jobs_union]
AS
SELECT     *
FROM         jobs..jobs (nolock)
UNION ALL
SELECT     *
FROM         jobs..arc_jobs  (nolock)


GO