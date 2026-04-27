/**
 * Items Handlers
 * 
 * Constains the handlers for item-related operations, such as creating, retrieving, updating, and listing items. 
 * Each handler interacts with the storage layer to perform the necessary operations and returns appropriate HTTP responses.
 */

import { createStorage } from '../storage/index.js';
import { ExamItemSchema, UpdateExamItemSchema } from '../types/item/item.schema.js';

const storage = createStorage();

export async function getItemHandler(id: string) {
  try {
    const item = await storage.getItem(id);

    if (!item) {
      return {
        statusCode: 404,
        body: { error: 'Item not found' },
      };
    }

    return {
      statusCode: 200,
      body: item,
    };
  } catch (error) {
    console.error('Error getting item:', error);
    return {
      statusCode: 500,
      body: { error: 'Internal server error' },
    };
  }
}

export async function createItemHandler(data: any) {
  try {
    
    // Add validation using Zod
    const validatedData = ExamItemSchema.safeParse(data); // This returns the CreateItemRequest object schema
    if (!validatedData.success) {
      return {
        statusCode: 400,
        body: { error: 'Invalid item data' }, // TODO find a way to show exactly what is causing the error https://zod.dev/error-customization
        details: validatedData.error.flatten(),
      };
    }

    const item = await storage.createItem(validatedData.data);

    return {
      statusCode: 201,
      body: item,
    };
  } catch (error) {
    console.error('Error creating item:', error);
    return {
      statusCode: 500,
      body: { error: 'Internal server error' },
    };
  }
}

export async function updateItemHandler(id: string, data: any) {
  try {
    if (!id) {
      return {
        statusCode: 400,
        body: { error: "Missing item id" },
      };
    }

    const validatedData = UpdateExamItemSchema.safeParse(data);

    if (!validatedData.success) {
      return {
        statusCode: 400,
        body: { error: "Invalid update data" },
        details: validatedData.error.flatten(),
      };
    }

    const updatedItem = await storage.updateItem(id, validatedData.data);

    if (!updatedItem) {
      return {
        statusCode: 404,
        body: { error: "Item not found" },
      };
    }

    return {
      statusCode: 200,
      body: updatedItem,
    };
  } catch (error) {
    console.error("Error updating item:", error);

    return {
      statusCode: 500,
      body: { error: "Internal server error" },
    };
  }
}
export async function createVersionHandler(id: string) {
  try {
    if (!id) {
      return {
        statusCode: 400,
        body: { error: "Missing item id" },
      };
    }

    const newVersion = await storage.createVersion(id);

    if (!newVersion) {
      return {
        statusCode: 404,
        body: { error: "Item not found" },
      };
    }

    return {
      statusCode: 201,
      body: newVersion,
    };

  } catch (error) {
    console.error("Error creating version:", error);

    return {
      statusCode: 500,
      body: { error: "Internal server error" },
    };
  }
}

// TODO: Implement other handlers:
// - listItemsHandler

// TODO: Ideally Implement versioning and audit trail handlers in their own files:
// Storage creation is not singleton
// - createVersionHandler
// - getAuditTrailHandler
