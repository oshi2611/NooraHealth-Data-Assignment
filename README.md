# NooraHealth-Data-Assignment

# Noora Health - Data Engineering Pipeline

## 1. Project Overview
This project processes **WhatsApp chat data** from Noora Health's **Remote Engagement Service**. The pipeline involves:
- Extracting raw data from Google Sheets
- Loading it into **BigQuery**
- Transforming it for analytics
- Validating data quality
- Creating interactive visualizations

## 2. Setup & Prerequisites
### Required Tools
- **Google Cloud Platform (GCP)** with **BigQuery enabled**
- SQL (for transformations)
- Google Looker Studio (for visualization)


## 3. Data Ingestion (Extract & Load)
### Upload Data to BigQuery
1. **Download CSV from Google Sheets**
2. **Upload to BigQuery** using:
   - BigQuery UI

## 4. Data Transformation
### Goal: Create a `final_messages` table
We merged `messages` and `statuses` tables to have **one row per message**.

### SQL Queries Used
#### Get Latest Status for Each Message
```sql
WITH latest_status AS (
    SELECT DISTINCT ON (message_uuid)
        message_uuid, status, timestamp AS last_status_timestamp
    FROM `project-noora-health.Noora_Chat_Data.statuses`
    ORDER BY message_uuid, timestamp DESC
)
SELECT
    m.id, m.content, m.direction, m.external_timestamp, m.is_deleted,
    l.status AS last_status, l.last_status_timestamp,
    m.inserted_at, m.updated_at
FROM `project-noora-health.Noora_Chat_Data.messages` m
LEFT JOIN latest_status l
ON m.uuid = l.message_uuid;
```

## 5. Data Validation
### Check for Missing Values
```sql
SELECT *
FROM `project-noora-health.Noora_Chat_Data.messages`
WHERE content IS NULL OR external_timestamp IS NULL;
```
### Identify Duplicate Messages
```sql
SELECT
    id, content, inserted_at,
    COUNT(*) OVER (
        PARTITION BY content
        ORDER BY inserted_at
        ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
    ) AS duplicate_flag
FROM `project-noora-health.Noora_Chat_Data.messages`;
```

## 6. Data Visualization
We used **Google Looker Studio** to visualize:
✅ Total vs. Active Users Over Time  
✅ Read Rate & Message Read Time  
✅ Message Status Distribution  

### SQL Query for Active Users Over Time
```sql
SELECT
    DATE_TRUNC(DATE(external_timestamp), WEEK) AS week,
    COUNT(DISTINCT masked_from_addr) AS total_users,
    COUNT(DISTINCT CASE WHEN direction = 'inbound' THEN masked_from_addr END) AS active_users
FROM `project-noora-health.Noora_Chat_Data.messages`
GROUP BY week
ORDER BY week;
```

### Steps to Create Dashboard
1. **Go to Looker Studio**
2. **Connect BigQuery dataset**
3. **Create Line Chart for weekly user trends**
4. **Create Bar Chart for message status**

## 7. How to Run the Project
### Steps to Execute
1. **Run Data Upload Script**
   ```bash
   python upload_data.py
   ```
2. **Run SQL Transformations in BigQuery**  
   - Execute `transform.sql` in BigQuery console.  

3. **Generate Reports in Looker Studio**  
   - Connect **final_messages** table.  
   - Create visualizations.  

## 8. Conclusion & Future Improvements
### Summary
This project **automated data ingestion, transformation, validation, and reporting** for Noora Health.

### Future Enhancements
- **Automate the pipeline** using **Airflow**
- **Optimize query performance** using **partitioning & clustering**
- **Implement real-time data ingestion** with **Pub/Sub**

## 9. Submitting the Assignment
### Steps to Submit:
1. **Upload Code & Queries to GitHub**
2. **Include this README.md**
3. **(Optional) Record a Short Loom Video**
4. **Send the GitHub Repo Link to the Hiring Team**

