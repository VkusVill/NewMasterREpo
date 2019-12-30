SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[make_tt_dynamic]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

declare @d date = dateadd(day,-1,convert(date,getdate()))

--create unique clustered index ind1 on  vv03..tt_dynamic (id_tt , date_d , type_d)
insert into m2..tt_dynamic
select tt.name_TT ,a.* , dateadd(day,1,@d) date_d , 1 type_d
from 
(
select DT.id_tt ,
--d.t,
--dt.Summa ,
sum(case d.t  when  0 then 1.0 / case when  DT2.Date_tt = DATEADD(day,-d.t-7, @d )then  DT2.Summa end  * dt.Summa end )  k_0,
sum(case d.t  when  1 then 1.0 / case when  DT2.Date_tt = DATEADD(day,-d.t-7, @d )then  DT2.Summa end  * dt.Summa end )  k_1,
sum(case d.t  when  2 then 1.0 / case when  DT2.Date_tt = DATEADD(day,-d.t-7, @d )then  DT2.Summa end * dt.Summa end ) k_2,
sum(case d.t  when  3 then 1.0 / case when  DT2.Date_tt = DATEADD(day,-d.t-7, @d )then  DT2.Summa end * dt.Summa end ) k_3,
sum(case d.t  when  4 then 1.0 / case when  DT2.Date_tt = DATEADD(day,-d.t-7, @d )then  DT2.Summa end * dt.Summa end ) k_4
from Reports..DT_01 dt (nolock)
inner join  Reports..DT_01 (nolock) dt2 on dt2.id_tt = dt.id_tt and dt2.Date_tt between  DATEADD(day,-4-7,dt.Date_tt) and  DATEADD(day,-0-7,dt.Date_tt)
inner join 
(select 0 t union select 1 union select 2 union select 3 union select 4) d on DT.Date_tt = DATEADD(day,-d.t , @d) 
where DT.Date_tt between DATEADD(day,-14,@d) and @d
and dt2.Summa>0
--and dt2.tt_format_dt=2
group by  DT.id_tt
) a
inner join m2..tt on tt.id_TT = a.id_tt and tt.tt_format in (2,4,12)

inner join
(
select a.tt_format , MAX(a.k_0) k_0 , MAX(a.k_1) k_1 , MAX(a.k_2) k_2 , MAX(a.k_3) k_3 , MAX(a.k_4) k_4
from 
(
select tt.tt_format ,d.t , DT2.Date_tt ,
--d.t,
--dt.Summa ,
case d.t  when  0 then 1.0 / case when  DT2.Date_tt = DATEADD(day,-d.t-7, @d )then  sum(DT2.Summa) end  * sum(dt.Summa) end   k_0,
case d.t  when  1 then 1.0 / case when  DT2.Date_tt = DATEADD(day,-d.t-7, @d )then  sum(DT2.Summa) end  * sum(dt.Summa) end   k_1,
case d.t  when  2 then 1.0 / case when  DT2.Date_tt = DATEADD(day,-d.t-7, @d )then  sum(DT2.Summa) end  * sum(dt.Summa) end   k_2,
case d.t  when  3 then 1.0 / case when  DT2.Date_tt = DATEADD(day,-d.t-7, @d )then  sum(DT2.Summa) end  * sum(dt.Summa) end   k_3,
case d.t  when  4 then 1.0 / case when  DT2.Date_tt = DATEADD(day,-d.t-7, @d )then  sum(DT2.Summa) end  * sum(dt.Summa) end   k_4
from Reports..DT_01 DT (nolock)
inner join m2..tt on tt.id_TT = dt.id_tt and tt.tt_format in (2,4,12)
inner join  Reports..DT_01 (nolock) dt2 on dt2.id_tt = dt.id_tt and dt2.Date_tt between  DATEADD(day,-4-7,dt.Date_tt) and  DATEADD(day,-0-7,dt.Date_tt)
inner join 
(select 0 t union select 1 union select 2 union select 3 union select 4) d on DT.Date_tt = DATEADD(day,-d.t , @d) 
where DT.Date_tt between DATEADD(day,-14,@d) and @d
and dt2.Summa>0
--and dt2.tt_format_dt=2
group by  tt.tt_format, d.t , DT2.Date_tt 
) a
group by a.tt_format) ttf on ttf.tt_format = tt.tt_format

left join m2..tt_dynamic td on td.id_tt = a.id_tt and td.date_d = dateadd(day,1,@d)  and td.type_d=1


where a.k_0>ttf.k_0+0.05 and a.k_1>ttf.k_1+0.05 and a.k_2>ttf.k_2+0.05
and a.k_0 + a.k_1 + a.k_2 + a.k_3  + a.k_4> ttf.k_0 + ttf.k_1 + ttf.k_2 + ttf.k_3  + ttf.k_4+ 0.25
and td.id_tt is null
order by a.k_0 + a.k_1 + a.k_2 + a.k_3  + a.k_4 desc

--declare @d date = dateadd(day,-1,convert(date,getdate()))

insert into m2..tt_dynamic
Select tt.name_TT ,DT.id_tt ,0,0,0,0,0, dateadd(day,1,@d) date_d , 1 type_d
from Reports..DT_01 DT (nolock)
inner join m2..tt on tt.id_TT = dt.id_tt and tt.tt_format in (2,4,12)
left join m2..tt_dynamic td on td.id_tt = DT.id_tt and td.date_d = dateadd(day,1,@d) and td.type_d=1
where DT.Date_tt>=DATEADD(day,-12,convert(date,getdate()))
and td.id_tt is null
group by tt.name_TT, DT.id_tt
having min(DT.Date_tt)>DATEADD(day,-12,convert(date,getdate()))



END
GO