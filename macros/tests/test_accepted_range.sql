{% test accepted_range(model, column_name, min_value=None, max_value=None, inclusive=True) %}

with validation as (
    select
        {{ column_name }} as value
    from {{ model }}
),

validation_errors as (
    select *
    from validation
    where
        {% if min_value is not none %}
            {% if inclusive %}
                value < {{ min_value }}
            {% else %}
                value <= {{ min_value }}
            {% endif %}
        {% endif %}

        {% if min_value is not none and max_value is not none %}
            or
        {% endif %}

        {% if max_value is not none %}
            {% if inclusive %}
                value > {{ max_value }}
            {% else %}
                value >= {{ max_value }}
            {% endif %}
        {% endif %}
)

select *
from validation_errors

{% endtest %}