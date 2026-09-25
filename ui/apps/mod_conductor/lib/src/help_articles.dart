part of 'app.dart';

enum _HelpSection { diagnostics, faq, guides }

class _HelpArticle {
  const _HelpArticle(
    this.id,
    this.title,
    this.topic,
    this.paragraphs, [
    this.steps = const [],
  ]);
  final String id, title, topic;
  final List<String> paragraphs, steps;
}

const _faqArticles = [
  _HelpArticle(
    'play',
    'What happens when I select Play?',
    'Profile and game files',
    [
      'Mod Conductor applies the selected profile files and deployment before it starts the game.',
      'A failed check stops the launch and keeps the problem visible.',
    ],
  ),
  _HelpArticle(
    'versions',
    'Does Mod Conductor change my original mod files?',
    'Saved mod versions',
    [
      'Mod Conductor stores immutable mod versions.',
      'A file edit creates a new version and keeps the original version.',
    ],
  ),
  _HelpArticle(
    'archives',
    'Which archive files can I browse?',
    'BSA and BA2 files',
    [
      'Mod Conductor can browse selected BSA and BA2 files.',
      'Support depends on the archive version and compression format.',
    ],
  ),
  _HelpArticle(
    'cloud',
    'Does Mod Conductor change Steam Cloud data?',
    'Local save files',
    [
      'Mod Conductor does not change Steam Cloud data.',
      'Save tools only use qualified local save paths.',
    ],
  ),
];

const _guideArticles = [
  _HelpArticle(
    'first-skyrim-workspace',
    'Set up your first Skyrim workspace',
    'Workspace',
    [
      'Start a workspace, create a profile, and then check the Skyrim components for that profile.',
    ],
    [
      'Create a workspace or open a workspace.',
      'Create a profile.',
      'Open Skyrim setup.',
    ],
  ),
  _HelpArticle(
    'add-mod',
    'Add a mod from an archive',
    'Mods',
    ['Use a supported archive file from a source that you trust.'],
    [
      'Open Mods.',
      'Select Add mod.',
      'Choose a supported archive file.',
      'Check the mod files.',
      'Select Add mod.',
    ],
  ),
  _HelpArticle('recover', 'Continue a deployment restore', 'Diagnostics', [], [
    'Preview the affected paths.',
    'Continue the restore.',
  ]),
  _HelpArticle('conflict', 'Resolve a file conflict', 'Diagnostics', [], [
    'Preview the change.',
    'Apply the change.',
  ]),
  _HelpArticle(
    'profile',
    'Change the active profile',
    'Profiles',
    ['A profile keeps its own saved mod order and private game files.'],
    [
      'Select the profile name in the workspace header.',
      'Select another profile.',
      'Check the deployment status.',
      'When the deployment is ready, select Play.',
    ],
  ),
];
