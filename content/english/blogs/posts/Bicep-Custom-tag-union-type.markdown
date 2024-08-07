---
title: "Bicep - Custom-tagged union data type"
images:
  - "https://images.seifbassem.com/images/Posts/custom-tagged-union-data-type/banner.png"
date: 2024-08-06 17:08:42 +0200
tags: ["Azure","Bicep","Infrastructure-as-code"]
categories: ["posts"]
draft: false
---

<!--more-->

Recently while building a Bicep template, I faced a situation where I wanted to have a parameter's type to be one of multiple types depending on the user's choice. I first started with using user-defined types but the parameter had to have just one type 😕😕. Then I stumbled upon `Custom-tagged union data type` which gave me exactly the flexibility I was looking for. Let's see how it works and how I used it.

## Scenario

In my Bicep module, I wanted to simplify defining [RBAC constrained delegation conditions](https://learn.microsoft.com/azure/role-based-access-control/delegate-role-assignments-portal) which allows you to define a set of rules when delegating role assignment to others. The code for those conditions can be challenging to build or understand so in the portal, you have some templates that simplify the code authoring immensely.

![Screenshot showing RBAC constrained delegation templates in the poral](https://images.seifbassem.com/images/Posts/custom-tagged-union-data-type/01.png)

Those templates allow you to restrict role assignment as follows:

| Template  | Conditions  |
|---|---|
| Constrain roles  | Allow user to only assign roles you select  |
| Constrain roles and principal types  | Allow user to only assign these roles to principal types you select (users, groups, or service principals)  |
| Constrain roles and principals  | Allow user to only assign these roles to principals you select  |
| Allow all except specific roles | Allow user to assign all roles except the roles you select |

## Scenario

To represent this in Bicep, I started first by defining a user-defined type for each template.

```bicep
type constrainRolesType = {
  rolesToAssign: array
}

type constrainRolesAndPrincipalTypesType = {
  rolesToAssign: array
  principleTypesToAssign: ('User' | 'Group' | 'ServicePrincipal')[]
}

type constrainRolesAndPrincipalsType = {
  rolesToAssign: array
  principalsToAssignTo: array
}

type excludeRolesType = {
  ExludededRoles: array
}
```

And now when I define a parameter to allow the user to select the template of their choice, I got stuck as the parameter needed to be of just one type.

```bicep
param roleConditionTemplate <Which type to use ??>
```

I wanted to have this parameter to accept multiple types so it can either be `constrainRolesType` or `constrainRolesAndPrincipalTypesType` or `constrainRolesAndPrincipalsType` or `excludeRolesType` so the user has the same experience in the portal as they can select only one template and populate it's properties.

## Custom-tagged union data type to the rescue 💡

As I was looking for a solution or even a different way to do this, I found something called "Custom-tagged union data type" which as explained in the Bicep documentation

> Bicep supports custom tagged union data type, which is used to represent a value that can be one of several different types

Which is exactly what I wanted to do 😃

To use it, we have to use the `@discriminator()` decorator which takes a single parameter, that represents a shared property name among all union members (in my case the user-defined types). This property name must be required on all members, unique and case-sensitive. Let's see how to do this.

```bicep
type constrainRolesType = {
  templateName: 'constrainRoles'
  rolesToAssign: array
}

type constrainRolesAndPrincipalTypesType = {
  templateName: 'constrainRolesAndPrincipalTypes'
  rolesToAssign: array
  principleTypesToAssign: ('User' | 'Group' | 'ServicePrincipal')[]
}

type constrainRolesAndPrincipalsType = {
  templateName: 'constrainRolesAndPrincipals'
  rolesToAssign: array
  principalsToAssignTo: array
}

type excludeRolesType = {
  templateName: 'excludeRoles'
  ExludededRoles: array
}

@discriminator('templateName')
type constrainedDelegationTemplatesType = excludeRolesType | constrainRolesType | constrainRolesAndPrincipalTypesType | constrainRolesAndPrincipalsType

type roleAssignmentCondtionType = {
  roleConditionType: constrainedDelegationTemplatesType?
  delegationCode: string?
  conditionVersion: '2.0'?
}
```

Adding to my previous code, I had to add a `templateName` property for each type to be used as a discriminator, in my case I can use the template name which is unique across all types. I defined a new type `constrainedDelegationTemplatesType` that represents the user's choice of any type of template.

Now in my code, I can defined a parameter of this type and this would give me the user experience I'm looking for.

```bicep
param roleAssignmentCondition roleAssignmentCondtionType
```

![Screenshot showing the option to select one of the templates](https://images.seifbassem.com/images/Posts/custom-tagged-union-data-type/02.png)

![Screenshot showing the option to select one of the templates](https://images.seifbassem.com/images/Posts/custom-tagged-union-data-type/03.png)

![Screenshot showing the option to select one of the templates](https://images.seifbassem.com/images/Posts/custom-tagged-union-data-type/04.png)

![Screenshot showing the option to select one of the templates](https://images.seifbassem.com/images/Posts/custom-tagged-union-data-type/05.png)

## References

- [Custom tagged union data type documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/data-types#custom-tagged-union-data-type)
- [A quick intro into user-defined types in Bicep](https://www.seifbassem.com/blogs/posts/bicep-user-defined-types/)