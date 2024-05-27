WITH

source AS (
	SELECT * FROM {{ source('raw_yahoofinance_api', 'raw_ccl_usd_ars') }}
),

renamed AS (
	SELECT
		"CCL_AVERAGE",
		"GGAL_CCL",
		"DATETIME",
		"YPF_CCL",
		"PAMP_CCL"
	FROM source
)

SELECT * FROM renamed
