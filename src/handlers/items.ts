/**
 * Items Handlers
 * 
 * Constains the handlers for item-related operations, such as creating, retrieving, updating, and listing items. 
 * Each handler interacts with the storage layer to perform the necessary operations and returns appropriate HTTP responses.
 */

import { createStorage } from '../storage/index.js';
import { ExamItemSchema } from '../types/item/item.schema.js';

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

// TODO: Implement other handlers:
// - updateItemHandler
// - listItemsHandler

// TODO: Implement versioning and audit trail handlers in separate files:
// - createVersionHandler
// - getAuditTrailHandler
