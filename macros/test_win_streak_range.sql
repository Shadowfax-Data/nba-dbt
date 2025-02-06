{% test test_win_streak_range(model, column_name) %}

select *
from {{ model }}
where {{ column_name }} < 0 or {{ column_name }} > 82

{% endtest %}