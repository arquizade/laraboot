# Laravel Installer

Install Laravel 13 using Docker. No PHP or Composer needed on your machine.

## Requirements

- Docker

## Usage

Install in current folder:

curl -fsSL https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/installer.sh | bash -s .

Install in a new folder:

curl -fsSL https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/installer.sh | bash -s my-project

## What it does

- Creates the project folder if needed
- Runs composer create-project inside Docker
- Runs composer install inside Docker
- Prints the command to serve the app
