*** Settings ***
Library    RequestsLibrary
Library    JSONSchemaLibrary
Library     JSONLibrary
Library    Collections
Library     BuiltIn
Library    ../resources/keywords/api_helpers.py
Resource    ../resources/keywords/keyword.robot.resource
Resource    ../resources/variables/variables.robot  # Import the variables from the external file
*** Variables ***
${ALL_PRODUCT_URL}     products
${SCHEMA_FILE}    resources/schema/product/getProduct.json
${SCHEMA_FILE_POST_METHOD}      resources/schema/product/addProduct.json
${MOCK_ALL_PRODUCT_RESPONSE_FILE}    resources/schema/product/response_allproduct_mock.json
${MOCK_SINGLE_PRODUCT_RESPONSE_FILE}    resources/schema/product/response_singleproduct_mock.json
${SINGLEPRODUCT_ENDPOINT}     /1
${LIMIT_ENDPOINT}       ?limit=
${LIMITPRODUCT_ENDPOINT}     ?limit=5
${SORTDESC_ENDPOINT}     ?sort=desc
${SORTASC_ENDPOINT}     ?sort=asc
${SORTPRODUCT_ENDPOINT}     ?sort=
${CATEGORISE_PRODUCT_ENDPOINT}     /categories
${SPECIFIC_CATEGORISE_ENDPOINT}     /category/
${SPECIFIC_CATEGORISE_PRODUCT_ENDPOINT}     /category/jewelery
@{LOOP_GET_ENDPOINTS_METHOD}        ${ALL_PRODUCT_URL}      ${ALL_PRODUCT_URL}${SINGLEPRODUCT_ENDPOINT}       ${ALL_PRODUCT_URL}${LIMITPRODUCT_ENDPOINT}        ${ALL_PRODUCT_URL}${SORTPRODUCT_ENDPOINT}     ${ALL_PRODUCT_URL}${CATEGORISE_PRODUCT_ENDPOINT}      ${ALL_PRODUCT_URL}${SPECIFIC_CATEGORISE_PRODUCT_ENDPOINT}

*** Test Cases ***
Test API Status Code Should Be 200
    FOR    ${endpoint}    IN    @{LOOP_GET_ENDPOINTS_METHOD}
        Check Endpoint Status    ${BASE_URL}${endpoint}
    END

Test API Response Times Less Than 2 Second
    FOR    ${endpoint}    IN    @{LOOP_GET_ENDPOINTS_METHOD}
        Check Response Time    ${BASE_URL}${endpoint}
    END

Test Schema Validation
#    Check Schema     ${BASE_URL}
    FOR    ${endpoint}    IN    @{LOOP_GET_ENDPOINTS_METHOD}
        Run Keyword If    'products/categories' != '${endpoint}'     Check Schema    ${BASE_URL}${endpoint}
#        Check Schema    ${BASE_URL}${endpoint}
    END
Test Product Limit By Maximum Index Value
    Create Session    api    ${BASE_URL}
    ${response}=    GET On Session    api    ${ALL_PRODUCT_URL}
    ${all_item_count}=    Get Length    ${response.json()}
    Create Session    api    ${BASE_URL}
    ${response_maxlimit}=    GET On Session    api    ${ALL_PRODUCT_URL}${LIMIT_ENDPOINT}${all_item_count}
    ${maxlimit_count}=    Get Length    ${response_maxlimit.json()}

    Should Be Equal     ${all_item_count}       ${maxlimit_count}

Test Product Limit By Zero
    Create Session    api    ${BASE_URL}
    ${response}=    GET On Session    api    ${ALL_PRODUCT_URL}
    ${all_item_count}=    Get Length    ${response.json()}
    ${zero}=        Evaluate    0
    Create Session    api    ${BASE_URL}
    ${response_maxlimit}=    GET On Session    api    ${ALL_PRODUCT_URL}${LIMIT_ENDPOINT}${zero}
    ${maxlimit_count}=    Get Length    ${response_maxlimit.json()}
    Should Be Equal     ${all_item_count}       ${maxlimit_count}

Test Product Limit By Specific Value
    ${specific_value}=        Evaluate    5
    Create Session    api    ${BASE_URL}
    ${response_specific}=    GET On Session    api    ${ALL_PRODUCT_URL}${LIMIT_ENDPOINT}${specific_value}
    ${specific_count}=    Get Length    ${response_specific.json()}
    Should Be Equal     ${specific_value}       ${specific_count}

Test Sorting Product Of id by Default
    [Documentation]    Verify if the `id` values in the response are sorted in ascending order.
    Create Session    api    ${BASE_URL}
    ${response}=    GET On Session    api    ${ALL_PRODUCT_URL}${SORTPRODUCT_ENDPOINT}
    ${specific_count}=    Get Length    ${response.json()}
    ${json_response}=       Evaluate        isinstance(${response.json()}, list)
    ${id_list}=    Get Ids From Response    ${response.json()}
    Log     ${json_response}
    Log    Extracted IDs: ${id_list}
    ${minimum_id}=    Get From List    ${id_list}    0    # First index is 0
    ${maximum_id}=     Get From List    ${id_list}    -1   # Last index is -1
    ${sorted_ids}=    Sort List Ascending    ${id_list}
    Log     ${sorted_ids}
    Should Be Equal    ${id_list}    ${sorted_ids}

