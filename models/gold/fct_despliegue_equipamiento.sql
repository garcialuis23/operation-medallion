{{ config(materialized='table') }}

/*
  Equipamiento desplegado por misión y país.
  Fuente: stg_despliegue_equipamiento (dato inferido/aproximado desde CSV2+CSV4).
  Granularidad: (mision_sk, pais_sk, tipo_equipamiento) — UNIQUE por diseño.
  Enriquecido con atributos de dim_mision, dim_pais, dim_equipamiento.
*/

select
    d.id_despliegue,
    d.mision_sk,
    d.pais_sk,
    -- Claves de negocio (auditoría)
    d.id_mision,
    d.codigo_iso,
    d.tipo_equipamiento,
    -- Atributos de misión
    dm.nombre_mision,
    dm.tipo_mision,
    dm.region_operacion,
    dm.zona_operacion,
    dm.nivel_amenaza,
    dm.tipo_liderazgo,
    dm.fecha_inicio_operacion,
    dm.anio_inicio,
    dm.era_otan,
    dm.decada,
    -- Atributos de país
    dp.pais,
    dp.region                                                   as region_pais,
    dp.generacion_otan,
    -- Atributos de equipamiento
    eq.categoria_equipamiento,
    eq.dominio,
    eq.dominio_es,
    eq.es_estandar_otan,
    eq.estandarizacion_es,
    eq.es_interoperable,
    eq.nivel_integracion_otan,
    -- Métricas
    d.cantidad_desplegada,
    d.fecha_inicio,
    d.fecha_fin,
    -- Clasificación del despliegue por dominio
    case eq.dominio
        when 'Air' then 'Despliegue Aéreo'
        when 'Sea' then 'Despliegue Naval'
        when 'Land' then 'Despliegue Terrestre'
        else 'Apoyo'
    end                                                         as tipo_despliegue
from {{ ref('stg_despliegue_equipamiento') }} d
left join {{ ref('dim_mision') }} dm
    on d.mision_sk = dm.mision_sk
left join {{ ref('dim_pais') }} dp
    on d.pais_sk = dp.pais_sk
left join {{ ref('dim_equipamiento') }} eq
    on d.tipo_equipamiento = eq.tipo_equipamiento
where d.cantidad_desplegada > 0
