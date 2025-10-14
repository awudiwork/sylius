# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

See @AGENTS.md

## Overview

Sylius is an open-source e-commerce framework built on **Symfony** (^6.4 || ^7.2) and **PHP 8.2+**. The project follows a modular architecture with separate **Bundles** (Symfony integration) and **Components** (framework-agnostic business logic) that can be used independently.

## Project Architecture

### Source Organization

The codebase is organized in `src/Sylius/` with the following structure:

- **`Bundle/`** - Symfony bundles providing framework integration (23 bundles)
  - `AdminBundle` - Admin panel UI
  - `ShopBundle` - Shop frontend UI
  - `ApiBundle` - RESTful API (API Platform 4.x)
  - `CoreBundle` - Integrates all bundles into complete solution
  - Domain-specific bundles: `ProductBundle`, `OrderBundle`, `CustomerBundle`, `PaymentBundle`, etc.

- **`Component/`** - Framework-agnostic business logic (17 components)
  - Domain models, repositories, services
  - Components correspond to bundles (e.g., `Product`, `Order`, `Customer`)

- **`Behat/`** - Behat test infrastructure and contexts

- **`Abstraction/StateMachine/`** - State machine abstraction layer

Each Bundle/Component is designed to be independently usable and follows domain-driven design principles.

### Key Design Principles

- **Extensibility** - Sylius must be easily extendable in end applications
- **Modularity** - Bundles and Components work independently
- **Backward Compatibility** - Follow Sylius BC policy strictly
- **Performance** - Designed for speed and efficiency

## Development Commands

### Installation & Setup

```bash
# Install PHP dependencies
composer install

# Install JavaScript dependencies
yarn install

# Initialize project (install + backend + frontend)
make init

# Backend setup (database + install + fixtures)
make backend

# Frontend build
make frontend
# Or for development
yarn encore dev
# Or watch mode
yarn watch
```

### Code Quality

```bash
# Fix code style (uses ECS - Easy Coding Standard)
vendor/bin/ecs
# Or shorthand
vendor/bin/ecs check
vendor/bin/ecs check --fix

# Static analysis (PHPStan level 6)
vendor/bin/phpstan analyse
# Or via Makefile
make phpstan

# Lint JavaScript
yarn lint
```

### Testing

```bash
# Run all PHPUnit tests
vendor/bin/phpunit
# Or via Makefile
make phpunit

# Run specific test suite
vendor/bin/phpunit --testsuite=sylius
vendor/bin/phpunit --testsuite=sylius-behat

# Run single test file
vendor/bin/phpunit tests/Path/To/TestFile.php

# Run single test method
vendor/bin/phpunit --filter testMethodName tests/Path/To/TestFile.php

# Behat - all tests
make behat

# Behat - CLI only
make behat-cli
vendor/bin/behat --tags="~@javascript&&@cli&&~@todo"

# Behat - non-JavaScript tests
make behat-non-js
vendor/bin/behat --tags="~@javascript&&~@cli&&~@todo"

# Behat - JavaScript tests (requires Chrome/Panther)
make behat-js
vendor/bin/behat --tags="@javascript&&~@cli&&~@todo"

# Run specific Behat scenario
vendor/bin/behat features/path/to/file.feature
vendor/bin/behat features/path/to/file.feature:42  # Run scenario at line 42

# CI pipeline
make ci  # Runs: init + phpstan + phpunit + behat
```

### Symfony Console

```bash
# Symfony console
bin/console

# Database operations
bin/console doctrine:database:create
bin/console doctrine:migrations:migrate

# Install Sylius
bin/console sylius:install

# Load fixtures
bin/console sylius:fixtures:load default

# Cache operations
bin/console cache:clear
bin/console cache:warmup
```

## API Development

### API Platform 4.x Configuration

- API resources are defined in `src/Sylius/Bundle/ApiBundle/Resources/config/api_resources/`
- Separate configurations for `admin/` and `shop/` contexts
- Operations order: `get collection`, `get item`, `post`, `put`, `patch`, `delete`
- Serialization groups defined in `serialization/` folder: `index`, `show`, `create`, `update`
- State providers: `src/Sylius/Bundle/ApiBundle/StateProvider/`
- State processors: `src/Sylius/Bundle/ApiBundle/StateProcessor/`
- Query extensions: `src/Sylius/Bundle/ApiBundle/QueryExtension/`

### Testing API

Use **PHPUnit** tests to validate:
- API configuration correctness
- API responses and status codes
- Serialization groups
- Validation rules

## Frontend Development

### Technologies

- **Symfony UX** components (Stimulus, Live Components, Autocomplete)
- **Webpack Encore** for asset compilation
- **Bootstrap 5** for styling
- **Tabler 1.x** icon library
- **Twig** templates with modern syntax
- **Twig Hooks** for extensibility

### Asset Compilation

