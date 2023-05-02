---
title: "Find service principals with privileged roles"
images:
  - "https://images.seifbassem.com/images/Posts/ARG-Privileged-ServicePrincipals/banner.png"
date: 2023-05-01 17:08:42 +0200
tags: ["Azure","Azure Resource Graph","Security","Governance"]
categories: ["posts"]
draft: false
---

<!--more-->

As more and more organizations adopt cloud computing, the use of Azure Active Directory (Azure AD) and service principals has become increasingly prevalent. Service principals are Azure AD identities that are used to authenticate and authorize applications and services to access Azure resources. While service principals can be a powerful tool for managing access to Azure resources, they also come with significant risks, particularly when they are granted privileged roles and are not properly tracked. In this article, we will explore how to use Azure Resource Graph to find those service principals, and discuss best practices for managing these identities to minimize the risk of security breaches.

## Azure Resource Graph

Azure Resource Graph is a powerful tool for managing complex Azure environments. With Resource Graph, you can easily query and inventory your Azure resources using a simple and intuitive syntax. Whether you're managing a small deployment or a large-scale enterprise environment, Resource Graph can help you gain better visibility into your resources and streamline your management tasks.

## Demo

What we want to do is look for service principals that have privileged roles so we can review their access and take an action based on that. We would like to list all the role assignments on a specific scope, get the role definitions on those assignments and look at their permissions.

### Getting all service principals with assigned builtin roles

Azure Resource Graph has a preview table that we can query for role assignments and definitions called _authorizationresources_

  ![Screenshot showing Azure resource graph query of the authorizationresources table](https://images.seifbassem.com/images/Posts/ARG-Privileged-ServicePrincipals/01.png)

If we query this table and filter for _roleassignments_, we can see we have the following interesting fields:

  ```python
  authorizationresources
  | where type =~ 'microsoft.authorization/roleassignments'
  ```

  ![Screenshot showing Azure resource graph query of the authorizationresources table filtering role assignments](https://images.seifbassem.com/images/Posts/ARG-Privileged-ServicePrincipals/02.png)

- _principalType_ where we can filter by service principal or user
- _principalId_ which is the Id of the service principal
- _roleDefinitionId_ which is the unique Id of the role
- _createdBy_ which can be used to filter out the builtin service principals

We can now create a query to list all role assignments for service principals that are not builtin

 ```python
 authorizationresources
 | where type =~ 'microsoft.authorization/roleassignments'
 | extend roleDefinitionId= tolower(tostring(properties.roleDefinitionId))
 | extend principalType = properties.principalType
 | extend principalId = properties.principalId
 | where principalType =~ 'ServicePrincipal' and properties.createdBy != ""
 ```

We will have to do a join to get the builtin role definitions on the assignments from the previous step to list all service principals with builtin roles

 ```python
 authorizationresources
| where type =~ 'microsoft.authorization/roleassignments'
| extend roleDefinitionId= tolower(tostring(properties.roleDefinitionId))
| extend principalType = properties.principalType
| extend principalId = properties.principalId
| where principalType =~ 'ServicePrincipal' and properties.createdBy != ""
| join kind = inner (
 authorizationresources
 | where type =~ 'microsoft.authorization/roledefinitions'
| extend roleDefinitionId = tolower(id), roleName = tostring(properties.roleName)
| where properties.type =~ 'BuiltInRole'
| project roleDefinitionId,roleName
) on roleDefinitionId
| project principalId,roleName,roleDefinitionId
 ```

  ![Screenshot showing Azure resource graph query of the authorizationresources table getting assignments with builtin roles](https://images.seifbassem.com/images/Posts/ARG-Privileged-ServicePrincipals/03.png)

### Getting all service principals with assigned builtin roles and write permissions

To take this up a notch, we can also use this query to look for assignments that have specific permissions. Say you want to look for service principals that can do some damage having role assignments with _write_ and _delete_ permissions only.

If we look closely to the _roledefinition_ properties, we can see an array containing the permissions assigned to this role which we can leverage in our query

 ```python
 authorizationresources
 | where type =~ 'microsoft.authorization/roledefinitions'
| extend roleDefinitionId = tolower(id), roleName = tostring(properties.roleName)
| where properties.type =~ 'BuiltInRole'
 ```

  ![Screenshot showing Azure resource graph query of the authorizationresources table showing builtin roles' permissions](https://images.seifbassem.com/images/Posts/ARG-Privileged-ServicePrincipals/04.png)

We will use the query we built in step one and add an _mv-expand_ operator which expands an array so we can filter out its content to only show permissions with _write_ and _delete_

 ```python
 authorizationresources
| where type =~ 'microsoft.authorization/roleassignments'
| extend roleDefinitionId= tolower(tostring(properties.roleDefinitionId))
| extend principalType = properties.principalType
| extend principalId = properties.principalId
| extend scope = properties.scope
| where principalType =~ 'ServicePrincipal' and properties.createdBy != ""
| join kind = inner (
 authorizationresources
 | where type =~ 'microsoft.authorization/roledefinitions'
| extend roleDefinitionId = tolower(id), roleName = tostring(properties.roleName)
| extend permissions = properties.permissions
| where properties.type =~ 'BuiltInRole'
| mv-expand permissions
 | extend actions = permissions.actions
 | mv-expand actions
 | where actions contains "write" or actions contains "delete"
| project roleDefinitionId,roleName
) on roleDefinitionId
| project principalId,roleName,roleDefinitionId,scope
| distinct roleName,tostring(principalId),tostring(scope)
 ```

  ![Screenshot showing Azure resource graph query of the authorizationresources table showing role assignments with write or delete permissions](https://images.seifbassem.com/images/Posts/ARG-Privileged-ServicePrincipals/05.png)

## Best practices managing service principals

Managing service principals effectively requires a combination of proactive monitoring, regular auditing, and careful role assignment. Here are some best practices for tracking and managing service principals on Azure:

- **Limit the number of service principals:** The more service principals you have, the harder it is to track and manage them. Limiting the number of service principals and ensuring that each one has a clear business justification can help reduce the risk of untracked identities.
- **Assign roles carefully:** Only grant service principals the minimum privileges they need to perform their intended function. Avoid assigning overly broad or generic roles, such as "Owner" or "Contributor," to service principals unless absolutely necessary.
- **Use Azure AD Privileged Identity Management (PIM):** PIM provides a way to manage and monitor access to Azure resources by requiring users to request elevated permissions for a limited time. By using PIM, you can ensure that service principals with privileged roles are only active when they are needed and reduce the risk of unauthorized access.
- **Regularly audit service principals:** Regularly review service principals to ensure that they are still necessary and that their assigned roles are appropriate. Remove any service principals that are no longer needed or have overly broad permissions.
- **Monitor service principal activity:** Use Azure AD audit logs to monitor service principal activity and detect any unusual or suspicious behavior. By tracking service principal activity, you can quickly identify and respond to security threats.
- **Implement Conditional Access for workload identities:** Implement Conditional Access policies for controlling access to Azure resources by service principals.