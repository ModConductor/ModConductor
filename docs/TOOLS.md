# Run a tool

In **Tools**, add an executable. Set its name, executable path, arguments,
working directory and runtime. Save does not start the program. Select **Run**
to start it.

## Runtime

- **Native** starts the supplied executable on the host.
- **Wine** uses the selected profile's checked Wine executable and prefix on
  Linux. Select a Wine context for the profile's non-Steam installation first.
- **Proton** uses the selected profile's checked Proton context on Linux.

A route with a missing context returns a configuration problem before a process
starts. Choosing Native does not select Wine because a filename ends in `.exe`.
Tools must have the dependencies required by their chosen runtime.

The tool retains its own GUI and batch options. MC does not insert tool flags,
select outfits or patches, or answer installer questions.

## Arguments and folders

Each argument is one value. Spaces, quotes and shell characters remain part of
that value; MC does not run a shell expression.

Two optional placeholders are available in arguments:

- `{game}` is the selected profile's deployed game folder, not its `Data` folder.
  Deploy the profile before using it. Append `/Data` or another suffix if the
  tool requires that input directory.
- `{output}` is the configured owned output folder. Select an output folder
  before using this placeholder.

Native arguments use host paths. Wine and Proton arguments use the checked
prefix's Windows drive mappings. The executable and working-directory fields
remain host paths.

Select **None** if the tool needs no owned output. Otherwise, select a folder
label. That label resolves to separate storage in each profile and installation
context. Two registrations that select the same label in the same context use
that same folder.

The folder appears as a generated mod at the initial highest priority. Later
runs preserve its enablement and priority. Run does not clear the folder, copy
its contents, or save a new output version. The tool controls its own state and
obsolete-file cleanup. Preparing a deployment captures the current enabled
output. **Play** also prepares a fresh deployment before the game starts. Saved
deployments can retain earlier captured files.

## Process results and external writes

MC reports process state and the recorded exit code. A closed process or zero
exit is not proof that the tool completed every requested task. Partial output
can remain after an error or tool-side cancellation. Use the existing output
view to inspect the files that are present.

**Stop waiting** stops tracking. It does not stop the program. Closing MC also
does not stop an already launched tool.

Execution uses the user's account; it is not a sandbox. MC does not copy an
external executable's parent folder or redirect arbitrary writes. Use a supplied
writable tool folder when the program writes settings, presets, caches or logs
beside its executable. Configure its input and output locations correctly. A
tool can still change files that its own configuration permits it to write.
