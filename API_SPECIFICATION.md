# Flask CRUD API - API Specification

## Base URL
```
Local: http://localhost:5000
K8s:   http://flask-api-service:80 (internal)
```

---

## 1. CREATE - Add New User

### Request
```
POST /api/users
Content-Type: application/json

{
  "name": "John Doe",           // Required: string, max 100 chars
  "email": "john@example.com",  // Required: string, must be unique
  "city": "New York",           // Required: string, max 100 chars
  "age": 30                     // Optional: integer
}
```

### Success Response (201 Created)
```json
{
  "message": "User created successfully",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "city": "New York",
    "age": 30,
    "created_at": "2026-05-13T10:30:45.123456",
    "updated_at": "2026-05-13T10:30:45.123456"
  }
}
```

### Error Responses

**Missing Required Field (400 Bad Request)**
```json
{
  "error": "name, email, and city are required"
}
```

**Duplicate Email (409 Conflict)**
```json
{
  "error": "Email already exists"
}
```

**Server Error (500)**
```json
{
  "error": "error description"
}
```

---

## 2. READ - Get All Users

### Request
```
GET /api/users?page=1&per_page=10
```

### Query Parameters
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| page | integer | 1 | Page number for pagination |
| per_page | integer | 10 | Number of users per page |

### Success Response (200 OK)
```json
{
  "users": [
    {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "city": "New York",
      "age": 30,
      "created_at": "2026-05-13T10:30:45.123456",
      "updated_at": "2026-05-13T10:30:45.123456"
    },
    {
      "id": 2,
      "name": "Jane Smith",
      "email": "jane@example.com",
      "city": "London",
      "age": 28,
      "created_at": "2026-05-13T10:31:20.654321",
      "updated_at": "2026-05-13T10:31:20.654321"
    }
  ],
  "total": 2,
  "pages": 1,
  "current_page": 1
}
```

### Error Response (500)
```json
{
  "error": "error description"
}
```

---

## 3. READ - Get Single User

### Request
```
GET /api/users/{id}
```

### Path Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| id | integer | User ID |

### Success Response (200 OK)
```json
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "city": "New York",
  "age": 30,
  "created_at": "2026-05-13T10:30:45.123456",
  "updated_at": "2026-05-13T10:30:45.123456"
}
```

### Error Responses

**User Not Found (404)**
```json
{
  "error": "User not found"
}
```

**Server Error (500)**
```json
{
  "error": "error description"
}
```

---

## 4. UPDATE - Modify User

### Request
```
PUT /api/users/{id}
Content-Type: application/json

{
  "name": "Jane Doe",      // Optional: update name
  "email": "jane@example.com",  // Optional: update email (must be unique)
  "city": "Paris",         // Optional: update city
  "age": 31                // Optional: update age
}
```

### Path Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| id | integer | User ID |

### Success Response (200 OK)
```json
{
  "message": "User updated successfully",
  "user": {
    "id": 1,
    "name": "Jane Doe",
    "email": "jane@example.com",
    "city": "Paris",
    "age": 31,
    "created_at": "2026-05-13T10:30:45.123456",
    "updated_at": "2026-05-13T10:35:12.789123"
  }
}
```

### Error Responses

**User Not Found (404)**
```json
{
  "error": "User not found"
}
```

**Duplicate Email (409 Conflict)**
```json
{
  "error": "Email already exists"
}
```

**Server Error (500)**
```json
{
  "error": "error description"
}
```

---

## 5. DELETE - Remove User

### Request
```
DELETE /api/users/{id}
```

### Path Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| id | integer | User ID |

### Success Response (200 OK)
```json
{
  "message": "User deleted successfully"
}
```

### Error Responses

**User Not Found (404)**
```json
{
  "error": "User not found"
}
```

**Server Error (500)**
```json
{
  "error": "error description"
}
```

---

## 6. UTILITY - Health Check

### Request
```
GET /health
```

