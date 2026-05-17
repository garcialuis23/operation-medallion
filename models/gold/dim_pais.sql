{{ config(materialized='table') }}

/*
  dim_pais: snapshot de la versión actual SCD-2.
  pais_sk: surrogate key — FK primaria para todas las fact tables.
  codigo_iso: clave de negocio — conservada para joins legacy y auditoría.
  generacion_otan: calculada desde fecha_ingreso_otan (DATE) para mayor precisión.
*/

select
    p.pais_sk,
    p.codigo_iso,
    p.pais,
    p.region,
    r.zona_geografica,
    r.es_flanco_este,
    r.es_norte_america,
    p.capital,
    p.area_km2,
    p.tipo_gobierno,
    p.rol_alianza,
    p.fecha_ingreso_otan,
    p.anio_ingreso_otan,
    p.es_miembro_fundador,
    p.tiene_comparticion_nuclear,
    case
        when p.anio_ingreso_otan <= 1949                   then 'Miembro Fundador'
        when p.anio_ingreso_otan between 1950 and 1982     then 'Primera Expansión'
        when p.anio_ingreso_otan between 1983 and 2003     then 'Expansión Post-GF'
        when p.anio_ingreso_otan >= 2004                   then 'Expansión Este'
        else 'Desconocido'
    end                                                     as generacion_otan,
    case
        when p.tiene_comparticion_nuclear and p.es_miembro_fundador then 'Nuclear-Fundador'
        when p.tiene_comparticion_nuclear                           then 'Nuclear'
        when p.es_miembro_fundador                                  then 'Fundador'
        else 'Estándar'
    end                                                     as perfil_nucleo,
    p.fecha_inicio_validez,
    p.fecha_fin_validez
from {{ ref('stg_pais') }} p
left join {{ ref('dim_region') }} r on p.region = r.region
where p.es_registro_actual = true
