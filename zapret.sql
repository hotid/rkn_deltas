-- MySQL dump 10.17  Distrib 10.3.12-MariaDB, for debian-linux-gnu (i686)
--
-- Host: localhost    Database: rsz_new
-- ------------------------------------------------------
-- Server version	10.3.12-MariaDB-1:10.3.12+maria~stretch

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `deltas`
--

DROP TABLE IF EXISTS `deltas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `deltas` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `deltaId` int(10) unsigned NOT NULL,
  `isEmpty` tinyint(1) unsigned NOT NULL,
  `actualDate` timestamp NULL DEFAULT NULL,
  `created` timestamp NOT NULL DEFAULT current_timestamp(),
  `status` tinyint(1) NOT NULL,
  `updated` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `deltaId` (`deltaId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `domains`
--

DROP TABLE IF EXISTS `domains`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `domains` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `recordId` int(10) unsigned NOT NULL,
  `domain` text NOT NULL,
  `ct` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `recordId` (`recordId`),
  CONSTRAINT `fk_domains_record_id` FOREIGN KEY (`recordId`) REFERENCES `records` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ipSubnets`
--

DROP TABLE IF EXISTS `ipSubnets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ipSubnets` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `recordId` int(10) unsigned NOT NULL,
  `ip` int(10) unsigned NOT NULL,
  `prefix` tinyint(2) unsigned NOT NULL,
  `ct` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `ts` datetime DEFAULT NULL,
  `last_ip_in_range` int(10) unsigned GENERATED ALWAYS AS (`ip` | (pow(2,32) - pow(2,32 - `prefix`)) ^ (pow(2,32) - 1)) STORED,
  PRIMARY KEY (`id`),
  KEY `recordId` (`recordId`),
  KEY `ip` (`ip`,`last_ip_in_range`),
  CONSTRAINT `fk_ipSubnets_record_id` FOREIGN KEY (`recordId`) REFERENCES `records` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ips`
--

