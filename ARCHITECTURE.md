# Architecture Documentation

## Research:
- While prerequisites were installing and I was doing project cloning and setup, I researched the following:
### Zod:
    - Used for input validation when creating new exam items
    - Zod package already installed
    - Documentation says to modify tsconfig.json for typescript v5.5 and greater for best practice https://zod.dev/?id=requirements (This was already done)
    - Either create Zod schema in the same file as the item.ts or create a validators folder for separation of concerns. 
        - Went with an in the middle, moved item.ts into types/item/ folder. Added schema file there. That way a general "validators" file doesnt exist that could contain all kinds of validators. Instead the schema lives next to item.ts but is still in its own file for separation. 
### Handlers:
    Separate by resposibility:
        - items.ts will contain CRUD operations for items (get, create, update, list)
        - versions.ts will contain createVersionHandler and version management related things
        - audit.ts will contain getAuditTrailHandler and audit related things
### CDK vs Terraform
    - Referenced this article for a quick overview of both. Went with Terraform for learning curve, community support, and ability to use this skill outside of AWS environment.
    - https://medium.com/@kansvignesh/aws-cdk-vs-terraform-738c39d91f7a
