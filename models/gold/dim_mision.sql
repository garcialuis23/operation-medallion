{{ config(materialized='table') }}

/*
  dim_mision: snapshot de la versión actual SCD-2.
  mision_sk: surrogate key — FK primaria para todas las fact tables.
  id_mision: clave de negocio conservada para auditoría.
  region_operacion recuperada via join a stg_cat_ubicacion_operacion.
  tipo_liderazgo: varchar ("NATO" / "Non-NATO" / "Joint UN-NATO").
*/

select
    m.mision_sk,
    m.id_mision,
    m.nombre_mision,
    m.tipo_mision,
    m.codigo_iso_lider,
    p.pais                                                  as pais_lider,
    p.region                                                as region_pais_lider,
    m.ubicacion_operacion,
    u.region                                                as region_operacion,
    rg.zona_geografica                                      as zona_operacion,
    rg.es_flanco_este,
    m.nivel_amenaza,
    m.cuartel_general,
    m.fase_mision,
    m.estado_mision,
    m.resultado_mision,
    est.estado_mision_es,
    est.resultado_mision_es,
    m.clasificacion,
    m.cobertura_mediatica,
    m.tipo_liderazgo,
    m.tiene_mandato_onu,
    m.fecha_inicio_operacion,
    m.fecha_fin_operacion,
    year(m.fecha_inicio_operacion)                          as anio_inicio,
    year(m.fecha_fin_operacion)                             as anio_fin,
    f.era_otan,
    f.decada,
    case m.nivel_amenaza
        when 'Critical' then 4
        when 'High'     then 3
        when 'Moderate' then 2
        when 'Low'      then 1
        else null
    end                                                     as nivel_amenaza_num
from {{ ref('stg_mision') }} m
left join {{ ref('stg_cat_ubicacion_operacion') }} u
    on m.ubicacion_operacion = u.ubicacion_operacion
left join {{ ref('dim_region') }} rg
    on u.region = rg.region
left join {{ ref('dim_pais') }} p
    on m.codigo_iso_lider = p.codigo_iso
left join {{ ref('dim_estado_mision') }} est
    on  m.fase_mision      = est.fase_mision
    and m.estado_mision    = est.estado_mision
    and m.resultado_mision = est.resultado_mision
left join {{ ref('dim_fecha') }} f
    on year(m.fecha_inicio_operacion) = f.anio
where m.es_registro_actual = true
