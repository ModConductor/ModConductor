# Thunderstore packages

Open a workspace, then select **Discover**. No game or profile is required.
The first supported community is Valheim.

Search packages, choose a sort order, and load more results as needed. Select a
package to see its versions, description, deprecation state and required
packages. **Add to library** adds the selected version and its exact required
versions. It does not select newer dependency versions.

Packages enter the workspace mod library. Their archive paths stay intact,
including `plugins/` and `BepInExPack_Valheim/`. This flow does not configure a
Valheim installation, map loader files, enable mods or deploy files to a game.
Valheim deployment and launch support are separate work.

Existing package versions remain in the library. Adding a different version
creates another library entry; it does not replace a pinned version. The details
show installed versions and whether the latest package version is present.

**Cancel** stops the current acquisition. A current download is paused through
the download service. Packages that completed installation stay in the library.
An unavailable version, unavailable dependency or conflicting exact requirement
stops acquisition before payload downloads. A provider request limit retains its
`Retry-After` time when supplied. Try again after that time. Payload download
retries and interruption handling use the existing download service.

## Provider contract

The engine uses the public Cyberstorm API, not the deprecated bulk experimental
package index. Routes are relative to
`https://thunderstore.io/api/cyberstorm/`:

- `listing/valheim/?q=...&ordering=...&page=...&deprecated=true` returns a page.
- `listing/valheim/{namespace}/{name}/` returns current package details.
- `listing/valheim/{namespace}/{name}/v/{version}/` returns the selected download
  and dependencies. Its `latest_version_number` still means package latest,
  **not** selected version.
- `package/{namespace}/{name}/versions/` returns exact available version choices.
- `package/{namespace}/{name}/v/{version}/dependencies/?page=...` supplies remaining
  dependency pages when details contain only part of the dependency list.

The reader follows page numbers, validates complete dependency counts and caches
one metadata response for its provider-declared lifetime. It does not fetch or
retain a bulk catalogue. Provider identities include community, namespace, name
and exact version. Download, library and portable-profile metadata keep those
identities separate from Nexus file identities.

The current contract was inspected in the
[Thunderstore server source](https://github.com/thunderstore-io/Thunderstore/tree/19507a16acea302f7472ada6fe420d8d525dbef9/django/thunderstore/api/cyberstorm).
The qualification uses Jotunn 2.30.2 and its declared BepInExPack_Valheim 5.4.2333
requirement, not BepInExPack_Valheim latest 5.4.2351.

## Permissions and limits

Public API access is not a licence to redistribute packages. MC downloads the
selected author packages for the user. It does not mirror packages, upload files,
write accounts, submit ratings or publish remote profile codes.

[Jotunn v2.30.2](https://github.com/Valheim-Modding/Jotunn/blob/v2.30.2/LICENSE)
and [BepInEx v5.4.23.3](https://github.com/BepInEx/BepInEx/blob/v5.4.23.3/LICENSE)
use MIT terms. Other bundled components retain their own terms. The downloaded
packages do not contain a blanket licence for all their bundled files.
[Thunderstore rules](https://wiki.thunderstore.io/moderation/global-rules) do not permit
unauthorised reuploads. A separate API service-terms document was not located in
the bounded qualification. No fixed request quota is assumed; the client respects
actual provider responses.
