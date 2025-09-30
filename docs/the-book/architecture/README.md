# Architecture

Before we dive separately into every Sylius concept, you need to have an overview of how our main application is structured.

### Architectural drivers

All architectural decisions need to be backed by a valid reason. The fundamental signposts we use to make such choices are explained in the [Architectural Drivers](architectural-drivers.md) section.

Specific decisions we make during the development are often explained using Architectural Decision Records. They’re stored in the [main Sylius repository](https://github.com/Sylius/Sylius/tree/1.11/adr) for better visibility.

### Architecture

In the image below, you can see the symbolic representation of Sylius architecture.

<figure><img src="../../.gitbook/assets/architecture_overview.png" alt="" width="375"><figcaption></figcaption></figure>

Keep on reading this chapter to learn more about each of its parts: Shop, Admin, API, Core, Components, and Bundles.

### Division into Components, Bundles, and Platform

You already know that Sylius is built from components and Symfony bundles, which are integration layers with the framework. All bundles share the same conventions for naming things and the way of data persistence.

#### Components

Every single component of Sylius can be used standalone. Taking the `Taxation` component as an example, its only responsibility is to calculate taxes, it does not matter whether these will be taxes for products or anything else, it is fully decoupled. In order to let the Taxation component operate on your objects, you need to have them implement the `TaxableInterface`. Since then, they can have taxes calculated. Such an approach is true for every component of Sylius. Besides components that are strictly connected to the e-commerce needs, we have plenty of more general components. For instance, Attribute, Mailer, Locale, etc.

All the components are packages available via [Packagist](https://packagist.org/).

#### Bundles

These are the Symfony Bundles - therefore, if you are a Symfony Developer, and you would like to use the Taxation component in your system, but you do not want to spend time on configuring forms or services in the container. You can include the `TaxationBundle` in your application with minimal or even no configuration to have access to all the services, models, configure tax rates, tax categories, and use that for any taxes you will need.

#### Platform

This is a full-stack Symfony Application, based on Symfony Standard. Sylius Platform gives you the classic, quite feature-rich webshop. Before you start using Sylius, you will need to decide whether you will need a full platform with all the features we provide, or maybe you will use decoupled bundles and components to build something very custom, maybe smaller, with different features. But of course, the platform itself is highly flexible and can be easily customized to meet all business requirements you may have.

### Division into Core, Admin, Shop, Api

#### Core

The Core is another component that integrates all the other components. This is the place where for example, the `ProductVariant` finally learns that it has a `TaxCategory`. The Core component is where the `ProductVariant` implements the `TaxableInterface` and other interfaces that are useful for its operation. Sylius has a fully integrated concept of everything that is needed to run a webshop. To get to know more about concepts applied in Sylius, keep on reading The Book.

#### Admin

In every system with a security layer, the functionalities of system administration need to be restricted to only some users with a certain role - Administrator. This is the responsibility of our `AdminBundle` although if you do not need it, you can turn it off. Views have been built using [Bootstrap](https://getbootstrap.com/).

#### Shop

Our `ShopBundle` is basically a standard B2C interface for everything that happens in the system. It is made mainly of yaml configurations and templates. Also, here views have been built using [Bootstrap](https://getbootstrap.com/).

#### API

When we created our API based on the API Platform framework, we did everything to make the API as easy as possible to use by developers. The most important features of our API:

* All operations are grouped by _shop_ and _admin_ context (two prefixes);
* Developers can enable or disable the entire API by changing a single parameter (check [this](../api/) chapter);
* We create all endpoints implementing the REST principles, and we are using HTTP verbs (POST, GET, PUT, PATCH, DELETE);
* Returned responses contain minimal information (the developer should extend serialization if needed for more data);
* The entire business logic is separated from the API - if necessary, we dispatch a command instead of mixing API logic with business logic.
