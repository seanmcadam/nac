--
-- Database: `nacaudit`
--
-- 
-- Examples for the CLASS table
-- 
--
-- Table structure for table `class`
--
-- 
-- CREATE TABLE IF NOT EXISTS `class` (
--   `classid` int(11) NOT NULL auto_increment COMMENT 'mac type id',
--   `name` varchar(64) NOT NULL COMMENT 'Mac type Name',
--   `ibfilter` enum('N','B','C','G','A') NOT NULL default 'N',
--   `priority` smallint(6) NOT NULL default '0' COMMENT 'priority assigned to this class',
--   `reauthtime` mediumint(5) NOT NULL default '3600',
--   `idletimeout` mediumint(5) NOT NULL default '3600',
--   `vlangroupid` int(11) default NULL,
--   `active` tinyint(1) NOT NULL default '1',
--   `locked` tinyint(1) NOT NULL default '0',
--   `comment` text,
--   PRIMARY KEY  (`classid`),
--   UNIQUE KEY `name` (`name`)
-- ) ENGINE=MyISAM  DEFAULT CHARSET=latin1 AUTO_INCREMENT=18 ;
-- 
--
-- Dumping data for table `class`
--

INSERT INTO `class` 
( `name`,  `priority`, `reauthtime`, `idletimeout`, `vlangroupid`, `active`, `locked`, `comment`) 
VALUES
('BLOCKEDMAC',   100, 3600,  3600, NULL, 1, 0, 'Uses vlangroup "BLOCK"'),
('FIXEDPORTTYPE', 90, 3600,  3600, NULL, 1, 0, 'Relies on vlanid in port2class'),
('RESERVEDIP',    80, 7200, 21000, NULL, 1, 0, 'Records pulled directly from Infoblox, these should not be updated by hand'),
('MAC2VLANID',    55, 3600,  3600, NULL, 1, 0, 'MAC2VLANID uses specific mac2class records to determine which VlanGroup to use'),
('MAC2VLANGROUP', 50, 3600,  3600, NULL, 1, 0, 'MAC2VLANGROUP uses specific mac2class records to determine which VlanGroup to use'),
('GUEST',         70, 3600,  3600, NULL, 1, 0, 'VlanGroup standard Guest'),
('COE',           20, 3600,  3600, NULL, 1, 0, 'Generic Catch all for COE MACs'),
('STATICMACVLAN',  5, 3600,  3600, NULL, 1, 0, 'Fall Back for Known MACs manually loaded. This is a temporary class while we transition into NAC.'),
('GUESTFALLBACK', 10, 3600,  3600, NULL, 1, 0, 'Fall back VLAN for Public Spaces, Associated with PORTs'),
('TEMPLATE',      45, 3600,  3600, NULL, 1, 0, 'Psudo Class for marking Templates in mac2class records'),
('MAC2TEMPLATE',  45, 3600,  3600, NULL, 1, 0, ''),
('MAC2VLAN',      55, 3600,  3600, NULL, 1, 0, ''),
('CHALLENGE',      1,  300,   600, NULL, 1, 0, 'The last Class to be checked, the default for unknown, or the default for all else has Failed for a MAC'),
;
