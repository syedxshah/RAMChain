# RAMChain API Instructions

This document explains all the available API endpoints for RAMChain, their required arguments, and how they work.

---

## 1. Create a RAMChain Model
Creates a new RAMChain in-memory storage instance.

- **URL:** `/create`
- **Method:** `POST`
- **Payload (`CreateModel`):**
  - `name` (string, required): The unique name for your RAMChain instance.
  - `size` (int, optional, default: 100): The maximum size (in MB) allocated for this instance.
- **How it works:** Initializes a new `RAMChain` object in active memory under the provided `name`. If the model already exists, it returns an error.

---

## 2. Insert Data
Inserts a new key-value pair into a specific RAMChain model.

- **URL:** `/insert`
- **Method:** `POST`
- **Payload (`DataModel`):**
  - `name` (string, required): The name of the RAMChain model.
  - `key` (string, required): The unique identifier for the data.
  - `value` (string, required): The data to be stored.
  - `ttl` (int, optional, default: None): Time-To-Live in seconds. If set, the data will automatically expire after this duration. Use `0` or omit for no expiration.
- **How it works:** Checks if the model exists and if the key is already taken. If everything is valid, it inserts the key and value into memory.

---

## 3. Update Data
Updates the value of an existing key in a RAMChain model.

- **URL:** `/update`
- **Method:** `POST`
- **Payload (`UpdatedModel`):**
  - `name` (string, required): The name of the RAMChain model.
  - `key` (string, required): The key whose value needs updating.
  - `new_value` (string, required): The new value to store.
- **How it works:** Verifies the model and the key exist, then overwrites the old value with the `new_value`.

---

## 4. Get Specific Data
Fetches the value associated with a specific key.

- **URL:** `/getdata`
- **Method:** `POST` *(Recently updated from GET to support JSON body)*
- **Payload (`GetModel`):**
  - `name` (string, required): The name of the RAMChain model.
  - `key` (string, required): The key to retrieve.
- **How it works:** Looks up the provided key in the specified RAMChain model and returns its stored value. Also triggers the middleware to track access times.

---

## 5. Get All Data
Retrieves all key-value pairs stored in a specific RAMChain model.

- **URL:** `/getall/{name}`
- **Method:** `GET`
- **Path Parameter:**
  - `name` (string, required): The name of the RAMChain model (passed in the URL).
- **How it works:** Returns a dictionary of all active (non-expired) data currently stored in the specified model.

---

## 6. Delete Data
Removes a specific key-value pair from a RAMChain model.

- **URL:** `/delete`
- **Method:** `DELETE`
- **Payload (`DeleteDataModel`):**
  - `name` (string, required): The name of the RAMChain model.
  - `key` (string, required): The key you want to delete.
- **How it works:** Checks if the key exists, and if so, deletes it from the specified RAMChain model.

---

## 7. Check Remaining RAM
Gets the amount of available space left in the RAMChain model.

- **URL:** `/remaining_ram/{name}`
- **Method:** `GET`
- **Path Parameter:**
  - `name` (string, required): The name of the RAMChain model.
- **How it works:** Calculates the difference between the total allocated size and the currently used space, returning the remaining space in MB.

---

## 8. Check Space Used
Gets the total amount of RAM currently consumed by a RAMChain model.

- **URL:** `/space_used/{name}`
- **Method:** `GET`
- **Path Parameter:**
  - `name` (string, required): The name of the RAMChain model.
- **How it works:** Returns the total space taken by all stored data in the specified model, formatted in MB.

---

## 9. Check Total RAM
Gets the total maximum size allocated to a RAMChain model.

- **URL:** `/total_ram/{name}`
- **Method:** `GET`
- **Path Parameter:**
  - `name` (string, required): The name of the RAMChain model.
- **How it works:** Returns the maximum configured size (in MB) that was set when the model was created.

---

### Additional Features (Middleware)
Every time a `POST` or `GET` request is made (except for `/create`, `/docs`, and `/openapi.json`), a background process runs to:
1. Update the "last accessed" order of the data.
2. Automatically clean up and delete any data whose `ttl` (Time-To-Live) has expired.
