<template>
	<div id="autocomplete_settings">
		<h2>{{ t('autocomplete_settings', 'Autocomplete visibility') }}</h2>
		<p>{{ t('autocomplete_settings', 'Control your visibility in autocomplete suggestions') }}</p>
		<NcCheckboxRadioSwitch
			class="autocomplete-switch-wrapper"
			:modelValue="optedOut"
			:disabled="saving"
			type="switch"
			@update:modelValue="savePreference">
			{{ t('autocomplete_settings', 'Hide from autocomplete suggestions') }}
		</NcCheckboxRadioSwitch>
		<p class="settings-hint">
			{{ t('autocomplete_settings', 'When enabled, your account will not appear in autocomplete suggestions, for example when other users share files or folders or mention someone in a comment. Users can still find you by typing your exact username.') }}
		</p>

		<p v-if="saving" class="autocomplete-hint">
			{{ t('autocomplete_settings', 'Saving…') }}
		</p>

		<NcNoteCard v-if="error" type="error">
			{{ error }}
		</NcNoteCard>
	</div>
</template>

<script>
import axios from '@nextcloud/axios'
import { showError, showSuccess } from '@nextcloud/dialogs'
import { loadState } from '@nextcloud/initial-state'
import { translate as t } from '@nextcloud/l10n'
import { generateUrl } from '@nextcloud/router'
import { ref } from 'vue'
import NcCheckboxRadioSwitch from '@nextcloud/vue/components/NcCheckboxRadioSwitch'
import NcNoteCard from '@nextcloud/vue/components/NcNoteCard'

export default {
	name: 'AutocompleteSettings',
	components: {
		NcCheckboxRadioSwitch,
		NcNoteCard,
	},

	setup() {
		const optedOut = ref(loadState('autocomplete_settings', 'exclude_user_from_autocomplete', false) === true)
		const saving = ref(false)
		const error = ref('')

		const savePreference = async (newValue) => {
			const previousValue = optedOut.value
			optedOut.value = newValue
			saving.value = true
			error.value = ''

			try {
				await axios.post(generateUrl('/apps/autocomplete_settings/settings/preference'), {
					value: newValue,
				})
				showSuccess(t('autocomplete_settings', 'Autocomplete preference updated'))
			} catch {
				error.value = t('autocomplete_settings', 'Failed to save preference. Please try again.')
				showError(t('autocomplete_settings', 'Failed to save autocomplete preference'))
				// Revert the toggle on error
				optedOut.value = previousValue
			} finally {
				saving.value = false
			}
		}

		return {
			optedOut,
			saving,
			error,
			savePreference,
			t,
		}
	},
}
</script>

<style lang="scss" scoped>
.settings-hint {
	color: var(--color-text-maxcontrast);
	margin-top: 8px;
	margin-bottom: 10px;
	margin-inline-start: 30px;
}
</style>
