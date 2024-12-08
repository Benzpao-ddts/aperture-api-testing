from robot.api.deco import keyword
import json
import requests
from pathlib import Path
from jsonschema import validate
from jsonschema.exceptions import ValidationError
from datetime import datetime

@keyword
def check_response_status(response, expected_status):
    """Check if the response status code matches the expected status."""
    print(f"Status Code: {response.status_code}")
    print(f"Expected Status: {expected_status}")
    if response.status_code != expected_status:
        raise AssertionError(f"Expected status code {expected_status}, but got {response.status_code}")
    return True

@keyword
def check_response_time(response, max_response_time):
    """Check if the response time is less than the maximum allowed time (in milliseconds)."""
    response_time_ms = response.elapsed.total_seconds() * 1000  # Convert seconds to milliseconds
    if response_time_ms > max_response_time:
        raise AssertionError(f"Expected response time less than {max_response_time}ms, but got {response_time_ms}ms")
    return True

@keyword
def convert_to_json(response_text):
    """Convert JSON string to Python object."""
    return json.loads(response_text)

@keyword
def validate_response_schema(response, file_directory, schema_type):
    # Load the schema from the file
    try:
        schema_file_directory = Path(file_directory)
        schema_file_path = schema_file_directory.resolve()
        with open(schema_file_path, 'r') as f:
            schema = json.load(f)
        if schema_type == "SINGLE":
            schema = schema['items']
    except Exception as e:
        raise AssertionError(f"Failed to load schema file: {e}")

    # Validate the response against the schema
    try:
        json_response = response.json()  # Convert the response to JSON
        validate(instance=json_response, schema=schema)
        print("Schema validation passed!")
    except ValidationError as e:
        raise AssertionError(f"Schema validation failed: {e.message}")
    except Exception as e:
        raise AssertionError(f"Failed to process schema validation: {e}")

@keyword
def validate_response_schema_post_method(response, file_directory):
    # Load the schema from the file
    try:
        schema_file_directory = Path(file_directory)
        schema_file_path = schema_file_directory.resolve()
        with open(schema_file_path, 'r') as f:
            schema = json.load(f)

    except Exception as e:
        raise AssertionError(f"Failed to load schema file: {e}")

    # Validate the response against the schema
    try:
        json_response = response.json()  # Convert the response to JSON
        validate(instance=json_response, schema=schema)
        print("Schema validation passed!")
    except ValidationError as e:
        raise AssertionError(f"Schema validation failed: {e.message}")
    except Exception as e:
        raise AssertionError(f"Failed to process schema validation: {e}")

@keyword
def validate_responsemock_schema(response, file_directory,  schema_type):
        # Load the schema from the file
        try:
            schema_file_directory = Path(file_directory)
            schema_file_path = schema_file_directory.resolve()
            with open(schema_file_path, 'r') as f:
                schema = json.load(f)
            if schema_type == "SINGLE":
                schema = schema['items']
            res_file_directory = Path(response)
            res_file_path = res_file_directory.resolve()
            with open(res_file_path, 'r') as f:
                res_schema = json.load(f)
        except Exception as e:
            raise AssertionError(f"Failed to load schema file: {e}")

        # Validate the response against the schema
        try:
            json_response = res_schema  # Convert the response to JSON
            validate(instance=json_response, schema=schema)
            print("Schema validation passed!")
        except ValidationError as e:
            raise AssertionError(f"Schema validation failed: {e.message}")
        except Exception as e:
            raise AssertionError(f"Failed to process schema validation: {e}")
@keyword
def get_products_by_category_endpoint(base_url, endpoint, json_response):
    for name in json_response:
        # Construct the full URL
        full_url = f"{base_url}{endpoint}{name}"
        # Send GET request
        response = requests.get(full_url)
        if response.status_code == 200:
            # Parse the JSON response
            response_data = response.json()

            # Iterate over each item in the array
            for item in response_data:
                # Check if the item is a dictionary and contains the 'category' key
                if isinstance(item, dict) and 'category' in item:
                    if item['category'] == name:
                        print(f"Response for category '{name}' is valid: {item}")
                    else:
                        raise AssertionError(f"Mismatch: Expected category '{name}', but got '{item.get('category')}'")
                else:
                    print(f"Skipping invalid item: {item}")
        else:
            raise AssertionError(f"Failed to fetch data for category '{name}' with status code {response.status_code}")

@keyword
def add_update_delete_product(url, method, length_array=None):
    # Send the POST request with the JSON data
    new_product_data = {
                        "title": "test product",
                        "price": 13.5,
                        "description": "lorem ipsum set",
                        "image": "https://i.pravatar.cc",
                        "category": "electronic"
                    }
    headers = {
        'Content-Type': 'application/json'
    }
    if method == 'POST':
        response = requests.post(url, json=new_product_data, headers=headers)
    elif method == 'PATCH':
        response = requests.patch(url, json=new_product_data, headers=headers)
    elif method == 'PUT':
        response = requests.put(url, json=new_product_data, headers=headers)
    elif method == 'DELETE':
        response = requests.delete(url, headers=headers)
    # Log status code and response body for debugging
    print(f"Response Status Code: {response.status_code}")
    print(f"Response Body: {response.text}")
    assert response.status_code == 200

    # Check if the status code is 201 (created)
    if response.status_code == 200:
        response_data = response.json()
        if method == 'DELETE':
            assert str(response_data['id']) == url.split('/')[-1], f"Expected id to be {url.split('/')[-1]}, but got {response_data['id']}"
        else:
            if method == 'POST':
                add_length_array = length_array+1
                assert (response_data['id']) == add_length_array, f"Expected length array to be {add_length_array}"
            else:
                assert str(response_data['id']) == url.split('/')[-1], f"Expected id to be {url.split('/')[-1]}, but got {response_data['id']}"
            # Validate the response body (only if status is 201)
            assert response_data['title'] == new_product_data[
                'title'], f"Expected title to be {new_product_data['title']}, but got {response_data['title']}"
            assert response_data['price'] == new_product_data[
                'price'], f"Expected category to be {new_product_data['price']}, but got {response_data['price']}"
            assert response_data['description'] == new_product_data[
                'description'], f"Expected category to be {new_product_data['description']}, but got {response_data['description']}"
            assert response_data['image'] == new_product_data[
                'image'], f"Expected category to be {new_product_data['image']}, but got {response_data['image']}"
            assert response_data['category'] == new_product_data[
                'category'], f"Expected category to be {new_product_data['category']}, but got {response_data['category']}"
    else:
        print(f"Failed to add product. Status code: {response.status_code}")
    return response

