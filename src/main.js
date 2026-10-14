/**
 * SPDX-FileCopyrightText: 2025 Autocomplete Settings contributors
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import { translate, translatePlural } from '@nextcloud/l10n'
import { createApp } from 'vue'
import AutocompleteSettings from './AutocompleteSettings.vue'

const app = createApp(AutocompleteSettings)

// Make translation functions available globally
app.config.globalProperties.t = translate
app.config.globalProperties.n = translatePlural

app.mount('#autocomplete-settings-app')
