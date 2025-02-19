
    DELETE FROM `project-noora-health.Noora_Chat_Data.combined_messages_final`
    WHERE content IS NULL 
       OR inserted_at_x IS NULL 
       OR status IS NULL;

    WITH DuplicateCheck AS (
        SELECT 
            id_x, 
            content, 
            inserted_at_x, 
            LEAD(inserted_at_x) OVER (PARTITION BY content ORDER BY inserted_at_x) AS next_inserted_at
        FROM `project-noora-health.Noora_Chat_Data.combined_messages_final`
    )
    DELETE FROM `project-noora-health.Noora_Chat_Data.combined_messages_final`
    WHERE id_x IN (
        SELECT id_x FROM DuplicateCheck 
        WHERE next_inserted_at IS NOT NULL 
          AND TIMESTAMP_DIFF(next_inserted_at, inserted_at_x, SECOND) <= 60
    );

    WITH RankedMessages AS (
        SELECT 
            id_x, 
            status, 
            inserted_at_x,
            ROW_NUMBER() OVER (PARTITION BY id_x ORDER BY inserted_at_x DESC) AS rank
        FROM `project-noora-health.Noora_Chat_Data.combined_messages_final`
    )
    DELETE FROM `project-noora-health.Noora_Chat_Data.combined_messages_final`
    WHERE id_x IN (
        SELECT id_x FROM RankedMessages WHERE rank > 1
    );
    