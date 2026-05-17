{{ config(materialized='table') }}

/*
  Hechos a nivel misión. Granularidad: una fila por misión (versión actual SCD-2).
  Tropas/activos totales: agregados desde fct_participacion_misiones (SUM).
  paises_contribuyentes: COUNT DISTINCT desde participacion.
  bajas + coste_mision_m_usd: hechos directos de CSV3 (stg_mision).
  Calculados: pct_bajas, coste_por_soldado_usd, duracion_anos, coste_anual_m_usd.
*/

with agg_participacion as (
    select
        mision_sk,
        count(distinct codigo_iso)                              as paises_contribuyentes,
        sum(tropas_contribuidas)                                as tropas_desplegadas,
        sum(activos_aereos_contribuidos)                        as activos_aereos_desplegados,
        sum(activos_navales_contribuidos)                       as activos_navales_desplegados
    from {{ ref('stg_participacion_mision') }}
    where es_registro_actual = true
    group by mision_sk
)

select
    m.mision_sk,
    m.id_mision,
    m.nombre_mision,
    m.tipo_mision,
    m.codigo_iso_lider,
    dm.pais_lider,
    dm.region_pais_lider,
    dm.region_operacion,
    dm.zona_operacion,
    dm.es_flanco_este,
    m.nivel_amenaza,
    dm.nivel_amenaza_num,
    m.cuartel_general,
    m.clasificacion,
    m.cobertura_mediatica,
    m.tipo_liderazgo,
    m.tiene_mandato_onu,
    m.fase_mision,
    m.estado_mision,
    m.resultado_mision,
    dm.estado_mision_es,
    dm.resultado_mision_es,
    m.fecha_inicio_operacion,
    m.fecha_fin_operacion,
    dm.anio_inicio,
    dm.anio_fin,
    f.era_otan,
    f.decada,
    -- Métricas de misión (fuente CSV3 directa)
    m.bajas,
    m.coste_mision_m_usd,
    m.pct_apoyo_publico,
    -- Métricas agregadas desde participacion
    agg.paises_contribuyentes,
    agg.tropas_desplegadas,
    agg.activos_aereos_desplegados,
    agg.activos_navales_desplegados,
    -- Calculados en Gold
    case
        when m.fecha_fin_operacion is not null
        then round(datediff('day', m.fecha_inicio_operacion, m.fecha_fin_operacion) / 365.25, 2)
        else null
    end                                                         as duracion_anos,
    case
        when agg.tropas_desplegadas > 0 and m.bajas is not null
        then round(m.bajas * 100.0 / agg.tropas_desplegadas, 2)
        else null
    end                                                         as pct_bajas,
    case
        when agg.tropas_desplegadas > 0 and m.coste_mision_m_usd > 0
        then round(m.coste_mision_m_usd * 1000000.0 / agg.tropas_desplegadas, 2)
        else null
    end                                                         as coste_por_soldado_usd,
    case
        when m.coste_mision_m_usd > 0
         and m.fecha_fin_operacion is not null
         and datediff('day', m.fecha_inicio_operacion, m.fecha_fin_operacion) > 0
        then round(
            m.coste_mision_m_usd
            / (datediff('day', m.fecha_inicio_operacion, m.fecha_fin_operacion) / 365.25),
        2)
        else null
    end                                                         as coste_anual_m_usd
from {{ ref('stg_mision') }} m
left join {{ ref('dim_mision') }} dm
    on m.mision_sk = dm.mision_sk
left join agg_participacion agg
    on m.mision_sk = agg.mision_sk
left join {{ ref('dim_fecha') }} f
    on year(m.fecha_inicio_operacion) = f.anio
where m.es_registro_actual = true
