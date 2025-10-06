-- Création du schéma de production pour LogisticoTrain

USE `myrames-prod-db`;

-- Table Voie
CREATE TABLE IF NOT EXISTS `voie` (
  `num_voie` INT(11) NOT NULL,
  `interdite` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`num_voie`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table Rame
CREATE TABLE IF NOT EXISTS `rame` (
  `num_serie` VARCHAR(12) NOT NULL,
  `type_rame` VARCHAR(50) NOT NULL,
  `voie` INT(11) DEFAULT NULL,
  `conducteur_entrant` VARCHAR(50) NOT NULL,
  PRIMARY KEY (`num_serie`),
  UNIQUE KEY `voie_unique` (`voie`),
  CONSTRAINT `fk_rame_voie` FOREIGN KEY (`voie`) REFERENCES `voie` (`num_voie`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table Tache
CREATE TABLE IF NOT EXISTS `tache` (
  `num_serie_rame` VARCHAR(12) NOT NULL,
  `num_tache` INT(11) NOT NULL,
  `tache` TEXT NOT NULL,
  PRIMARY KEY (`num_serie_rame`, `num_tache`),
  CONSTRAINT `fk_tache_rame` FOREIGN KEY (`num_serie_rame`) REFERENCES `rame` (`num_serie`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Données de test (quelques voies)
INSERT INTO `voie` (`num_voie`, `interdite`) VALUES
(1, 0),
(2, 0),
(3, 0),
(4, 0),
(5, 0);
