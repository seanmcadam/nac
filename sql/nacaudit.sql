-- phpMyAdmin SQL Dump
-- version 2.11.11.3
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Jan 27, 2014 at 04:53 AM
-- Server version: 5.1.71
-- PHP Version: 5.3.3

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";

--
-- Database: `nacaudit`
--

-- --------------------------------------------------------

--
-- Table structure for table `class`
--

CREATE TABLE IF NOT EXISTS `class` (
  `classid` int(11) NOT NULL AUTO_INCREMENT COMMENT 'mac type id',
  `name` varchar(64) NOT NULL COMMENT 'Mac type Name',
  `priority` smallint(6) NOT NULL DEFAULT '0' COMMENT 'priority assigned to this class',
  `reauthtime` mediumint(5) NOT NULL DEFAULT '3600',
  `idletimeout` mediumint(5) NOT NULL DEFAULT '3600',
  `vlangroupid` int(11) DEFAULT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  `locked` tinyint(1) NOT NULL DEFAULT '0',
  `comment` text,
  PRIMARY KEY (`classid`),
  UNIQUE KEY `name` (`name`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `dhcpstate`
--

CREATE TABLE IF NOT EXISTS `dhcpstate` (
  `macid` int(11) NOT NULL,
  `lastupdate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `state` varchar(20) NOT NULL DEFAULT 'INACTIVE',
  `ip` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`macid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `coe_mac_exception`
--

CREATE TABLE IF NOT EXISTS `coe_mac_exception` (
  `macid` int(10) NOT NULL,
  `ticketref` varchar(16) NOT NULL,
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `comment` text,
  PRIMARY KEY (`macid`),
  KEY `ticketref` (`ticketref`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `eventlog`
--

CREATE TABLE IF NOT EXISTS `eventlog` (
  `eventlogid` int(11) NOT NULL AUTO_INCREMENT,
  `eventtime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `eventtype` enum('EVENT_START','EVENT_STOP','EVENT_ACCT_STOP','EVENT_ACCT_START','EVENT_AUTH_CLEAR','EVENT_AUTH_BLOCK','EVENT_AUTH_CHALLENGE','EVENT_AUTH_GUEST','EVENT_AUTH_MAC','EVENT_AUTH_PORT','EVENT_AUTH_VOICE','EVENT_AUTH_NAK','EVENT_CHALLENGE_ERR','EVENT_CIDR_ADD','EVENT_CIDR_DEL','EVENT_CLASS_ADD','EVENT_CLASS_DEL','EVENT_CLASS_UPD','EVENT_DB_ERR','EVENT_DB_WARN','EVENT_FILTER_ADD','EVENT_FILTER_DEL','EVENT_FIXEDIP_ADD','EVENT_FIXEDIP_DEL','EVENT_FIXEDIP_UPD','EVENT_MAC2CLASS_ADD','EVENT_MAC2CLASS_DEL','EVENT_MAC2CLASS_UPD','EVENT_MAC_ADD','EVENT_MAC_DEL','EVENT_MAC_UPD','EVENT_MAGIC_PORT','EVENT_MEMCACHE_ERR','EVENT_MEMCACHE_WARN','EVENT_LOC_ADD','EVENT_LOC_DEL','EVENT_LOC_UPD','EVENT_PORT_ADD','EVENT_PORT_DEL','EVENT_PORT2CLASS_ADD','EVENT_PORT2CLASS_DEL','EVENT_PORT2CLASS_UPD','EVENT_SWITCH_ADD','EVENT_SWITCH_DEL','EVENT_SWITCH_UPD','EVENT_SWITCHPORT_ADD','EVENT_SWITCHPORT_DEL','EVENT_SWITCH2VLAN_ADD','EVENT_SWITCH2VLAN_DEL','EVENT_TEMPLATE_ADD','EVENT_TEMPLATE_DEL','EVENT_TEMPLATE2VLANGROUP_ADD','EVENT_TEMPLATE2VLANGROUP_DEL','EVENT_VLAN_ADD','EVENT_VLAN_DEL','EVENT_VLANGROUP_ADD','EVENT_VLANGROUP_DEL','EVENT_VLANGROUP2VLAN_ADD','EVENT_VLANGROUP2VLAN_DEL','EVENT_NOLOCATION','EVENT_SMTP_FAIL','EVENT_LOGIC_FAIL','EVENT_EVAL_FAIL','EVENT_FUNC_FAIL','EVENT_ERR','EVENT_WARN','EVENT_NOTICE','EVENT_INFO','EVENT_DEBUG','EVENT_FATAL','EVENT_DISTRESS') NOT NULL,
  `userid` int(11) DEFAULT NULL,
  `hostname` varchar(64) DEFAULT NULL,
  `classid` int(11) DEFAULT NULL,
  `locationid` int(11) DEFAULT NULL,
  `macid` int(11) DEFAULT NULL,
  `mac2classid` int(11) DEFAULT NULL,
  `magicportid` int(11) DEFAULT NULL,
  `port2classid` int(11) DEFAULT NULL,
  `switchid` int(11) DEFAULT NULL,
  `switchportid` int(11) DEFAULT NULL,
  `switch2vlanid` int(11) DEFAULT NULL,
  `templateid` int(11) DEFAULT NULL,
  `template2vlangroupid` int(11) DEFAULT NULL,
  `vlangroupid` int(11) DEFAULT NULL,
  `vlangroup2vlanid` int(11) DEFAULT NULL,
  `vlanid` int(11) DEFAULT NULL,
  `ip` varchar(20) DEFAULT NULL,
  `eventtext` text,
  PRIMARY KEY (`eventlogid`),
  KEY `eventtype` (`eventtype`),
  KEY `eventtime` (`eventtime`),
  KEY `macid` (`macid`),
  KEY `switchportid` (`switchportid`),
  KEY `swichid` (`switchid`),
  KEY `userid` (`userid`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `location`
--

CREATE TABLE IF NOT EXISTS `location` (
  `locationid` int(11) NOT NULL AUTO_INCREMENT,
  `site` varchar(32) NOT NULL,
  `bldg` varchar(32) NOT NULL,
  `locationname` varchar(256) DEFAULT NULL,
  `locationdescription` varchar(1024) DEFAULT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  `comment` text,
  PRIMARY KEY (`locationid`),
  UNIQUE KEY `uniquesitebldg` (`site`,`bldg`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `loopcidr2loc`
--

CREATE TABLE IF NOT EXISTS `loopcidr2loc` (
  `loopcidr2locid` int(11) NOT NULL AUTO_INCREMENT,
  `cidr` varchar(19) NOT NULL,
  `locid` int(11) NOT NULL,
  `comment` varchar(256) NOT NULL,
  PRIMARY KEY (`loopcidr2locid`),
  UNIQUE KEY `cidrlocidunique` (`cidr`,`locid`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `mac`
--

CREATE TABLE IF NOT EXISTS `mac` (
  `macid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `mac` char(18) NOT NULL COMMENT 'Created by NAC, Syslog, MACAuth, or Admin',
  `firstseen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `lastseen` timestamp NULL DEFAULT NULL COMMENT 'Updated by Syslog',
  `laststatechange` timestamp NULL DEFAULT NULL COMMENT 'Last time the state transitioned',
  `description` varchar(1024) DEFAULT NULL COMMENT 'Update by Admin',
  `assettag` varchar(32) DEFAULT NULL,
  `dhcpstateid` int(11) DEFAULT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  `coe` tinyint(1) NOT NULL DEFAULT '0',
  `locked` tinyint(1) NOT NULL DEFAULT '0',
  `comment` text,
  PRIMARY KEY (`macid`),
  UNIQUE KEY `mac` (`mac`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `mac2class`
--

CREATE TABLE IF NOT EXISTS `mac2class` (
  `mac2classid` int(11) NOT NULL AUTO_INCREMENT,
  `macid` int(11) NOT NULL,
  `classid` int(11) NOT NULL,
  `vlanid` int(11) NOT NULL DEFAULT '0' COMMENT 'VLAN with location association',
  `vlangroupid` int(11) NOT NULL DEFAULT '0' COMMENT 'VLAN type with out location association',
  `templateid` int(11) NOT NULL DEFAULT '0' COMMENT 'Predefined groups of vlangroups',
  `priority` smallint(6) NOT NULL DEFAULT '0',
  `expiretime` timestamp NULL DEFAULT NULL,
  `locked` tinyint(1) NOT NULL DEFAULT '0',
  `comment` text,
  PRIMARY KEY (`mac2classid`),
  UNIQUE KEY `uniquemacclass` (`macid`,`classid`,`priority`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `magicport`
--

CREATE TABLE IF NOT EXISTS `magicport` (
  `magicportid` int(11) NOT NULL AUTO_INCREMENT,
  `switchportid` int(11) NOT NULL,
  `classid` int(11) NOT NULL,
  `vlanid` int(11) NOT NULL DEFAULT '0',
  `vlangroupid` int(11) NOT NULL DEFAULT '0',
  `templateid` int(11) NOT NULL DEFAULT '0',
  `priority` smallint(6) NOT NULL DEFAULT '0',
  `comment` text,
  `magicporttype` set('REPLACE','ADD') NOT NULL DEFAULT 'REPLACE',
  PRIMARY KEY (`magicportid`),
  KEY `switchportid` (`switchportid`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `port2class`
--

CREATE TABLE IF NOT EXISTS `port2class` (
  `port2classid` int(11) NOT NULL AUTO_INCREMENT,
  `switchportid` int(11) NOT NULL,
  `classid` int(11) NOT NULL,
  `vlanid` int(11) NOT NULL DEFAULT '0' COMMENT 'VLAN with location association',
  `vlangroupid` int(11) NOT NULL DEFAULT '0' COMMENT 'VLAN type with out location association',
  `locked` tinyint(1) NOT NULL DEFAULT '0',
  `comment` text,
  PRIMARY KEY (`port2classid`),
  UNIQUE KEY `uniqueportclass` (`switchportid`,`classid`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `radiusaudit`
--

CREATE TABLE IF NOT EXISTS `radiusaudit` (
  `radiusauditid` int(11) NOT NULL AUTO_INCREMENT,
  `macid` int(11) NOT NULL,
  `switchportid` int(11) NOT NULL,
  `audittime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `auditserver` varchar(32) NOT NULL DEFAULT 'unknown',
  `type` varchar(32) NOT NULL,
  `cause` varchar(32) DEFAULT NULL,
  `octetsin` int(16) NOT NULL DEFAULT '0',
  `octetsout` int(16) NOT NULL DEFAULT '0',
  `packetsin` int(11) NOT NULL DEFAULT '0',
  `packetsout` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`radiusauditid`),
  KEY `macid` (`macid`),
  KEY `switchportid` (`switchportid`),
  KEY `audittime` (`audittime`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `switch`
--

CREATE TABLE IF NOT EXISTS `switch` (
  `switchid` int(11) NOT NULL AUTO_INCREMENT,
  `switchname` varchar(64) DEFAULT NULL,
  `locationid` int(11) NOT NULL,
  `switchdescription` varchar(512) DEFAULT NULL,
  `ip` varchar(15) NOT NULL,
  `lastseen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `comment` text,
  PRIMARY KEY (`switchid`),
  UNIQUE KEY `IP` (`ip`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `switch2vlan`
--

CREATE TABLE IF NOT EXISTS `switch2vlan` (
  `switch2vlanid` int(11) NOT NULL AUTO_INCREMENT,
  `switchid` int(11) NOT NULL,
  `vlanid` int(11) NOT NULL,
  PRIMARY KEY (`switch2vlanid`),
  UNIQUE KEY `switchvlanunique` (`switchid`,`vlanid`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `switchport`
--

CREATE TABLE IF NOT EXISTS `switchport` (
  `switchportid` int(11) NOT NULL AUTO_INCREMENT,
  `switchid` int(11) NOT NULL,
  `portname` varchar(64) NOT NULL COMMENT 'Used as the look up index into the table with the switchid',
  `portdescription` varchar(64) DEFAULT NULL,
  `comment` text,
  PRIMARY KEY (`switchportid`),
  UNIQUE KEY `uniqueportid` (`switchid`,`portname`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `switchportstate`
--

CREATE TABLE IF NOT EXISTS `switchportstate` (
  `switchportid` int(11) NOT NULL DEFAULT '0',
  `macid` int(11) NOT NULL DEFAULT '0',
  `ip` varchar(15) NOT NULL DEFAULT '0',
  `lastupdate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `stateupdate` timestamp NULL DEFAULT NULL,
  `hostname` varchar(32) NOT NULL,
  `classid` int(11) NOT NULL DEFAULT '0',
  `templateid` int(11) NOT NULL DEFAULT '0',
  `vlangroupid` int(11) NOT NULL DEFAULT '0',
  `vlanid` int(11) NOT NULL DEFAULT '0',
  `vmacid` int(11) NOT NULL DEFAULT '0',
  `vip` varchar(15) NOT NULL DEFAULT '0',
  `vhostname` varchar(32) NOT NULL DEFAULT 'no-host',
  `vclassid` int(11) NOT NULL DEFAULT '0',
  `vtemplateid` int(11) NOT NULL DEFAULT '0',
  `vvlangroupid` int(11) NOT NULL DEFAULT '0',
  `vvlanid` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`switchportid`),
  KEY `lastupdate` (`lastupdate`),
  KEY `hostname` (`hostname`),
  KEY `classid` (`classid`),
  KEY `vlangroupid` (`vlangroupid`),
  KEY `vlanid` (`vlanid`),
  KEY `macid` (`macid`),
  KEY `ip` (`ip`),
  KEY `v_macid_idx` (`vmacid`),
  KEY `v_ip` (`vip`),
  KEY `v_hostname` (`vhostname`),
  KEY `v_classid` (`vclassid`),
  KEY `v_templateid` (`vtemplateid`),
  KEY `v_vlangroup` (`vvlangroupid`),
  KEY `v_vlan` (`vvlanid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `template`
--

CREATE TABLE IF NOT EXISTS `template` (
  `templateid` int(11) NOT NULL AUTO_INCREMENT,
  `templatename` varchar(32) NOT NULL,
  `templatedescription` varchar(128) DEFAULT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  `comment` text,
  PRIMARY KEY (`templateid`),
  UNIQUE KEY `templatename` (`templatename`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `template2vlangroup`
--

CREATE TABLE IF NOT EXISTS `template2vlangroup` (
  `template2vlangroupid` int(11) NOT NULL AUTO_INCREMENT,
  `templateid` int(11) NOT NULL,
  `vlangroupid` int(11) NOT NULL,
  `priority` smallint(4) NOT NULL,
  PRIMARY KEY (`template2vlangroupid`),
  UNIQUE KEY `unique` (`templateid`,`vlangroupid`),
  UNIQUE KEY `uniquepriority` (`templateid`,`priority`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE IF NOT EXISTS `users` (
  `userid` int(11) NOT NULL,
  `username` varchar(32) NOT NULL,
  `lastlogin` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `permissions` set('DB_PERM_ADMIN','DB_PERM_TECH','DB_PERM_GUEST','DB_PERM_CLASS_ADD','DB_PERM_CLASSMACPORT_GET','DB_PERM_CLASS_GET','DB_PERM_CLASS_REM','DB_PERM_CLASS_UPD','DB_PERM_DHCPS_GET','DB_PERM_EVENTLOG_GET','DB_PERM_EVENTLOG_REM','DB_PERM_LOCATION_ADD','DB_PERM_LOCATION_GET','DB_PERM_LOCATION_REM','DB_PERM_LOCATION_UPD','DB_PERM_MAC2CLASS_ADD','DB_PERM_MAC2CLASS_GET','DB_PERM_MAC2CLASS_REM','DB_PERM_MAC2CLASS_UPD','DB_PERM_MAC_ADD','DB_PERM_MAC_GET','DB_PERM_MAC_REM','DB_PERM_MAC_UPD','DB_PERM_PORT2CLASS_ADD','DB_PERM_PORT2CLASS_GET','DB_PERM_PORT2CLASS_REM','DB_PERM_PORT2CLASS_UPD','DB_PERM_RADIUSAUDIT_GET','DB_PERM_RADIUSAUDIT_REM','DB_PERM_SWITCH2VLAN_ADD','DB_PERM_SWITCH2VLAN_GET','DB_PERM_SWITCH2VLAN_REM','DB_PERM_SWITCH2VLAN_UPD','DB_PERM_SWITCHPORT_ADD','DB_PERM_SWITCHPORT_GET','DB_PERM_SWITCHPORT_REM','DB_PERM_SWITCHPORT_UPD','DB_PERM_SWITCHPORTSTATE_GET','DB_PERM_SWITCH_ADD','DB_PERM_SWITCH_GET','DB_PERM_SWITCH_REM','DB_PERM_SWITCH_UPD','DB_PERM_TEMPLATE2VLANGROUP_ADD','DB_PERM_TEMPLATE2VLANGROUP_GET','DB_PERM_TEMPLATE2VLANGROUP_REM','DB_PERM_TEMPLATE2VLANGROUP_UPD','DB_PERM_TEMPLATE_ADD','DB_PERM_TEMPLATE_GET','DB_PERM_TEMPLATE_REM','DB_PERM_TEMPLATE_UPD','DB_PERM_VLANGROUP2VLAN_ADD','DB_PERM_VLANGROUP2VLAN_GET','DB_PERM_VLANGROUP2VLAN_REM','DB_PERM_VLANGROUP2VLAN_UPD','DB_PERM_VLANGROUP_ADD','DB_PERM_VLANGROUP_GET','DB_PERM_VLANGROUP_REM','DB_PERM_VLANGROUP_UPD','DB_PERM_VLAN_GET','DB_PERM_VLAN_REM','DB_PERM_VLAN_UPD') DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `vlan`
--

CREATE TABLE IF NOT EXISTS `vlan` (
  `vlanid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `locationid` int(10) unsigned NOT NULL,
  `vlan` int(4) NOT NULL,
  `type` varchar(20) NOT NULL DEFAULT 'X',
  `cidr` varchar(20) DEFAULT '0.0.0.0/0',
  `nacip` varchar(15) DEFAULT NULL COMMENT 'Special Purpose IP address, NAC server will use to listen on',
  `vlanname` varchar(256) NOT NULL,
  `vlandescription` varchar(1024) DEFAULT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  `coe` tinyint(1) NOT NULL DEFAULT '0',
  `comment` text,
  PRIMARY KEY (`vlanid`),
  UNIQUE KEY `lvtc` (`locationid`,`vlan`,`type`,`cidr`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `vlangroup`
--

CREATE TABLE IF NOT EXISTS `vlangroup` (
  `vlangroupid` int(11) NOT NULL AUTO_INCREMENT,
  `vlangroupname` varchar(256) NOT NULL,
  `vlangroupdescription` varchar(1024) DEFAULT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  `comment` text,
  PRIMARY KEY (`vlangroupid`),
  UNIQUE KEY `vlangroupname` (`vlangroupname`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `vlangroup2vlan`
--

CREATE TABLE IF NOT EXISTS `vlangroup2vlan` (
  `vlangroup2vlanid` int(11) NOT NULL AUTO_INCREMENT,
  `vlangroupid` int(11) NOT NULL,
  `vlanid` int(11) NOT NULL,
  `priority` smallint(4) NOT NULL DEFAULT '0',
  PRIMARY KEY (`vlangroup2vlanid`),
  KEY `unique` (`vlangroupid`,`vlanid`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;