Test Product ID Sorting: Max Value to Min Value
    [Documentation]    Verify if the `id` values in the response are sorted in ascending order.
    Create Session    api    ${BASE_URL}
    ${response}=    GET On Session    api    ${ALL_PRODUCT_URL}${SORTDESC_ENDPOINT}
    ${specific_count}=    Get Length    ${response.json()}
    ${json_response}=       Evaluate        isinstance(${response.json()}, list)
    ${id_list}=    Get Ids From Response    ${response.json()}
    Log     ${json_response}

    Log    Extracted IDs: ${id_list}
    ${sorted_ids}=    Sort List Descending    ${id_list}
    Log     ${sorted_ids}
    Should Be Equal    ${id_list}    ${sorted_ids}

Test Product ID Sorting: Min Value to Max Value
    [Documentation]    Verify if the `id` values in the response are sorted in ascending order.
    Create Session    api    ${BASE_URL}
    ${response}=    GET On Session    api    ${ALL_PRODUCT_URL}${SORTASC_ENDPOINT}
    ${specific_count}=    Get Length    ${response.json()}
    ${json_response}=       Evaluate        isinstance(${response.json()}, list)
    ${id_list}=    Get Ids From Response    ${response.json()}
    Log     ${json_response}
    Log    Extracted IDs: ${id_list}
    ${minimum_id}=    Get From List    ${id_list}    0    # First index is 0
    ${maximum_id}=     Get From List    ${id_list}    -1   # Last index is -1
    ${sorted_ids}=    Sort List Ascending    ${id_list}
    Log     ${sorted_ids}
    Should Be Equal    ${id_list}    ${sorted_ids}

Test Schema Of All Categories Should be List
    Create Session    api    ${BASE_URL}
    ${response}=    GET On Session    api    ${ALL_PRODUCT_URL}${CATEGORISE_PRODUCT_ENDPOINT}
    ${response_type}=    Evaluate    isinstance(${response.json()}, list)
    Should Be True      ${response_type}

Test Filter Specific Categories
    Create Session    api    ${BASE_URL}
    ${response}=    GET On Session    api    ${ALL_PRODUCT_URL}${CATEGORISE_PRODUCT_ENDPOINT}
    Get Products By Category Endpoint       ${BASE_URL}     ${ALL_PRODUCT_URL}${SPECIFIC_CATEGORISE_ENDPOINT}    ${response.json()}

Test Add New Product
    Create Session    api    ${BASE_URL}
    ${response_specific}=    GET On Session    api    ${ALL_PRODUCT_URL}
    ${specific_count}=    Get Length    ${response_specific.json()}
    ${id_list}=    Get Ids From Response    ${response_specific.json()}
    Log    Extracted IDs: ${id_list}
    ${maximum_id}=     Get From List    ${id_list}    -1   # Last index is -1

    ${response}=   Add Update Delete Product     ${BASE_URL}${ALL_PRODUCT_URL}     POST        ${maximum_id}
    # Add condition to check response type and perform action
    Validate Response Schema Post Method        ${response}       ${SCHEMA_FILE_POST_METHOD}

Test Update New Product with PUT
    ${specific_id}=        Evaluate    5
    ${response}=   Add Update Delete Product     ${BASE_URL}${ALL_PRODUCT_URL}/${specific_id}     PUT
    # Add condition to check response type and perform action
    Validate Response Schema Post Method        ${response}       ${SCHEMA_FILE_POST_METHOD}


Test Update New Product with PATCH
    ${specific_id}=        Evaluate    3
    ${response}=   Add Update Delete Product     ${BASE_URL}${ALL_PRODUCT_URL}/${specific_id}     PATCH
    # Add condition to check response type and perform action
    Validate Response Schema Post Method        ${response}       ${SCHEMA_FILE_POST_METHOD}

Test Delete New Product
    ${specific_id}=        Evaluate    3
    ${response}=   Add Update Delete Product     ${BASE_URL}${ALL_PRODUCT_URL}/${specific_id}     DELETE
    # Add condition to check response type and perform action
    Validate Response Schema Post Method        ${response}       ${SCHEMA_FILE_POST_METHOD}

*** Keywords ***
Check Schema
    [Arguments]     ${url}
    Create Session    api    ${BASE_URL}
    ${response}=    GET On Session    api    ${url}
    # Check if the response body is an array or an object
    ${response_type}=    Evaluate    isinstance(${response.json()}, list)
    # Add condition to check response type and perform action
    Run Keyword If    '${response_type}' == 'True'      Validate Response Schema        ${response}       ${SCHEMA_FILE}        ${SCHEMA_ALL_PRODUCT_TYPE}  # Example additional check for arrays
    Run Keyword If    '${response_type}' == 'False'      Validate Response Schema        ${response}     ${SCHEMA_FILE}      ${SCHEMA_SINGLE_PRODUCT_TYPE}

Convert To JSON
    [Arguments]    ${response}
    ${json_response}=    ${response.json()}    # Convert response to JSON
    RETURN   ${json_response}

Get Ids From Response
    [Arguments]    ${json_response}
    ${id_list}=    Create List
    FOR    ${item}    IN    @{json_response}
        ${id}=    Get From Dictionary    ${item}    id
        Append To List    ${id_list}    ${id}
    END
    RETURN    ${id_list}

Sort List Descending
    [Arguments]    ${id_list}
    ${sorted_ids}=    Evaluate    sorted(${id_list}, reverse=True)
    RETURN    ${sorted_ids}

Sort List Ascending
    [Arguments]    ${id_list}
    ${sorted_ids}=    Evaluate    sorted(${id_list}, reverse=False)
    RETURN   ${sorted_ids}

Get List From Json Response
    [Arguments]    ${response}
    ${categories}=    Get From List    ${response.json()}   index
    RETURN    ${categories}