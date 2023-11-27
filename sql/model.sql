-- create ccira fish distribution models as per Gowgaia model
drop table if exists psf.ccira;

create table psf.ccira as

-- identify watershed codes of systems containing sockeye
-- (sockeye lakes and known sockeye spawning streams)
-- lakes
with sk_lakes as (
  select distinct on (a.waterbody_poly_id)
    a.waterbody_poly_id,
    s.wscode_ltree,
    s.localcode_ltree
  from bcfishpass.dfo_known_sockeye_lakes a
  inner join whse_basemapping.fwa_lakes_poly l
  on a.waterbody_poly_id = l.waterbody_poly_id
  inner join bcfishpass.streams s
  on l.waterbody_key = s.waterbody_key
  order by a.waterbody_poly_id, s.wscode_ltree, s.localcode_ltree
),

-- tribs to Kwakwa Lake
-- (the lake does not exist in FWA)
-- manually add all watershed codes draining into the lagoon/lake
kwakwa as
(
  select distinct on (blue_line_key)
    blue_line_key,
    wscode_ltree,
    localcode_ltree
  from whse_basemapping.fwa_stream_networks_sp
  where blue_line_key in (
    360256405,
    360707969,
    360740205,
    360870394,
    360771634,
    360684689,
    360686504,
    360268244,
    360822784,
    360874324
  )
  order by blue_line_key, wscode_ltree, localcode_ltree
),

-- streams
sk_linear as (
  select
  blue_line_key,
  min(downstream_route_measure) as downstream_route_measure
  from bcfishpass.user_habitat_classification
  where species_code = 'SK'
  group by blue_line_key
),

-- combine lakes/streams
sk_wsc as (
  select
    s.wscode_ltree,
    s.localcode_ltree
  from bcfishpass.streams s
  inner join sk_linear skl
  on s.blue_line_key = skl.blue_line_key
  and round(skl.downstream_route_measure::numeric, 4) >= round(s.downstream_route_measure::numeric,4)
  and round(skl.downstream_route_measure::numeric) < round(s.upstream_route_measure::numeric, 4)
  union
  select
    wscode_ltree,
    localcode_ltree
  from sk_lakes
  union
  select
    wscode_ltree,
    localcode_ltree
  from kwakwa
),

-- downstream trace
wsc_below_sk_lakes as (
  select distinct
    s.wscode_ltree
  from sk_wsc sk
  inner join bcfishpass.streams s
  on fwa_downstream(sk.wscode_ltree, sk.localcode_ltree, s.wscode_ltree, s.localcode_ltree)
  or sk.wscode_ltree = s.wscode_ltree -- fwa_downstream does not include equivalent codes
),

-- all streams with same wscode prefix are eligible for sk model
potential_sockeye_streams as
(
  select distinct on (s.segmented_stream_id)
    s.segmented_stream_id,
    true as sk_presence
    from bcfishpass.streams s
  inner join wsc_below_sk_lakes sk on sk.wscode_ltree @> s.wscode_ltree
  order by segmented_stream_id, sk.wscode_ltree
),