```bash
# Development build
yarn encore dev

# Production build
yarn encore production

# Watch mode (auto-rebuild on changes)
yarn watch
```

### Frontend Structure

- Admin assets: `src/Sylius/Bundle/AdminBundle/`
- Shop assets: `src/Sylius/Bundle/ShopBundle/`
- Compiled assets output to `public/`
- Webpack config: `webpack.config.js` (delegates to bundle configs)

## Testing Strategy

### PHPUnit (Unit & Functional Tests)

- Test files in `tests/` and `src/Sylius/Behat/tests/`
- Use modern PHPUnit 11.5 syntax
- Bootstrap: `config/bootstrap.php`
- Test suites: `all`, `sylius`, `sylius-behat`

### Behat (Behavior-Driven Development)

- Feature files in `features/`
- Contexts in `src/Sylius/Behat/`
- Suites configured in `src/Sylius/Behat/Resources/config/suites.yml`
- Supports multiple sessions: `symfony`, `chromedriver`, `panther`
- JavaScript tests use Panther (headless Chrome)

## Code Style & Standards

### PHP

- **PHP 8.2+** features and syntax
- `declare(strict_types=1);` in all files
- Type declarations for all properties, arguments, return values
- `final` for all classes (except entities and repositories)
- `readonly` for immutable services and value objects
- Naming conventions:
  - `camelCase` for variables and methods
  - `SCREAMING_SNAKE_CASE` for constants
  - `snake_case` for config keys, routes, template variables
  - Suffix interfaces with `Interface`, traits with `Trait`
- Class element order: constants → properties → constructor → public → protected → private
- Use fast returns instead of deep nesting
- Trailing commas in multi-line arrays/arguments
- Alphabetical ordering for array keys where applicable
- PHPDoc only when necessary (e.g., `@var Collection<ProductInterface>`)

### Templates

- Modern **Twig** syntax (latest features)
- **HTML5** markup
- `snake_case` for directory, file, and variable names
- Template structure mirrors Twig hook structure under `templates/`
- All text uses translations, never hardcode strings
- Icons from **Tabler 1.x** library

### CSS

- Use **SCSS** syntax only (`.scss` files required)
- Prefer **Bootstrap 5** utility classes
- Modular component styles (1 component = 1 partial)
- Variables in `_variables.scss`
- Avoid `!important` unless necessary
- Use `rem` over `px` for spacing and font sizes
- Reusable logic in `mixins/`

### JavaScript

- Modern ES6+ syntax
- **Stimulus** controllers for interactivity
- ESLint for linting (`yarn lint`)

## Common Workflows

### Adding a New Feature

1. Identify relevant Component and Bundle
2. Add domain logic to Component
3. Integrate with Symfony in Bundle
4. Add API resources if needed (API Platform config)
5. Create/update templates with Twig hooks
6. Write PHPUnit tests for logic
7. Write Behat scenarios for user flows
8. Run code quality checks (ECS, PHPStan)

### Modifying Existing Code

1. Understand Component/Bundle separation
2. Check for dependencies (upstream/downstream)
3. Follow existing patterns and idioms in the codebase
4. Update tests (PHPUnit and Behat)
5. Ensure BC compatibility
6. Run full test suite

### Debugging

- Symfony Web Profiler available in dev environment
- Logs in `var/log/`
- Behat screenshots on failures in `etc/build/`
- ChromeDriver logs in `etc/build/chromedriver.log`

## Dependencies

### Key Libraries

- **Symfony** ^6.4 || ^7.2 (Full Stack Framework)
- **API Platform** ^4.1.7 (REST API)
- **Doctrine ORM** ^2.18 || ^3.3 (Database)
- **Twig** ^3.14 (Templating)
- **PHPUnit** ^11.5 (Testing)
- **Behat** ^3.22 (BDD Testing)
- **Payum** (Payment Processing)
- **LiipImagineBundle** (Image Processing)

### Development Tools

- **ECS** (Easy Coding Standard) - Code style
- **PHPStan** (level 6) - Static analysis
- **Rector** - Code refactoring
- **PHPArkitect** - Architecture validation

## File Headers

All PHP files must include the standard Sylius header:

```php
<?php

/*
 * This file is part of the Sylius package.
 *
 * (c) Sylius Sp. z o.o.
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

declare(strict_types=1);
```

## Version Compatibility

- Current version: `2.1.7-dev` (from composer.json)
- PHP: `^8.2`
- Symfony: `^6.4 || ^7.2`
- API Platform: `^4.1.7`
- Node.js: `>=20`

## Additional Resources

- **Documentation**: https://docs.sylius.com
- **Contributing Guide**: https://docs.sylius.com/the-book/contributing
- **API Docs**: Check `src/Sylius/Bundle/ApiBundle/docs/`
- **ADRs** (Architecture Decision Records): `adr/` directory
- **Upgrade Guides**: `UPGRADE-*.md` files in root
