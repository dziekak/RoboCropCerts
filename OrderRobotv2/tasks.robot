*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Variables ***
${TEMP_FOLDER}      ${OUTPUT_DIR}${/}output


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${url}=    Ask for URL
    ${secret}=    Get Secret    secret_name=urls
    Open the robot order website    ${url}
    ${orders}=    Get orders    ${secret}[robo]
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the from    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    Clean up


*** Keywords ***
Open the robot order website
    [Arguments]    ${url}
    Open Available Browser    ${url}
    #https://robotsparebinindustries.com/#/robot-order

Get orders
    [Arguments]    ${url}
    Download    ${url}    ${TEMP_FOLDER}${/}orders.csv    overwrite=True
    ${orders table}=    Read table from CSV    ${TEMP_FOLDER}${/}orders.csv
    RETURN    ${orders table}

Close the annoying modal
    Click Button    OK

Fill the from
    [Arguments]    ${row}
    Select From List By Index    id:head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath://input[@placeholder='Enter the part number for the legs']    ${row}[Legs]
    Input Text    id:address    ${row}[Address]

Preview the robot
    Click Button    Preview

Submit the order
    Wait Until Keyword Succeeds    10x    2s    Click order

Store the receipt as a PDF file
    [Arguments]    ${order number}
    ${receipt}=    Get Element Attribute    id:receipt    outerHTML
    ${pdf path}=    Set Variable    ${TEMP_FOLDER}${/}${order number}.pdf
    Html To Pdf    ${receipt}    ${pdf path}
    RETURN    ${pdf path}

Take a screenshot of the robot
    [Arguments]    ${order number}
    ${screenshot path}=    Set Variable    ${TEMP_FOLDER}${/}${order number}.png
    Screenshot    id:robot-preview-image    filename=${screenshot path}
    RETURN    ${screenshot path}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}

Go to order another robot
    Click Button    id:order-another

Click order
    Click Button    id:order
    Assert ordered

Assert ordered
    Wait Until Page Contains    Receipt    1s

Create a ZIP file of the receipts
    Archive Folder With Zip    ${TEMP_FOLDER}    ${TEMP_FOLDER}${/}PDFs.zip    include=*.pdf

Ask for URL
    Add heading    Provide URL
    Add text input    url    label=URL Adress
    ${result}=    Run dialog
    RETURN    ${result.url}

Clean up
    ${files patterns}=    Create List    *.png    *.pdf    *.csv
    FOR    ${pattern}    IN    @{files patterns}
        ${files}=    Find files    ${TEMP_FOLDER}${/}${pattern}
        FOR    ${file}    IN    @{files}
            Remove File    ${file}
        END
    END
