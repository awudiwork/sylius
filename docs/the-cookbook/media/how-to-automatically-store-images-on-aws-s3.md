# How to automatically store images on AWS-S3?

This guide explains how to configure your Sylius 2.x store to automatically upload and store images (such as product images) on Amazon Web Services (AWS) S3.

Using S3 storage reduces server load, improves performance, and provides scalability for your images.

### Prerequisites

* A Sylius 2.x project
* An AWS account with S3 bucket created
* Basic familiarity with Symfony and Composer

### Step 1: Install Required Packages

First, install the Flysystem AWS S3 adapter to enable communication between your application and AWS S3:

```bash
composer require league/flysystem-aws-s3-v3
```

### Step 2: Configure the AWS S3 Service

In your project's `config/services.yaml`, add the AWS S3 client configuration:

```yaml
services:
    Aws\S3\S3Client:
        arguments:
            -
                version: 'latest'
                region: '%env(AWS_REGION)%'
                credentials:
                    key: '%env(AWS_ACCESS_KEY_ID)%'
                    secret: '%env(AWS_SECRET_ACCESS_KEY)%'
```

{% hint style="info" %}
Replace the placeholders (`AWS_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) with your actual AWS credentials. It's recommended to store these credentials securely in environment variables (using `.env`).
{% endhint %}

### Step 3: Set Up Flysystem with AWS S3

Define Flysystem storage in your Sylius project. Edit `config/packages/flysystem.yaml` (create this file if it doesn't exist):

```yaml
flysystem:
    storages:
        sylius.storage:
            adapter: 'aws'
            options:
                client: 'Aws\S3\S3Client'
                bucket: '%env(AWS_BUCKET)%'
                prefix: 'media/image' # Optional, set your preferred folder
```

{% hint style="info" %}
Replace `%env(AWS_BUCKET)%` with your AWS S3 bucket name (use environment variables).
{% endhint %}

### Step 4: Configure Sylius to Use S3 Storage

Update your Sylius configuration to use the Flysystem storage defined above. In `config/packages/sylius.yaml`, add or modify the following:

```yaml
sylius:
    uploader:
        filesystem: sylius.storage
```

### Step 5: Clear Cache and Test

After configuration, clear your Symfony cache:

```bash
bin/console cache:clear
```

Test the configuration by uploading a product image in your Sylius admin panel. The image should now automatically appear in your specified AWS S3 bucket.

### Verify Your Setup

* Log in to your AWS console and open your S3 bucket.
* Check if the uploaded images appear under the configured folder (`media/image`).

### Troubleshooting

* **Access Denied Errors**: Ensure your IAM user has sufficient permissions (`s3:PutObject`, `s3:GetObject`, `s3:DeleteObject`). See [AWS IAM Documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html) for more.
* **Region Issues**: Confirm your bucket region matches your AWS configuration.
* **Images Not Uploading**: Ensure environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_BUCKET`) are correctly defined.

### Further Reading

* [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)
* [Symfony Flysystem Bundle](https://flysystem.thephpleague.com/)

Congratulations! You've successfully configured automatic image storage with AWS S3 in your Sylius application.