@keyword
def add_update_delete_card(url, method, userid=None):
    # Send the POST request with the JSON data
    new_product_data = {
                        "userId": userid,
                        "date": "2020-02-03",
                        "products": [
                            {"productId": 5, "quantity": 1},
                            {"productId": 1, "quantity": 5}
                        ]
                    }
    headers = {
        'Content-Type': 'application/json'
    }

    if method == 'POST':
        print(url)
        response = requests.post(url, json=new_product_data, headers=headers)
    elif method == 'PATCH':
        response = requests.patch(url, json=new_product_data, headers=headers)
    elif method == 'PUT':
        response = requests.put(url, json=new_product_data, headers=headers)
    elif method == 'DELETE':
        response = requests.delete(url, headers=headers)
    # Log status code and response body for debugging
    print(f"Response Status Code: {response.status_code}")
    print(f"Response Body: {response.text}")
    assert response.status_code == 200

    # Check if the status code is 201 (created)
    if response.status_code == 200:
        response_data = response.json()
        if method == 'DELETE':
            assert (str(response_data['id'])) == str(url.split('/')[-1]), f"Expected id to be {url.split('/')[-1]}"
        else:
            if method == 'POST':
                assert (response_data['userId']) == userid, f"Expected userId to be {userid}"

            else:
                assert (response_data['userId']) == userid, f"Expected userId to be {userid}"
            assert response_data['date'] == new_product_data[
                'date'], f"Expected title to be {new_product_data['date']}, but got {response_data['date']}"
            assert response_data['products'] == new_product_data[
                'products'], f"Expected category to be {new_product_data['products']}, but got {response_data['products']}"
    else:
        print(f"Failed to add product. Status code: {response.status_code}")
    return response

@keyword
def add_update_delete_user(url, method):
    # Send the POST request with the JSON data
    new_product_data = {
                      "email": "John@gmail.com",
                      "username": "johnd",
                      "password": "m38rmF$",
                      "name": {
                        "firstname": "John",
                        "lastname": "Doe"
                      },
                      "address": {
                        "city": "kilcoole",
                        "street": "7835 new road",
                        "number": 3,
                        "zipcode": "12926-3874",
                        "geolocation": {
                          "lat": "-37.3159",
                          "long": "81.1496"
                        }
                      },
                      "phone": "1-570-236-7033"
                    }
    headers = {
        'Content-Type': 'application/json'
    }

    if method == 'POST':
        response = requests.post(url, json=new_product_data, headers=headers)
    elif method == 'PATCH':
        response = requests.patch(url, json=new_product_data, headers=headers)
    elif method == 'PUT':
        response = requests.put(url, json=new_product_data, headers=headers)
    elif method == 'DELETE':
        response = requests.delete(url, headers=headers)
    # Log status code and response body for debugging
    print(f"Response Status Code: {response.status_code}")
    print(f"Response Body: {response.text}")
    assert response.status_code == 200

    # Check if the status code is 201 (created)
    if response.status_code == 200:
        response_data = response.json()
        if method == 'DELETE':
            assert (str(response_data['id'])) == str(url.split('/')[-1]), f"Expected id to be {url.split('/')[-1]}"
        else:
            if method == 'POST':
                del response_data["id"]
                assert (response_data) == new_product_data, f"Expected actual response to be expected response"
            else:
                assert (response_data) == new_product_data, f"Expected actual response to be expected response"

    else:
        print(f"Failed to add product. Status code: {response.status_code}")
    return response

@keyword
def is_date_within_range(url, start_date, end_date):
    headers = {
        'Content-Type': 'application/json'
    }

    start_date_endpoint = str(start_date).replace(' 00:00:00', '')
    end_date_endpoint = str(end_date).replace(' 00:00:00', '')
    response = requests.get(f"{url}?startdate={start_date_endpoint}&enddate={end_date_endpoint}", headers=headers)
    assert response.status_code == 200
    if response.status_code == 200:
        original_format = "%Y-%m-%d %H:%M:%S"
        start_date_obj = datetime.strptime(str(start_date), original_format)
        end_date_obj = datetime.strptime(str(end_date), original_format)
        response_data = response.json()

        for card in response_data:
            response_date_obj = (datetime.strptime(card['date'], "%Y-%m-%dT%H:%M:%S.%fZ"))
            print('start_date_obj',start_date_obj)
            print('end_date_obj',end_date_obj)
            print('response_date_obj',response_date_obj)
            if start_date_obj <= response_date_obj <= end_date_obj:
                return True
            else:
                return False