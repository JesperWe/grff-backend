ALTER TABLE public.sources
    ADD COLUMN IF NOT EXISTS document_url TEXT NULL;

DROP FUNCTION public.get_country_sources(text, text);
CREATE OR REPLACE FUNCTION public.get_country_sources(iso3166_ text, iso3166_2_ text DEFAULT ''::text)
    RETURNS TABLE
            (
                source_id          integer,
                name               text,
                name_pretty        text,
                description        text,
                url                text,
                document_url       text,
                records            bigint,
                data_points        bigint,
                latest_curation_at timestamp without time zone,
                data_type          data_point_type,
                quality            integer,
                grades             text[],
                year               integer
            )
    LANGUAGE sql
    STABLE
AS
$function$
SELECT DISTINCT s.source_id,
                s.name,
                s.name_pretty,
                s.description,
                s.url,
                s.document_url,
                s.records,
                s.data_points,
                s.latest_curation_at,
                dp.data_type,
                dp.quality,
                array_agg(dp.grade),
                max(dp.YEAR)
FROM sources s,
     country_data_point dp
WHERE s.source_id = dp.source_id
  AND iso3166_ = dp.iso3166
  AND dp.iso3166_2 = iso3166_2_
GROUP BY s.source_id, dp.data_type, dp.quality
UNION
SELECT s.source_id,
       s.name,
       s.name_pretty,
       s.description,
       s.url,
       s.document_url,
       s.records,
       s.data_points,
       s.latest_curation_at,
       'projection'::data_point_type AS data_type,
       1                             as quality,
       array ['xp']                  as grades,
       2020                          AS year
FROM sources s
WHERE s.source_id = 100;
$function$;