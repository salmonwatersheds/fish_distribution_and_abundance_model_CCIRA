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

    This classification was adjusted up one category for any stream listed as a top ten producer in the NuSEDS data.
    
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

2. Apply the Gowgaia model and generate deliverables:

        ./ccira.sh
