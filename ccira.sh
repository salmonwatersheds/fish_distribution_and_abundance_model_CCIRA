#!/bin/bash
set -euxo pipefail

# ----
# * NOTE *
# ----
# before running, run bcfishpass model for groups of interest, including the ct_dv_rb access model
# ----

DATABASE_URL=postgresql://postgres@localhost:5432/bcfp_test

# load PSF provided nuseds data
psql $DATABASE_URL -c "drop table if exists psf.nuseds"
psql $DATABASE_URL -c "create table psf.nuseds (pop_id integer, spp text, gfe_id integer, sys_nm text, geom_mean double precision)"
psql $DATABASE_URL -c "\copy psf.nuseds FROM data/nuseds.csv delimiter ',' csv header"

# get nuseds - FWA lookup, load to pg
curl https://open.canada.ca/data/en/datastore/dump/fc475853-b599-4e68-8d80-f49c03ddc01c?bom=True | shampoo | csvcut -c pop_id,fwa_watershed_cde > data/nuseds_sites.csv
psql $DATABASE_URL -c "drop table if exists psf.nuseds_sites"
psql $DATABASE_URL -c "create table psf.nuseds_sites (pop_id integer, fwa_watershed_cde text, wscode public.ltree generated always as ((replace(replace((fwa_watershed_cde)::text, '-000000'::text, ''::text), '-'::text, '.'::text))::public.ltree) stored)"
psql $DATABASE_URL -c "\copy psf.nuseds_sites FROM data/nuseds_sites.csv delimiter ',' csv header"

# find top ten producers per spp in nuseds data
psql $DATABASE_URL -f sql/nuseds_top10.sql

# create gowgaia classifcations
psql $DATABASE_URL -f sql/model.sql

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
           from bcfishpass.observations_vw"