### Success Response (200 OK)
```json
{
  "status": "healthy"
}
```

---

## 7. LEGACY - Welcome Message

### Request
```
GET /
```

### Success Response (200 OK)
```json
{
  "message": "Good morning from Shreyas K N! Welcome to CRUD API with MySQL"
}
```

---

## 8. LEGACY - Greeting Endpoint

### Request
```
GET /greeting?Name=John&City=NewYork
```

### Query Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| Name | string | User's name (required) |
| City | string | User's city (required) |

### Success Response (200 OK)
```json
{
  "Greeting": "Hello John",
  "Message": "How are things at NewYork?"
}
```

### Error Response (403 Forbidden)
```json
{
  "Message": "Name and City fields are required"
}
```

---

## HTTP Status Codes Summary

| Code | Meaning | Common Causes |
|------|---------|---------------|
| 200 | OK | Successful GET, PUT, DELETE |
| 201 | Created | User created successfully |
| 400 | Bad Request | Missing required fields, invalid data |
| 403 | Forbidden | Missing query parameters in greeting |
| 404 | Not Found | User ID doesn't exist |
| 409 | Conflict | Email already exists |
| 500 | Server Error | Database connection failure, internal error |

---

## Data Types & Constraints

### User Object
| Field | Type | Constraints | Nullable |
|-------|------|-------------|----------|
| id | Integer | Primary Key, Auto-increment | No |
| name | String | Max 100 characters | No |
| email | String | Max 100 characters, Unique | No |
| city | String | Max 100 characters | No |
| age | Integer | None | Yes |
| created_at | DateTime | Auto-set on creation | No |
| updated_at | DateTime | Auto-set on update | No |

---

## Example cURL Commands

### Create User
```bash
curl -X POST http://localhost:5000/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "city": "New York",
    "age": 30
  }'
```

### Get All Users
```bash
curl http://localhost:5000/api/users
```

### Get All Users with Pagination
```bash
curl "http://localhost:5000/api/users?page=1&per_page=20"
```

### Get Single User
```bash
curl http://localhost:5000/api/users/1
```

### Update User (partial update)
```bash
curl -X PUT http://localhost:5000/api/users/1 \
  -H "Content-Type: application/json" \
  -d '{
    "age": 31
  }'
```

### Delete User
```bash
curl -X DELETE http://localhost:5000/api/users/1
```

### Health Check
```bash
curl http://localhost:5000/health
```

### Greeting
```bash
curl "http://localhost:5000/greeting?Name=Shreyas&City=Bangalore"
```

---

## Response Headers

All responses include:
```
Content-Type: application/json
```

---

## Rate Limiting
Currently not implemented. Can be added with Flask-Limiter in future.

---

## Authentication
Currently not implemented. Can be added with Flask-JWT-Extended in future.

---

## API Versioning
Currently at v1 (default). URL structure allows for versioning: `/api/v1/users`

---

## Pagination Details

### Default Behavior
- Page: 1 (first page)
- Per page: 10 items

### Response Fields
```json
{
  "users": [...],           // Array of user objects
  "total": 50,              // Total number of users in database
  "pages": 5,               // Total number of pages
  "current_page": 1         // Current page number
}
```

---

## Error Handling Best Practices

1. **Always include error field** with descriptive message
2. **Use appropriate HTTP status codes**
3. **Don't expose sensitive information** in error messages
4. **Log errors server-side** for debugging
5. **Validate input** before processing

---

## Future Enhancements

- [ ] JWT Authentication
- [ ] API Key authentication
- [ ] Rate limiting
- [ ] Request logging
- [ ] API versioning
- [ ] Swagger/OpenAPI documentation
- [ ] Database transactions
- [ ] Caching (Redis)
- [ ] Advanced filtering/searching
- [ ] Export to CSV/Excel

---

**API Specification Version:** 1.0  
**Last Updated:** May 13, 2026  
**Status:** Production Ready ✅

