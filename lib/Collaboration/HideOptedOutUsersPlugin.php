<?php

declare(strict_types=1);

namespace OCA\AutocompleteSettings\Collaboration;

use OCA\AutocompleteSettings\AppInfo\Application;
use OCP\Collaboration\Collaborators\ISearchPlugin;
use OCP\Collaboration\Collaborators\ISearchResult;
use OCP\Collaboration\Collaborators\SearchResultType;
use OCP\Config\IUserConfig;
use OCP\Config\ValueType;

/**
 * Removes users that opted out of autocomplete from the fuzzy user matches.
 *
 * Core registers its own user plugins before any app plugin, so this runs on the
 * already collected results. Exact matches (full user id, display name or email)
 * are kept, so opted-out users can still be found by typing their exact name.
 */
class HideOptedOutUsersPlugin implements ISearchPlugin {
	public function __construct(
		private readonly IUserConfig $userConfig,
	) {
	}

	/**
	 * Parameters are untyped on purpose: ISearchPlugin::search() only has typed
	 * parameters from Nextcloud 35 on, and typing them here breaks Nextcloud 33/34.
	 *
	 * @param string $search
	 * @param int $limit
	 * @param int $offset
	 */
	#[\Override]
	public function search($search, $limit, $offset, ISearchResult $searchResult): bool {
		$userType = new SearchResultType('users');
		/** @var array{users?: list<array{value: array{shareWith: array-key}}>, exact: array{users?: list<array>}} $results */
		$results = $searchResult->asArray();
		$fuzzyMatches = $results['users'] ?? [];
		if ($fuzzyMatches === []) {
			return false;
		}

		$userIds = array_map(static fn (array $match): string => (string)$match['value']['shareWith'], $fuzzyMatches);
		$optedOut = array_filter($this->userConfig->getValuesByUsers(
			Application::PREFERENCE_APP,
			Application::PREFERENCE_KEY,
			ValueType::BOOL,
			$userIds,
		));
		if ($optedOut === []) {
			return false;
		}

		$search = mb_strtolower(trim($search));
		$visibleMatches = array_values(array_filter(
			$fuzzyMatches,
			static function (array $match) use ($optedOut, $search): bool {
				$userId = (string)$match['value']['shareWith'];
				return !isset($optedOut[$userId]) || mb_strtolower($userId) === $search;
			},
		));

		$exactMatches = $results['exact']['users'] ?? [];
		$searchResult->unsetResult($userType);
		$searchResult->addResultSet($userType, $visibleMatches, $exactMatches);

		return false;
	}
}
