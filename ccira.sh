#!/bin/bash
set -euxo pipefail

# ----
# * NOTE *
# ----
# before running, run bcfishpass model for groups of interest, including the ct_dv_rb access model
# ----

DATABASE_URL=postgresql://postgres@localhost:5432/bcfishpass_dev

# load PSF provided nuseds data
psql $DATABASE_URL -c "create schema if not exists psf"
psql $DATABASE_URL -c "drop table if exists psf.nuseds"
psql $DATABASE_URL -c "create table psf.nuseds (pop_id integer, spp text, gfe_id integer, sys_nm text, geom_mean double precision)"
psql $DATABASE_URL -c "\copy psf.nuseds FROM data/nuseds.csv delimiter ',' csv header"

# get nuseds - FWA lookup, load to pg
psql $DATABASE_URL -c "drop table if exists psf.nuseds_sites"
psql $DATABASE_URL -c "create table psf.nuseds_sites (pop_id integer, fwa_watershed_cde text, wscode public.ltree generated always as ((replace(replace((fwa_watershed_cde)::text, '-000000'::text, ''::text), '-'::text, '.'::text))::public.ltree) stored)"
psql $DATABASE_URL -c "\copy psf.nuseds_sites FROM data/nuseds_sites.csv delimiter ',' csv header"

# find top ten producers per spp in nuseds data
psql $DATABASE_URL -f sql/nuseds_top10.sql

# create gowgaia classifcations
psql $DATABASE_URL -f sql/model.sql

# what streams had abundance model upgraded by nuseds data?
psql $DATABASE_URL --csv -f sql/upgraded_streams.sql > upgraded_streams.csv

# dump to file
rm -rf outputs
mkdir outputs

echo 'dumping streams'
ogr2ogr \
    -f GPKG \
    outputs/ccira.gpkg \
    PG:$DATABASE_URL \
    -nln fish_distribution_model \
    -nlt LineStringZM \
    -sql "select * from psf.ccira"

echo 'dumping barriers_salmon'
ogr2ogr \
    -f GPKG \
    -append \
    -update \
    outputs/ccira.gpkg \
    PG:$DATABASE_URL \
    -nln barriers_salmon \
    -nlt PointZM \
    -sql "select 
       barriers_ch_cm_co_pk_sk_id,
       barrier_type,
       barrier_name,
       linear_feature_id,
       blue_line_key,
       watershed_key,
       downstream_route_measure,
       wscode_ltree as wscode,
       localcode_ltree as localcode,
       watershed_group_code,
       total_network_km,
       geom
        from bcfishpass.barriers_ch_cm_co_pk_sk"

echo 'dumping barriers_steelhead'
ogr2ogr \
    -f GPKG \
    -append \
    -update \
    outputs/ccira.gpkg \
    PG:$DATABASE_URL \
    -nln barriers_steelhead \
    -nlt PointZM \
    -sql "select 
       barriers_st_id,
       barrier_type,
       barrier_name,
       linear_feature_id,
       blue_line_key,
       watershed_key,
       downstream_route_measure,
       wscode_ltree as wscode,
       localcode_ltree as localcode,
       watershed_group_code,
       total_network_km,
       geom
        from bcfishpass.barriers_st"

echo 'dumping barriers_resident'
ogr2ogr \
    -f GPKG \
    -append \
    -update \
    outputs/ccira.gpkg \
    PG:$DATABASE_URL \
    -nln barriers_resident \
    -nlt PointZM \
    -sql "select 
       barriers_ct_dv_rb_id,
       barrier_type,
       barrier_name,
       linear_feature_id,
       blue_line_key,
       watershed_key,
       downstream_route_measure,
       wscode_ltree as wscode,
       localcode_ltree as localcode,
       watershed_group_code,
       total_network_km,
       geom
        from bcfishpass.barriers_ct_dv_rb"

echo 'dumping observations'
ogr2ogr \
    -f GPKG \
    -append \
    -update \
    outputs/ccira.gpkg \
    PG:$DATABASE_URL \
    -nln observations \
    -nlt PointZM \
    -sql "select
             fish_observation_point_id,
             fish_obsrvtn_event_id,
             linear_feature_id,
             blue_line_key,
             wscode_ltree as wscode,
             localcode_ltree as localcode,
             downstream_route_measure,
             watershed_group_code,
             species_code,
             observation_date,
             activity_code,
             activity,
             life_stage_code,
             life_stage,
             acat_report_url,
             geom
           from bcfishpass.observations_vw
           where watershed_group_code in ('ATNA','BELA','KHTZ','KITL','KLIN','KTSU','LDEN','LRDO','NASC','NECL','NIEL','OWIK')"

echo 'dumping dams (all dams, not just barriers)'
ogr2ogr \
    -f GPKG \
    -append \
    -update \
    outputs/ccira.gpkg \
    PG:$DATABASE_URL \
    -nln dams \
    -nlt PointZM \
    -sql "select
             aggregated_crossings_id as dam_id,
             barrier_status,
             -- cabd attributes
             dam_name,
             dam_height,
             dam_owner,
             dam_use,
             dam_operating_status,
             linear_feature_id,
             blue_line_key,
             watershed_key,
             downstream_route_measure,
             wscode_ltree::text as wscode,
             localcode_ltree::text as localcode,
             watershed_group_code,
             gnis_stream_name as gnis_name,
             stream_order,
             stream_magnitude,
             geom
          from bcfishpass.crossings
          where watershed_group_code in ('ATNA','BELA','KHTZ','KITL','KLIN','KTSU','LDEN','LRDO','NASC','NECL','NIEL','OWIK')
          and crossing_source = 'CABD'"

# zip
cd outputs; zip -r ccira.gpkg.zip ccira.gpkg