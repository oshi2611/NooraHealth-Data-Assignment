# Noora Health - Data Engineering Pipeline

## 1. Project Overview
This project processes **WhatsApp chat data** from Noora Health's **Remote Engagement Service**. The pipeline involves:
- Extracting raw data from **Google Sheets**
- Loading it into **BigQuery**
- Transforming it for analytics
- Validating data quality
- Creating interactive visualizations using **Power BI**

## 2. Setup & Prerequisites
### Required Tools
- **Google Cloud Platform (GCP)** with **BigQuery enabled**
- **SQL** (for transformations)
- **Power BI** (for visualization)

## 3. Data Ingestion (Extract & Load)
### Uploading Data to BigQuery
1. **Download as CSV from Google Sheets**
2. **Upload to BigQuery** using:
   - **BigQuery UI**

## 4. Data Transformation
### Goal: Create a `combined_messages` Table
We merged the `messages` and `statuses` tables to have **one row per message**.

#### SQL Query Used:
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
The merged data is saved as `merged_messages.csv`.

## 5. Data Validation
### Validation Checks:
1. **Detect Duplicate Messages** (Consistency)
2. **Check for Missing Critical Fields** (Completeness)
3. **Verify Status Updates for Messages** (Quality)

#### **Consistency Check (Duplicate Messages)**
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
             AND ABS(STRFTIME('%s', inserted_at) - STRFTIME('%s', prev_inserted_at)) <= 60
        THEN 'Duplicate'
        ELSE 'Unique'
    END AS flag
FROM DuplicateRecords;
```
The flagged data is saved as `flagged_messages.csv`.

#### **Completeness Check (Missing Data)**
```sql
SELECT COUNT(*) AS missing_records
FROM `project-noora-health.Noora_Chat_Data.combined_messages_final`
WHERE content IS NULL
   OR inserted_at_x IS NULL
   OR status IS NULL;
```

#### **Quality Check (Conflicting Status Updates)**
```sql
SELECT message_id, COUNT(DISTINCT status) AS unique_status_count
FROM `project-noora-health.Noora_Chat_Data.combined_messages_final`
GROUP BY message_id
HAVING unique_status_count > 1;
```

### **Validation Results:**
- **Missing Critical Fields (Completeness):** 🚨 32,158 records have missing values.
- **Duplicate Messages (Consistency):** ⚠️ 1,577 records flagged as duplicates.
- **Conflicting Status Updates (Quality):** ❗ 11,578 messages have multiple conflicting statuses.

### **Data Cleansing**
#### SQL Queries Used for Data Cleaning:
```sql
DELETE FROM `project-noora-health.Noora_Chat_Data.combined_messages_final`
WHERE content IS NULL
   OR inserted_at_x IS NULL
   OR status IS NULL;
```
```sql
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
      AND ABS(STRFTIME('%s', inserted_at_x) - STRFTIME('%s', next_inserted_at)) <= 60
);
```
```sql
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
```
The cleaned data is saved as `cleaned_messages.csv`.

## 6. Data Visualization
### **Dashboard Creation Using Power BI**
1. **Connect BigQuery dataset**
2. **Create visualizations:**
   - **Line Chart**: Weekly user engagement trends
   - **Pie Chart**: Read vs. Unread messages
   - **Bar Chart**: Message statuses

#### **Key Insights:**
1️⃣ **User Engagement Trends**
   - Weekly trend of total & active users.

2️⃣ **Read vs. Unread Messages**
   - **38.7%** of sent messages have been read.
   - **61.3%** remain unread.

3️⃣ **Message Status Breakdown**
   - **19 messages sent**
   - **14 messages read**
   - **9 messages delivered but not read**

## 7. Conclusion & Future Enhancements
### **Summary**
This project **automated data ingestion, transformation, validation, and reporting** for Noora Health.

### **Future Improvements**
- **Automate the pipeline** using **Airflow**
- **Optimize query performance** with **partitioning & clustering**
- **Implement real-time data ingestion** using **Pub/Sub**

