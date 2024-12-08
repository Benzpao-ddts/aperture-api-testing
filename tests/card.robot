*** Settings ***
Library    RequestsLibrary
Library    JSONSchemaLibrary
Library     JSONLibrary
Library    Collections
Library     BuiltIn
Library    DateTime
Library    ../resources/keywords/api_helpers.py
Resource    ../resources/keywords/keyword.robot.resource
Resource    ../resources/variables/variables.robot  # Import the variables from the external file
*** Variables ***
${SCHEMA_FILE}    resources/schema/card/getCard.json
${SCHEMA_FILE_POST_METHOD}      resources/schema/card/addCard.json
${ALL_PRODUCT_URL}     carts
${SINGLEPRODUCT_ENDPOINT}     /1
${LIMIT_ENDPOINT}       ?limit=
${LIMITPRODUCT_ENDPOINT}     ?limit=5
${SORTDESC_ENDPOINT}     ?sort=desc
${SORTASC_ENDPOINT}     ?sort=asc
${SORTPRODUCT_ENDPOINT}     ?sort=


@{LOOP_GET_ENDPOINTS_METHOD}        ${ALL_PRODUCT_URL}      ${ALL_PRODUCT_URL}${SINGLEPRODUCT_ENDPOINT}     ${ALL_PRODUCT_URL}${LIMIT_ENDPOINT}     ${ALL_PRODUCT_URL}${SORTPRODUCT_ENDPOINT}

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

Test Sorting User Of Card by Default
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

Test Card ID Sorting: Max Value to Min Value
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

Test Card ID Sorting: Min Value to Max Value
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

Test Filter By Date
    ${start_date}=      Evaluate    datetime.datetime(2020,1,1)
    ${end_date}=        Evaluate    datetime.datetime(2020,6,25)
#    Create Session    api    ${BASE_URL}
    ${response}=        Is Date Within Range        ${BASE_URL}${ALL_PRODUCT_URL}       ${start_date}       ${end_date}
    Should Be True      ${response}
#    ${response}=    GET On Session    api    ${ALL_PRODUCT_URL}?startdate=${start_date}&enddate=${end_date}
#    Is Date Within Range

Test Add New Card
    Create Session    api    ${BASE_URL}
    ${userid}=     Evaluate    3
    ${response}=   Add Update Delete Card     ${BASE_URL}${ALL_PRODUCT_URL}     POST        ${userid}
    # Add condition to check response type and perform action
    Validate Response Schema Post Method        ${response}       ${SCHEMA_FILE_POST_METHOD}

Test Update New Product with PUT
    ${userid}=        Evaluate    5
    ${card_id}=        Evaluate    7
    ${response}=   Add Update Delete Card      ${BASE_URL}${ALL_PRODUCT_URL}/${card_id}     PUT     ${userid}
    # Add condition to check response type and perform action
    Validate Response Schema Post Method        ${response}       ${SCHEMA_FILE_POST_METHOD}


Test Update New Product with PATCH
    ${userid}=        Evaluate    3
    ${card_id}=        Evaluate    4
    ${response}=   Add Update Delete Card      ${BASE_URL}${ALL_PRODUCT_URL}/${card_id}     PATCH       ${userid}
    # Add condition to check response type and perform action
    Validate Response Schema Post Method        ${response}       ${SCHEMA_FILE_POST_METHOD}

Test Delete New Product
    ${userid}=        Evaluate    3
    ${card_id}=        Evaluate    4
    ${response}=   Add Update Delete Card      ${BASE_URL}${ALL_PRODUCT_URL}/${card_id}     DELETE
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