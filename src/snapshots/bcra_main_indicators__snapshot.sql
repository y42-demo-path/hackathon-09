{% snapshot bcra_main_indicators__snapshot %}

	{{
		config(
			target_database='HACKATHON_9',
			target_schema='snapshots',
			unique_key='variable_id',
			strategy='timestamp',
			updated_at='variable_at',
		)
	}}

	select
	
	    "idVariable" as variable_id,
	    "descripcion" as variable_description,
	    "valor" as variable_value,
	    "fecha"::date as variable_at
	
	from {{ source('raw_bcra_api', 'raw_bcra_api') }}
	

{% endsnapshot %}
