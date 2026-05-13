#!/bin/bash

# Quick Test Script for Flask CRUD API

API_URL="http://localhost:5000"

echo "======================================"
echo "Flask CRUD API - Quick Test Script"
echo "======================================"

# Test 1: Health Check
echo -e "\n1. Health Check:"
curl -s -X GET $API_URL/health | python -m json.tool

# Test 2: Home Endpoint
echo -e "\n2. Home Endpoint:"
curl -s -X GET $API_URL/ | python -m json.tool

# Test 3: Original Greeting Endpoint
echo -e "\n3. Greeting Endpoint:"
curl -s -X GET "$API_URL/greeting?Name=Shreyas&City=Bangalore" | python -m json.tool

# Test 4: Create User 1
echo -e "\n4. Create User 1:"
USER1=$(curl -s -X POST $API_URL/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "city": "New York",
    "age": 30
  }')
echo $USER1 | python -m json.tool

# Test 5: Create User 2
echo -e "\n5. Create User 2:"
USER2=$(curl -s -X POST $API_URL/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Jane Smith",
    "email": "jane@example.com",
    "city": "London",
    "age": 28
  }')
echo $USER2 | python -m json.tool

# Test 6: Get All Users
echo -e "\n6. Get All Users:"
curl -s -X GET "$API_URL/api/users?page=1&per_page=10" | python -m json.tool

# Test 7: Get Single User
echo -e "\n7. Get Single User (ID: 1):"
curl -s -X GET $API_URL/api/users/1 | python -m json.tool

# Test 8: Update User
echo -e "\n8. Update User (ID: 1):"
curl -s -X PUT $API_URL/api/users/1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Updated",
    "age": 31
  }' | python -m json.tool

# Test 9: Get Updated User
echo -e "\n9. Get Updated User (ID: 1):"
curl -s -X GET $API_URL/api/users/1 | python -m json.tool

# Test 10: Delete User
echo -e "\n10. Delete User (ID: 2):"
curl -s -X DELETE $API_URL/api/users/2 | python -m json.tool

# Test 11: Verify User Deleted
echo -e "\n11. Get All Users After Delete:"
curl -s -X GET "$API_URL/api/users?page=1&per_page=10" | python -m json.tool

# Test 12: Error Cases
echo -e "\n12. Test Error - Missing Required Field:"
curl -s -X POST $API_URL/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Incomplete User"
  }' | python -m json.tool

echo -e "\n13. Test Error - Duplicate Email:"
curl -s -X POST $API_URL/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Duplicate User",
    "email": "john@example.com",
    "city": "Paris",
    "age": 25
  }' | python -m json.tool

echo -e "\n14. Test Error - User Not Found:"
curl -s -X GET $API_URL/api/users/999 | python -m json.tool

echo -e "\n======================================"
echo "Tests Complete!"
echo "======================================"

