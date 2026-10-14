<!--
  - SPDX-FileCopyrightText: 2026 Autocomplete Settings contributors
  - SPDX-License-Identifier: AGPL-3.0-or-later
-->
# Changelog

All notable changes to this app are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## 2.0.0 - 2026-10-12

### Changed

- No patch to Nextcloud is needed anymore. The app now removes opted-out users from the search results itself.
  Exact matches (full user id, display name or email) are still shown.
- Opted-out users are now also hidden from @mention suggestions in comments.
- Supports Nextcloud 33 – 35 and PHP 8.2 and later.
- The JavaScript is about half the size.

### Fixed

- The settings switch can be saved again after a failed save.
- The personal settings no longer crash when nobody is logged in.

## 1.0.1 - 2026-06-05

### Changed

- Supports Nextcloud 33.

## 1.0.0 - 2025-12-10

### Added

- Users can hide themselves from autocomplete suggestions in the share dialog, under Personal settings → Sharing.
