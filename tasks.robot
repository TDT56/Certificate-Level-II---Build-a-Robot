*** Settings ***
Documentation     Open the order website
...
...
Library           RPA.Browser.Selenium    auto_close=${TRUE}
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.FileSystem
Library           RPA.Dialogs
Library           RPA.Robocloud.Secrets
Library           mykeywords.py

*** Tasks ***
Order robots from RobotSpareBin Industries Inc    
    ${website} =    Input form Dialog
    Open the robot order website    ${website}
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order    ${row}
        ${pdf}=    Store the receipt as a PDF file    ${row}    #[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}    #[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    Remove temporary files
    
*** Keywords ***
Open the robot order website

    [Arguments]    ${website}
    Open Available Browser    ${website}
    Click Link    Order your robot!

Get orders
    ${secret}=    Get Secret    robotsparebin
    Download    ${secret}[csv_site]    overwrite=True  #https://robotsparebinindustries.com/orders.csv
    ${table}=    Read table from CSV    orders.csv    dialect=excel    header=True
    [Return]    ${table}

Close the annoying modal
    Click Button    OK

Fill the form
    [Arguments]    ${row}
    ${Body_ID}=    Get Body Name at Index    ${row}[Body]
    Select From List By Value    id:head    ${row}[Head]
    Click Button    ${Body_ID}
    Input Text    class:form-control    ${row}[Legs]
    Input Text    address    ${row}[Address]

Submit the order
    [Arguments]    ${row}
    Click Button    Order
    ${res}    Is element visible    id:order-another
    IF    ${res} == ${False}    # ALL THE IFS IS BECAUSE THE WHILE FUNCTION DIDN'T WANT TO WORK
        Click Button    Order
        ${res}    Is element visible    id:order-another
        IF    ${res} == ${False}
            Click Button    Order
            ${res}    Is element visible    id:order-another
            IF    ${res} == ${False}
                Click Button    Order
                ${res}    Is element visible    id:order-another
                IF    ${res} == ${False}
                Click Button    Order
                ${res}    Is element visible    id:order-another
                    IF    ${res} == ${False}
                Click Button    Order
                ${res}    Is element visible    id:order-another
                    END
                END
            END
        END
    END

Preview the robot
    Click Button    Preview

Go to order another robot
    Click Button    Order another robot

Store the receipt as a PDF file
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:order-completion
    ${res} =    Is element visible    id:order-completion
    IF    ${res} == ${False}    # the while function does not seem to be wokring
        Click Button    Order
    END
    ${sales_results_html}=    Get Element Attribute    id:order-completion    outerHTML
    ${PDF_name}=    Catenate    SEPARATOR=    ${row}[Order number]    .pdf
    Html To Pdf    ${row}    ${CURDIR}${/}${PDF_name}
    [Return]    ${PDF_name}

Take a screenshot of the robot
    [Arguments]    ${row}
    ${Filename}    Catenate    SEPARATOR=    ${row}[Order number]    .png
    Screenshot    id:robot-preview-image    filename=${Filename}
    [Return]    ${Filename}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${files}=    Create List
    ...    ${CURDIR}${/}${pdf}
    ...    ${CURDIR}${/}${screenshot}
    Add Files To PDF    ${files}    ${pdf}

Create a ZIP file of the receipts
    Archive Folder With Zip    ${CURDIR}    ${CURDIR}${/}myfiles.zip    recursive=false    include=*.pdf

Input form Dialog
    Add text input    website    label=Insert the original website: https://robotsparebinindustries.com/
    ${response}=    Run dialog
    [Return]    ${response.website}

Remove temporary files
    FOR    ${num}    IN RANGE    1    21    1
        ${pdf_name}=    Catenate    SEPARATOR=    ${num}    .pdf
        ${png_name}=    Catenate    SEPARATOR=    ${num}    .png
        Remove File    ${CURDIR}${/}${pdf_name}
        Remove File    ${CURDIR}${/}${png_name}
    END
