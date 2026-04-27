# Architecture Documentation

## DynamoDB data model design for Examitem
- Single table design for scalability and avoids heavy join operations
    - CURRENT items, version history, and audit logs are stored as separate item types distinguished by SK prefixes, avoiding the need for separate tables
- CRUD operations
- version history tracking

### PK and SK structure
PK = item:test-item-0000
SK = current | version:000 | audit:0000000000

Supports:
    - Query all items with pagination
        ```
        Defined in Current Item
        GSI1PK = entity:item
        GSI1SK = lastModified (timestamp)
        ```
    - Query all versions of one item
        ```
        PK = item:test-item-0001
        SK begins_with version:
        ```
    - Query all audits for one item
        ```
        PK = item:test-item-0001
        SK begins_with audit:
        ```

### Current Item (Latest version):
```json
{
    "PK": "item:test-item-0001",
    "SK": "CURRENT",

    "id": "item-0001",
    "subject": "AP Biology",
    "itemType": "multiple-choice",
    "difficulty": 3,
    "content": {
        "question": "...",
        "options": ["A", "B", "C"],
        "correctAnswer": "A",
        "explanation": "..."
    },
    "metadata": {
        "author": "teacher1",
        "created": 1710000000,
        "lastModified": 1710000500,
        "version": 3,
        "status": "approved",
        "tags": ["example-tag"]
    },
    "securityLevel": "standard",

    "GSI1PK": "entity:item",
    "GSI1SK": 1710000500 // matches last modified
}
```

### Audit item event log
Track specific changes made when updating an item, and version change
```json
{
    "PK": "item:test-item-0001",
    "SK": "audit:78247388000",

    "action": "UPDATED",
    "actor": "teacher1",

    "changes": {
        "difficulty": {
            "from": 2,
            "to": 3
        },
        "metadata.tags": {
            "from": ["example-tag"],
            "to": ["example-tag", "biology"]
        }
    }
}
```

### Version Item snapshot
Even though audits would track changes, they wouldnt track what a test item looked like at a specific version without replaying the audits for that test item.

```json
{
    "PK": "item:test-item-0001",
    "SK": "version:003",

    "version": 3,
    "snapshot": {
        "subject": "AP Biology",
        "itemType": "multiple-choice",
        "difficulty": 3,
        "content": {
            "question": "...",
            "options": ["A", "B", "C"],
            "correctAnswer": "A",
            "explanation": "..."
        },
        "metadata": {
            "author": "teacher1",
            "created": 1710000000,
            "lastModified": 1710000500,
            "version": 3,
            "status": "approved",
            "tags": ["example-tag"]
        },
        "securityLevel": "standard"
    },
    "createdAt": 1710000500,
    "createdBy": "teacher1"
}
```

## Infrastructure choices
CDK vs Terraform:
- Referenced this article for a quick overview of both. Went with Terraform for learning curve, community support, and ability to use this skill outside of AWS environment.
- https://medium.com/@kansvignesh/aws-cdk-vs-terraform-738c39d91f7a

## Scalability
- DynamoDB uses GSI for flexible system wide querying
- The sort key stores multiple record types (current, versions, audits) under a single item partition for single-partition queries

## Security
- Implemented IAM-based service authorization between AWS services, not end-user auth with the time constraint
    - Lambda runs under a IAM role
    - Allowed limited privileges for DB access: GetItem, PutItem, UpdateItem, Query
    - Permissions for API gateway to invoke Lambda

## Trade-offs
- My goal was a vertical slice implementation so I could touch all the aspects of this assignment. Also focused more time on the things that I knew less.
    - Didnt imnplement all handlers
    - Didnt get to implementing all api endpoint Lambda functions in Terraform, only has a single shared Lambda for GET and POST to /items.

## Extra notes and research:
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