streams as (
  select
    s.segmented_stream_id,
    s.linear_feature_id,
    s.blue_line_key,
    s.edge_type,
    s.downstream_route_measure,
    s.upstream_route_measure,
    s.stream_order,
    s.stream_magnitude,
    s.watershed_group_code,
    s.gnis_name,
    s.wscode_ltree,
    s.localcode_ltree,
    s.barriers_ch_cm_co_pk_sk_dnstr,
    s.barriers_dams_dnstr,
    s.barriers_ct_dv_rb_dnstr,
    s.barriers_st_dnstr,
    s.obsrvtn_species_codes_upstr,
    s.species_codes_dnstr,
    1 as elevation_band,
    (st_dump(st_locatebetweenelevations(geom, 0, 1005))).geom as geom
  from bcfishpass.streams s
  INNER JOIN whse_basemapping.fwa_streams_watersheds_lut l
  ON s.linear_feature_id = l.linear_feature_id
  INNER JOIN whse_basemapping.fwa_watersheds_upstream_area ua
  ON l.watershed_feature_id = ua.watershed_feature_id
  where
    st_z(st_startpoint(geom)) <= 1005
    and watershed_group_code in ('ATNA','BELA','KHTZ','KITL','KLIN','KTSU','LDEN','LRDO','NASC','NECL','NIEL','OWIK')
  union all
  select
    s.segmented_stream_id,
    s.linear_feature_id,
    s.blue_line_key,
    s.edge_type,
    s.downstream_route_measure,
    s.upstream_route_measure,
    s.stream_order,
    s.stream_magnitude,
    s.watershed_group_code,
    s.gnis_name,
    s.wscode_ltree,
    s.localcode_ltree,
    s.barriers_ch_cm_co_pk_sk_dnstr,
    s.barriers_dams_dnstr,
    s.barriers_ct_dv_rb_dnstr,
    s.barriers_st_dnstr,
    s.obsrvtn_species_codes_upstr,
    s.species_codes_dnstr,
    2 as elevation_band,
    (st_dump(st_locatebetweenelevations(geom, 1005, 1508))).geom as geom
  from bcfishpass.streams s
  INNER JOIN whse_basemapping.fwa_streams_watersheds_lut l
  ON s.linear_feature_id = l.linear_feature_id
  INNER JOIN whse_basemapping.fwa_watersheds_upstream_area ua
  ON l.watershed_feature_id = ua.watershed_feature_id
  where
    st_z(st_startpoint(geom)) <= 1508
    and watershed_group_code in ('ATNA','BELA','KHTZ','KITL','KLIN','KTSU','LDEN','LRDO','NASC','NECL','NIEL','OWIK')
  union all
  select
    s.segmented_stream_id,
    s.linear_feature_id,
    s.blue_line_key,
    s.edge_type,
    s.downstream_route_measure,
    s.upstream_route_measure,
    s.stream_order,
    s.stream_magnitude,
    s.watershed_group_code,
    s.gnis_name,
    s.wscode_ltree,
    s.localcode_ltree,
    s.barriers_ch_cm_co_pk_sk_dnstr,
    s.barriers_dams_dnstr,
    s.barriers_ct_dv_rb_dnstr,
    s.barriers_st_dnstr,
    s.obsrvtn_species_codes_upstr,
    s.species_codes_dnstr,
    3 as elevation_band,
    (st_dump(st_locatebetweenelevations(geom, 1508, 1831))).geom as geom
  from bcfishpass.streams s
  INNER JOIN whse_basemapping.fwa_streams_watersheds_lut l
  ON s.linear_feature_id = l.linear_feature_id
  INNER JOIN whse_basemapping.fwa_watersheds_upstream_area ua
  ON l.watershed_feature_id = ua.watershed_feature_id
  where
    st_z(st_startpoint(geom)) <= 1831
    and watershed_group_code in ('ATNA','BELA','KHTZ','KITL','KLIN','KTSU','LDEN','LRDO','NASC','NECL','NIEL','OWIK')
),

