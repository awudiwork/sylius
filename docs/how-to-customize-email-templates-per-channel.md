---
layout:
  title:
    visible: true
  description:
    visible: false
  tableOfContents:
    visible: true
  outline:
    visible: true
  pagination:
    visible: true
---

# How to customize email templates per channel?

Let’s assume you have two channels in your Sylius store: `TOY_STORE` and `FASHION_WEB`. You want to personalize email content depending on which channel the customer used to place an order. This guide shows how to achieve this in a maintainable and scalable way.

To verify and manage channels in your system, open the **Channels grid** in the Sylius admin panel. You’ll find each channel’s code, name, and hostname.

<figure><img src=".gitbook/assets/image (17).png" alt=""><figcaption></figcaption></figure>

These codes are what you will use to differentiate content in your Twig templates.

***

## 2. Identify the Email Template to Override

You can find a full list of templates and context variables in the emails documentation.

Original template path:

```markup
@SyliusCoreBundle/Email/orderConfirmation.html.twig
```

To override it, copy it to:

```bash
templates/bundles/SyliusCoreBundle/Email/orderConfirmation.html.twig
```

{% hint style="info" %}
Twig paths like `@SyliusCoreBundle/...` point to the original bundle templates. To override them, create files under `templates/bundles/...`, following Symfony’s bundle override system.
{% endhint %}

***

## 3. Use `if` Statements for Simple Channel Variations

For minor differences between channels, use `if` conditions in the Twig template:

```twig
{# templates/bundles/SyliusCoreBundle/Email/orderConfirmation.html.twig #}

{% extends '@SyliusCore/Email/layout.html.twig' %}

{% block subject %}
    {% include '@SyliusCore/Email/Blocks/OrderConfirmation/_subject.html.twig' %}
{% endblock %}

{% block content %}
    {% if sylius.channel.code == 'TOY_STORE' %}
        Thanks for buying one of our toys!
    {% elseif sylius.channel.code == 'FASHION_WEB' %}
        Your new style is on the way!
    {% else %}
        Thanks for your purchase!
    {% endif %}

    Your order no. {{ order.number }} has been successfully placed.
{% endblock %}
```

{% hint style="success" %}
Best for 2–3 channels that have cosmetic differences.
{% endhint %}

***

## 4. Extract Channel-Specific Templates for Maintainability (Recommended)

Instead of using many `if` statements, extract logic into per-channel files:

### Parent Template:

```twig
{# templates/bundles/SyliusCoreBundle/Email/orderConfirmation.html.twig #}

{% extends '@SyliusCore/Email/layout.html.twig' %}

{% block subject %}
    {% include '@SyliusCore/Email/Blocks/OrderConfirmation/_subject.html.twig' %}
{% endblock %}

{% block content %}
    {% include [
        'Email/OrderConfirmation/' ~ sylius.channel.code ~ '.html.twig',
        'Email/OrderConfirmation/_default.html.twig'
    ] %}
{% endblock %}
```

### Example File Structure

```
templates/
├── bundles/
│   └── SyliusShopBundle/
│       └── Email/
│           └── orderConfirmation.html.twig
└── Email/
    └── OrderConfirmation/
        ├── TOY_STORE.html.twig
        ├── FASHION_WEB.html.twig
        └── _default.html.twig
```

### Sample Channel Files

`_default.html.twig`

```twig
{# templates/Email/OrderConfirmation/_default.html.twig #}

Your order no. {{ order.number }} has been successfully placed.
```

**`TOY_STORE.html.twig`**

```twig
{# templates/Email/OrderConfirmation/TOY_STORE.html.twig #}

Thanks for buying one of our toys!

Your order with number {{ order.number }} is currently being processed.
```

**`FASHION_WEB.html.twig`**

```twig
{# templates/Email/OrderConfirmation/FASHION_WEB.html.twig #}

Your new style is on the way!

We’ve received your order no. {{ order.number }}.
```

{% hint style="success" %}
This structure allows you to extend or localize emails without changing the parent layout.
{% endhint %}

***

## 5. Understand the Default Layout

By default, the core Sylius `orderConfirmation.html.twig` email looks like this:

```twig
{# SyliusCoreBundle/Resources/views/Email/orderConfirmation.html.twig #}

{% extends '@SyliusCore/Email/layout.html.twig' %}

{% block subject %}
    {% include '@SyliusCore/Email/Blocks/OrderConfirmation/_subject.html.twig' %}
{% endblock %}

{% block content %}
    {% include '@SyliusCore/Email/Blocks/OrderConfirmation/_content.html.twig' %}
{% endblock %}
```

* `_subject.html.twig`: contains the translated subject line
* `_content.html.twig`: includes layout, order number, and optional link

{% hint style="success" %}
### You can override any of these includes or the layout itself per channel as needed.

Check out available email templates [here](https://github.com/Sylius/Sylius/tree/v2.1.2/src/Sylius/Bundle/ShopBundle/templates/email) and [here](https://github.com/Sylius/Sylius/tree/2.1/src/Sylius/Bundle/CoreBundle/Resources/views/Email)
{% endhint %}

***

### 6. Summary: Strategy by Complexity

| Scenario                        | Strategy                                |
| ------------------------------- | --------------------------------------- |
| 1–2 channels, small changes     | Use `{% if %}` blocks in one template   |
| 3+ channels, or different voice | Use `include` with fallback per channel |

***

## :white\_check\_mark: Result

Each email adapts to the right channel automatically. Developers can manage templates independently, and fallback logic ensures robustness.

You’ve now implemented clean, scalable multi-channel email templates in Sylius!

<figure><img src=".gitbook/assets/image (18).png" alt=""><figcaption><p>FASHION_WEB channel</p></figcaption></figure>

<figure><img src=".gitbook/assets/image (19).png" alt=""><figcaption><p>TOY_STORE channel</p></figcaption></figure>
