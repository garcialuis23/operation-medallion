{{ config(materialized='table') }}

/*
  Gasto en defensa por país y año.
  Métricas atómicas de Silver: pib_bn_usd, presupuesto_defensa_bn_usd, poblacion_millones.
  Calculados en Gold (ya no vienen de stg_estadisticas_pais):
    · pib_per_capita_usd        = (pib_bn_usd * 1e9) / (poblacion_millones * 1e6)
    · defensa_pct_pib           = presupuesto_defensa_bn_usd / pib_bn_usd * 100
    · cumple_objetivo_2pct      = defensa_pct_pib >= 2.0
    · gasto_defensa_per_capita_usd = (presupuesto_defensa_bn_usd * 1e9) / (poblacion_millones * 1e6)
*/

select
    p.pais_sk,
    e.codigo_iso,
    p.pais,
    p.region,
    p.zona_geografica,
    p.generacion_otan,
    p.es_miembro_fundador,
    p.tiene_comparticion_nuclear,
    p.rol_alianza,
    year(e.fecha)                                               as anio,
    e.fecha,
    e.pib_bn_usd,
    e.presupuesto_defensa_bn_usd,
    e.poblacion_millones,
    e.tasa_inflacion_pct,
    e.tasa_desempleo_pct,
    -- Calculados
    case
        when e.poblacion_millones > 0
        then round((e.pib_bn_usd * 1000.0) / e.poblacion_millones, 2)
        else null
    end                                                         as pib_per_capita_usd,
    case
        when e.pib_bn_usd > 0
        then round(e.presupuesto_defensa_bn_usd / e.pib_bn_usd * 100, 4)
        else null
    end                                                         as defensa_pct_pib,
    case
        when e.pib_bn_usd > 0
        then (e.presupuesto_defensa_bn_usd / e.pib_bn_usd * 100) >= 2.0
        else null
    end                                                         as cumple_objetivo_2pct,
    case
        when e.pib_bn_usd > 0
             and (e.presupuesto_defensa_bn_usd / e.pib_bn_usd * 100) >= 2.0
        then 'Cumple Objetivo'
        else 'Bajo Objetivo'
    end                                                         as estado_objetivo_2pct,
    case
        when e.poblacion_millones > 0
        then round((e.presupuesto_defensa_bn_usd * 1000.0) / e.poblacion_millones, 2)
        else null
    end                                                         as gasto_defensa_per_capita_usd,
    f.era_otan,
    f.es_era_guerra_fria,
    f.decada
from {{ ref('stg_estadisticas_pais') }} e
left join {{ ref('dim_pais') }} p
    on e.pais_sk = p.pais_sk
left join {{ ref('dim_fecha') }} f
    on year(e.fecha) = f.anio
where e.pib_bn_usd is not null
