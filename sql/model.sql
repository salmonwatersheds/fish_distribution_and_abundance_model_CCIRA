-- create ccira fish distribution models as per Gowgaia model
drop table if exists psf.ccira;

create table psf.ccira as
with access as (
  select
    s.segmented_stream_id,
    s.linear_feature_id,
    s.blue_line_key,
    s.edge_type,
    s.downstream_route_measure,
    s.upstream_route_measure,
    s.stream_order,
    s.stream_magnitude,
    ua.upstream_area_ha,
    s.watershed_group_code,
    s.gnis_name,
    -- translate barrier columns to string for easy export
    wscode_ltree::text as wscode,
    localcode_ltree::text as localcode,
    barriers_ch_cm_co_pk_sk_dnstr,
    barriers_ct_dv_rb_dnstr,
    obsrvtn_species_codes_upstr,
    species_codes_dnstr,
    -- anadromous models
    case 
    when obsrvtn_species_codes_upstr && array['CH'] then 'KNOWN'  
    when obsrvtn_species_codes_upstr && array['CH'] is false and  
        species_codes_dnstr && array['CH'] and
        barriers_ch_cm_co_pk_sk_dnstr = array[]::text[] then 'INFERRED' 
    when obsrvtn_species_codes_upstr && array['CH'] is false and  
        species_codes_dnstr && array['CH'] is false and
        barriers_ch_cm_co_pk_sk_dnstr = array[]::text[] then 'POTENTIAL' 
    end as model_ch,
    case 
    when obsrvtn_species_codes_upstr && array['CM'] then 'KNOWN'  
    when obsrvtn_species_codes_upstr && array['CM'] is false and  
        species_codes_dnstr && array['CM'] and
        barriers_ch_cm_co_pk_sk_dnstr = array[]::text[] then 'INFERRED' 
    when obsrvtn_species_codes_upstr && array['CM'] is false and  
        species_codes_dnstr && array['CM'] is false and
        barriers_ch_cm_co_pk_sk_dnstr = array[]::text[] then 'POTENTIAL' 
    end as model_cm,
    case 
    when obsrvtn_species_codes_upstr && array['CO'] then 'KNOWN'  
    when obsrvtn_species_codes_upstr && array['CO'] is false and  
        species_codes_dnstr && array['CO'] and
        barriers_ch_cm_co_pk_sk_dnstr = array[]::text[] then 'INFERRED' 
    when obsrvtn_species_codes_upstr && array['CO'] is false and  
        species_codes_dnstr && array['CO'] is false and
        barriers_ch_cm_co_pk_sk_dnstr = array[]::text[] then 'POTENTIAL' 
    end as model_co,
    case 
    when obsrvtn_species_codes_upstr && array['PK'] then 'KNOWN'  
    when obsrvtn_species_codes_upstr && array['PK'] is false and  
        species_codes_dnstr && array['PK'] and
        barriers_ch_cm_co_pk_sk_dnstr = array[]::text[] then 'INFERRED' 
    when obsrvtn_species_codes_upstr && array['PK'] is false and  
        species_codes_dnstr && array['PK'] is false and
        barriers_ch_cm_co_pk_sk_dnstr = array[]::text[] then 'POTENTIAL' 
    end as model_pk,
    case 
    when obsrvtn_species_codes_upstr && array['SK'] then 'KNOWN'  
    when obsrvtn_species_codes_upstr && array['SK'] is false and  
        species_codes_dnstr && array['SK'] and
        barriers_ch_cm_co_pk_sk_dnstr = array[]::text[] then 'INFERRED' 
    when obsrvtn_species_codes_upstr && array['SK'] is false and  
        species_codes_dnstr && array['SK'] is false and
        barriers_ch_cm_co_pk_sk_dnstr = array[]::text[] then 'POTENTIAL' 
    end as model_sk,
    case 
    when obsrvtn_species_codes_upstr && array['ST'] then 'KNOWN'  
    when obsrvtn_species_codes_upstr && array['ST'] is false and  
        species_codes_dnstr && array['ST'] and
        barriers_st_dnstr = array[]::text[] then 'INFERRED' 
    when obsrvtn_species_codes_upstr && array['ST'] is false and  
        species_codes_dnstr && array['ST'] is false and
        barriers_st_dnstr = array[]::text[] then 'POTENTIAL' 
    end as model_st,

    -- resident models
    case 
    when obsrvtn_species_codes_upstr && array['BT','DV'] then 'KNOWN'  -- downstream of observation
    when obsrvtn_species_codes_upstr && array['BT','DV'] is false and  -- upstream of observation, no barrier downstream
      species_codes_dnstr && array['BT','DV'] and
      barriers_ct_dv_rb_dnstr = array[]::text[] then 'INFERRED' 
    when obsrvtn_species_codes_upstr && array['BT','DV'] is false and  -- no observation upstream or downstream, no barrier
      species_codes_dnstr && array['BT','DV'] is false and
      barriers_ct_dv_rb_dnstr = array[]::text[] then 'POTENTIAL' 
    when obsrvtn_species_codes_upstr && array['BT','DV'] is false and  -- no observation upstream or downstream, barrier downstream
      barriers_ct_dv_rb_dnstr != array[]::text[] 
      and edge_type not in (1100, 1200, 1350, 1410, 1425, 1450)  -- no elevation cap, but at least exclude some edge types
      then 'POTENTIAL_BARRIER_DNSTR'      
    end as model_dv,
    case 
    when obsrvtn_species_codes_upstr && array['CT'] then 'KNOWN'  
    when obsrvtn_species_codes_upstr && array['CT'] is false and  
      species_codes_dnstr && array['CT'] and
      barriers_ct_dv_rb_dnstr = array[]::text[] then 'INFERRED' 
    when obsrvtn_species_codes_upstr && array['CT'] is false and  
      species_codes_dnstr && array['CT'] is false and
      barriers_ct_dv_rb_dnstr = array[]::text[] then 'POTENTIAL' 
    when obsrvtn_species_codes_upstr && array['CT'] is false and  
      barriers_ct_dv_rb_dnstr != array[]::text[] 
      and edge_type not in (1100, 1200, 1350, 1410, 1425, 1450)  -- no elevation cap, but at least exclude some edge types
      then 'POTENTIAL_BARRIER_DNSTR' 
    end as model_ct,
    case 
    when obsrvtn_species_codes_upstr && array['RB'] then 'KNOWN'  
    when obsrvtn_species_codes_upstr && array['RB'] is false and  
      species_codes_dnstr && array['RB'] and
      barriers_ct_dv_rb_dnstr = array[]::text[] then 'INFERRED' 
    when obsrvtn_species_codes_upstr && array['RB'] is false and  
      species_codes_dnstr && array['RB'] is false and
      barriers_ct_dv_rb_dnstr = array[]::text[] then 'POTENTIAL' 
    when obsrvtn_species_codes_upstr && array['RB'] is false and  
      barriers_ct_dv_rb_dnstr != array[]::text[]
      and edge_type not in (1100, 1200, 1350, 1410, 1425, 1450)  -- no elevation cap, but at least exclude some edge types
      then 'POTENTIAL_BARRIER_DNSTR' 
    end as model_rb,
    geom
  from bcfishpass.streams s
  INNER JOIN whse_basemapping.fwa_streams_watersheds_lut l
  ON s.linear_feature_id = l.linear_feature_id
  INNER JOIN whse_basemapping.fwa_watersheds_upstream_area ua
  ON l.watershed_feature_id = ua.watershed_feature_id

  where watershed_group_code in ('ATNA','BELA','KHTZ','KITL','KLIN','KTSU','LDEN','LRDO','NASC','NECL','NIEL','OWIK')
)

