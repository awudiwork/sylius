phpunit:
	vendor/bin/phpunit

phpstan:
	vendor/bin/phpstan analyse

behat-cli:
	vendor/bin/behat --colors --strict --no-interaction -vvv -f progress --tags="~@javascript&&@cli&&~@todo" || vendor/bin/behat --colors --strict --no-interaction -vvv -f progress --tags="~@javascript&&@cli&&~@todo" --rerun

behat-non-js:
	vendor/bin/behat --colors --strict --no-interaction -vvv -f progress --tags="~@javascript&&~@cli&&~@todo" || vendor/bin/behat --colors --strict --no-interaction -vvv -f progress --tags="~@javascript&&~@cli&&~@todo" --rerun

behat-js:
	vendor/bin/behat --colors --strict --no-interaction -vvv -f progress --tags="@javascript&&~@cli&&~@todo" || vendor/bin/behat --colors --strict --no-interaction -vvv -f progress --tags="@javascript&&~@cli&&~@todo" --rerun

install:
	composer install --no-interaction --no-scripts

backend:
	@echo "Creating required directories..."
	mkdir -p var/log var/cache public/media
	bin/console doctrine:database:create --no-interaction || true
	bin/console sylius:install --no-interaction
	bin/console sylius:fixtures:load default --no-interaction
	@echo "Fixing permissions..."
	chown -R www-data:www-data var/ public/media/ 2>/dev/null || true
	chmod -R 775 var/ public/media/ 2>/dev/null || true

frontend:
	yarn install --pure-lockfile
	yarn encore production

behat: behat-cli behat-non-js behat-js

init: install backend frontend
	@echo "Deployment completed. Fixing final permissions..."
	chown -R www-data:www-data var/ public/media/ 2>/dev/null || true
	chmod -R 775 var/ public/media/ 2>/dev/null || true

ci: init phpstan phpunit behat

integration: init phpunit behat-cli behat-non-js

static: install phpstan

# Example execution: make profile url=http://app
profile:
	docker compose exec blackfire blackfire curl -L $(url)
