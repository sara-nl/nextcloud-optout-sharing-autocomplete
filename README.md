<!--
  - SPDX-FileCopyrightText: 2025 Autocomplete Settings contributors
  - SPDX-License-Identifier: AGPL-3.0-or-later
-->
# Nextcloud Opt Out for Share AutoComplete

This app allow users to opt-out of autocomplete, where some users do not want to be found via autocomplete suggestions.
When a user has opted out of autocomplete, they no longer show up when other users type part of their name in the share dialog or when mentioning someone in a comment.
The full user name (or exact display name or email address) must be entered to share, or the personal address book must be consulted.

![HelplinksAdminInterface.png](https://github.com/T0mWz/nextcloud-optout-sharing-autocomplete/raw/main/docs/OptOut_for_sharing_autocomplete.png)

Supported Nextcloud versions: 33 – 35.

### Technically

The preference is stored as a user setting:

```
sudo -u www-data php occ user:setting <UserID> files_sharing exclude_user_from_autocomplete true
```

The app registers a collaborator search plugin (see `appinfo/info.xml`) that runs after the Nextcloud user search
and removes opted-out users from the partial matches. Exact matches are kept.
This applies to every feature that uses the Nextcloud collaborator search, such as the share dialog and @mentions in comments.

### Releasing

Releases are published to the [Nextcloud App Store](https://apps.nextcloud.com/apps/autocomplete_settings) by the Release workflow:

1. Set the new version in `appinfo/info.xml` and `package.json`, and describe the changes in `CHANGELOG.md`.
2. Merge to `main` and check that the tests are green.
3. Publish a GitHub release with the tag `v<version>`, for example `v2.0.1`, and approve the `appstore` deployment
   within 30 days. After that the built app has expired and the workflow has to be run again.

The workflow builds the app in a job without secrets. A second job signs it with the app's code signing certificate,
attaches the tarball to the GitHub release and publishes it to the App Store.

- A pre-release is signed and attached, but not published to the App Store. To publish it later, remove the tarball
  from the release, turn the release into a draft, untick "Set as a pre-release" and publish it again.
  Only unticking it does not start the workflow.
- If a run fails after the tarball was attached, re-run the failed jobs: the attached tarball is reused, not replaced,
  so a signature the App Store already has stays valid.
- A tarball that was attached by hand, or by another run, is never signed or published. The workflow stops then:
  remove the tarball from the release and re-run the workflow.
- Keep "immutable releases" off in the repository settings, because the tarball is attached after the release was published.

#### One-time setup

1. Request the code signing certificate for `autocomplete_settings` at [nextcloud/app-certificate-requests](https://github.com/nextcloud/app-certificate-requests),
   and keep `autocomplete_settings.key` safe outside the repository.
2. Register the app on the [App Store](https://apps.nextcloud.com/developer/apps/new) with the certificate and a signature of the app id:
   `echo -n "autocomplete_settings" | openssl dgst -sha512 -sign autocomplete_settings.key | openssl base64`.
   Then create an API token in your App Store account.
3. In the GitHub repository, create the environment `appstore` (Settings → Environments). Add required reviewers,
   limit its deployment tags to `v*`, and add these secrets to it:
   - `APP_PRIVATE_KEY`: the private key of the code signing certificate (`autocomplete_settings.key`)
   - `APP_PUBLIC_CRT`: the certificate Nextcloud issued for it (`autocomplete_settings.crt`)
   - `APPSTORE_TOKEN`: the API token of the App Store account that owns the app
4. Protect the release tags with a tag ruleset for `v*` (Settings → Rules → Rulesets), so only maintainers can create them.
   The workflow that runs is the one in the tagged commit, so the tag decides which code gets the signing key.

To build a release by hand, see [docs/BuildApp.md](docs/BuildApp.md). The tarball still has to be signed with `occ integrity:sign-app`.

### Tests

The tests run against a real Nextcloud, using the official Docker image:

```
npm ci && npm run build
make test nc=35
```

`tests/e2e/e2e.sh` can also run against an existing test server over SSH, see the comment at the top of the script.
GitHub Actions runs the tests on Nextcloud 33, 34 and 35 for every pull request, and monthly against the newest Nextcloud release. The monthly run also checks the code with psalm against the API of the next Nextcloud version.

### Upgrading from 1.0.x

Version 1.0.x needed a patch to `apps/files_sharing`. That is no longer needed, the app now filters the results itself.
An existing patch does no harm and disappears with the next Nextcloud upgrade.