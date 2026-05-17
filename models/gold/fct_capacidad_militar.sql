{{ config(materialized='table') }}

/*
  Capacidad militar por país y año.
  personal_total recalculado en Gold (ya no viene de stg_estadisticas_pais).
  Ratios derivados: pct_fuerzas_activas, militares_por_1000_hab.
*/

select
    p.pais_sk,
    e.codigo_iso,
    p.pais,
    p.region,
    p.zona_geografica,
    p.generacion_otan,
    p.es_miembro_fundador,
    p.rol_alianza,
    year(e.fecha)                                               as anio,
    e.fecha,
    e.personal_activo,
    e.personal_reserva,
    -- Calculados en Gold
    coalesce(e.personal_activo, 0)
        + coalesce(e.personal_reserva, 0)                       as personal_total,
    case
        when (coalesce(e.personal_activo, 0) + coalesce(e.personal_reserva, 0)) > 0
        then round(
            e.personal_activo * 100.0
            / (e.personal_activo + coalesce(e.personal_reserva, 0)),
        2)
        else null
    end                                                         as pct_fuerzas_activas,
    case
        when e.poblacion_millones > 0
        then round(
            (coalesce(e.personal_activo, 0) + coalesce(e.personal_reserva, 0))
            / (e.poblacion_millones * 1000.0),
        2)
        else null
    end                                                         as militares_por_1000_hab,
    e.score_interoperabilidad,
    case
        when e.score_interoperabilidad >= 8 then 'Alto'
        when e.score_interoperabilidad >= 5 then 'Medio'
        else 'Bajo'
    end                                                         as nivel_interoperabilidad,
    e.ejercicios_entrenamiento_anio,
    e.rango_contribucion_otan,
    f.era_otan,
    f.decada
from {{ ref('stg_estadisticas_pais') }} e
left join {{ ref('dim_pais') }} p
    on e.pais_sk = p.pais_sk
left join {{ ref('dim_fecha') }} f
    on year(e.fecha) = f.anio
where e.personal_activo is not null
