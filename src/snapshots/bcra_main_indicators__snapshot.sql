{% snapshot bcra_main_indicators__snapshot %}

	{{
		config(
			target_database='HACKATHON_9',
			target_schema='snapshots',
			unique_key='idVariable',
			strategy='timestamp',
			updated_at='fecha',
		)
	}}

	select * from {{ source('raw_bcra_api', 'raw_bcra_api') }}

{% endsnapshot %}
