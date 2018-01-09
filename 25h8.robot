*** Settings ***
Library  Selenium2Library
Library  BuiltIn
Library  Collections
Library  String
Library  DateTime
Library  25h8_service.py

*** Variables ***

${host}=  test.25h8.auction
${acceleration}=  720

*** Keywords ***

Підготувати дані для оголошення тендера
  [Arguments]  ${username}  ${tender_data}  ${role_name}
  ${tender_data}=   adapt_procuringEntity   ${role_name}   ${tender_data}
  [return]  ${tender_data}

Підготувати клієнт для користувача
  [Arguments]  ${username}
  Set Suite Variable  ${my_alias}  ${username + 'CUSTOM'}
  Open Browser  ${USERS.users['${username}'].homepage}  ${USERS.users['${username}'].browser}  alias=${my_alias}
  Set Window Size  @{USERS.users['${username}'].size}
  Set Window Position  @{USERS.users['${username}'].position}
  Run Keyword If  '${username}' != 'b25h8_Viewer'  Run Keywords
  ...  Login  ${username}
  ...  AND  Run Keyword And Ignore Error  Wait Until Keyword Succeeds  10 x  1 s  Закрити модалку з новинами

Закрити модалку з новинами
  Wait Until Element Is Enabled   xpath=//button[@data-dismiss="modal"]
  Click Element   xpath=//button[@data-dismiss="modal"]
  Wait Until Element Is Not Visible  xpath=//button[@data-dismiss="modal"]

Login
  [Arguments]  ${username}
  Click Element  xpath=//a[@href="/site/login"]
  Wait Until Page Contains Element  id=username  10
  Input text  id=username  ${USERS.users['${username}'].login}
  Input text  id=password  ${USERS.users['${username}'].password}
  Scroll And Click  xpath=//*[contains(@class, "login-btn")]

###############################################################################################################
######################################    СТВОРЕННЯ ТЕНДЕРУ    ################################################
###############################################################################################################

