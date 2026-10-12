<?php

declare(strict_types=1);

namespace OCA\AutocompleteSettings\AppInfo;

use OCP\AppFramework\App;
use OCP\AppFramework\Bootstrap\IBootContext;
use OCP\AppFramework\Bootstrap\IBootstrap;
use OCP\AppFramework\Bootstrap\IRegistrationContext;

class Application extends App implements IBootstrap {
	public const APP_ID = 'autocomplete_settings';

	// The preference is stored under files_sharing for compatibility with existing installations
	public const PREFERENCE_APP = 'files_sharing';
	public const PREFERENCE_KEY = 'exclude_user_from_autocomplete';

	public function __construct() {
		parent::__construct(self::APP_ID);
	}

	#[\Override]
	public function register(IRegistrationContext $context): void {
		// The collaborator search plugin is registered in appinfo/info.xml
	}

	#[\Override]
	public function boot(IBootContext $context): void {
	}
}
