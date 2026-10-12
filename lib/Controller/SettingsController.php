<?php

declare(strict_types=1);

namespace OCA\AutocompleteSettings\Controller;

use OCA\AutocompleteSettings\AppInfo\Application;
use OCP\AppFramework\Controller;
use OCP\AppFramework\Http;
use OCP\AppFramework\Http\Attribute\FrontpageRoute;
use OCP\AppFramework\Http\Attribute\NoAdminRequired;
use OCP\AppFramework\Http\JSONResponse;
use OCP\Config\IUserConfig;
use OCP\IRequest;
use OCP\IUserSession;

class SettingsController extends Controller {
	public function __construct(
		string $appName,
		IRequest $request,
		private readonly IUserConfig $userConfig,
		private readonly IUserSession $userSession,
	) {
		parent::__construct($appName, $request);
	}

	#[NoAdminRequired]
	#[FrontpageRoute(verb: 'GET', url: '/settings/preference')]
	public function getPreference(): JSONResponse {
		$user = $this->userSession->getUser();
		if ($user === null) {
			return new JSONResponse(['error' => 'User not logged in'], Http::STATUS_UNAUTHORIZED);
		}

		$value = $this->userConfig->getValueBool(
			$user->getUID(),
			Application::PREFERENCE_APP,
			Application::PREFERENCE_KEY,
		);

		return new JSONResponse([
			'value' => $value,
		]);
	}

	#[NoAdminRequired]
	#[FrontpageRoute(verb: 'POST', url: '/settings/preference')]
	public function setPreference(bool $value): JSONResponse {
		$user = $this->userSession->getUser();
		if ($user === null) {
			return new JSONResponse(['error' => 'User not logged in'], Http::STATUS_UNAUTHORIZED);
		}

		$this->userConfig->setValueBool(
			$user->getUID(),
			Application::PREFERENCE_APP,
			Application::PREFERENCE_KEY,
			$value,
		);

		return new JSONResponse([
			'success' => true,
			'value' => $value,
		]);
	}
}
