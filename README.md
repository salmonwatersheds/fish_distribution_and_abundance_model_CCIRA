# CCIRA project

Coordinated by the Pacific Salmon Foundation in support of salmon restoration work by Heiltsuk, Kitasoo Xai’xais, Nuxalk, and Wuikinuxv Nations, these scripts adapt fish distribution / abundance models developed for the Haida Gwaii by [Gowgaia (2009)](https://salmonwatersheds.ca/document/lib_465/) to the CCIRA study area using current tools, methods and data.


## Method

1. Determine BC Freshwater Atlas watershed groups present within the study area: `ATNA,BELA,KHTZ,KITL,KLIN,KTSU,LDEN,LRDO,NASC,NECL,NIEL,OWIK`

2. Reference Pacific Salmon Explorer known spawning streams to BC Freshwater Atlas stream network and load to `bcfishpass`, discarding modelled natural barriers downstream of known habitat

3. Perform basic QA checks of observations and barriers present in study area from all sources

4. Generate three [`bcfishpass` access models](https://smnorris.github.io/bcfishpass/02_model_access.html) using these natural barrier assumptions:

    - Salmon (CH/CM/CO/PK/SK): falls >5m, subsurface flow, 15% gradient for >= 100m
    - Steelhead (ST): falls >5m, subsurface flow, 20% gradient for >= 100m
    - Resident (CT/DV/RB): falls >5m, subsurface flow, 25% gradient for >= 100m

5. Extend the `bcfishpass` accessibility model with the Gowgaia stream classifications:

    #### Anadromous (CH/CM/CO/PK/SK)

    - `KNOWN` fish presence: stream downstream of known observation(s) for given species
    - `INFERRED` fish presence: stream upstream of known observations and downstream of known/modelled barriers
    - `POTENTIAL` anadromous fish presence: unsurveyed streams from stream mouth to first known/modelled barrier

    #### Resident (CT/DV/RB)

    - `KNOWN` fish presence: stream downstream of known observation(s) for given species
    - `INFERRED` fish presence: stream upstream of known observations and downstream of known/modelled barriers
    - `POTENTIAL` resident fish presence: unsurveyed streams from stream mouth to first known/modelled barrier and below the elevation of the highest observation of the species in the study area
    - `POTENTIAL_BARRIER_DNSTR` all stream upstream of known/modelled barriers, not downstream of observations, and below the elevation of the highest observation of the species in the study area

    Elevation maximums:

    - `CT`: 1508m
    - `DV`: 1005m
    - `RB`: 1831m

6. Extend the above fish accessibility model with an adaptation of the Gowgaia abundance classification:

    #### Anadromous

    For all `KNOWN`,`INFERRED`,`POTENTIAL` streams, classify as follows:

    - `FEW_SALMON`: magnitude < 5
    - `SOME_SALMON`: magnitude >= 5, < 40
    - `MANY_SALMON`: magnitude >= 40
    - `MOST_SALMON`: where a stream is noted as a top ten producer in the NuSEDS data for any given salmon species

    #### Resident

    For streams modelled as inaccessible to salmon:

    - `RESIDENT_FISH_ONLY`: streams with no known/modelled barrier to resident fish downstream
    - `RESIDENT_FISH_ONLY_BARRIER_DNSTR`: streams with known/modelled barrier to resident fish downstream

    Output dataset includes the column `upstream_area_ha` to enable further adjustments to this classification. Note that `upstream_area_ha` includes all watersheds upstream of a stream with a given watershed code, but does *not* include the area of the watershed(s) having the equivalent watershed code as the stream.


## Setup

Install the following tools (for the August 2023 deliverable, the noted versions were used - scripts may have to be adjusted if running with the latest dependencies):

- [`fwapg`](https://github.com/smnorris/fwapg) : [v0.5.1]
- [`bcfishobs`](https://github.com/smnorris/bcfishobs) : [v0.1.3]
- [`bcfishpass`](https://github.com/smnorris/bcfishpass) : [v0.1.dev5]


## Run scripts

1. Build the `bcfishpass` database using the [CCIRA parameters](https://github.com/smnorris/bcfishpass/tree/main/parameters/example_ccira) and generate these access models for the above noted watershed groups (see instructions in `bcfishpass`):

    - [salmon](https://github.com/smnorris/bcfishpass/blob/main/model/access/sql/model_access_ch_cm_co_pk_sk.sql)
    - [resident](https://github.com/smnorris/bcfishpass/blob/main/model/access/sql/model_access_ct_dv_rb.sql)
    - [steelhead](https://github.com/smnorris/bcfishpass/blob/main/model/access/sql/model_access_st.sql)

2. Process NuSEDS, apply the Gowgaia model and generate deliverables:

        ./ccira.sh


Model output is dumped to `/outputs/ccira.gpkg.zip`
Streams with abundance upgraded to `MOST_SALMON` based on NuSEDs productivity ranking (and their original, magnitude based abundance values) are noted in [upgraded_streams.csv](upgraded_streams.csv)

## Data definitions

#### `fish_distribution_model`

| Column                 | Type                        | Description |
| --------------------------- | --------------------------- | ----------- |
| ccira_id                      | integer                     | ccira model output unique identifier
| segmented_stream_id           | text                        | bcfishpass unique stream segment id
| linear_feature_id             | bigint                      | FWA stream segment identifier
| blue_line_key                 | integer                     | Uniquely identifies a single flow line such that a main channel and a secondary channel with the same watershed code would have different blue line keys (the Fraser River and all side channels have different blue line keys).
| edge_type                     | integer                     | A 4 digit numeric code used by the Freshwater Atlas to identify the various types of water network linear features. eg. 1050.
| downstream_route_measure      | double precision            | The distance, in meters, along the route from the mouth of the route to the feature.  This distance is measured from the mouth of the containing route to the downstream end of the feature.
| upstream_route_measure        | double precision            | The distance, in meters, along the route from the mouth of the route to upstream end of the feature.  This distance is measured from the mouth of the containing route to the upstream end of the feature.
| gnis_name                     | character varying(80)       | The BCGNIS  (BC Geographical Names Information System)  name associated with the GNIS feature id (an English name was used where available, otherwise another language was selected).
| wscode                        | text                        | Abbreviated version of source FWA watershed code
| localcode                     | text                        | Abbreviated version of source local watershed code
| stream_order                  | integer                     | The calculated modified Strahler order.
| stream_magnitude              | integer                     | The calculated magnitude.
| watershed_group_code          | text                        | The watershed group code associated with the stream.
| upstream_area_ha              | double precision            | Area upstream of the stream(s) with the given local watershed code. NOTE - does not include the area of the watershed(s) in which the streams lie.
| barriers_ch_cm_co_pk_sk_dnstr | text                        | Natural barriers to salmon downstream
| barriers_dams_dnstr           | text                        | CABD dams noted as barriers downstream
| barriers_ct_dv_rb_dnstr       | text                        | Natural barriers to cutthroat, dolly varden, rainbow downstream
| obsrvtn_species_codes_upstr   | text                        | Species codes of known observations upstream (for species of interest only, within the same watershed group as stream)
| species_codes_dnstr           | text                        | Species codes of known observations downstream (for species of interest only, within the same watershed group as stream)
| model_ch                      | text                        | Fish distribution model for Chinoook (see above for method and codes)
| model_cm                      | text                        | Fish distribution model for Chum (see above for method and codes)
| model_co                      | text                        | Fish distribution model for Coho (see above for method and codes)
| model_pk                      | text                        | Fish distribution model for Pink (see above for method and codes)
| model_sk                      | text                        | Fish distribution model for Sockeye (see above for method and codes)
| model_st                      | text                        | Fish distribution model for Steelhead (see above for method and codes)
| model_ct                      | text                        | Fish distribution model for Cutthroat Trout (see above for method and codes)
| model_dv                      | text                        | Fish distribution model for Dolly Varden Char (see above for method and codes)
| model_rb                      | text                        | Fish distribution model for Rainbow Trout (see above for method and codes)
| nuseds_top10_cm               | boolean                     | Identifies if stream is one of top 10 producers for study area for CM
| nuseds_top10_cn               | boolean                     | Identifies if stream is one of top 10 producers for study area for CN
| nuseds_top10_co               | boolean                     | Identifies if stream is one of top 10 producers for study area for CO
| nuseds_top10_pke              | boolean                     | Identifies if stream is one of top 10 producers for study area for PKE
| nuseds_top10_pko              | boolean                     | Identifies if stream is one of top 10 producers for study area for PKO
| nuseds_top10_sel              | boolean                     | Identifies if stream is one of top 10 producers for study area for SEL
| nuseds_top10_ser              | boolean                     | Identifies if stream is one of top 10 producers for study area for SER
| abundance                     | text                        | Abundance/fishyness index - based on distribution model, magnitude, escapement
| geom                          | geometry(LineStringZM,3005) | Stream segment geometry



#### `barriers_salmon`/`barriers_steelhead`/`barriers_resident`

Natural barriers to noted species.

|           Column           |         Type         | Description |
|----------------------------|----------------------|------------|
| barriers_<species>_id | text                 | unique identifier           |
| barrier_type               | text                 | Natural barrier type (falls, gradient barrier, etc)           |
| barrier_name               | text                 | Name of barrier, where applicable           |
| linear_feature_id          | integer              | See FWA documentation           |
| blue_line_key              | integer              | See FWA documentation           |
| watershed_key              | integer              | See FWA documentation           |
| downstream_route_measure   | double precision     | See FWA documentation           |
| wscode                     | ltree                | Abbreviated version of source FWA watershed code           |
| localcode                  | ltree                | Abbreviated version of source local watershed code           |
| watershed_group_code       | character varying(4) | See FWA documentation           |
| total_network_km           | double precision     | Total length of stream upstream of barrier, useful for barrier QA           |
| geom                       | geometry(Point,3005) | Geometry           |


#### `dams`

All dams in study area, taken from [Canadian Aquatic Barrier Database (CABD)](https://cabd-docs.netlify.app/index.html), as documented [here](https://cabd-docs.netlify.app/docs_tech/docs_tech_arch_models.html)

|          Column           |          Type          | Description                                                   |
|---------------------------|------------------------|-----------                                                    |
| dam_id                   | text                | Source CABD unique identifier              
| barrier_status           | text                | Derived from CABD `passability_status_code`                    
| dam_name                 | text                | CABD `dam_name_en`              
| dam_height               | text                | CABD `dam_height_m`                
| dam_owner                | text                | CABD `owner`               
| dam_use                  | text                | CABD `dam_use`             
| dam_operating_status     | text                | CABD `operating_status`                          
| linear_feature_id        | integer             | See FWA documentation                          
| blue_line_key            | integer             | See FWA documentation                      
| watershed_key            | integer             | See FWA documentation                      
| downstream_route_measure | double precision    | See FWA documentation                                          
| wscode                   | text                | See FWA documentation            
| localcode                | text                | See FWA documentation               
| watershed_group_code     | text                | See FWA documentation                          
| gnis_name                | text                | See FWA documentation               
| stream_order             | integer             | See FWA documentation                     
| stream_magnitude         | integer             | See FWA documentation                        
| geom                     | geometry(Point,3005) | Geometry           |


### `observations`

From [Known Fish Observations](https://catalogue.data.gov.bc.ca/dataset/known-bc-fish-observations-and-bc-fish-distributions)

|          Column           |          Type          | Description                                                   |
|---------------------------|------------------------|-----------                                                    |
| fish_observation_point_id | integer                | DataBC provided unique ID (does not remain constant over time)|
| fish_obsrvtn_event_id     | bigint                 | bcfishpass internal unique id                                 |
| linear_feature_id         | bigint                 | See FWA documentation                                         |
| blue_line_key             | integer                | See FWA documentation                                         |
| wscode_ltree              | ltree                  | Abbreviated version of source FWA watershed code              |
| localcode_ltree           | ltree                  | Abbreviated version of source FWA watershed code              |
| downstream_route_measure  | double precision       | See FWA documentation                                         |
| watershed_group_code      | character varying(4)   | See FWA documentation                                         |
| species_code              | text                   | See observation documentation                                 |
| observation_date          | date                   | See observation documentation                                 |
| activity_code             | character varying(100) | See observation documentation                                 |
| activity                  | character varying(300) | See observation documentation                                 |
| life_stage_code           | character varying(100) | See observation documentation                                 |
| life_stage                | character varying(300) | See observation documentation                                 |
| acat_report_url           | character varying(254) | See observation documentation                                 |
| geom                      | geometry(PointZM,3005) | Geometry                                                      |