-- add abundance model
select 
  a.segmented_stream_id,
  a.linear_feature_id,
  a.blue_line_key,
  a.edge_type,
  a.downstream_route_measure,
  a.upstream_route_measure,
  a.gnis_name,
  a.wscode,
  a.localcode,
  a.stream_order,
  a.stream_magnitude,
  a.upstream_area_ha,
  array_to_string(a.barriers_ch_cm_co_pk_sk_dnstr,'; ') as barriers_ch_cm_co_pk_sk_dnstr,
  array_to_string(a.barriers_ct_dv_rb_dnstr,'; ') as barriers_ct_dv_rb_dnstr,
  array_to_string(a.obsrvtn_species_codes_upstr,'; ') as obsrvtn_species_codes_upstr,
  array_to_string(a.species_codes_dnstr,'; ') as species_codes_dnstr,
  a.model_ch,
  a.model_cm,
  a.model_co,
  a.model_pk,
  a.model_sk,
  a.model_st,
  a.model_ct,
  a.model_dv,
  a.model_rb,
  b.cm as nuseds_top10_cm,
  b.cn as nuseds_top10_cn,
  b.co as nuseds_top10_co,
  b.pke as nuseds_top10_pke,
  b.pko as nuseds_top10_pko,
  b.sel as nuseds_top10_sel,
  b.ser as nuseds_top10_ser,
  case 
    when
      a.barriers_ch_cm_co_pk_sk_dnstr = array[]::text[]
      and a.stream_magnitude < 5
    then 'FEW_SALMON'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr = array[]::text[]
      and a.stream_magnitude >= 5
      and a.stream_magnitude < 40
    then 'SOME_SALMON'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr = array[]::text[]
      and a.stream_magnitude >= 40
    then 'MANY_SALMON'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr != array[]::text[]
      and a.barriers_ct_dv_rb_dnstr = array[]::text[]
    then 'RESIDENT_FISH_ONLY'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr != array[]::text[]
      and a.barriers_ct_dv_rb_dnstr != array[]::text[]
      and a.edge_type not in (1100, 1200, 1350, 1410, 1425, 1450)
    then 'RESIDENT_FISH_ONLY_BARRIER_DNSTR'
  end as fishyness_magnitude,
  case
    when
      a.barriers_ch_cm_co_pk_sk_dnstr = array[]::text[]
      and a.stream_magnitude < 5
    then 'FEW_SALMON'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr = array[]::text[]
      and a.stream_magnitude >= 5
      and a.stream_magnitude < 40
    then 'SOME_SALMON'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr = array[]::text[]
      and a.stream_magnitude >= 40
    then 'MANY_SALMON'
    when b.cm is true or b.cn is true or b.co is true or b.pke is true or b.pko is true or b.sel is true or b.ser is true
    then 'MOST_SALMON'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr != array[]::text[]
      and a.barriers_ct_dv_rb_dnstr = array[]::text[]
    then 'RESIDENT_FISH_ONLY'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr != array[]::text[]
      and a.barriers_ct_dv_rb_dnstr != array[]::text[]
      and a.edge_type not in (1100, 1200, 1350, 1410, 1425, 1450)
    then 'RESIDENT_FISH_ONLY_BARRIER_DNSTR'
  end as fishyness_salmon,
  case
    when
      a.barriers_ch_cm_co_pk_sk_dnstr = array[]::text[]
      and a.stream_magnitude < 5
    then 'FEW_SALMON'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr = array[]::text[]
      and a.stream_magnitude >= 5
      and a.stream_magnitude < 40
    then 'SOME_SALMON'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr = array[]::text[]
      and a.stream_magnitude >= 40
    then 'MANY_SALMON'
    when b.cm is true
    then 'MOST_SALMON'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr != array[]::text[]
      and a.barriers_ct_dv_rb_dnstr = array[]::text[]
    then 'RESIDENT_FISH_ONLY'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr != array[]::text[]
      and a.barriers_ct_dv_rb_dnstr != array[]::text[]
      and a.edge_type not in (1100, 1200, 1350, 1410, 1425, 1450)
    then 'RESIDENT_FISH_ONLY_BARRIER_DNSTR'
  end as fishyness_cm,
  case
    when
      a.barriers_ch_cm_co_pk_sk_dnstr = array[]::text[]
      and a.stream_magnitude < 5
    then 'FEW_SALMON'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr = array[]::text[]
      and a.stream_magnitude >= 5
      and a.stream_magnitude < 40
    then 'SOME_SALMON'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr = array[]::text[]
      and a.stream_magnitude >= 40
    then 'MANY_SALMON'
    when b.cn is true
    then 'MOST_SALMON'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr != array[]::text[]
      and a.barriers_ct_dv_rb_dnstr = array[]::text[]
    then 'RESIDENT_FISH_ONLY'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr != array[]::text[]
      and a.barriers_ct_dv_rb_dnstr != array[]::text[]
      and a.edge_type not in (1100, 1200, 1350, 1410, 1425, 1450)
    then 'RESIDENT_FISH_ONLY_BARRIER_DNSTR'
  end as fishyness_cn,
  case
    when
      a.barriers_ch_cm_co_pk_sk_dnstr = array[]::text[]
      and a.stream_magnitude < 5
    then 'FEW_SALMON'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr = array[]::text[]
      and a.stream_magnitude >= 5
      and a.stream_magnitude < 40
    then 'SOME_SALMON'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr = array[]::text[]
      and a.stream_magnitude >= 40
    then 'MANY_SALMON'
    when b.co is true
    then 'MOST_SALMON'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr != array[]::text[]
      and a.barriers_ct_dv_rb_dnstr = array[]::text[]
    then 'RESIDENT_FISH_ONLY'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr != array[]::text[]
      and a.barriers_ct_dv_rb_dnstr != array[]::text[]
      and a.edge_type not in (1100, 1200, 1350, 1410, 1425, 1450)
    then 'RESIDENT_FISH_ONLY_BARRIER_DNSTR'
  end as fishyness_co,
  case
    when
      a.barriers_ch_cm_co_pk_sk_dnstr = array[]::text[]
      and a.stream_magnitude < 5
    then 'FEW_SALMON'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr = array[]::text[]
      and a.stream_magnitude >= 5
      and a.stream_magnitude < 40
    then 'SOME_SALMON'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr = array[]::text[]
      and a.stream_magnitude >= 40
    then 'MANY_SALMON'
    when b.pke is true
    then 'MOST_SALMON'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr != array[]::text[]
      and a.barriers_ct_dv_rb_dnstr = array[]::text[]
    then 'RESIDENT_FISH_ONLY'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr != array[]::text[]
      and a.barriers_ct_dv_rb_dnstr != array[]::text[]
      and a.edge_type not in (1100, 1200, 1350, 1410, 1425, 1450)
    then 'RESIDENT_FISH_ONLY_BARRIER_DNSTR'
  end as fishyness_pke,
  case
    when
      a.barriers_ch_cm_co_pk_sk_dnstr = array[]::text[]
      and a.stream_magnitude < 5
    then 'FEW_SALMON'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr = array[]::text[]
      and a.stream_magnitude >= 5
      and a.stream_magnitude < 40
    then 'SOME_SALMON'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr = array[]::text[]
      and a.stream_magnitude >= 40
    then 'MANY_SALMON'
    when b.pko is true
    then 'MOST_SALMON'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr != array[]::text[]
      and a.barriers_ct_dv_rb_dnstr = array[]::text[]
    then 'RESIDENT_FISH_ONLY'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr != array[]::text[]
      and a.barriers_ct_dv_rb_dnstr != array[]::text[]
      and a.edge_type not in (1100, 1200, 1350, 1410, 1425, 1450)
    then 'RESIDENT_FISH_ONLY_BARRIER_DNSTR'
  end as fishyness_pko,
  case
    when
      a.barriers_ch_cm_co_pk_sk_dnstr = array[]::text[]
      and a.stream_magnitude < 5
    then 'FEW_SALMON'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr = array[]::text[]
      and a.stream_magnitude >= 5
      and a.stream_magnitude < 40
    then 'SOME_SALMON'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr = array[]::text[]
      and a.stream_magnitude >= 40
    then 'MANY_SALMON'
    when b.sel is true
    then 'MOST_SALMON'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr != array[]::text[]
      and a.barriers_ct_dv_rb_dnstr = array[]::text[]
    then 'RESIDENT_FISH_ONLY'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr != array[]::text[]
      and a.barriers_ct_dv_rb_dnstr != array[]::text[]
      and a.edge_type not in (1100, 1200, 1350, 1410, 1425, 1450)
    then 'RESIDENT_FISH_ONLY_BARRIER_DNSTR'
  end as fishyness_sel,
  case
    when
      a.barriers_ch_cm_co_pk_sk_dnstr = array[]::text[]
      and a.stream_magnitude < 5
    then 'FEW_SALMON'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr = array[]::text[]
      and a.stream_magnitude >= 5
      and a.stream_magnitude < 40
    then 'SOME_SALMON'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr = array[]::text[]
      and a.stream_magnitude >= 40
    then 'MANY_SALMON'
    when b.ser is true
    then 'MOST_SALMON'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr != array[]::text[]
      and a.barriers_ct_dv_rb_dnstr = array[]::text[]
    then 'RESIDENT_FISH_ONLY'
    when
      a.barriers_ch_cm_co_pk_sk_dnstr != array[]::text[]
      and a.barriers_ct_dv_rb_dnstr != array[]::text[]
      and a.edge_type not in (1100, 1200, 1350, 1410, 1425, 1450)
    then 'RESIDENT_FISH_ONLY_BARRIER_DNSTR'
  end as fishyness_ser,
  geom
from access a
left outer join psf.nuseds_top10 b
on a.wscode = b.wscode::text;

create index on psf.ccira using gist (geom);
