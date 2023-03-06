#!/bin/bash
set -euxo pipefail


# before running, run bcfishpass model for groups of interest, including the ct_dv_rb access model


# create gowgaia classifcations
psql -f sql/model.sql

# dump to file
mkdir -p outputs

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
        from bcfishpass.barriers_ct_dv_rb_"

echo 'dumping observations'
ogr2ogr \
    -f GPKG \
    -append \
    -update \
    outputs/ccira.gpkg \
    PG:$DATABASE_URL \
    -nln observations \
    -nlt PointZM \
    -sql "bcfishpass.observations_vw"