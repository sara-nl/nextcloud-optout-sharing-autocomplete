<?php

declare(strict_types=1);

namespace OCA\AutocompleteSettings\Settings;

use OCA\AutocompleteSettings\AppInfo\Application;
use OCP\AppFramework\Http\TemplateResponse;
use OCP\AppFramework\Services\IInitialState;
use OCP\Config\IUserConfig;
use OCP\IUserSession;
use OCP\Settings\ISettings;
use OCP\Util;

class Personal implements ISettings {
	public function __construct(
		private readonly IInitialState $initialState,
		private readonly IUserConfig $userConfig,
		private readonly IUserSession $userSession,
	) {
	}

	#[\Override]
	public function getForm(): TemplateResponse {
		$user = $this->userSession->getUser();
		$excludeAutocomplete = $user !== null && $this->userConfig->getValueBool(
			$user->getUID(),
			Application::PREFERENCE_APP,
			Application::PREFERENCE_KEY,
		);

		$this->initialState->provideInitialState(Application::PREFERENCE_KEY, $excludeAutocomplete);

		Util::addScript(Application::APP_ID, 'autocomplete_settings-main');
		Util::addStyle(Application::APP_ID, 'autocomplete_settings-main');

		return new TemplateResponse(Application::APP_ID, 'settings-personal');
	}

	/**
	 * @return string the section ID (e.g. 'sharing')
	 */
	#[\Override]
	public function getSection(): string {
		return 'sharing';
	}

	/**
	 * @return int priority (lower is higher in the list)
	 */
	#[\Override]
	public function getPriority(): int {
		return 50;
	}
}
