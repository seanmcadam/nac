SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";

--
-- Database: `nacbuffer`
--

-- --------------------------------------------------------

--
-- Table structure for table `add_mac`
--

CREATE TABLE IF NOT EXISTS `add_mac` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `mac` char(18) NOT NULL,
  `lastseen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `mac` (`mac`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `add_radiusaudit`
--

CREATE TABLE IF NOT EXISTS `add_radiusaudit` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `macid` int(11) NOT NULL,
  `swpid` int(11) NOT NULL,
  `type` varchar(32) NOT NULL,
  `cause` varchar(32) DEFAULT NULL,
  `octetsin` int(16) NOT NULL DEFAULT '0',
  `octetsout` int(16) NOT NULL DEFAULT '0',
  `packetsin` int(11) NOT NULL DEFAULT '0',
  `packetsout` int(11) NOT NULL DEFAULT '0',
  `audittime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `add_switch`
--

CREATE TABLE IF NOT EXISTS `add_switch` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ip` varchar(16) NOT NULL,
  `lastseen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `mac` (`ip`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `add_switchport`
--

CREATE TABLE IF NOT EXISTS `add_switchport` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `switchid` int(11) NOT NULL,
  `portname` varchar(64) NOT NULL,
  `lastseen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `switch_portname` (`switchid`,`portname`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `eventlog`
--

CREATE TABLE IF NOT EXISTS `eventlog` (
  `eventlogid` int(11) NOT NULL AUTO_INCREMENT,
  `eventtime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `eventtype` enum('EVENT_START','EVENT_STOP','EVENT_ACCT_STOP','EVENT_ACCT_START','EVENT_AUTH_CLEAR','EVENT_AUTH_BLOCK','EVENT_AUTH_CHALLENGE','EVENT_AUTH_GUEST','EVENT_AUTH_MAC','EVENT_AUTH_PORT','EVENT_AUTH_VOICE','EVENT_AUTH_NAK','EVENT_CHALLENGE_ERR','EVENT_CIDR_ADD','EVENT_CIDR_DEL','EVENT_CLASS_ADD','EVENT_CLASS_DEL','EVENT_CLASS_UPD','EVENT_DB_ERR','EVENT_DB_WARN','EVENT_FILTER_ADD','EVENT_FILTER_DEL','EVENT_FIXEDIP_ADD','EVENT_FIXEDIP_DEL','EVENT_FIXEDIP_UPD','EVENT_MAC2CLASS_ADD','EVENT_MAC2CLASS_DEL','EVENT_MAC2CLASS_UPD','EVENT_MAC_ADD','EVENT_MAC_DEL','EVENT_MAC_UPD','EVENT_MAGIC_PORT','EVENT_MEMCACHE_ERR','EVENT_MEMCACHE_WARN','EVENT_LOC_ADD','EVENT_LOC_DEL','EVENT_LOC_UPD','EVENT_PORT_ADD','EVENT_PORT_DEL','EVENT_PORT2CLASS_ADD','EVENT_PORT2CLASS_DEL','EVENT_PORT2CLASS_UPD','EVENT_SWITCH_ADD','EVENT_SWITCH_DEL','EVENT_SWITCH_UPD','EVENT_SWITCHPORT_ADD','EVENT_SWITCHPORT_DEL','EVENT_SWITCH2VLAN_ADD','EVENT_SWITCH2VLAN_DEL','EVENT_TEMPLATE_ADD','EVENT_TEMPLATE_DEL','EVENT_TEMPLATE2VLANGROUP_ADD','EVENT_TEMPLATE2VLANGROUP_DEL','EVENT_VLAN_ADD','EVENT_VLAN_DEL','EVENT_VLANGROUP_ADD','EVENT_VLANGROUP_DEL','EVENT_VLANGROUP2VLAN_ADD','EVENT_VLANGROUP2VLAN_DEL','EVENT_NOLOCATION','EVENT_SMTP_FAIL','EVENT_LOGIC_FAIL','EVENT_EVAL_FAIL','EVENT_FUNC_FAIL','EVENT_ERR','EVENT_WARN','EVENT_NOTICE','EVENT_INFO','EVENT_DEBUG','EVENT_FATAL','EVENT_DISTRESS') NOT NULL,
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
  PRIMARY KEY (`eventlogid`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `lastseen_location`
--

CREATE TABLE IF NOT EXISTS `lastseen_location` (
  `locid` int(11) NOT NULL,
  `lastseen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`locid`)
) ENGINE=MEMORY DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `lastseen_mac`
--

CREATE TABLE IF NOT EXISTS `lastseen_mac` (
  `macid` int(11) NOT NULL,
  `mac` char(18) NOT NULL,
  `lastseen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`macid`)
) ENGINE=MEMORY DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `lastseen_switch`
--

CREATE TABLE IF NOT EXISTS `lastseen_switch` (
  `switchid` int(11) NOT NULL,
  `switchname` varchar(64) NOT NULL,
  `lastseen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`switchid`)
) ENGINE=MEMORY DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `lastseen_switchport`
--

CREATE TABLE IF NOT EXISTS `lastseen_switchport` (
  `switchportid` int(11) NOT NULL,
  `switchport` varchar(64) NOT NULL,
  `lastseen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`switchportid`)
) ENGINE=MEMORY DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `switchportstate`
--

CREATE TABLE IF NOT EXISTS `switchportstate` (
  `switchportid` int(11) NOT NULL DEFAULT '0',
  `macid` int(11) NOT NULL DEFAULT '0',
  `mac` char(18) DEFAULT NULL,
  `ip` varchar(15) NOT NULL DEFAULT '0',
  `lastupdate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `classid` int(11) NOT NULL DEFAULT '0',
  `templateid` int(11) NOT NULL DEFAULT '0',
  `vlangroupid` int(11) NOT NULL DEFAULT '0',
  `vlanid` int(11) NOT NULL DEFAULT '0',
  `vmacid` int(11) NOT NULL DEFAULT '0',
  `vmac` char(18) DEFAULT NULL,
  `vip` varchar(15) NOT NULL DEFAULT '0',
  `vclassid` int(11) NOT NULL DEFAULT '0',
  `vtemplateid` int(11) NOT NULL DEFAULT '0',
  `vvlangroupid` int(11) NOT NULL DEFAULT '0',
  `vvlanid` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`switchportid`),
  KEY `lastupdate` (`lastupdate`)
) ENGINE=MEMORY DEFAULT CHARSET=latin1;

