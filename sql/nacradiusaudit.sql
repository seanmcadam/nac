
SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";

--
-- Database: `nacradiusaudit`
--

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
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;

