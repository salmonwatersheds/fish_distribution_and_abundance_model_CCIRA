# CCIRA project

Generate fish distribution and abundance models for PSF/CCIRA within provided study area, in support of salmon restoration work by Heiltsuk, Kitasoo Xai’xais, and Nuxalk, and Wuikinuxv Nations.


## Method

1. Determine BC Freshwater Atlas watershed groups present within the study area: `ATNA,BELA,KHTZ,KITL,KLIN,KTSU,LDEN,LRDO,NASC,NECL,NIEL,OWIK`

2. Map provided PSE spawning data (Chinoo, Coho, Sockeye, Steelhead)

3. Where PSE spawning data were upstream of barriers present in `bcfishpass`, reference the spawning data to BC Freshwater Atlas stream network and load to `bcfishpass`, cancelling these downstream barriers

4. Perform basic QA checks of observations and barriers present in study area from all sources

5. Generate three `bcfishpass` access models using these barrier assumptions:

    - Salmon (CH/CM/CO/PK/SK): falls >5m, subsurface flow, 15% gradient for >= 100m
    - Steelhead (ST): falls >5m, subsurface flow, 20% gradient for >= 100m
    - Resident (CT/DV/RB): falls >5m, subsurface flow, 25% gradient for >= 100m

6. Extend the `bcfishpass` accessibility model with the Gowgaia stream classifications:

    #### Anadromous (CH/CM/CO/PK/SK)

    - `KNOWN` fish presence: stream downstream of known observation(s) for given species
    - `INFERRED` fish presence: stream upstream of known observations and downstream of known/modelled barriers
    - `POTENTIAL` anadromous fish presence: unsurveyed streams from stream mouth to first known/modelled barrier

    #### Resident (CT/DV/RB)

    - `KNOWN` fish presence: stream downstream of known observation(s) for given species
    - `INFERRED` fish presence: stream upstream of known observations and downstream of known/modelled barriers
    - `POTENTIAL` resident fish presence: unsurveyed streams from stream mouth to first known/modelled barrier
    - `POTENTIAL_BARRIER_DNSTR` all stream upstream of known/modelled barriers and not downstream of observations (an extension of the Gowgaia model in absence of an elevation cutoff threshold)

7. Extend the above fish accessibility model with an adaptation of the Gowgaia 'fishyness' classification:

    #### Anadromous

    For all `KNOWN`,`INFERRED`,`POTENTIAL` streams:

    - `FEW_SALMON`: magnitude < 5
    - `SOME_SALMON`: magnitude >= 5, < 40
    - `MANY_SALMON`: magnitude >= 40
    - `MOST_SALMON`: where a stream is noted as a top ten producer in the NuSEDS data.

    #### Resident

    For streams modelled as inaccessible to salmon:

    - `RESIDENT_FISH_ONLY`: streams with no known/modelled barrier to resident fish downstream
    - `RESIDENT_FISH_ONLY_BARRIER_DNSTR`: streams with known/modelled barrier to resident fish downstream

    Output dataset includes the column `upstream_area_ha` to enable further adjustments to this classification. Note that `upstream_area_ha` includes all watersheds upstream of a stream with a given watershed code, but does *not* include the area of the watershed(s) having the equivalent watershed code as the stream.


## Setup

Install the following tools (for the March 2023 deliverable, the noted versions were used):

- [`fwapg`](https://github.com/smnorris/fwapg) : [v0.3.1](https://github.com/smnorris/fwapg/archive/refs/tags/v0.3.1.zip)
- [`bcfishobs`](https://github.com/smnorris/bcfishobs) : [v0.1.0](https://github.com/smnorris/bcfishobs/archive/refs/tags/v0.1.0.zip)
- [`bcfishpass`](https://github.com/smnorris/bcfishpass) : [v0.1.dev2]()


## Run scripts

1. Build the `bcfishpass` database and generate these access models to the above noted watershed groups (see instructions in `bcfishpass`):

    - [salmon](https://github.com/smnorris/bcfishpass/blob/main/model/access/sql/model_access_ch_cm_co_pk_sk.sql)
    - [resident](https://github.com/smnorris/bcfishpass/blob/main/model/access/sql/model_access_ct_dv_rb.sql)
    - [steelhead](https://github.com/smnorris/bcfishpass/blob/main/model/access/sql/model_access_st.sql)

2. Process NuSEDS, apply the Gowgaia model and generate deliverables:

        ./ccira.sh


## Data definition

| COLUMN NAME                 | TYPE                        | DESCRIPTION |
| --------------------------- | --------------------------- | ----------- |
| segmented_stream_id           | text                        | internal bcfishpass unique stream segment id
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
| upstream_area_ha              | double precision            | Area upstream of the stream(s) with the given local watershed code. NOTE - does not include the area of the watershed(s) in which the streams lie.
| barriers_ch_cm_co_pk_sk_dnstr | text                        | Natural barriers to salmon downstream
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
| fishyness_magnitude           | text                        | Fishyness index, magnitude based only (no `MOST_SALMON` class)
| fishyness_salmon              | text                        | Fishyness index, salmon (all)
| fishyness_cm                  | text                        | Fishyness index, CM
| fishyness_cn                  | text                        | Fishyness index, CN
| fishyness_co                  | text                        | Fishyness index, CO
| fishyness_pke                 | text                        | Fishyness index, PKE
| fishyness_pko                 | text                        | Fishyness index, PKO
| fishyness_sel                 | text                        | Fishyness index, SEL
| fishyness_ser                 | text                        | Fishyness index, SER
| geom                          | geometry(LineStringZM,3005) | Stream segment geometry