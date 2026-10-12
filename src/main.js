import { translate, translatePlural } from '@nextcloud/l10n'
import { createApp } from 'vue'
import AutocompleteSettings from './AutocompleteSettings.vue'

const app = createApp(AutocompleteSettings)

// Make translation functions available globally
app.config.globalProperties.t = translate
app.config.globalProperties.n = translatePlural

app.mount('#autocomplete-settings-app')