access as (
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
    s.wscode_ltree,
    s.localcode_ltree,
    s.barriers_ch_cm_co_pk_sk_dnstr,
    s.barriers_dams_dnstr,
    s.barriers_ct_dv_rb_dnstr,
    s.obsrvtn_species_codes_upstr,
    s.species_codes_dnstr,
    -- anadromous models
    case 
    when barriers_ch_cm_co_pk_sk_dnstr = array[]::text[] and
         barriers_dams_dnstr is null and
         obsrvtn_species_codes_upstr && array['CH'] then 'KNOWN'
    when obsrvtn_species_codes_upstr && array['CH'] is false and  
        species_codes_dnstr && array['CH'] and
        barriers_ch_cm_co_pk_sk_dnstr = array[]::text[] and
        barriers_dams_dnstr is null then 'INFERRED'
    when obsrvtn_species_codes_upstr && array['CH'] is false and  
        species_codes_dnstr && array['CH'] is false and
        barriers_ch_cm_co_pk_sk_dnstr = array[]::text[] and
        barriers_dams_dnstr is null then 'POTENTIAL'
    end as model_ch,
    case 
    when obsrvtn_species_codes_upstr && array['CM'] and
         barriers_dams_dnstr is null then 'KNOWN'
    when obsrvtn_species_codes_upstr && array['CM'] is false and  
        species_codes_dnstr && array['CM'] and
        barriers_ch_cm_co_pk_sk_dnstr = array[]::text[] and
        barriers_dams_dnstr is null then 'INFERRED'
    when obsrvtn_species_codes_upstr && array['CM'] is false and  
        species_codes_dnstr && array['CM'] is false and
        barriers_ch_cm_co_pk_sk_dnstr = array[]::text[] and
        barriers_dams_dnstr is null then 'POTENTIAL'
    end as model_cm,
    case 
    when obsrvtn_species_codes_upstr && array['CO'] and
        barriers_dams_dnstr is null then 'KNOWN'
    when obsrvtn_species_codes_upstr && array['CO'] is false and  
        species_codes_dnstr && array['CO'] and
        barriers_ch_cm_co_pk_sk_dnstr = array[]::text[] and
        barriers_dams_dnstr is null then 'INFERRED'
    when obsrvtn_species_codes_upstr && array['CO'] is false and  
        species_codes_dnstr && array['CO'] is false and
        barriers_ch_cm_co_pk_sk_dnstr = array[]::text[] and
        barriers_dams_dnstr is null then 'POTENTIAL'
    end as model_co,
    case 
    when obsrvtn_species_codes_upstr && array['PK'] and
        barriers_dams_dnstr is null then 'KNOWN'
    when obsrvtn_species_codes_upstr && array['PK'] is false and  
        species_codes_dnstr && array['PK'] and
        barriers_ch_cm_co_pk_sk_dnstr = array[]::text[] and
        barriers_dams_dnstr is null then 'INFERRED'
    when obsrvtn_species_codes_upstr && array['PK'] is false and  
        species_codes_dnstr && array['PK'] is false and
        barriers_ch_cm_co_pk_sk_dnstr = array[]::text[] and
        barriers_dams_dnstr is null then 'POTENTIAL'
    end as model_pk,
    case
    when obsrvtn_species_codes_upstr && array['SK'] and
        barriers_dams_dnstr is null and
        -- apply sk model only in systems with sockeye lakes present
        sk.sk_presence is true then 'KNOWN'
    when obsrvtn_species_codes_upstr && array['SK'] is false and  
        species_codes_dnstr && array['SK'] and
        barriers_ch_cm_co_pk_sk_dnstr = array[]::text[] and
        barriers_dams_dnstr is null and
        -- apply sk model only in systems with sockeye lakes present
        sk.sk_presence is true then 'INFERRED'
    when obsrvtn_species_codes_upstr && array['SK'] is false and  
        species_codes_dnstr && array['SK'] is false and
        barriers_ch_cm_co_pk_sk_dnstr = array[]::text[] and
        barriers_dams_dnstr is null and
        sk.sk_presence is true then 'POTENTIAL'
    end as model_sk,
    case 
    when obsrvtn_species_codes_upstr && array['ST'] and
        barriers_dams_dnstr is null then 'KNOWN'
    when obsrvtn_species_codes_upstr && array['ST'] is false and  
        species_codes_dnstr && array['ST'] and
        barriers_st_dnstr = array[]::text[] and
        barriers_dams_dnstr is null then 'INFERRED'
    when obsrvtn_species_codes_upstr && array['ST'] is false and  
        species_codes_dnstr && array['ST'] is false and
        barriers_st_dnstr = array[]::text[] and
        barriers_dams_dnstr is null then 'POTENTIAL'
    end as model_st,

    -- resident models
    case 
    when obsrvtn_species_codes_upstr && array['BT','DV'] then 'KNOWN'  -- downstream of observation

    when obsrvtn_species_codes_upstr && array['BT','DV'] is false and  -- upstream of observation, no barrier downstream
      species_codes_dnstr && array['BT','DV'] and
      barriers_ct_dv_rb_dnstr = array[]::text[] and
      barriers_dams_dnstr is null and
      elevation_band = 1
      then 'INFERRED'
    when obsrvtn_species_codes_upstr && array['BT','DV'] is false and  -- no observation upstream or downstream, no barrier
      species_codes_dnstr && array['BT','DV'] is false and
      barriers_ct_dv_rb_dnstr = array[]::text[] and
      barriers_dams_dnstr is null and
      elevation_band = 1
    then 'POTENTIAL'

    when obsrvtn_species_codes_upstr && array['BT','DV'] is false and  -- no observation upstream or downstream, barrier downstream
      (barriers_ct_dv_rb_dnstr != array[]::text[] or
        barriers_dams_dnstr is not null)
      and edge_type not in (1350, 1410, 1425)  -- exclude ice etc
      and elevation_band = 1
      then 'POTENTIAL_BARRIER_DNSTR'      
    end as model_dv,

    case
    when obsrvtn_species_codes_upstr && array['CT'] then 'KNOWN'  
    when obsrvtn_species_codes_upstr && array['CT'] is false and  
      species_codes_dnstr && array['CT'] and
      barriers_ct_dv_rb_dnstr = array[]::text[] and
      barriers_dams_dnstr is null and
      elevation_band <= 2
    then 'INFERRED'
    when obsrvtn_species_codes_upstr && array['CT'] is false and  
      species_codes_dnstr && array['CT'] is false and
      barriers_ct_dv_rb_dnstr = array[]::text[] and
      barriers_dams_dnstr is null and
      elevation_band <= 2
      then 'POTENTIAL'
    when obsrvtn_species_codes_upstr && array['CT'] is false and  
      (barriers_ct_dv_rb_dnstr != array[]::text[] or barriers_dams_dnstr is null)
      and edge_type not in (1350, 1410, 1425)  -- exclude ice etc
      and elevation_band <= 2
      then 'POTENTIAL_BARRIER_DNSTR' 
    end as model_ct,

    case
    when obsrvtn_species_codes_upstr && array['RB'] then 'KNOWN'  
    when obsrvtn_species_codes_upstr && array['RB'] is false and  
      species_codes_dnstr && array['RB'] and
      barriers_ct_dv_rb_dnstr = array[]::text[] and
      barriers_dams_dnstr is null and
      elevation_band <= 3
      then 'INFERRED'
    when obsrvtn_species_codes_upstr && array['RB'] is false and  
      species_codes_dnstr && array['RB'] is false and
      barriers_ct_dv_rb_dnstr = array[]::text[] and
      barriers_dams_dnstr is null and
      elevation_band <= 3
      then 'POTENTIAL'
    when obsrvtn_species_codes_upstr && array['RB'] is false and  
      (barriers_ct_dv_rb_dnstr != array[]::text[] or barriers_dams_dnstr is null)
      and edge_type not in (1350, 1410, 1425)  -- exclude ice etc
      and elevation_band <= 3
      then 'POTENTIAL_BARRIER_DNSTR' 
    end as model_rb,

    geom
  from streams s
  INNER JOIN whse_basemapping.fwa_streams_watersheds_lut l
  ON s.linear_feature_id = l.linear_feature_id
  INNER JOIN whse_basemapping.fwa_watersheds_upstream_area ua
  ON l.watershed_feature_id = ua.watershed_feature_id
  left outer join potential_sockeye_streams sk
  on s.segmented_stream_id = sk.segmented_stream_id
  where st_geometrytype(geom) = 'ST_LineString' -- remove any points created by imprecision of st_locatebetweenelevations()
)

