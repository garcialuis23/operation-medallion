{{ config(materialized='table') }}

/*
  dim_equipamiento: jerarquía completa tipo → categoría → dominio (snowflake).
  es_estandar_otan y es_interoperable provienen de stg_tipo_equipamiento (movidos
  desde stg_inventario_equipamiento en v10 — son atributos del tipo, no del lote).
*/

select
    t.tipo_equipamiento,
    t.categoria_equipamiento,
    c.dominio,
    case c.dominio
        when 'Air'     then 'Aéreo'
        when 'Land'    then 'Terrestre'
        when 'Sea'     then 'Naval'
        when 'Support' then 'Apoyo'
        else c.dominio
    end                                                     as dominio_es,
    t.es_estandar_otan,
    case t.es_estandar_otan
        when 'Yes'     then 'Estandarizado'
        when 'Partial' then 'Parcialmente Estandarizado'
        when 'No'      then 'No Estandarizado'
        else t.es_estandar_otan
    end                                                     as estandarizacion_es,
    t.es_interoperable,
    case
        when t.es_estandar_otan = 'Yes' and t.es_interoperable  then 'Totalmente Integrado'
        when t.es_estandar_otan = 'Yes' and not t.es_interoperable then 'Estándar sin Interop'
        when t.es_estandar_otan = 'Partial'                     then 'Integración Parcial'
        else 'No Integrado'
    end                                                     as nivel_integracion_otan
from {{ ref('stg_tipo_equipamiento') }} t
left join {{ ref('stg_cat_categoria_equipamiento') }} c
    on t.categoria_equipamiento = c.categoria_equipamiento
where t.tipo_equipamiento is not null
