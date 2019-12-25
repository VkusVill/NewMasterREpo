SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[find_str_modules]
(	
@text1  char(200) ,
@text2  char(200)  ,
@is_table int
)
RETURNS TABLE 
AS
RETURN 
(

SELECT sq.[base]
      ,sq.[name]
      ,sq.[xtype]      
      ,sq.[table_from]      
      ,sqs.text
      , case when CHARINDEX(rtrim(@text1),sqs.text,1)>0 
      and ((CHARINDEX(rtrim(@text2),sqs.text,1)>0 and isnull(@text2,'')<>'') 
      or isnull(@text2,'')='')      
      then 10
             when CHARINDEX(rtrim(@text1),sqs.text,1)>0 
      then 1     
             when (CHARINDEX(rtrim(@text2),sqs.text,1)>0 and isnull(@text2,'')<>'') 
             and  CHARINDEX(rtrim(@text1),sqs.text,1)=0
      then 2         
      
      else 0 end Is_find
      ,row_number() over ( order by sq.[base]
      , sq.[name]
      ,sq.[xtype]
      ,sqs.rn 
      , sqs.rn_2) rn
  FROM [jobs].[dbo].[sql_texts_str] (nolock) sqs
  inner join 
  ( select distinct base, name , xtype , table_from from jobs..sql_texts (nolock) sq  
  where ( CHARINDEX(rtrim(@text1),sq.text,1)>0
  and ((CHARINDEX(rtrim(@text2),sq.text,1)>0 and isnull(@text2,'')<>'') 
  or isnull(@text2,'')='')  and isnull(@is_table,0)=0 ) 
  or (isnull(@is_table,0)=1 and
  ( 
  
    CHARINDEX(rtrim(@text1) + '..' + rtrim(@text2),sq.text,1)>0 or 
    CHARINDEX(rtrim(@text1) + '.dbo.' + rtrim(@text2),sq.text,1)>0 or
    CHARINDEX('[' +rtrim(@text1) + ']..' + rtrim(@text2),sq.text,1)>0 or
    CHARINDEX('[' +rtrim(@text1) + '].dbo.' + rtrim(@text2),sq.text,1)>0 or
    CHARINDEX(rtrim(@text1) + '..[' + rtrim(@text2) + ']',sq.text,1)>0 or 
    CHARINDEX(rtrim(@text1) + '.dbo.[' + rtrim(@text2)+ ']',sq.text,1)>0 or
    CHARINDEX('[' +rtrim(@text1) + ']..[' + rtrim(@text2)+ ']',sq.text,1)>0 or
    CHARINDEX('[' +rtrim(@text1) + '].dbo.[' + rtrim(@text2)+ ']',sq.text,1)>0 


  )
  )
  
  
  
  ) sq on sq.base =sqs.base
  and sq.name=sqs.name and sq.xtype=sqs.xtype 

)
GO