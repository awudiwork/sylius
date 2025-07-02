# CONFLICTS

This document explains why certain conflicts were added to `composer.json` and references related issues.

- `api-platform/jsonld: ^4.1.1`

  API Platform introduced changes in version 4.1.1 that modify API responses, potentially breaking compatibility with our current implementation.  
  To ensure stable behavior, we have added this conflict until we can verify and adapt to the changes.

- `behat/gherkin:^4.13.0`:

  This version moved files to flatten paths into a PSR-4 structure, which lead to a fatal error:
  `PHP Fatal error:  Uncaught Error: Failed opening required '/home/runner/work/Sylius/Sylius/vendor/behat/gherkin/src/../../../i18n.php' (include_path='.:/usr/share/php') in /home/runner/work/Sylius/Sylius/vendor/behat/gherkin/src/Keywords/CachedArrayKeywords.php:34`

- `symfony/serializer:^6.4.23`:

  This version introduces a change in method signature that is not compatible with API Platform 2.7 and leads to a fatal error:
  `PHP Fatal error:  Declaration of ApiPlatform\Serializer\AbstractItemNormalizer::getAllowedAttributes($classOrObject, array $context, $attributesAsString = false) must be compatible with Symfony\Component\Serializer\Normalizer\AbstractObjectNormalizer::getAllowedAttributes(object|string $classOrObject, array $context, bool $attributesAsString = false): array|bool in /home/runner/work/Sylius/Sylius/vendor/api-platform/core/src/Serializer/AbstractItemNormalizer.php on line 493`
