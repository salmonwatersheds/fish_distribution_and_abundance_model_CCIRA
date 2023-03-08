-- rank nuseds data, finding top 10 producing streams per species

drop table if exists psf.nuseds_top10;

create table psf.nuseds_top10 as
-- remove duplicate locations
with cleaned as (
  select distinct on (spp, sys_nm)
    spp, 
    sys_nm,
    pop_id,
    geom_mean 
  from psf.nuseds 
  where geom_mean is not null
  order by spp, sys_nm, geom_mean desc
),

-- rank locations per species
ranked as (
  select
    spp,
    sys_nm,
    pop_id,
    geom_mean,
    rank() over (partition by spp order by geom_mean desc)
  from cleaned
),

-- uniquify watershed code lookup
wsc as (
  select distinct 
    pop_id,
    wscode
   from psf.nuseds_sites
),

-- pull only top 10, add watershed code
top10 as (
  select
    a.spp,
    a.sys_nm,
    a.rank,
    b.wscode
  from ranked a
  left outer join wsc b
  on a.pop_id = b.pop_id
  where rank <= 10
  order by spp, rank
),

-- extract all distinct locations
codes as (
select distinct 
  wscode
from top10 
order by wscode
)

-- for each location, note which spp are top 10 (enabling simple join to spatial)
select 
  cd.wscode,
  case when cm.spp is not null then true else null end as cm,
  case when cn.spp is not null then true else null end as cn,
  case when co.spp is not null then true else null end as co,
  case when pke.spp is not null then true else null end as pke,
  case when pko.spp is not null then true else null end as pko,
  case when sel.spp is not null then true else null end as sel,
  case when ser.spp is not null then true else null end as ser
from codes cd
left join top10 cm on cd.wscode = cm.wscode and cm.spp = 'CM'
left join top10 cn on cd.wscode = cn.wscode and cn.spp = 'CN'
left join top10 co on cd.wscode = co.wscode and co.spp = 'CO'
left join top10 pke on cd.wscode = pke.wscode and pke.spp = 'PKE'
left join top10 pko on cd.wscode = pko.wscode and pko.spp = 'PKO'
left join top10 sel on cd.wscode = sel.wscode and sel.spp = 'SEL'
left join top10 ser on cd.wscode = ser.wscode and ser.spp = 'SER'