Створити тендер
  [Arguments]  ${username}  ${tender_data}
  ${items}=  Get From Dictionary  ${tender_data.data}  items
  ${number_of_items}=  Get Length  ${items}
  ${tenderAttempts}=   Convert To String   ${tender_data.data.tenderAttempts}
  Switch Browser  ${my_alias}
  Wait Until Page Contains Element  xpath=//a[@href="http://${host}/tenders"]  10
  Click Element  xpath=//a[@href="http://${host}/tenders"]
  Click Element  xpath=//a[@href="http://${host}/tenders/index"]
  Click Element  xpath=//a[contains(@href,"/buyer/tender/create")]
  Select From List By Value  name=tender_method  open_${tender_data.data.procurementMethodType}
  Conv And Select From List By Value  name=Tender[value][valueAddedTaxIncluded]  ${tender_data.data.value.valueAddedTaxIncluded}
  ConvToStr And Input Text  name=Tender[value][amount]  ${tender_data.data.value.amount}
  ConvToStr And Input Text  name=Tender[minimalStep][amount]  ${tender_data.data.minimalStep.amount}
  ConvToStr And Input Text  name=Tender[guarantee][amount]  ${tender_data.data.guarantee.amount}
  Input text  name=Tender[title]  ${tender_data.data.title}
  Input text  name=Tender[dgfID]  ${tender_data.data.dgfID}
  Input text  name=Tender[description]  ${tender_data.data.description}
  Input text  name=Tender[dgfDecisionID]  ${tender_data.data.dgfDecisionID}
  Select From List By Value  name=Tender[tenderAttempts]  ${tenderAttempts}
  Input Date  name=Tender[dgfDecisionDate]  ${tender_data.data.dgfDecisionDate}
  Input Date  name=Tender[auctionPeriod][startDate]  ${tender_data.data.auctionPeriod.startDate}
  :FOR  ${index}  IN RANGE  ${number_of_items}
  \  Run Keyword If  ${index} != 0  Scroll And Click  xpath=(//button[@id="add-item"])[last()]
  \  Додати предмет  ${items[${index}]}  ${index}
  Execute Javascript  $('#draft-submit').before('<input type="hidden" name="procurementMethodDetails" value="quick, accelerator=${acceleration}">');
  Scroll And Click  id=btn-submit-form
  Wait Until Page Contains Element  xpath=//*[@data-test-id="tenderID"]  10
  ${tender_uaid}=  Get Text  xpath=//*[@data-test-id="tenderID"]
  [return]  ${tender_uaid}

Додати предмет
  [Arguments]  ${item}  ${index}
  ${index}=  Convert To Integer  ${index}
  Input text  name=Tender[items][${index}][description]  ${item.description}
  Input text  name=Tender[items][${index}][quantity]  ${item.quantity}
  Select From List By Value  name=Tender[items][${index}][unit][code]  ${item.unit.code}
  Scroll And Click  name=Tender[items][${index}][classification][description]
  Wait Until Element Is Visible  id=search_code   30
  Input text  id=search_code  ${item.classification.id}
  Wait Until Page Contains  ${item.classification.id}
  Scroll And Click  xpath=//span[contains(text(),'${item.classification.id}')]
  Scroll And Click  id=btn-ok
  Run Keyword And Ignore Error  Wait Until Element Is Not Visible  xpath=//div[@class="modal-backdrop fade"]  10
  Select From List By Label  name=Tender[items][${index}][address][countryName]  ${item.deliveryAddress.countryName}
  Wait Until Keyword Succeeds  5 x  400 ms  Select From List By Label  name=Tender[items][${index}][address][region]  ${item.deliveryAddress.region}
  Input text  name=Tender[items][${index}][address][locality]  ${item.deliveryAddress.locality}
  Input text  name=Tender[items][${index}][address][streetAddress]  ${item.deliveryAddress.streetAddress}
  Input text  name=Tender[items][${index}][address][postalCode]  ${item.deliveryAddress.postalCode}
  Select From List By Index  id=contact-point-select  1

Додати предмет закупівлі
  [Arguments]  ${username}  ${tender_uaid}  ${item}
  25h8.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Click Element  xpath=//a[contains(text(),'Редагувати')]
  Run Keyword And Ignore Error  Click Element  xpath=(//button[contains(@class,'add_item')])[last()]

Видалити предмет закупівлі
  [Arguments]  ${username}  ${tender_uaid}  ${item_id}
  25h8.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Click Element  xpath=//a[contains(text(),'Редагувати')]
  Run Keyword And Ignore Error  Click Element  xpath=(//button[contains(@class,'delete_item')])[last()]

Завантажити документ
  [Arguments]  ${username}  ${filepath}  ${tender_uaid}  ${illustration}=False
  Switch Browser  ${my_alias}
  25h8.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Click Element  xpath=//a[contains(text(),'Редагувати')]
  Choose File  xpath=(//*[@name="FileUpload[file][]"])[last()]  ${filepath}
  Scroll And Select From List By Value   xpath=//input[contains(@value,"${filepath.split("/")[-1].split(".")[0]}")]/ancestor::*[contains(@class,"document panel")]/descendant::select[@class="document-type"]   illustration
  Scroll And Select From List By Value   xpath=//input[contains(@value,"${filepath.split("/")[-1].split(".")[0]}")]/ancestor::*[contains(@class,"document panel")]/descendant::select[@class="document-related-item"]   tender
  Input Text  xpath=(//input[@class="document-title"])[last()]    ${filepath.split('/')[-1]}
  Click Button  id=btn-submit-form
  Wait Until Keyword Succeeds  10 x  1 s  Element Should Not Be Visible  id=btn-submit-form
  Дочекатися завантаження документу

Завантажити ілюстрацію
  [Arguments]  ${username}  ${tender_uaid}  ${filepath}
  25h8.Завантажити документ   ${username}  ${filepath}  ${tender_uaid}  True

Дочекатися завантаження документу
  Wait Until Keyword Succeeds  30 x  20 s  Run Keywords
  ...  Reload Page
  ...  AND  Wait Until Page Does Not Contain   Документ завантажується...  10

Додати Virtual Data Room
  [Arguments]  ${username}  ${tender_uaid}  ${vdr_url}  ${title}=Sample Virtual Data Room
  25h8.Пошук тендера по ідентифікатору   ${username}   ${tender_uaid}
  Click Element  xpath=//a[contains(text(),'Редагувати')]
  Scroll And Click  xpath=//*[@data-type="virtualDataRoom"]
  Wait Until Element Is Visible  xpath=(//*[@class="document-url"])[last()]
  Input Text  xpath=(//*[@class="document-title"])[last()]  ${title}
  Input Text  xpath=(//*[@class="document-url"])[last()]  ${vdr_url}
  Click Button  id=btn-submit-form
  Wait Until Element Is Visible  xpath=//div[contains(@class,'alert-info')]

Завантажити документ в тендер з типом
  [Arguments]  ${username}  ${tender_uaid}  ${filepath}  ${documentType}
  Switch Browser  ${my_alias}
  25h8.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Click Element  xpath=//a[contains(text(),'Редагувати')]
  Choose File  xpath=(//*[@name="FileUpload[file][]"])[last()]  ${filepath}
  Scroll And Select From List By Value   xpath=//input[contains(@value,"${filepath.split("/")[-1].split(".")[0]}")]/ancestor::*[contains(@class,"document panel")]/descendant::select[@class="document-type"]   ${documentType}
  Scroll And Select From List By Value   xpath=//input[contains(@value,"${filepath.split("/")[-1].split(".")[0]}")]/ancestor::*[contains(@class,"document panel")]/descendant::select[@class="document-related-item"]   tender
  Input Text  xpath=(//input[@class="document-title"])[last()]    ${filepath.split('/')[-1]}
  Click Button  id=btn-submit-form
  Wait Until Keyword Succeeds  20 x  1 s  Element Should Not Be Visible  id=btn-submit-form
  Дочекатися завантаження документу

Додати публічний паспорт активу
  [Arguments]  ${username}  ${tender_uaid}  ${certificate_url}  ${title}=Public Asset Certificate
  25h8.Пошук тендера по ідентифікатору   ${username}   ${tender_uaid}
  Click Element  xpath=//a[contains(text(),'Редагувати')]
  Click Element  xpath=//*[@data-type="x_dgfPublicAssetCertificate"]
  Wait Until Element Is Visible  xpath=(//*[@class="document-url"])[last()]
  Input Text  xpath=(//*[@class="document-title"])[last()]  ${title}
  Input Text  xpath=(//*[@class="document-url"])[last()]  ${certificate_url}
  Click Button  id=btn-submit-form
  Wait Until Element Is Visible  xpath=//div[contains(@class,'alert-info')]

Додати офлайн документ
  [Arguments]  ${username}  ${tender_uaid}  ${accessDetails}  ${title}=Familiarization with bank asset
  25h8.Пошук тендера по ідентифікатору   ${username}   ${tender_uaid}
  Click Element  xpath=//a[contains(text(),'Редагувати')]
  Click Element  xpath=//*[@data-type="x_dgfAssetFamiliarization"]
  Wait Until Element Is Visible  xpath=(//input[@class="document-access-details"])[last()]
  Input Text  xpath=(//input[@class="document-access-details"])[last()]  ${accessDetails}
  Input Text  xpath=(//input[@class="document-title"])[last()]  ${title}
  Click Button  id=btn-submit-form
  Wait Until Element Is Visible  xpath=//div[contains(@class,'alert-info')]

Пошук тендера по ідентифікатору
  [Arguments]  ${username}  ${tender_uaid}
  Switch Browser  ${my_alias}
  Reload Page
  Wait Until Element Is Not Visible  xpath=//div[@class="modal-backdrop fade"]  10
  ${is_events_visible}=  Run Keyword And Return Status  Element Should Be Visible  xpath=//*[@id="events"]/descendant::*[@class="close"]
  Run Keyword If  ${is_events_visible}  Run Keywords
  ...  Дочекатися Анімації  xpath=//*[@id="events"]/descendant::*[@class="close"]
  ...  AND  Click Element  xpath=//*[@id="events"]/descendant::*[@class="close"]
  ...  AND  Дочекатися Анімації  xpath=//*[@id="events"]/descendant::*[@class="close"]
  Дочекатися І Клікнути  xpath=//*[@id="h-menu"]/descendant::a[contains(@href,"/tenders") and @data-toggle="dropdown"]
  Дочекатися І Клікнути  xpath=//*[@id="h-menu"]/descendant::a[contains(@href,"tenders/index")]
  Дочекатися І Клікнути  id=more-filter
  Дочекатися Анімації  id=tenderssearch-tender_cbd_id
  Wait Until Element Is Visible  name=TendersSearch[tender_cbd_id]  10
  Input text  name=TendersSearch[tender_cbd_id]  ${tender_uaid}
  Wait Until Keyword Succeeds  6x  20s  Run Keywords
  ...  Дочекатися І Клікнути  xpath=//button[text()='Шукати']
  ...  AND  Wait Until Element Is Visible  xpath=//*[contains(@class, "btn-search_cancel")]  10
  ...  AND  Wait Until Element Is Visible  xpath=//*[contains(text(),'${tender_uaid}')]/ancestor::div[@class="search-result"]/descendant::a[1]  10
  Click Element  xpath=//*[contains(text(),'${tender_uaid}')]/ancestor::div[@class="search-result"]/descendant::a[1]
  Wait Until Element Is Visible  xpath=//*[@data-test-id="tenderID"]  10
  Click Element  xpath=//*[contains(@href, "tender/json/")]

Оновити сторінку з тендером
  [Arguments]  ${username}  ${tender_uaid}
  Switch Browser  ${my_alias}
  25h8.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}

Внести зміни в тендер
  [Arguments]  ${username}  ${tender_uaid}  ${field_name}  ${field_value}
  ${filepath}=  get_upload_file_path
  ${field_value}=  Convert To String  ${field_value}
  25h8.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Click Element  xpath=//a[contains(text(),'Редагувати')]
  Choose File  xpath=(//*[@name="FileUpload[file][]"])[last()]  ${filepath}
  Select From List By Value   xpath=//input[contains(@value, '${filepath.split('/')[-1].split('.')[1]}')]/../descendant::*[contains(@name,"[documentType]")]   clarifications
  Select From List By Value   xpath=(//select[@class="document-related-item"])[last()]   tender
  Run Keyword If  "${field_name}" == "tenderAttempts"  Select From List By Value  name=Tender[${field_name}]  ${field_value}
  ...  ELSE IF  "Date" in "${field_name}"  Input Date  name=Tender[${field_name}]  ${field_value}
  ...  ELSE  Input text  name=Tender[${field_name}]  ${field_value}
  Click Element  id=btn-submit-form
  Wait Until Element Is Visible  xpath=//div[contains(@class,'alert-success')]
  #Wait Until Page Contains  ${field_value}  30

###############################################################################################################
##########################################    СКАСУВАННЯ    ###################################################
###############################################################################################################

Скасувати закупівлю
  [Arguments]  ${username}  ${tender_uaid}  ${cancellation_reason}  ${document}  ${new_description}
  25h8.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Click Element  xpath=//a[contains(@href,'/tender/cancel/')]
  Select From List By Value  id=cancellation-relatedlot  tender
  Select From List By Value  id=cancellation-reason  ${cancellation_reason}
  Choose File  name=FileUpload[file][]  ${document}
  Wait Until Element Is Visible  name=Tender[cancellations][documents][0][title]
  Input Text  name=Tender[cancellations][documents][0][title]  ${document.replace('/tmp/', '')}
  Click Element  xpath=//button[@type="submit"]
  Wait Until Element Is Visible  xpath=//div[contains(@class,'alert-success')]
  Wait Until Keyword Succeeds  30 x  1 m  Звірити статус тендера  ${username}  ${tender_uaid}  cancelled

###############################################################################################################
############################################    ПИТАННЯ    ####################################################
###############################################################################################################

Задати питання
  [Arguments]  ${username}  ${tender_uaid}  ${question}  ${item_id}=False
  25h8.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Wait Until Element Is Enabled  xpath=//a[@data-test-id="sidebar.questions"]
  Click Element  xpath=//a[@data-test-id="sidebar.questions"]
  ${status}  ${item_option}=   Run Keyword And Ignore Error   Get Text   //option[contains(text(), '${item_id}')]
  Run Keyword If  '${status}' == 'PASS'   Select From List By Label  name=Question[questionOf]  ${item_option}
  Input Text  name=Question[title]  ${question.data.title}
  Input Text  name=Question[description]  ${question.data.description}
  Click Element  name=question_submit
  Wait Until Page Contains Element  xpath=//div[contains(@class,'alert-success')]  30

Задати запитання на тендер
  [Arguments]  ${username}  ${tender_uaid}  ${question}
  25h8.Задати питання  ${username}  ${tender_uaid}  ${question}

Задати запитання на предмет
  [Arguments]  ${username}  ${tender_uaid}  ${item_id}  ${question}
  25h8.Задати питання  ${username}  ${tender_uaid}  ${question}  ${item_id}

Відповісти на запитання
  [Arguments]  ${username}  ${tender_uaid}  ${answer_data}  ${question_id}
  25h8.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Wait Until Element Is Enabled  xpath=//a[@data-test-id="sidebar.questions"]
  Click Element  xpath=//a[@data-test-id="sidebar.questions"]
  Toggle Sidebar
  Wait Until Element Is Visible  xpath=//*[contains(text(),'${question_id}')]/../descendant::textarea[contains(@name,'[answer]')]
  Input text  xpath=//*[contains(text(),'${question_id}')]/../descendant::textarea[contains(@name,'[answer]')]  ${answer_data.data.answer}
  Scroll And Click  xpath=//*[contains(text(),'${question_id}')]/../descendant::button[@name="answer_question_submit"]
  Wait Until Page Contains Element  xpath=//div[contains(@class,'alert-success')]  30

###############################################################################################################
###################################    ВІДОБРАЖЕННЯ ІНФОРМАЦІЇ    #############################################
###############################################################################################################

Отримати інформацію із тендера
  [Arguments]  ${username}  ${tender_uaid}  ${field_name}
  Switch Browser  ${my_alias}
  ${red}=  Evaluate  "\\033[1;31m"
  Click Element  xpath=//*[contains(@href, "tender/json/")]
  Run Keyword If  'title' in '${field_name}'  Execute Javascript  $("[data-test-id|='title']").css("text-transform", "unset")
  ${value}=  Run Keyword If
  ...  'awards' in '${field_name}'  Отримати інформацію про авард  ${username}  ${tender_uaid}  ${field_name}
  ...  ELSE IF  'status' in '${field_name}'  Отримати інформацію про статус  ${field_name}
  ...  ELSE IF  '${field_name}' == 'auctionPeriod.startDate'  Get Text  xpath=//*[@data-test-id="auctionPeriod.startDate"]
  ...  ELSE IF  '${field_name}' == 'tenderAttempts'  Get Element Attribute  xpath=//*[@data-test-id="tenderAttempts"]@data-test-value
  ...  ELSE IF  'cancellations' in '${field_name}'  Get Text  xpath=//*[@data-test-id="${field_name.replace('[0]','')}"]
  ...  ELSE  Get Text  xpath=//*[@data-test-id="${field_name.replace('auction', 'tender')}"]
  ${value}=  adapt_view_data  ${value}  ${field_name}
  [return]  ${value}

Отримати інформацію про статус
  [Arguments]  ${field_name}
  Run Keyword And Ignore Error  Click Element   xpath=//a[text()='Інформація про аукціон']
  Reload Page
  ${value}=  Run Keyword If  'cancellations' in '${field_name}'
  ...  Get Element Attribute  //*[contains(text(), "Причина скасування")]@data-test-id-cancellation-status
  ...  ELSE  Get Text  xpath=//*[@data-test-id="${field_name.split('.')[-1]}"]
  [return]  ${value.lower()}

Отримати інформацію із предмету
  [Arguments]  ${username}  ${tender_uaid}  ${item_id}  ${field_name}
  ${red}=  Evaluate  "\\033[1;31m"
  ${field_name}=  Set Variable If  '[' in '${field_name}'  ${field_name.split('[')[0]}${field_name.split(']')[1]}  ${field_name}
  ${value}=  Run Keyword If
  ...  'unit.code' in '${field_name}'  Log To Console   ${red}\n\t\t\t Це поле не виводиться на 25h8
  ...  ELSE IF  'deliveryLocation' in '${field_name}'  Log To Console  ${red}\n\t\t\t Це поле не виводиться на 25h8
  ...  ELSE  Get Text  xpath=//*[contains(text(), '${item_id}')]/ancestor::div[contains(@class,"item-inf_txt")]/descendant::*[@data-test-id='item.${field_name}']
  ${value}=  adapt_view_item_data  ${value}  ${field_name}
  [return]  ${value}

Отримати кількість предметів в тендері
  [Arguments]  ${username}  ${tender_uaid}
  25h8.Пошук тендера по ідентифікатору   ${username}   ${tender_uaid}
  ${number_of_items}=  Get Matching Xpath Count  //div[@class="item no_border"]
  [return]  ${number_of_items}

Отримати інформацію із запитання
  [Arguments]  ${username}  ${tender_uaid}  ${question_id}  ${field_name}
  25h8.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Wait Until Element Is Enabled  xpath=//a[@data-test-id="sidebar.questions"]
  Click Element  xpath=//a[@data-test-id="sidebar.questions"]
  ${value}=  Get Text  xpath=//*[contains(text(),'${question_id}')]/../descendant::*[@data-test-id='question.${field_name}']
  [return]  ${value}

Отримати інформацію із пропозиції
  [Arguments]  ${username}  ${tender_uaid}  ${field}
  ${bid_value}=   Get Value   xpath=//*[@id="value-amount"]
  ${bid_value}=   Convert To Number   ${bid_value}
  [return]  ${bid_value}

Отримати інформацію із документа
  [Arguments]  ${username}  ${tender_uaid}  ${doc_id}  ${field}
  ${doc_value}=  Get Text  xpath=//a[contains(text(),'${doc_id}')]
  [return]  ${doc_value}

Отримати документ
  [Arguments]  ${username}  ${tender_uaid}  ${doc_id}
  ${file_name}=   Get Text   xpath=//a[contains(text(),'${doc_id}')]
  ${url}=   Get Element Attribute   xpath=//a[contains(text(),'${doc_id}')]@href
  download_file   ${url}  ${file_name}  ${OUTPUT_DIR}
  [return]  ${file_name}

Отримати кількість документів в тендері
  [Arguments]  ${username}  ${tender_uaid}
  25h8.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${number_of_documents}=  Get Matching Xpath Count  //*[@data-test-id="document.title"]
  [return]  ${number_of_documents}

Отримати інформацію із документа по індексу
  [Arguments]  ${username}  ${tender_uaid}  ${document_index}  ${field}
  25h8.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${doc_value}=  Get Text  xpath=(//*[@data-test-id="documentType"])[${document_index + 1}]
  ${doc_value}=  convert_string_from_dict_25h8  ${doc_value}
  [return]  ${doc_value}

Отримати інформацію про авард
  [Arguments]  ${username}  ${tender_uaid}  ${field_name}
  ${status}=  Run Keyword And Return Status  Перейти на сторінку кваліфікації учасників  ${username}  ${tender_uaid}
  Run Keyword If  not ${status}  Click Element  xpath=//a[text()="Протокол розкриття пропозицiй"]
  ${award_index}=  Convert To Integer  ${field_name[7:8]}
  ${value}=  Get Text  xpath=(//div[@data-mtitle="Статус:"])[${award_index + 1}]
  [return]  ${value.lower()}

###############################################################################################################
#######################################    ПОДАННЯ ПРОПОЗИЦІЙ    ##############################################
###############################################################################################################

Подати цінову пропозицію
  [Arguments]  ${username}  ${tender_uaid}  ${bid}
  ${status}=  Get From Dictionary  ${bid['data']}  qualified
  Switch Browser  ${my_alias}
  25h8.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  Run Keyword And Ignore Error  25h8.Скасувати цінову пропозицію  ${username}  ${tender_uaid}
  Run Keyword If  '${MODE}' != 'dgfInsider'  ConvToStr And Input Text  xpath=//input[contains(@name, '[value][amount]')]  ${bid.data.value.amount}
  ...  ELSE  Scroll And Click  xpath=//input[@id="bid-participate"]/..
  Run Keyword And Ignore Error  Дочекатися І Клікнути  xpath=//*[@id="bid-checkforunlicensed"]/..
  Click Element  xpath=//button[contains(text(), 'Відправити')]
  Wait Until Page Contains Element  xpath=//div[contains(@class,'alert-success')]
  Опублікувати Пропозицію  ${status}

Опублікувати Пропозицію
  [Arguments]  ${status}
  ${url}=  Log Location
  Run Keyword If  ${status}
  ...  Go To  http://${host}/bids/send/${url.split('?')[0].split('/')[-1]}?token=465
  ...  ELSE  Go To  http://${host}/bids/decline/${url.split('?')[0].split('/')[-1]}?token=465
  Go To  ${url}
  Wait Until Keyword Succeeds  6 x  30 s  Run Keywords
  ...  Reload Page
  ...  AND  Page Should Contain  опубліковано

Скасувати цінову пропозицію
  [Arguments]  ${username}  ${tender_uaid}
  25h8.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  Click Element  xpath=//button[@name="delete_bids"]
  Wait Until Element Is Visible  xpath=//button[@data-bb-handler="confirm"]
  Click Element  xpath=//button[@data-bb-handler="confirm"]
  Wait Until Keyword Succeeds  10 x  1 s  Element Should Be Visible  xpath=//input[contains(@name, '[value][amount]')]

Змінити цінову пропозицію
  [Arguments]  ${username}  ${tender_uaid}  ${fieldname}  ${fieldvalue}
  25h8.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  Wait Until Element Is Visible   xpath=//input[contains(@name, '[value][amount]')]
  ConvToStr And Input Text  xpath=//input[contains(@name, '[value][amount]')]  ${fieldvalue}
  Click Element  xpath=//button[contains(text(), 'Відправити')]
  Wait Until Element Is Visible  xpath=//div[contains(@class,'alert-success')]

Завантажити документ в ставку
  [Arguments]  ${username}  ${path}  ${tender_uaid}  ${doc_type}=documents
  25h8.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  Choose File  name=FileUpload[file][]  ${path}
  Run Keyword If  '${MODE}' != 'dgfOtherAssets'
  ...  Select From List By Value  xpath=//input[contains(@value,"${path.split("/")[-1].split(".")[0]}")]/ancestor::*[@class="bid_file_wrap"]/descendant::*[@class="select_document_type"]  financialLicense
  ...  ELSE  Select From List By Value  xpath=//input[contains(@value,"${path.split("/")[-1].split(".")[0]}")]/ancestor::*[@class="bid_file_wrap"]/descendant::*[@class="select_document_type"]  commercialProposal
  Click Element  xpath=//button[contains(text(), 'Відправити')]
  Wait Until Element Is Visible  xpath=//div[contains(@class,'alert-success')]

Завантажити фінансову ліцензію
  [Arguments]  ${username}  ${tender_uaid}  ${filepath}
  25h8.Завантажити документ в ставку  ${username}  ${filepath}  ${tender_uaid}

Змінити документ в ставці
  [Arguments]  ${username}  ${tender_uaid}  ${path}  ${docid}
  25h8.Завантажити документ в ставку  ${username}  ${path}  ${tender_uaid}

###############################################################################################################
##############################################    АУКЦІОН    ##################################################
###############################################################################################################

Отримати посилання на аукціон для глядача
  [Arguments]  ${username}  ${tender_uaid}  ${lot_id}=${Empty}
  Switch Browser  ${my_alias}
  25h8.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  ${auction_url}=  Get Element Attribute  xpath=(//a[contains(text(), "Перейти в аукціон")])[1]@href
  [return]  ${auction_url}

Отримати посилання на аукціон для учасника
  [Arguments]  ${username}  ${tender_uaid}  ${lot_id}=${Empty}
  Switch Browser  ${my_alias}
  25h8.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  Wait Until Keyword Succeeds  15 x  60 s  Run Keywords
  ...  Click Element  xpath=//*[contains(@href, "tender/json/")]
  ...  AND  Element Should Be Visible  xpath=//a[@class="auction_seller_url"]
  ${current_url}=  Get Location
  Execute Javascript  window['url'] = null; $.get( "http://${host}/seller/tender/updatebid", { id: "${current_url.split("/")[-1]}"}, function(data){ window['url'] = data.data.participationUrl },'json');
  Wait Until Keyword Succeeds  20 x  1 s  JQuery Ajax Should Complete
  ${auction_url}=  Execute Javascript  return window['url'];
  [return]  ${auction_url}


###############################################################################################################
###########################################    КВАЛІФІКАЦІЯ    ################################################
###############################################################################################################

Підтвердити постачальника
  [Arguments]  ${username}  ${tender_uaid}  ${award_num}
  25h8.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  Wait Until Keyword Succeeds   30 x   30 s  Run Keywords
  ...  Reload Page
  ...  AND  Click Element  xpath=//a[text()='Таблиця квалiфiкацiї']
  Wait Until Element Is Visible  xpath=//button[text()='Підтвердити отримання оплати']
  Click Element  xpath=//button[text()='Підтвердити отримання оплати']
  Wait Until Keyword Succeeds  10 x  1 s  Element Should Be Visible  xpath=//button[@data-bb-handler="confirm"]
  Click Element  xpath=//button[@data-bb-handler="confirm"]
  Wait Until Element Is Visible   xpath=//button[text()="Контракт"]

Отримати кількість документів в ставці
  [Arguments]  ${username}  ${tender_uaid}  ${bid_index}
  25h8.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  Wait Until Element Is Visible  xpath=//a[text()='Таблиця квалiфiкацiї']
  Click Element  xpath=//a[text()='Таблиця квалiфiкацiї']
  ${disqualification_status}=  Run Keyword And Return Status  Wait Until Page Does Not Contain Element  xpath=//*[contains(text(),'Дисквалiфiковано')]  10
  Run Keyword If  ${disqualification_status}  Wait Until Keyword Succeeds  15 x  1 m  Run Keywords
  ...    Reload Page
  ...    AND  Wait Until Page Contains  auctionProtocol
  ...  ELSE  Wait Until Keyword Succeeds  15 x  1 m  Run Keywords
  ...    Reload Page
  ...    AND  Xpath Should Match X Times  //*[contains(text(),'auctionProtocol')]  2
  ${bid_doc_number}=   Get Matching Xpath Count   //td[contains(text(),'На розглядi ')]/../following-sibling::tr[2]/descendant::div[@class="bid_document_block"]/table/tbody/tr
  [return]  ${bid_doc_number}

Отримати дані із документу пропозиції
  [Arguments]  ${username}  ${tender_uaid}  ${bid_index}  ${document_index}  ${field}
  ${doc_value}=  Get Text  xpath=//div[@class="bid_document_block"]/table/tbody/tr[${document_index + 1}]/td[2]/span
  [return]  ${doc_value}

Завантажити протокол аукціону
  [Arguments]  ${username}  ${tender_uaid}  ${filepath}  ${award_index}
  Перейти на сторінку кваліфікації учасників  ${username}  ${tender_uaid}
  Choose File  name=FileUpload[file][]  ${filepath}
  Wait Until Element Is Visible  xpath=//*[contains(@name,'[documentType]')]
  Select From List By Value  xpath=(//*[contains(@name,'[documentType]')])[last()]  auctionProtocol
  Click Element  id=submit_winner_files
  Wait Until Element Is Visible  xpath=//div[contains(@class,'alert-success')]
  Wait Until Keyword Succeeds  15 x  1 m  Дочекатися завантаження файлу  ${filepath.split('/')[-1]}

Завантажити протокол аукціону в авард
  [Arguments]  ${username}  ${tender_uaid}  ${filepath}  ${award_index}
  Run Keyword If  """Відображення статусу 'оплачено, очікується підписання договору'""" not in """${PREV TEST NAME}"""
  ...  Wait Until Keyword Succeeds  10 x  60 s  Звірити статус тендера  ${username}  ${tender_uaid}  active.qualification
  Перейти на сторінку кваліфікації учасників  ${username}  ${tender_uaid}
  Click Element  xpath=//*[contains(@id,"modal-verification")]
  Дочекатися Анімації  name=protokol_ok
  Choose File  xpath=//*[@id="verification-form-upload-file"]/descendant::input[@type="file"]  ${filepath}
  Click Element  name=protokol_ok
  Wait Until Keyword Succeeds  10 x  400 ms  Element Should Be Visible  xpath=//div[contains(@class,'alert-success')]
  Wait Until Keyword Succeeds  10 x  30 s  Run Keywords
  ...  Reload Page
  ...  AND  Element Should Not Be Visible  xpath=//button[@onclick="window.location.reload();"]

Підтвердити наявність протоколу аукціону
  [Arguments]  ${username}  ${tender_uaid}  ${award_index}
  Перейти на сторінку кваліфікації учасників  ${username}  ${tender_uaid}
  Wait Until Page Contains  Очікується підписання договору

Скасування рішення кваліфікаційної комісії
  [Arguments]  ${username}  ${tender_uaid}  ${award_num}
  Перейти на сторінку кваліфікації учасників  ${username}  ${tender_uaid}
  Wait Until Element Is Enabled  xpath=//button[@name="cancelled"]
  Scroll And Click  xpath=//button[@name="cancelled"]
  Wait Until Keyword Succeeds  10 x  1 s  Element Should Be Visible  xpath=//button[@data-bb-handler="confirm"]
  Click Element  xpath=//button[@data-bb-handler="confirm"]

Дискваліфікувати постачальника
  [Arguments]  ${username}  ${tender_uaid}  ${award_num}  ${description}
  ${document}=  get_upload_file_path
  Run Keyword If  """Відображення статусу 'оплачено, очікується підписання договору'""" not in """${PREV TEST NAME}"""
  ...  Wait Until Keyword Succeeds  10 x  60 s  Звірити статус тендера  ${username}  ${tender_uaid}  active.qualification
  Перейти на сторінку кваліфікації учасників  ${username}  ${tender_uaid}
  Click Element  xpath=//*[contains(@id, "modal-disqualification")]
  Дочекатися І Клікнути  xpath=(//input[@name="Award[cause][]"])[1]/..
  Choose File  xpath=//*[@id="disqualification-form-upload-file"]/descendant::input[@type="file"]  ${document}
  Click Element  id=disqualification
  Wait Until Keyword Succeeds  10 x  1 s  Element Should Be Visible  xpath=//div[contains(@class,'alert-success')]
  Wait Until Keyword Succeeds  10 x  30 s  Run Keywords
  ...  Reload Page
  ...  AND  Element Should Not Be Visible  xpath=//button[@onclick="window.location.reload();"]

Завантажити документ рішення кваліфікаційної комісії
  [Arguments]  ${username}  ${document}  ${tender_uaid}  ${award_num}
  Перейти на сторінку кваліфікації учасників  ${username}  ${tender_uaid}
  Choose File  name=FileUpload[file][]  ${document}

Завантажити угоду до тендера
  [Arguments]  ${username}  ${tender_uaid}  ${contract_num}  ${filepath}
  Перейти на сторінку кваліфікації учасників   ${username}  ${tender_uaid}
  Click Element  xpath=//button[text()="Контракт"]
  Choose File  xpath=//*[@id="uploadcontract"]/descendant::input[@type="file"]  ${filepath}


Підтвердити підписання контракту
  [Arguments]  ${username}  ${tender_uaid}  ${contract_num}
  ${filepath}=  get_upload_file_path
  Перейти на сторінку кваліфікації учасників   ${username}  ${tender_uaid}
  Wait Until Keyword Succeeds  5 x  0.5 s  Click Element  xpath=//button[text()="Контракт"]
  Wait Until Element Is Visible  xpath=//*[text()="Додати документ"]
  Choose File  xpath=//*[@id="uploadcontract"]/descendant::input[@type="file"]  ${filepath}
  Wait Until Keyword Succeeds  10 x  1 s  Element Should Be Visible  xpath=//button[contains(@class, "delete_file")]
  Input Text  id=contract-contractnumber  777
  Click Element  id=contract-fill-data
  Wait Until Keyword Succeeds  10 x  1 s  Page Should Contain  Кнопка "Завершити електронні торги" з'явиться після закінчення завантаження даних та оновлення сторінки
  Wait Until Keyword Succeeds  10 x  60 s  Run Keywords
  ...  Reload Page
  ...  AND  Element Should Be Visible  id=contract-activate
  Choose Ok On Next Confirmation
  Click Element  id=contract-activate
  Confirm Action

###############################################################################################################

ConvToStr And Input Text
  [Arguments]  ${elem_locator}  ${smth_to_input}
  ${smth_to_input}=  Convert To String  ${smth_to_input}
  Input Text  ${elem_locator}  ${smth_to_input}

Conv And Select From List By Value
  [Arguments]  ${elem_locator}  ${smth_to_select}
  ${smth_to_select}=  Convert To String  ${smth_to_select}
  ${smth_to_select}=  convert_string_from_dict_25h8  ${smth_to_select}
  Select From List By Value  ${elem_locator}  ${smth_to_select}

Input Date
  [Arguments]  ${elem_locator}  ${date}
  ${date}=  convert_datetime_to_25h8_format  ${date}
  Input Text  ${elem_locator}  ${date}

Дочекатися завантаження файлу
  [Arguments]  ${doc_name}
  Reload Page
  Wait Until Page Contains  ${doc_name}  10

Перейти на сторінку кваліфікації учасників
  [Arguments]  ${username}  ${tender_uaid}
  25h8.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  Wait Until Element Is Visible  xpath=//a[text()='Таблиця квалiфiкацiї']
  Click Element  xpath=//a[text()='Таблиця квалiфiкацiї']

Дочекатися Анімації
  [Arguments]  ${locator}
  Set Test Variable  ${prev_vert_pos}  0
  Wait Until Keyword Succeeds  20 x  500 ms  Position Should Equals  ${locator}

Position Should Equals
  [Arguments]  ${locator}
  ${current_vert_pos}=  Get Vertical Position  ${locator}
  ${status}=  Run Keyword And Return Status  Should Be Equal  ${prev_vert_pos}  ${current_vert_pos}
  Set Test Variable  ${prev_vert_pos}  ${current_vert_pos}
  Should Be True  ${status}

Scroll To Element
  [Arguments]  ${locator}
  ${elem_vert_pos}=  Get Vertical Position  ${locator}
  Execute Javascript  window.scrollTo(0,${elem_vert_pos - 300});

Scroll And Click
  [Arguments]  ${locator}
  Scroll To Element  ${locator}
  Click Element  ${locator}

Scroll And Select From List By Value
  [Arguments]  ${locator}  ${value}
  Scroll To Element  ${locator}
  Select From List By Value  ${locator}  ${value}

JQuery Ajax Should Complete
  ${active}=  Execute Javascript  return jQuery.active
  Should Be Equal  "${active}"  "0"

Дочекатися і Клікнути
  [Arguments]  ${locator}
  Wait Until Keyword Succeeds  10 x  1 s  Element Should Be Visible  ${locator}
  Scroll To Element  ${locator}
  Click Element  ${locator}

Toggle Sidebar
  ${is_sidebar_visible}=  Run Keyword And Return Status  Element Should Be Visible  xpath=//div[contains(@class,"mk-slide-panel_body")]
  Run Keyword If  ${is_sidebar_visible}  Run Keywords
  ...  Wait Until Keyword Succeeds  5 x  1 s  Click Element  id=slidePanelToggle
  ...  AND  Дочекатися Анімації  xpath=//div[@class="title"]