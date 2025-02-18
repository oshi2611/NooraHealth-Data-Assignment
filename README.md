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
- PowerBI (for visualization)

## 3. Data Ingestion (Extract & Load)
### Upload Data to BigQuery
1. **Download as CSV from Google Sheets**
2. **Upload to BigQuery** using:
   - BigQuery UI

## 4. Data Transformation
### Goal: Create a `combined_messages` table
We merged `messages` and `statuses` tables to have **one row per message**.

SQL Query used to merge the 2 tables based on the message ID:
```sql
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
```
The merged CSV is uploaded as `merged_messages.csv`.

## 5. Data Validation:
   i. Detect Duplicate Messages (Consistency)
  ii. Check for missing critical fields (Completeness)
 iii. Verify Status Update for messages (Quality)

### SQL Queries Used
#### **Consistency - Detecting Duplicate Messages**
```sql
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
```
The flagged CSV is uploaded as `flagged_messages.csv`.

### **Completeness - Checking for Missing Critical Fields**
```sql
SELECT
    COUNT(*) AS missing_records
FROM `project-noora-health.Noora_Chat_Data.combined_messages_final`
WHERE content IS NULL
   OR inserted_at_x IS NULL
   OR status IS NULL;
```

### **Quality - Identifying Conflicting Status Updates**
```sql
SELECT message_id, COUNT(DISTINCT status) AS unique_status_count
FROM `project-noora-health.Noora_Chat_Data.combined_messages_final`
GROUP BY message_id
HAVING unique_status_count > 1;
```

Here are the results of the data validation checks:

1️⃣ **Missing Critical Fields (Completeness):** 🚨 32,158 records have missing values in either content, inserted_at_x, or status.

2️⃣ **Duplicate Messages (Consistency):** ⚠️ 1,577 records have identical content with timestamps within 1 minute.

3️⃣ **Conflicting Status Updates (Quality):** ❗ 11,578 messages have multiple conflicting statuses.

These indicate potential data quality issues. A `cleaned_messages.csv` was generated using the following queries.

### **Data Cleansing Queries**
#### **Removing Incomplete Messages**
```sql
DELETE FROM `project-noora-health.Noora_Chat_Data.combined_messages_final`
WHERE content IS NULL
   OR inserted_at_x IS NULL
   OR status IS NULL;
```

#### **Removing Duplicate Messages**
```sql
DELETE FROM `project-noora-health.Noora_Chat_Data.combined_messages_final`
WHERE id_x IN (
    SELECT id_x FROM (
        SELECT
            id_x,
            content,
            inserted_at_x,
            LEAD(inserted_at_x) OVER (PARTITION BY content ORDER BY inserted_at_x) AS next_inserted_at
        FROM `project-noora-health.Noora_Chat_Data.combined_messages_final`
    )
    WHERE next_inserted_at IS NOT NULL
      AND TIMESTAMP_DIFF(next_inserted_at, inserted_at_x, SECOND) <= 60
);
```

#### **Keeping Only the Latest Status Update**
```sql
DELETE FROM `project-noora-health.Noora_Chat_Data.combined_messages_final`
WHERE id_x NOT IN (
    SELECT id_x FROM (
        SELECT
            id_x,
            status,
            inserted_at_x,
            ROW_NUMBER() OVER (PARTITION BY id_x ORDER BY inserted_at_x DESC) AS rank
        FROM `project-noora-health.Noora_Chat_Data.combined_messages_final`
    )
    WHERE rank = 1
);
```
The cleaned CSV is uploaded as `cleaned_messages.csv`.

## 6. Data Visualization
### Steps to Create Dashboard
1. **Go to Power BI**
2. **Connect BigQuery dataset**
3. **Create Line Chart for weekly user trends**
4. **Create Pie Chart for Read and Unread message %**
5. **Create Bar Chart for message status**

### 1️⃣ Total & Active Users Over Time – Weekly trend for the last 3 months.
![Total & Active Users Over Time](https://github.com/oshi2611/NooraHealth-Data-Assignment/blob/main/Charts/Image%203.png)

The trend shows how many users are engaging with messages weekly.
Active users (those who send messages) follow a similar pattern to total users.

### 2️⃣ Fraction of Sent Messages Read & Read Time Analysis – How many outbound messages are read and their response time.
![Fraction of Sent Messages Read](https://github.com/oshi2611/NooraHealth-Data-Assignment/blob/main/Charts/Image%202.png)

38.7% of sent messages have been read.
The remaining 61.3% remain unread.

### 3️⃣ Outbound Messages by Status in the Last Week – Breakdown of message statuses.
![Outbound Messages by Status](https://github.com/oshi2611/NooraHealth-Data-Assignment/blob/main/Charts/Image%201.png)

19 messages were sent  
14 messages were read  
9 messages were delivered but not read  

## 7. Conclusion & Future Improvements
### Summary
This project automates data ingestion, transformation, validation, and visualization for Noora Health’s Remote Engagement Service. It streamlines the process of handling WhatsApp chat data, ensuring data accuracy and reliability while providing actionable insights into user engagement. The pipeline is designed to:
✅ Ingest raw data from Google Sheets into BigQuery
✅ Transform and merge messages with statuses for a unified view
✅ Validate data quality by detecting duplicates, missing values, and inconsistencies
✅ Visualize key engagement metrics through interactive dashboards

With these capabilities, Noora Health can better track outreach effectiveness, optimize messaging strategies, and enhance patient engagement. Future enhancements include real-time analytics and automated data pipelines to further improve efficiency and responsiveness.

### Future Enhancements
- **Automate the pipeline** using **Airflow**
- **Optimize query performance** using **partitioning & clustering**
- **Implement real-time data ingestion Pub/Sub and Dataflow to process messages instantly.**
- **Develop a real-time dashboard in Power BI / Looker using BigQuery BI Engine for low-latency visualizations**

