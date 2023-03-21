with mags as
(
select gnis_name, max(stream_magnitude) as mag
from psf.ccira
where abundance = 'MOST_SALMON'
and gnis_name is not null
group by gnis_name

)

select 
  gnis_name,
  case 
    when mag >= 5 and mag < 40 then 'SOME_SALMON'
    when mag >= 40 then 'MANY_SALMON'
  end as magnitude_based_abundance
from mags
