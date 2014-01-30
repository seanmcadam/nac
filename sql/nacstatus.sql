
SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";

--
-- Database: `nacstatus`
--

-- --------------------------------------------------------

--
-- Table structure for table `host`
--

CREATE TABLE IF NOT EXISTS `host` (
  `hostname` varchar(64) NOT NULL,
  `lastseen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `slavecheckin` timestamp NULL DEFAULT NULL,
  `slavestatus` varchar(32) NOT NULL DEFAULT 'UNKNOWN',
  PRIMARY KEY (`hostname`)
) ENGINE=MEMORY DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `location`
--

CREATE TABLE IF NOT EXISTS `location` (
  `locationid` int(11) NOT NULL,
  `site` varchar(32) NOT NULL,
  `bldg` varchar(32) NOT NULL,
  `lastseen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `hostname` varchar(64) NOT NULL,
  PRIMARY KEY (`locationid`),
  UNIQUE KEY `sitebldg` (`site`,`bldg`)
) ENGINE=MEMORY DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `mac`
--

CREATE TABLE IF NOT EXISTS `mac` (
  `macid` int(11) NOT NULL,
  `mac` char(18) NOT NULL,
  `lastseen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `hostname` varchar(64) NOT NULL,
  PRIMARY KEY (`macid`),
  UNIQUE KEY `mac` (`mac`)
) ENGINE=MEMORY DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `switch`
--

CREATE TABLE IF NOT EXISTS `switch` (
  `switchid` int(11) NOT NULL,
  `switchname` varchar(64) NOT NULL,
  `locationid` int(11) NOT NULL,
  `lastseen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `hostname` varchar(64) NOT NULL,
  PRIMARY KEY (`switchid`,`hostname`)
) ENGINE=MEMORY DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `switchport`
--

CREATE TABLE IF NOT EXISTS `switchport` (
  `switchportid` int(11) NOT NULL,
  `lastseen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `hostname` varchar(64) NOT NULL,
  `locid` int(11) NOT NULL DEFAULT '0',
  `site` varchar(16) NOT NULL,
  `bldg` varchar(16) NOT NULL,
  `switchid` int(11) NOT NULL DEFAULT '0',
  `switchname` varchar(64) NOT NULL,
  `portname` varchar(32) NOT NULL,
  `ifindex` int(11) NOT NULL DEFAULT '0',
  `description` varchar(128) DEFAULT NULL,
  `operstatus` tinyint(4) NOT NULL DEFAULT '-1',
  `adminstatus` tinyint(4) NOT NULL DEFAULT '-1',
  `mabenabled` tinyint(4) NOT NULL DEFAULT '-1',
  `mabauthmethod` tinyint(4) NOT NULL DEFAULT '-1',
  `mabstate` tinyint(4) NOT NULL DEFAULT '-1',
  `mabauth` tinyint(4) NOT NULL DEFAULT '-1',
  PRIMARY KEY (`switchportid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

