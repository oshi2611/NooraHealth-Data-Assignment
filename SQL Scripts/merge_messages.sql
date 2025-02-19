
    SELECT 
        m.id AS message_id, 
        m.message_type, 
        m.masked_addressees, 
        m.masked_author, 
        m.content, 
        m.author_type, 
        m.direction, 
        m.external_id, 
        m.external_timestamp, 
        m.masked_from_addr, 
        m.is_deleted, 
        m.last_status, 
        m.last_status_timestamp, 
        m.rendered_content, 
        m.source_type, 
        m.uuid AS message_uuid, 
        m.inserted_at AS inserted_at_x, 
        m.updated_at AS updated_at_x, 
        s.id AS status_id, 
        s.status, 
        s.timestamp, 
        s.message_uuid, 
        s.number_id, 
        s.inserted_at AS inserted_at_y, 
        s.updated_at AS updated_at_y
    FROM `project-noora-health.Noora_Chat_Data.messages_final` m
    LEFT JOIN `project-noora-health.Noora_Chat_Data.statuses` s 
    ON m.id = s.message_id;
    