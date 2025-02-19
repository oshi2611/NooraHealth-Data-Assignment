
    SELECT 
        COUNT(*) AS missing_records 
    FROM `project-noora-health.Noora_Chat_Data.combined_messages_final`
    WHERE content IS NULL 
       OR inserted_at_x IS NULL 
       OR status IS NULL;
    