-- add abundance model
select 
  row_number() over() as ccira_id, -- add a unique identifier (because streams are getting split at elevation bands)
  a.segmented_stream_id,
  a.linear_feature_id,
  a.blue_line_key,
  a.edge_type,
  a.downstream_route_measure,
  a.upstream_route_measure,
  a.gnis_name,
  a.wscode_ltree::text as wscode,
  a.localcode_ltree::text as localcode,
  a.stream_order,
  a.stream_magnitude,
  a.watershed_group_code,
  a.upstream_area_ha,
  array_to_string(a.barriers_ch_cm_co_pk_sk_dnstr,'; ') as barriers_ch_cm_co_pk_sk_dnstr,
  array_to_string(a.barriers_dams_dnstr,'; ') as barriers_dams_dnstr,
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
      (a.model_ch is not null or a.model_cm is not null or a.model_co is not null or a.model_pk is not null or a.model_sk is not null or a.model_st is not null)
      and a.stream_magnitude < 5
    then 'FEW_SALMON'
    when
      (a.model_ch is not null or a.model_cm is not null or a.model_co is not null or a.model_pk is not null or a.model_sk is not null or a.model_st is not null)
      and a.stream_magnitude >= 5
      and a.stream_magnitude < 40
    then 'SOME_SALMON'
    when
      (a.model_ch is not null or a.model_cm is not null or a.model_co is not null or a.model_pk is not null or a.model_sk is not null or a.model_st is not null)
      and a.stream_magnitude >= 40
    then 'MANY_SALMON'
    when
      (a.model_ch is null and a.model_cm is null and a.model_co is null and a.model_pk is null and a.model_sk is null and a.model_st is null)
      and (a.model_ct is not null or a.model_dv is not null or a.model_rb is not null)
    then 'RESIDENT_FISH_ONLY'
  end as abundance,
  geom
from access a
left outer join psf.nuseds_top10 b
on a.wscode_ltree = b.wscode;

-- apply most salmon based on nuseds info
update psf.ccira
set abundance = 'MOST_SALMON'
where stream_magnitude >= 5 and (
  nuseds_top10_cm is not null or
  nuseds_top10_cn is not null or
  nuseds_top10_co is not null or
  nuseds_top10_pke is not null or
  nuseds_top10_pko is not null or
  nuseds_top10_sel is not null or
  nuseds_top10_ser is not null);



create index on psf.ccira using gist (geom);
