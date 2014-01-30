SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";

--
-- Database: `nacconfig`
--

-- --------------------------------------------------------

--
-- Table structure for table `config`
--

CREATE TABLE IF NOT EXISTS `config` (
  `configid` int(11) NOT NULL AUTO_INCREMENT,
  `hostname` varchar(64) DEFAULT NULL,
  `name` varchar(64) NOT NULL,
  `value` varchar(64) NOT NULL,
  PRIMARY KEY (`configid`),
  UNIQUE KEY `hostname_name_unique` (`hostname`,`name`),
  KEY `hostname` (`hostname`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;

