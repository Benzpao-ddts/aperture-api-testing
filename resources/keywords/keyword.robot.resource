# Created by benzddts at 8/12/2024 AD
*** Settings ***
Library    RequestsLibrary
Library    JSONSchemaLibrary
Library     JSONLibrary
Library    ../keywords/api_helpers.py
Resource    ../variables/variables.robot  # Import the variables from the external file

*** Keywords ***
Get Response Elapsed Time
    [Arguments]    ${response}
    ${elapsed_time}=    Evaluate    str(${response.elapsed.total_seconds()})
    RETURN    ${elapsed_time}

Check Endpoint Status
    [Arguments]    ${url}
    Create Session    api    ${BASE_URL}
    ${response}=    GET On Session    api    ${url}
    ${int_status}=    Convert To Integer    ${EXPECTED_STATUS_CODE}
    Should Be Equal As Numbers    ${response.status_code}    ${int_status}
    Check response status    ${response}    ${int_status}

Check Response Time
    [Arguments]     ${url}
    Create Session    api    ${BASE_URL}
    ${response}=    GET On Session    api    ${url}
    ${elapsed_time}=    Get Response Elapsed Time    ${response}
    Log    Response time: ${elapsed_time}
    Should Be True    ${elapsed_time} < ${MAX_RESPONSE_TIME}

Check Response Content Length
    [Arguments]    ${response}
    ${length}=    Get Length    ${response.json()}
    Log    The length of the array is ${length}

