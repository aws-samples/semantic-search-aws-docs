oclif-hello-world
=================

oclif example Hello World CLI

[![oclif](https://img.shields.io/badge/cli-oclif-brightgreen.svg)](https://oclif.io)
[![Version](https://img.shields.io/npm/v/oclif-hello-world.svg)](https://npmjs.org/package/oclif-hello-world)
[![CircleCI](https://circleci.com/gh/oclif/hello-world/tree/main.svg?style=shield)](https://circleci.com/gh/oclif/hello-world/tree/main)
[![Downloads/week](https://img.shields.io/npm/dw/oclif-hello-world.svg)](https://npmjs.org/package/oclif-hello-world)
[![License](https://img.shields.io/npm/l/oclif-hello-world.svg)](https://github.com/oclif/hello-world/blob/main/package.json)

<!-- toc -->
* [Usage](#usage)
* [Commands](#commands)
<!-- tocstop -->
# Usage
<!-- usage -->
```sh-session
$ npm install -g semantic-search-cli
$ semantic-search-cli COMMAND
running command...
$ semantic-search-cli (--version)
semantic-search-cli/0.0.0 darwin-arm64 node-v18.16.0
$ semantic-search-cli --help [COMMAND]
USAGE
  $ semantic-search-cli COMMAND
...
```
<!-- usagestop -->
# Commands
<!-- commands -->
* [`semantic-search-cli hello PERSON`](#semantic-search-cli-hello-person)
* [`semantic-search-cli hello world`](#semantic-search-cli-hello-world)
* [`semantic-search-cli help [COMMANDS]`](#semantic-search-cli-help-commands)
* [`semantic-search-cli plugins`](#semantic-search-cli-plugins)
* [`semantic-search-cli plugins:install PLUGIN...`](#semantic-search-cli-pluginsinstall-plugin)
* [`semantic-search-cli plugins:inspect PLUGIN...`](#semantic-search-cli-pluginsinspect-plugin)
* [`semantic-search-cli plugins:install PLUGIN...`](#semantic-search-cli-pluginsinstall-plugin-1)
* [`semantic-search-cli plugins:link PLUGIN`](#semantic-search-cli-pluginslink-plugin)
* [`semantic-search-cli plugins:uninstall PLUGIN...`](#semantic-search-cli-pluginsuninstall-plugin)
* [`semantic-search-cli plugins:uninstall PLUGIN...`](#semantic-search-cli-pluginsuninstall-plugin-1)
* [`semantic-search-cli plugins:uninstall PLUGIN...`](#semantic-search-cli-pluginsuninstall-plugin-2)
* [`semantic-search-cli plugins update`](#semantic-search-cli-plugins-update)

## `semantic-search-cli hello PERSON`

Say hello

```
USAGE
  $ semantic-search-cli hello PERSON -f <value>

ARGUMENTS
  PERSON  Person to say hello to

FLAGS
  -f, --from=<value>  (required) Who is saying hello

DESCRIPTION
  Say hello

EXAMPLES
  $ oex hello friend --from oclif
  hello friend from oclif! (./src/commands/hello/index.ts)
```

_See code: [dist/commands/hello/index.ts](https://github.com/aws-samples/semantic-search-aws-docs/blob/v0.0.0/dist/commands/hello/index.ts)_

## `semantic-search-cli hello world`

Say hello world

```
USAGE
  $ semantic-search-cli hello world

DESCRIPTION
  Say hello world

EXAMPLES
  $ semantic-search-cli hello world
  hello world! (./src/commands/hello/world.ts)
```

## `semantic-search-cli help [COMMANDS]`

Display help for semantic-search-cli.

```
USAGE
  $ semantic-search-cli help [COMMANDS] [-n]

ARGUMENTS
  COMMANDS  Command to show help for.

FLAGS
  -n, --nested-commands  Include all nested commands in the output.

DESCRIPTION
  Display help for semantic-search-cli.
```

_See code: [@oclif/plugin-help](https://github.com/oclif/plugin-help/blob/v5.2.9/src/commands/help.ts)_

## `semantic-search-cli plugins`

List installed plugins.

```
USAGE
  $ semantic-search-cli plugins [--core]

FLAGS
  --core  Show core plugins.

DESCRIPTION
  List installed plugins.

EXAMPLES
  $ semantic-search-cli plugins
```

_See code: [@oclif/plugin-plugins](https://github.com/oclif/plugin-plugins/blob/v2.4.6/src/commands/plugins/index.ts)_

## `semantic-search-cli plugins:install PLUGIN...`

Installs a plugin into the CLI.

```
USAGE
  $ semantic-search-cli plugins:install PLUGIN...

ARGUMENTS
  PLUGIN  Plugin to install.

FLAGS
  -f, --force    Run yarn install with force flag.
  -h, --help     Show CLI help.
  -v, --verbose

DESCRIPTION
  Installs a plugin into the CLI.
  Can be installed from npm or a git url.

  Installation of a user-installed plugin will override a core plugin.

  e.g. If you have a core plugin that has a 'hello' command, installing a user-installed plugin with a 'hello' command
  will override the core plugin implementation. This is useful if a user needs to update core plugin functionality in
  the CLI without the need to patch and update the whole CLI.


ALIASES
  $ semantic-search-cli plugins add

EXAMPLES
  $ semantic-search-cli plugins:install myplugin 

  $ semantic-search-cli plugins:install https://github.com/someuser/someplugin

  $ semantic-search-cli plugins:install someuser/someplugin
```

## `semantic-search-cli plugins:inspect PLUGIN...`

Displays installation properties of a plugin.

```
USAGE
  $ semantic-search-cli plugins:inspect PLUGIN...

ARGUMENTS
  PLUGIN  [default: .] Plugin to inspect.

FLAGS
  -h, --help     Show CLI help.
  -v, --verbose

GLOBAL FLAGS
  --json  Format output as json.

DESCRIPTION
  Displays installation properties of a plugin.

EXAMPLES
  $ semantic-search-cli plugins:inspect myplugin
```

## `semantic-search-cli plugins:install PLUGIN...`

Installs a plugin into the CLI.

```
USAGE
  $ semantic-search-cli plugins:install PLUGIN...

ARGUMENTS
  PLUGIN  Plugin to install.

FLAGS
  -f, --force    Run yarn install with force flag.
  -h, --help     Show CLI help.
  -v, --verbose

DESCRIPTION
  Installs a plugin into the CLI.
  Can be installed from npm or a git url.

  Installation of a user-installed plugin will override a core plugin.

  e.g. If you have a core plugin that has a 'hello' command, installing a user-installed plugin with a 'hello' command
  will override the core plugin implementation. This is useful if a user needs to update core plugin functionality in
  the CLI without the need to patch and update the whole CLI.


ALIASES
  $ semantic-search-cli plugins add

EXAMPLES
  $ semantic-search-cli plugins:install myplugin 

  $ semantic-search-cli plugins:install https://github.com/someuser/someplugin

  $ semantic-search-cli plugins:install someuser/someplugin
```

## `semantic-search-cli plugins:link PLUGIN`

Links a plugin into the CLI for development.

```
USAGE
  $ semantic-search-cli plugins:link PLUGIN

ARGUMENTS
  PATH  [default: .] path to plugin

FLAGS
  -h, --help     Show CLI help.
  -v, --verbose

DESCRIPTION
  Links a plugin into the CLI for development.
  Installation of a linked plugin will override a user-installed or core plugin.

  e.g. If you have a user-installed or core plugin that has a 'hello' command, installing a linked plugin with a 'hello'
  command will override the user-installed or core plugin implementation. This is useful for development work.


EXAMPLES
  $ semantic-search-cli plugins:link myplugin
```

## `semantic-search-cli plugins:uninstall PLUGIN...`

Removes a plugin from the CLI.

```
USAGE
  $ semantic-search-cli plugins:uninstall PLUGIN...

ARGUMENTS
  PLUGIN  plugin to uninstall

FLAGS
  -h, --help     Show CLI help.
  -v, --verbose

DESCRIPTION
  Removes a plugin from the CLI.

ALIASES
  $ semantic-search-cli plugins unlink
  $ semantic-search-cli plugins remove
```

## `semantic-search-cli plugins:uninstall PLUGIN...`

Removes a plugin from the CLI.

```
USAGE
  $ semantic-search-cli plugins:uninstall PLUGIN...

ARGUMENTS
  PLUGIN  plugin to uninstall

FLAGS
  -h, --help     Show CLI help.
  -v, --verbose

DESCRIPTION
  Removes a plugin from the CLI.

ALIASES
  $ semantic-search-cli plugins unlink
  $ semantic-search-cli plugins remove
```

## `semantic-search-cli plugins:uninstall PLUGIN...`

Removes a plugin from the CLI.

```
USAGE
  $ semantic-search-cli plugins:uninstall PLUGIN...

ARGUMENTS
  PLUGIN  plugin to uninstall

FLAGS
  -h, --help     Show CLI help.
  -v, --verbose

DESCRIPTION
  Removes a plugin from the CLI.

ALIASES
  $ semantic-search-cli plugins unlink
  $ semantic-search-cli plugins remove
```

## `semantic-search-cli plugins update`

Update installed plugins.

```
USAGE
  $ semantic-search-cli plugins update [-h] [-v]

FLAGS
  -h, --help     Show CLI help.
  -v, --verbose

DESCRIPTION
  Update installed plugins.
```
<!-- commandsstop -->
