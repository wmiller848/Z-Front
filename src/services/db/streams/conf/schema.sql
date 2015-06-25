# Nodes
# ------------------------------------------------------------

DROP TABLE IF EXISTS `nodes`;

CREATE TABLE `nodes` (
  `uuid` varchar(64) NOT NULL DEFAULT '',
  `date` date DEFAULT NULL,
  PRIMARY KEY (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;



# Products
# ------------------------------------------------------------

DROP TABLE IF EXISTS `products`;

CREATE TABLE `products` (
  `uuid` varchar(64) NOT NULL DEFAULT '',
  `node_uuid` varchar(64) NOT NULL DEFAULT '',
  `producer_uuid` varchar(64) NOT NULL,
  `product_name` varchar(300) DEFAULT '"unknown"',
  `description` varchar(2000) DEFAULT '"not available"',
  PRIMARY KEY (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
