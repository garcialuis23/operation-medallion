{% macro generate_database_name(custom_database_name=none, node=none) -%}
    {%- set env_map = {'default': 'DEV', 'dev': 'DEV', 'pro': 'PRO'} -%}
    {%- set env = env_map.get(target.name | lower, target.name | upper) -%}
    {%- if custom_database_name is none -%}
        {{ target.database }}
    {%- else -%}
        {{ custom_database_name }}_{{ env }}
    {%- endif -%}
{%- endmacro %}
