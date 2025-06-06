-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: May 31, 2025 at 03:51 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `psycho_app`
--

-- --------------------------------------------------------

--
-- Table structure for table `alembic_version`
--

CREATE TABLE `alembic_version` (
  `version_num` varchar(32) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `appointments`
--

CREATE TABLE `appointments` (
  `id` int(11) NOT NULL,
  `psychologist_id` int(11) DEFAULT NULL,
  `patient_id` int(11) DEFAULT NULL,
  `datetime` datetime NOT NULL,
  `duration` int(11) DEFAULT 60,
  `notes` text DEFAULT NULL,
  `status` enum('scheduled','completed','cancelled') DEFAULT 'scheduled',
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `appointments`
--

INSERT INTO `appointments` (`id`, `psychologist_id`, `patient_id`, `datetime`, `duration`, `notes`, `status`, `created_at`) VALUES
(1, 2, 3, '2025-06-01 10:00:00', 60, 'First session', 'scheduled', '2025-05-28 17:11:22'),
(2, 2, 4, '2025-06-02 11:00:00', 60, 'Follow-up', 'scheduled', '2025-05-28 17:11:22');

-- --------------------------------------------------------

--
-- Table structure for table `assignments`
--

CREATE TABLE `assignments` (
  `id` int(11) NOT NULL,
  `psychologist_id` int(11) DEFAULT NULL,
  `patient_id` int(11) DEFAULT NULL,
  `assigned_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `assignments`
--

INSERT INTO `assignments` (`id`, `psychologist_id`, `patient_id`, `assigned_at`) VALUES
(1, 2, NULL, '2025-05-28 17:11:22'),
(2, 2, 4, '2025-05-28 17:11:22');

-- --------------------------------------------------------

--
-- Table structure for table `conversations`
--

CREATE TABLE `conversations` (
  `id` int(11) NOT NULL,
  `psychologist_id` int(11) DEFAULT NULL,
  `patient_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `conversations`
--

INSERT INTO `conversations` (`id`, `psychologist_id`, `patient_id`, `created_at`) VALUES
(1, 2, NULL, '2025-05-28 17:11:22');

-- --------------------------------------------------------

--
-- Table structure for table `messages`
--

CREATE TABLE `messages` (
  `id` int(11) NOT NULL,
  `conversation_id` int(11) NOT NULL,
  `sender_id` int(11) DEFAULT NULL,
  `content` text NOT NULL,
  `sent_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `messages`
--

INSERT INTO `messages` (`id`, `conversation_id`, `sender_id`, `content`, `sent_at`) VALUES
(1, 1, 2, 'Hello Bob, welcome to your first session!', '2025-05-28 17:11:22'),
(2, 1, NULL, 'Thank you, doctor.', '2025-05-28 17:11:22');

-- --------------------------------------------------------

--
-- Table structure for table `password_resets`
--

CREATE TABLE `password_resets` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `code` varchar(10) NOT NULL,
  `expires_at` datetime NOT NULL,
  `used` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `recordings`
--

CREATE TABLE `recordings` (
  `id` int(11) NOT NULL,
  `appointment_id` int(11) NOT NULL,
  `file_path` varchar(255) NOT NULL,
  `uploaded_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `recordings`
--

INSERT INTO `recordings` (`id`, `appointment_id`, `file_path`, `uploaded_at`) VALUES
(1, 1, 'recordings/session1_pat1.mp3', '2025-05-28 17:11:22');

-- --------------------------------------------------------

--
-- Table structure for table `user`
--

CREATE TABLE `user` (
  `id` int(11) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `role` enum('admin','psychologist','patient') NOT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `user`
--

INSERT INTO `user` (`id`, `email`, `password`, `name`, `role`, `created_at`) VALUES
(2, 'psy1@example.com', 'scrypt:32768:8:1$2ww4YAosAIQeWANl$ebc0b215e6da089e5f5e6dc087f815b45440900365547795f138d866c3ef83482746df0b1d46ab56a2982ddf56aef51e72dfeae5c0ff5405f6ddacb3b2af854d', 'Modified Psy', 'psychologist', '2025-05-28 17:11:22'),
(4, 'pat2@example.com', 'scrypt:32768:8:1$GIJ3USlrxcY1s4VI$fef8d973c504c86b33b3fcde17a8ccae5a578b3f6b07f3547f7a868ecca8b52c519e328d84fe563e0b49231ccecd9b39ba4b4f0fb7e63503b03173b1d153c367', 'Carol Patient', 'patient', '2025-05-28 17:11:22'),
(5, 'patient1@example.com', 'scrypt:32768:8:1$IMUi25k1uxJl5Jg0$686326960e1046b76945a2db5712ffe7d41d41aa4a55fca36b60ee35bc209edce98571664accffbfa4b76c476b9f07a31a03182f2e640ad5daf0fdab56b04287', 'Patient', 'patient', '2025-05-28 19:45:52'),
(7, 'admin@example.com', 'scrypt:32768:8:1$eIlma2ym7yw3HtrX$b24ce57be1930ae3979a0e05fa0709fe17a86611113738ba86cd879512273c9e44c54d532041f6ca1d8525f4135aa06e7c38a4cf06d085a8dfac6dff500c7bfa', 'Admin', 'admin', '2025-05-28 19:50:42'),
(8, 'psy@example.com', 'scrypt:32768:8:1$Naksa0hqUnA8wutq$3c3d35442a0b40b50ea8a99d8a3749f7a0614c3f6eca53ee9c180447b50169f65979dc33b1becc139539273e817bd815abc45d2474c54232f13860cca572268b', 'Psychologist', 'psychologist', '2025-05-28 19:52:02'),
(9, 'patient@example.com', 'scrypt:32768:8:1$QP6ASsgPtHwTDixI$bad942a10cd088c19f5d2e6a1d687854c8f7ac083cf1d48fdd1570637b5b41fdce7f843b016580c6b97271f51624ea76bbdbbffc8eb99d4e9b81ed2c624f96ef', 'Patient 2', 'patient', '2025-05-28 20:01:52'),
(10, 'psy2@example.com', 'scrypt:32768:8:1$NmFBU0ZlT6902U0C$6282e58c60e061aa569f0bb22968d9f4326d883be68c59d45aeaf2160cfaa1cc8e465d897c6897e0af327cac08a1db59e01fcfa1b7978859b409ac04ed180dd2', 'Psychologist 2', 'psychologist', '2025-05-28 20:05:16');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `alembic_version`
--
ALTER TABLE `alembic_version`
  ADD PRIMARY KEY (`version_num`);

--
-- Indexes for table `appointments`
--
ALTER TABLE `appointments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `psychologist_id` (`psychologist_id`),
  ADD KEY `patient_id` (`patient_id`);

--
-- Indexes for table `assignments`
--
ALTER TABLE `assignments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `assignments_ibfk_1` (`psychologist_id`),
  ADD KEY `assignments_ibfk_2` (`patient_id`);

--
-- Indexes for table `conversations`
--
ALTER TABLE `conversations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `conversations_ibfk_1` (`psychologist_id`),
  ADD KEY `conversations_ibfk_2` (`patient_id`);

--
-- Indexes for table `messages`
--
ALTER TABLE `messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `messages_ibfk_1` (`conversation_id`),
  ADD KEY `messages_ibfk_2` (`sender_id`);

--
-- Indexes for table `password_resets`
--
ALTER TABLE `password_resets`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `recordings`
--
ALTER TABLE `recordings`
  ADD PRIMARY KEY (`id`),
  ADD KEY `recordings_ibfk_1` (`appointment_id`);

--
-- Indexes for table `user`
--
ALTER TABLE `user`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `appointments`
--
ALTER TABLE `appointments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `assignments`
--
ALTER TABLE `assignments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `conversations`
--
ALTER TABLE `conversations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `messages`
--
ALTER TABLE `messages`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `password_resets`
--
ALTER TABLE `password_resets`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `recordings`
--
ALTER TABLE `recordings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `user`
--
ALTER TABLE `user`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `assignments`
--
ALTER TABLE `assignments`
  ADD CONSTRAINT `assignments_ibfk_1` FOREIGN KEY (`psychologist_id`) REFERENCES `user` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `assignments_ibfk_2` FOREIGN KEY (`patient_id`) REFERENCES `user` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `conversations`
--
ALTER TABLE `conversations`
  ADD CONSTRAINT `conversations_ibfk_1` FOREIGN KEY (`psychologist_id`) REFERENCES `user` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `conversations_ibfk_2` FOREIGN KEY (`patient_id`) REFERENCES `user` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `messages`
--
ALTER TABLE `messages`
  ADD CONSTRAINT `messages_ibfk_1` FOREIGN KEY (`conversation_id`) REFERENCES `conversations` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `messages_ibfk_2` FOREIGN KEY (`sender_id`) REFERENCES `user` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `password_resets`
--
ALTER TABLE `password_resets`
  ADD CONSTRAINT `password_resets_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`);

--
-- Constraints for table `recordings`
--
ALTER TABLE `recordings`
  ADD CONSTRAINT `recordings_ibfk_1` FOREIGN KEY (`appointment_id`) REFERENCES `appointments` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
