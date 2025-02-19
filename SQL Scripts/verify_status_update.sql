
    SELECT message_id, COUNT(DISTINCT status) AS unique_status_count
    FROM `project-noora-health.Noora_Chat_Data.combined_messages_final`
    GROUP BY message_id
    HAVING unique_status_count > 1;
    