DROP TABLE IF EXISTS `ips`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ips` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `recordId` int(10) unsigned NOT NULL,
  `ip` int(10) unsigned NOT NULL,
  `ct` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `ts` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `recordId` (`recordId`),
  KEY `ts` (`ts`),
  KEY `ip` (`ip`),
  CONSTRAINT `fk_ips_record_id` FOREIGN KEY (`recordId`) REFERENCES `records` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `records`
--

DROP TABLE IF EXISTS `records`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `records` (
  `id` int(10) unsigned NOT NULL,
  `includeTime` timestamp NOT NULL DEFAULT current_timestamp(),
  `entryType` tinyint(2) unsigned DEFAULT NULL,
  `decisionNumber` varchar(255) DEFAULT NULL,
  `decisionOrg` varchar(255) DEFAULT NULL,
  `decisionDate` varchar(255) DEFAULT NULL,
  `blockType` varchar(15) NOT NULL DEFAULT 'default',
  PRIMARY KEY (`id`),
  KEY `id` (`id`,`blockType`),
  KEY `blockType` (`blockType`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `settings`
--

DROP TABLE IF EXISTS `settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `settings` (
  `param` varchar(255) NOT NULL,
  `value` text NOT NULL,
  UNIQUE KEY `param` (`param`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `urls`
--

DROP TABLE IF EXISTS `urls`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `urls` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `recordId` int(10) unsigned NOT NULL,
  `url` text NOT NULL,
  PRIMARY KEY (`id`),
  KEY `recordId` (`recordId`),
  CONSTRAINT `fk_urls_record_id` FOREIGN KEY (`recordId`) REFERENCES `records` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary table structure for view `zap2_domains`
--

DROP TABLE IF EXISTS `zap2_domains`;
/*!50001 DROP VIEW IF EXISTS `zap2_domains`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `zap2_domains` (
  `id` tinyint NOT NULL,
  `date_add` tinyint NOT NULL,
  `record_id` tinyint NOT NULL,
  `domain` tinyint NOT NULL,
  `domain_fixed` tinyint NOT NULL
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `zap2_ips`
--

DROP TABLE IF EXISTS `zap2_ips`;
/*!50001 DROP VIEW IF EXISTS `zap2_ips`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `zap2_ips` (
  `id` tinyint NOT NULL,
  `record_id` tinyint NOT NULL,
  `date_add` tinyint NOT NULL,
  `ip` tinyint NOT NULL,
  `resolved` tinyint NOT NULL,
  `domain` tinyint NOT NULL
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `zap2_only_ips`
--

DROP TABLE IF EXISTS `zap2_only_ips`;
/*!50001 DROP VIEW IF EXISTS `zap2_only_ips`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `zap2_only_ips` (
  `id` tinyint NOT NULL,
  `record_id` tinyint NOT NULL,
  `date_add` tinyint NOT NULL,
  `ip` tinyint NOT NULL,
  `resolved` tinyint NOT NULL,
  `domain` tinyint NOT NULL,
  `ts` tinyint NOT NULL
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `zap2_subnets`
--

DROP TABLE IF EXISTS `zap2_subnets`;
/*!50001 DROP VIEW IF EXISTS `zap2_subnets`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `zap2_subnets` (
  `id` tinyint NOT NULL,
  `date_add` tinyint NOT NULL,
  `record_id` tinyint NOT NULL,
  `subnet` tinyint NOT NULL,
  `ts` tinyint NOT NULL
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `zap2_urls`
--

DROP TABLE IF EXISTS `zap2_urls`;
/*!50001 DROP VIEW IF EXISTS `zap2_urls`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `zap2_urls` (
  `id` tinyint NOT NULL,
  `date_add` tinyint NOT NULL,
  `record_id` tinyint NOT NULL,
  `url` tinyint NOT NULL,
  `url_fixed` tinyint NOT NULL
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;

--
-- Final view structure for view `zap2_domains`
--

/*!50001 DROP TABLE IF EXISTS `zap2_domains`*/;
/*!50001 DROP VIEW IF EXISTS `zap2_domains`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8 */;
/*!50001 SET character_set_results     = utf8 */;
/*!50001 SET collation_connection      = utf8_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `zap2_domains` AS select `domains`.`id` AS `id`,NULL AS `date_add`,`domains`.`recordId` AS `record_id`,`domains`.`domain` AS `domain`,`domains`.`domain` AS `domain_fixed` from (`domains` join `records`) where `records`.`blockType` = 'domain' and `domains`.`recordId` = `records`.`id` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `zap2_ips`
--

/*!50001 DROP TABLE IF EXISTS `zap2_ips`*/;
/*!50001 DROP VIEW IF EXISTS `zap2_ips`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8 */;
/*!50001 SET character_set_results     = utf8 */;
/*!50001 SET collation_connection      = utf8_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `zap2_ips` AS select `ips`.`id` AS `id`,`ips`.`recordId` AS `record_id`,NULL AS `date_add`,`ips`.`ip` AS `ip`,0 AS `resolved`,'' AS `domain` from `ips` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `zap2_only_ips`
--

/*!50001 DROP TABLE IF EXISTS `zap2_only_ips`*/;
/*!50001 DROP VIEW IF EXISTS `zap2_only_ips`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8 */;
/*!50001 SET character_set_results     = utf8 */;
/*!50001 SET collation_connection      = utf8_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `zap2_only_ips` AS select `ips`.`id` AS `id`,`ips`.`recordId` AS `record_id`,`ips`.`ct` AS `date_add`,`ips`.`ip` AS `ip`,0 AS `resolved`,'' AS `domain`,`ips`.`ts` AS `ts` from (`ips` join `records`) where `ips`.`recordId` = `records`.`id` and `records`.`blockType` = 'ip' */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `zap2_subnets`
--

/*!50001 DROP TABLE IF EXISTS `zap2_subnets`*/;
/*!50001 DROP VIEW IF EXISTS `zap2_subnets`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8 */;
/*!50001 SET character_set_results     = utf8 */;
/*!50001 SET collation_connection      = utf8_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `zap2_subnets` AS select `ipSubnets`.`id` AS `id`,`ipSubnets`.`ct` AS `date_add`,`ipSubnets`.`recordId` AS `record_id`,concat(inet_ntoa(`ipSubnets`.`ip`),'/',`ipSubnets`.`prefix`) AS `subnet`,`ipSubnets`.`ts` AS `ts` from `ipSubnets` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `zap2_urls`
--

/*!50001 DROP TABLE IF EXISTS `zap2_urls`*/;
/*!50001 DROP VIEW IF EXISTS `zap2_urls`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8 */;
/*!50001 SET character_set_results     = utf8 */;
/*!50001 SET collation_connection      = utf8_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `zap2_urls` AS select `urls`.`id` AS `id`,NULL AS `date_add`,`urls`.`recordId` AS `record_id`,`urls`.`url` AS `url`,'' AS `url_fixed` from `urls` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2019-04-12  1:17:07
