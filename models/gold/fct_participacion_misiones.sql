{{ config(materialized='table') }}

/*
  Participación de países en misiones. Granularidad: (mision_sk, pais_sk, rol_participacion).
  FK joins via surrogate keys para eliminar joins temporales en consultas analíticas.
  pct_contribucion calculado sobre tropas_desplegadas de fct_misiones (no sobre tropas fuente CSV3).
*/

with tropas_mision as (
    select
        mision_sk,
        sum(tropas_contribuidas)                                as tropas_desplegadas_total
    from {{ ref('stg_participacion_mision') }}
    where es_registro_actual = true
    group by mision_sk
)

select
    -- Surrogate keys
    p.participacion_sk,
    p.mision_sk,
    p.pais_sk,
    -- Claves de negocio (auditoría)
    p.id_participante,
    p.id_mision,
    p.codigo_iso,
    -- Atributos de misión (desnormalizados para BI)
    dm.nombre_mision,
    dm.tipo_mision,
    dm.region_operacion,
    dm.zona_operacion,
    dm.nivel_amenaza,
    dm.tipo_liderazgo,
    dm.tiene_mandato_onu,
    dm.fecha_inicio_operacion,
    dm.anio_inicio,
    dm.estado_mision_es,
    dm.resultado_mision_es,
    dm.era_otan,
    dm.decada,
    -- Atributos de país (desnormalizados para BI)
    dp.pais,
    dp.region                                                   as region_pais,
    dp.zona_geografica,
    dp.generacion_otan,
    dp.es_miembro_fundador,
    dp.tiene_comparticion_nuclear,
    -- Rol y dimensión de rol
    p.rol_participacion,
    r.categoria_rol,
    r.es_rol_liderazgo,
    -- Métricas atómicas
    p.tropas_contribuidas,
    p.activos_aereos_contribuidos,
    p.activos_navales_contribuidos,
    p.fecha_inicio_participacion,
    -- Calculados en Gold
    case
        when p.tropas_contribuidas > 0
             and t.tropas_desplegadas_total > 0
        then round(p.tropas_contribuidas * 100.0 / t.tropas_desplegadas_total, 4)
        else null
    end                                                         as pct_contribucion_tropas,
    case
        when p.tropas_contribuidas > 0 and p.activos_aereos_contribuidos > 0
        then round(p.activos_aereos_contribuidos * 1.0 / p.tropas_contribuidas, 4)
        else null
    end                                                         as ratio_aereo_por_tropa
from {{ ref('stg_participacion_mision') }} p
left join {{ ref('dim_mision') }}            dm on p.mision_sk      = dm.mision_sk
left join {{ ref('dim_pais') }}              dp on p.pais_sk        = dp.pais_sk
left join {{ ref('dim_rol_participacion') }} r  on p.rol_participacion = r.rol_participacion
left join tropas_mision                     t  on p.mision_sk      = t.mision_sk
where p.es_registro_actual = true
