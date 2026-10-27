-- =============================================================================
-- ORION | Hive setup: database and session settings          (branch: feature/hive-analytics)
-- Owner: Member 3 - Hive Analytics & SQL Summaries
-- Run first:  hive -f hive/00_setup.hql
-- NOTE: every ORION dataset is SYNTHETIC / simulated. Keep that visible in dashboards and reports.
-- =============================================================================

CREATE DATABASE IF NOT EXISTS orion
COMMENT 'ORION - Ocean Research and Intelligence for Aquaculture (simulated data)'
LOCATION '/user/hive/warehouse/orion.db';

USE orion;

SET hive.exec.dynamic.partition = true;
SET hive.exec.dynamic.partition.mode = nonstrict;
SET hive.exec.max.dynamic.partitions = 1000;
SET hive.cli.print.header = true;
