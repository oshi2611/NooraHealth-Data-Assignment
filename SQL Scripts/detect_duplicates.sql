
    WITH DuplicateRecords AS (
        SELECT 
            id, 
            content, 
            inserted_at,
            LAG(inserted_at) OVER (PARTITION BY content ORDER BY inserted_at) AS prev_inserted_at
        FROM `project-noora-health.Noora_Chat_Data.combined_messages_final`
    )
    SELECT 
        id, 
        content, 
        inserted_at,
        CASE 
            WHEN prev_inserted_at IS NOT NULL 
                 AND TIMESTAMP_DIFF(inserted_at, prev_inserted_at, SECOND) <= 60 
            THEN 'Duplicate' 
            ELSE 'Unique' 
        END AS flag
    FROM DuplicateRecords;
    