{{ config(materialized='table') }}

/*
  Inventario de equipamiento por (país, tipo_equipamiento). Estado actual (es_registro_actual).
  es_estandar_otan + es_interoperable provienen de dim_equipamiento (movidos desde inventario en v10).
  fecha_ultimo_mantenimiento / fecha_proximo_upgrade: ahora son DATE (antes integer).
  Calculados en Gold: valor_total_m_usd, antiguedad_anos, estado_readiness, generacion_equipo.
*/

select
    i.record_id,
    p.pais_sk,
    i.codigo_iso,
    p.pais,
    p.region,
    p.zona_geografica,
    p.generacion_otan,
    i.tipo_equipamiento,
    d.categoria_equipamiento,
    d.dominio,
    d.dominio_es,
    d.es_estandar_otan,
    d.estandarizacion_es,
    d.es_interoperable,
    d.nivel_integracion_otan,
    i.codigo_iso_origen,
    year(i.fecha_adquisicion)                                   as anio_adquisicion,
    i.fecha_adquisicion,
    i.cantidad_unidades,
    i.coste_unitario_m_usd,
    -- Calculados en Gold
    round(coalesce(i.cantidad_unidades, 0)
          * coalesce(i.coste_unitario_m_usd, 0), 4)             as valor_total_m_usd,
    case
        when i.fecha_adquisicion is not null
        then year(current_date()) - year(i.fecha_adquisicion)
        else null
    end                                                         as antiguedad_anos,
    i.estado_operacional,
    i.condicion,
    i.pct_combat_ready,
    i.fecha_ultimo_mantenimiento,
    i.fecha_proximo_upgrade,
    case
        when i.pct_combat_ready >= 90 then 'Óptimo'
        when i.pct_combat_ready >= 70 then 'Bueno'
        when i.pct_combat_ready >= 50 then 'Aceptable'
        else 'Crítico'
    end                                                         as estado_readiness,
    case
        when year(current_date()) - year(i.fecha_adquisicion) <= 10 then 'Nuevo (<10 años)'
        when year(current_date()) - year(i.fecha_adquisicion) <= 25 then 'Moderno (10-25)'
        when year(current_date()) - year(i.fecha_adquisicion) <= 40 then 'Veterano (25-40)'
        else 'Obsoleto (>40 años)'
    end                                                         as generacion_equipo,
    f.era_otan,
    f.decada
from {{ ref('stg_inventario_equipamiento') }} i
left join {{ ref('dim_pais') }} p
    on i.pais_sk = p.pais_sk
left join {{ ref('dim_equipamiento') }} d
    on i.tipo_equipamiento = d.tipo_equipamiento
left join {{ ref('dim_fecha') }} f
    on year(i.fecha_adquisicion) = f.anio
where i.es_registro_actual = true
  and i.tipo_equipamiento is not null
