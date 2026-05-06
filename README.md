# Laraboot (Laravel + Docker Installer )

Install Laravel with Docker. No PHP or Composer needed on your machine.

## Requirements

- Docker

## Install

Install in current folder:

    curl -fsSL https://raw.githubusercontent.com/arquizade/laraboot/main/installer.sh | zsh -s .

Install in a named folder:

    curl -fsSL https://raw.githubusercontent.com/arquizade/laraboot/main/installer.sh | zsh -s my-project

Using bash:

    curl -fsSL https://raw.githubusercontent.com/arquizade/laraboot/main/installer.sh | bash -s my-project

## Specify a Laravel Version

Install a specific Laravel version using the --laravel flag:

    # Install Laravel 13
    curl -fsSL https://raw.githubusercontent.com/arquizade/laraboot/main/installer.sh | zsh -s my-project --laravel=13

    # Install Laravel 12
    curl -fsSL https://raw.githubusercontent.com/arquizade/laraboot/main/installer.sh | zsh -s my-project --laravel=12

    # Install Laravel 11
    curl -fsSL https://raw.githubusercontent.com/arquizade/laraboot/main/installer.sh | zsh -s my-project --laravel=11

If no --laravel flag is provided, it installs the latest stable version.

## Install with a Starter Kit

Use the --using flag to install a community starter kit from Packagist:

    curl -fsSL https://raw.githubusercontent.com/arquizade/laraboot/main/installer.sh | zsh -s my-project --using=laravel/breeze

    curl -fsSL https://raw.githubusercontent.com/arquizade/laraboot/main/installer.sh | zsh -s my-project --laravel=13 --using=laravel/breeze

## Install with a Stack

Use the --stack flag to install a predefined set of packages:

    curl -fsSL https://raw.githubusercontent.com/arquizade/laraboot/main/installer.sh | zsh -s my-project --stack=ai

    curl -fsSL https://raw.githubusercontent.com/arquizade/laraboot/main/installer.sh | zsh -s my-project --laravel=13 --stack=ai

Available stacks:

    ai          openai-php/laravel, spatie/laravel-data, prism-php/prism
    api         laravel/sanctum, spatie/laravel-query-builder, spatie/laravel-fractal
    fullstack   livewire/livewire, spatie/laravel-permission
    cms         filament/filament, spatie/laravel-medialibrary, spatie/laravel-tags

## Install with Extra Packages

Pass package names after the flags:

    curl -fsSL https://raw.githubusercontent.com/arquizade/laraboot/main/installer.sh | zsh -s my-project spatie/laravel-permission laravel/sanctum

## Combine All Flags

    curl -fsSL https://raw.githubusercontent.com/arquizade/laraboot/main/installer.sh | zsh -s my-project --laravel=13 --using=laravel/breeze --stack=ai spatie/laravel-permission

## After Install

    cd my-project
    make setup

## Makefile Commands

    make setup                                     install deps, copy .env, generate key
    make start                                     start server on http://localhost:8000
    make stop                                      stop running containers
    make require --package=vendor/package          install a single composer package
    make stack --name=ai                           install a predefined stack
    make artisan migrate                           run any artisan command
    make artisan make:controller UserController    run artisan with arguments

### Examples

    # First time setup
    make setup

    # Start the server
    make start

    # Stop the server
    make stop

    # Install a single package
    make require package=openai-php/laravel

    # Install a predefined stack
    make stack name=ai
    make stack name=api
    make stack name=cms

    # Run artisan commands
    make artisan migrate
    make artisan make:controller UserController
    make artisan make:model Post -m

## Pin to a Specific laraboot Version

    # Laravel 13
    curl -fsSL https://raw.githubusercontent.com/arquizade/laraboot/v1.0.0/installer.sh | zsh -s my-project

Versions:

    v1.0.0   Laravel 13, PHP 8.4

## Repo Structure

    laraboot/
      installer.sh        runs the install, fetches Makefile
      Makefile            downloaded into your project folder
      README.md
      LICENSE
      stacks/
        ai.sh
        api.sh
        fullstack.sh
        cms.sh

## License

MIT
