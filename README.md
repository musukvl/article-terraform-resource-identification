---
title: Resource identification in Terraform
published: true
description: An article used to test pushing to Dev.to
tags: terraform
cover_image: ./logo.jpg
canonical_url: null
id: 1520872
date: '2023-06-29T14:00:48Z'
---

# Resource identification in Terraform

## Basic concepts

Each resource created with Terraform present on three levels:

1. Resource has definition in .tf-file code as `resource` block.
2. Created resource has record in Terraform state file.
3. Resource is also actual resource created in a cloud.

On each level resource has its own identification. 
You need clearly understand how resource identified on each level to avoid unexpected resource recreation and data loss.
Proper resource identifiers also make your code maintainable and readable.

The code examples in this article are based on Azure provider. But the same concepts are applicable for other providers.
The link to code examples: https://github.com/musukvl/article-terraform-resource-identification

## Resource identifier in case of single resource

Let's check the [simple example](https://github.com/musukvl/article-terraform-resource-identification/blob/master/001-basic-example/main.tf) of azure storage account created with Terraform and track resource identification on each level:

Resource definition in .tf-file code level is:

```hcl
resource "azurerm_storage_account" "application_storage" {}
```

It has resource type `azurerm_storage_account` and resource name `application_storage`. In code the storage account can be referenced as  `azurerm_storage_account.application_storage`.

In the terraform state the storage account is identified with `type` and `name` fields:

```json
"resources": [
  {
    "mode": "managed",
    "type": "azurerm_storage_account",
    "name": "application_storage",
    "provider": "provider[\"registry.terraform.io/hashicorp/azurerm\"]",
    "instances": [
      {
        "schema_version": 3,
        "attributes": {
            "id": "/subscriptions/xxxxx/resourceGroups/ary-app-rg/providers/Microsoft.Storage/storageAccounts/aryappsa",
            "name": "aryappsa",
            ...
        }  
      }
    ] 
  } 
]           
```

Full example of state file is [here](https://github.com/musukvl/article-terraform-resource-identification/blob/master/001-basic-example/terraform.tfstate.json).

Actual storage account has `/subscriptions/xxxxx/resourceGroups/ary-app-rg/providers/Microsoft.Storage/storageAccounts/aryappsa` id in Azure cloud.   

Terraform matching resource on each level by corresponding identifier. 

For example, if you change name of the resource in *.tf-file:

```hcl
  resource "azurerm_storage_account" "application_storage_NEW" {}
```

During the `terraform plan` operation:

* Terraform realizes that it has no matching code definition for resource in the state with type `azurerm_storage_account` and name `application_storage`. So Terraform will destroy resource in Azure and remove it from state.
* Terraform realizes that it has no matching record in the state for resource defined in the code with identifier `azurerm_storage_account.application_storage_NEW`. So Terraform will create it in Azure and add record to the state.

## Identifiers vs attributes

Keep in mind, that `name` attribute of `azurerm_storage_account` and name of Terraform resource block are different things. 

The `name` attribute of `azurerm_storage_account` is not part of resource identifier. 
Changing attributes could cause resource recreation in some cases and depends on resource provider, but changing identifier *always* cause resource recreation.


## Resource identifier in case of `for_each`
If `for_each` is used in resource definition, multiple instances of resources will be created. Each instance can be addressed by index key.

For example, let's check the levels for azure storage account resource in [for_each case example](https://github.com/musukvl/article-terraform-resource-identification/blob/master/002-for_each/main.tf)

Resource definition in .tf-file code is:

```hcl
locals {
  application = {
    "document-parser-service" = {
    storage_account_name = "arydocparsesvc"
    }
    "email-sender-service" = {
    storage_account_name = "aryemailsendersvc"
    }
  }
}

resource "azurerm_storage_account" "application_storage" {
  for_each = local.application
```

It has resource type `azurerm_storage_account` and resource name `application_storage`. In code the storage account can be referenced with index key:  `azurerm_storage_account.application_storage["document-parser-service"]`.

In the state we will see two instances of storage account resource:

```json
resources: [
{
  "mode": "managed",
  "type": "azurerm_storage_account",
  "name": "application_storage",
  "provider": "provider[\"registry.terraform.io/hashicorp/azurerm\"]",
  "instances": [
    {
      "index_key": "document-parser-service",
      "attributes": {
        "id": "/subscriptions/xxxxx/resourceGroups/ary-app-rg-document-parser-service/providers/Microsoft.Storage/storageAccounts/arydocparsesvc",
        "name": "arydocparsesvc",
        ...
      }
    },
    {
      "index_key": "email-sender-service",
      "attributes": {
        "id": "/subscriptions/xxxxx/resourceGroups/ary-app-rg-email-sender-service/providers/Microsoft.Storage/storageAccounts/aryemailsendersvc",
        "name": "aryemailsendersvc"            
        ...
      }
    }        
  ]
}
]
```


Full example of state file is [here](https://github.com/musukvl/article-terraform-resource-identification/blob/master/002-for_each/terraform.tfstate.json).

Actual storage accounts have `/subscriptions/xxxxx/resourceGroups/ary-app-rg/providers/Microsoft.Storage/storageAccounts/aryappsa` and `/subscriptions/xxxxx/resourceGroups/ary-app-rg/providers/Microsoft.Storage/storageAccounts/aryemailsendersvc` ids in Azure cloud.


## Resource identifier in case of `count`
The `count` statement works pretty similar to `for_each` except resource idex is array index number instead of map key string.

Let's check [`count` case example](https://github.com/musukvl/article-terraform-resource-identification/blob/master/003-count/main.tf) the same as `for_each` case example:

Resource definition in .tf-file code is:

```hcl
locals {
  applications = [
    {
      name = "document-parser-service"
      storage_account_name = "arydocparsesvc"
    },
    {
      name = "email-sender-service"
      storage_account_name = "aryemailsendersvc"
    }
  ]
}

resource "azurerm_storage_account" "application_storage" {
  count = length(local.applications)
```

In code the storage account can be referenced with index key: `azurerm_storage_account.application_storage[0]`.

In the state we will see two instances of storage account resource:

```json
resources: [
{
  "mode": "managed",
  "type": "azurerm_storage_account",
  "name": "application_storage",
  "provider": "provider[\"registry.terraform.io/hashicorp/azurerm\"]",
  "instances": [
    {
      "index_key": 0,
      "attributes": {
        "id": "/subscriptions/xxxxx/resourceGroups/ary-app-rg-document-parser-service/providers/Microsoft.Storage/storageAccounts/arydocparsesvc",
        "name": "arydocparsesvc",
        ...
      }
    },
    {
      "index_key": 1,
      "attributes": {
        "id": "/subscriptions/xxxxx/resourceGroups/ary-app-rg-email-sender-service/providers/Microsoft.Storage/storageAccounts/aryemailsendersvc",
        "name": "aryemailsendersvc"            
        ...
      }
    }        
  ]
}
]
```


Full example of state file is [here](https://github.com/musukvl/article-terraform-resource-identification/blob/master/003-count/terraform.tfstate.json).

Storage accounts has the same IDs and names in azure as in `for_each` case example, but the difference identification in state file and in code.

Using int idex instead of string key is not very convenient, so `for_each` is preferred over `count` in most cases.

## Conclusion

Understanding of resource identification is very important in case of shared terraform modules and for cases when resources can't be easily recreated for refactoring purposes. 
