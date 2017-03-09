*** Settings ***
Library  Selenium2Library
Library  String
Library  Collections
Library  DateTime
Library  25h8_service.py

*** Variables ***


*** Keywords ***

Підготувати дані для оголошення тендера
  [Arguments]  ${username}  ${tender_data}  ${role_name}
  ${tender_data}=  adapt_procuringEntity  ${tender_data}
  [Return]  ${tender_data}

Підготувати клієнт для користувача
  [Arguments]  ${username}
  Open Browser  ${USERS.users['${username}'].homepage}  ${USERS.users['${username}'].browser}  alias=${username}
  Set Window Size  @{USERS.users['${username}'].size}
  Set Window Position  @{USERS.users['${username}'].position}
 # Run Keyword If  'Viewer' not in '${username}'  Login  ${username}
  Run Keyword If  '${username}' != 'u25_Viewer'  Run Keywords
  ...  Login  ${username}
  ...  AND  Run Keyword And Ignore Error  Wait Until Keyword Succeeds  10 x  1 s  Закрити модалку з новинами

Закрити модалку з новинами
  Wait Until Element Is Enabled   xpath=//button[@data-dismiss="modal"]
  Click Element   xpath=//button[@data-dismiss="modal"]
  Wait Until Element Is Not Visible  xpath=//button[@data-dismiss="modal"]

Login
  [Arguments]  ${username}
  Wait Until Page Contains Element  id=loginform-username  10
  Input text  id=loginform-username  ${USERS.users['${username}'].login}
  Input text  id=loginform-password  ${USERS.users['${username}'].password}
  Click Element  name=login-button

###############################################################################################################
######################################    СТВОРЕННЯ ТЕНДЕРУ    ################################################
###############################################################################################################

Створити тендер
  [Arguments]  ${username}  ${tender_data}
  ${items}=  Get From Dictionary  ${tender_data.data}  items
  ${amount}=   add_second_sign_after_point   ${tender_data.data.value.amount}
  ${minimalStep}=   add_second_sign_after_point   ${tender_data.data.minimalStep.amount}
  ${meat}=  Evaluate  ${tender_meat} + ${lot_meat} + ${item_meat}
  Switch Browser  ${username}
  Wait Until Element Is Not Visible  xpath=//div[@class="modal-backdrop fade"]  10
  Click Element  xpath=//a[@href="http://25h8.byustudio.in.ua/tenders"]
  Click Element  xpath=//a[@href="http://25h8.byustudio.in.ua/tenders/index"]
  Click Element  xpath=//a[contains(@href,"/buyer/tender/create")]
  Execute Javascript  $('#navbar-main').remove()
  Select From List By Value  name=tender_method  open_${tender_data.data.procurementMethodType}
  Run Keyword If  ${number_of_lots} > 0  Select From List By Value  name=tender_type  2
  Conv And Select From List By Value  name=Tender[value][valueAddedTaxIncluded]  ${tender_data.data.value.valueAddedTaxIncluded}
  Run Keyword If  ${number_of_lots} == 0  Run Keywords
  ...  ConvToStr And Input Text  name=Tender[value][amount]  ${amount}
  ...  AND  ConvToStr And Input Text  name=Tender[minimalStep][amount]  ${minimalStep}
  ...  AND  Select From List By Value  name=Tender[value][currency]  ${tender_data.data.value.currency}
  Input text  name=Tender[title]  ${tender_data.data.title}
  Input text  name=Tender[description]  ${tender_data.data.description}
  Run Keyword If  "${tender_data.data.procurementMethodType}" == "belowThreshold"  Run Keywords
  ...  Input Date  name=Tender[enquiryPeriod][endDate]  ${tender_data.data.tenderPeriod.startDate}
  ...  AND Input Date  name=Tender[tenderPeriod][startDate]  ${tender_data.data.tenderPeriod.startDate}
  Input Date  name=Tender[tenderPeriod][endDate]  ${tender_data.data.tenderPeriod.endDate}
  Run Keyword If   ${number_of_lots} == 0   Run Keywords
  ...          Input Text   name=data[minimalStep][amount]   ${minimalStep}
  #...          AND   Click Element   xpath=//button[contains(@class, "add_lot")]
  ...          AND   Додати багато предметів   ${tender_data}
  ...   ELSE  Додати багато лотів  ${tender_data}
 # Додати предмет  ${items[0]}  0
  Run Keyword If  ${meat} > 0  Додати нецінові критерії  ${tender_data}
  Click Element  xpath=//button[contains(@class,'btn_submit_form')]
  Wait Until Element Is Visible  xpath=//*[@tid="tenderID"]  10
  ${tender_uaid}=  Get Text  xpath=//*[@tid="tenderID"]
  [Return]  ${tender_uaid}

Додати багато лотів
  [Arguments]  ${tender_data}
  ${lots}=  Get From Dictionary  ${tender_data.data}  lots
  ${lots_length}=  Get Length  ${lots}
  :FOR  ${index}  IN RANGE  ${lots_length}
  \  Run Keyword if  ${index} != 0  Click Element  xpath=//button[contains(@class, "add_lot")]
  \  25h8.Створити лот  u25_Owner  ${None}  ${lots[${index}]}  ${tender_data}

Створити лот
  [Arguments]  ${username}  ${tender_uaid}  ${lot}   ${data}=${EMPTY}
  ${lot}=   Set Variable If   '${tender_uaid}' != '${None}'   ${lot.data}   ${lot}
  ${amount}=   add_second_sign_after_point   ${lot.value.amount}
  ${minimalStep}=   add_second_sign_after_point   ${lot.minimalStep.amount}
  ${lot_id}=   Get Element Attribute  xpath=(//input[contains(@name, "Tender[lots]") and contains(@name, "[value][amount]")])[last()]@id
  ${lot_index}=   Set Variable  ${lot_id.split("-")[1]}
  Input text   name=Tender[lots][${lot_index}][title]                 ${lot.title}
  Input text   name=Tender[lots][${lot_index}][description]           ${lot.description}
  Input text   name=Tender[lots][${lot_index}][value][amount]         ${amount}
  Input text   name=Tender[lots][${lot_index}][minimalStep][amount]   ${minimalStep}
  Run Keyword If   '${mode}' == 'openeu'   Run Keywords
  ...   Click Element   xpath=//label[@class="item l relative"][input[@value="en"]]
  ...   AND   Input Text   name=data[lots][${lot_index}][title_en]   ${lot.title}
  ...   AND   Input Text   name=data[lots][${lot_index}][description_en]    ${lot.description}
  ...   AND   Click Element    xpath=//label[@class="item l relative"][input[@value="uk"]]
  Capture Page Screenshot
  Додати багато предметів   ${data}

Додати багато предметів
  [Arguments]  ${data}
  Log Many  ${data}
  ${status}  ${items}=  Run Keyword And Ignore Error  Get From Dictionary   ${data.data}   items
  @{items}=  Run Keyword If  "${status}" == "PASS"  Set Variable  ${items}
  ...  ELSE  Create List  ${data}
  Log Many  ${items}
  ${items_length}=  Get Length  ${items}
  :FOR  ${index}  IN RANGE  ${items_length}
  \  Run Keyword if  ${index} != 0  Click Element  xpath=//button[contains(@class, "add_item")]
  \  Додати предмет   ${items[${index}]}


Додати предмет
  [Arguments]  ${item}
  Log Many  ${item}
  Capture Page Screenshot
  ${item_id}=   Get Element Attribute  xpath=(//input[contains(@name, "Tender[items]") and contains(@name, "[quantity]")])[last()]@id
  ${index}=   Set Variable  ${item_id.split("-")[1]}
  Input text  name=Tender[items][${index}][description]  ${item.description}
  Input text  name=Tender[items][${index}][quantity]  ${item.quantity}
  Select From List By Value  name=Tender[items][${index}][unit][code]  ${item.unit.code}
  Click Element  name=Tender[items][${index}][classification][description]
  Wait Until Element Is Visible  id=search
  Input text  id=search  ${item.classification.description}
  Wait Until Page Contains  ${item.classification.description}
  Click Element  xpath=//span[contains(text(),'${item.classification.description}')]
  Click Element  id=btn-ok
  Wait Until Element Is Not Visible  xpath=//div[@class="modal-backdrop fade"]  10
  Select From List By Value  name=Tender[items][${index}][additionalClassifications][0][dkType]  ДКПП_dkpp
  Click Element  name=Tender[items][${index}][additionalClassifications][0][description]
  Input text  id=search  ${item.additionalClassifications[0].description}
  Wait Until Page Contains  ${item.additionalClassifications[0].description}
  Click Element  xpath=//div[@id="${item.additionalClassifications[0].id}"]/div/span[contains(text(), '${item.additionalClassifications[0].description}')]
  Click Element  id=btn-ok
  Wait Until Element Is Visible  name=Tender[items][${index}][deliveryAddress][countryName]
  Input text  name=Tender[items][${index}][deliveryAddress][countryName]  ${item.deliveryAddress.countryName}
  Input text  name=Tender[items][${index}][deliveryAddress][region]  ${item.deliveryAddress.region}
  Input text  name=Tender[items][${index}][deliveryAddress][locality]  ${item.deliveryAddress.locality}
  Input text  name=Tender[items][${index}][deliveryAddress][streetAddress]  ${item.deliveryAddress.streetAddress}
  Input text  name=Tender[items][${index}][deliveryAddress][postalCode]  ${item.deliveryAddress.postalCode}
  Input Date  name=Tender[items][${index}][deliveryDate][startDate]  ${item.deliveryDate.endDate}
  Input Date  name=Tender[items][${index}][deliveryDate][endDate]  ${item.deliveryDate.endDate}
  Select From List By Value  name=Tender[procuringEntity][contactPoint][fio]  2
  Capture Page Screenshot

Додати нецінові критерії
  [Arguments]  ${tender_data}
  ${features}=   Get From Dictionary   ${tender_data.data}   features
  ${features_length}=   Get Length   ${features}
  :FOR   ${index}   IN RANGE   ${features_length}
  \   Run Keyword If  '${features[${index}].featureOf}' != 'tenderer'   Run Keywords
  ...  Click Element  xpath=(//div[@class="lot"]/descendant::button[contains(text(), "Додати показник")])[last()]
  ...  AND  Додати показник   ${features[${index}]}  ${tender_data}
  \   Run Keyword If  '${features[${index}].featureOf}' == 'tenderer'   Run Keywords
  ...   Click Element   xpath=(//div[@class="features_wrapper"]/descendant::button[contains(text(), "Додати показник")])[last()]
  ...   AND   Додати показник   ${features[${index}]}  ${tender_data}

Додати показник
  [Arguments]   ${feature}  ${tender_data}
  ${feature_index}=  Execute Javascript  return FeatureCount
  ${enum_length}=  Get Length   ${feature.enum}
  ${relatedItem}=  Run Keyword If   "${feature.featureOf}" == "item"   get_related_elem_description   ${tender_data}   ${feature}
  ...  ELSE IF  "${feature.featureOf}" == "lot"  Set Variable  Поточний лот
  ...  ELSE  Set Variable  Все оголошення
  Input text   name=Tender[features][${feature_index - 1}][title]   ${feature.title}
  Input text   name=Tender[features][${feature_index - 1}][description]   ${feature.description}
  #Select From List By Value   name=Tender[features][${feature_index - 1}][relatedItem]   ${relatedItem}
  Click Element  xpath=//select[@name="Tender[features][${feature_index - 1}][relatedItem]"]/descendant::option[contains(text(),"${relatedItem}")]
  :FOR   ${index}   IN RANGE   ${enum_length}
  \   Run Keyword if   ${index} != 0   Click Element   xpath=//input[@name="Tender[features][${feature_index - 1}][title]"]/ancestor::div[@class="feature grey"]/descendant::button[contains(@class,"add_feature_enum")]
  \   Додати опцію   ${feature.enum[${index}]}   ${index}   ${feature_index - 1}

Додати опцію
  [Arguments]  ${enum}  ${index}  ${feature_index}
  ${enum_value}=   Convert To Integer   ${enum.value * 100}
  Input Text   name=Tender[features][${feature_index}][enum][${index}][title]   ${enum.title}
  Input Text   name=Tender[features][${feature_index}][enum][${index}][value]   ${enum_value}

Завантажити документ
  [Arguments]  ${username}  ${filepath}  ${tender_uaid}
  Switch Browser  ${username}
  25h8.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Click Element  xpath=//a[contains(text(),'Редагувати')]
  Wait Until Element Is Visible  xpath=(//input[@name="FileUpload[file]"]/ancestor::a[contains(@class,'uploadfile')])[last()]
  Choose File  name=FileUpload[file]  ${filepath}
  ${last_doc_name}=  Get Element Attribute  xpath=(//input[contains(@name,"Tender[documents]")])[last()]@name
  ${doc_index}=  Set Variable  ${last_doc_name.split("][")[1]}
  Wait Until Element Is Visible  xpath=//input[@name="Tender[documents][${doc_index}][title]"]
  Input Text  xpath=//input[@name="Tender[documents][${doc_index}][title]"]  ${filepath.split("/")[-1]}
  Click Button  xpath=//button[contains(@class,'btn_submit_form')]
  Wait Until Page Contains Element  xpath=//div[contains(@class, "alert-success")]
  Дочекатися завантаження документу
  Capture Page Screenshot

Дочекатися завантаження документу
  Wait Until Keyword Succeeds  30 x  20 s  Run Keywords
  ...  Reload Page
  ...  AND  Wait Until Page Does Not Contain   Документ завантажується...  10

Пошук тендера по ідентифікатору
  [Arguments]  ${username}  ${tender_uaid}
  Switch browser  ${username}
  Go To  http://25h8.byustudio.in.ua/tenders/
  Execute Javascript  $('#navbar-main').remove()
  Input text  name=TendersSearch[tender_cbd_id]  ${tender_uaid}
  Click Element  xpath=//button[text()='Шукати']
  Wait Until Keyword Succeeds  30x  400ms  Перейти на сторінку з інформацією про тендер  ${tender_uaid}
  Execute Javascript  $('#navbar-main').remove()

Перейти на сторінку з інформацією про тендер
  [Arguments]  ${tender_uaid}
  Wait Until Element Is Not Visible  xpath=//ul[@class="pagination"]
  Click Element  xpath=//h3[text()='${tender_uaid}']/ancestor::div[@class="panel panel-default"]/descendant::a
  Wait Until Element Is Visible  xpath=//*[@tid="tenderID"]

Оновити сторінку з тендером
  [Arguments]  ${username}  ${tenderID}
  Reload Page

Внести зміни в тендер
  [Arguments]  ${username}  ${tenderID}  ${field_name}  ${field_value}
  25h8.Пошук тендера по ідентифікатору  ${username}  ${tenderID}
  Click Element  xpath=//a[contains(text(),'Редагувати')]
  Execute Javascript  $('#navbar-main').remove()
  Run Keyword If  "Date" in "${field_name}"  Input Date  name=Tender[${field_name.replace(".", "][")}]  ${field_value}
  ...  ELSE  Input text  name=Tender[${field_name}]  ${field_value}
  Click Element  xpath=//button[contains(@class,'btn_submit_form')]
  Wait Until Page Contains Element  xpath=//div[contains(@class, "alert-success")]

Змінити лот
  [Arguments]  ${username}  ${tender_uaid}  ${lot_id}  ${fieldname}  ${fieldvalue}
  25h8.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Click Element  xpath=//a[contains(text(),'Редагувати')]
  Execute Javascript  $('#navbar-main').remove()
  Input Text  xpath=//input[contains(@value,"${lot_id}")]/ancestor::div[@class="lots_marker"]/descendant::input[contains(@name,"${fieldname.replace(".", "][")}")]  ${fieldvalue}
  Click Element  xpath=//button[contains(@class,'btn_submit_form')]
  Wait Until Page Contains Element  xpath=//div[contains(@class, "alert-success")]

Завантажити документ в лот
  [Arguments]  ${username}  ${filepath}  ${tender_uaid}  ${lot_id}
  25h8.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Click Element  xpath=//a[contains(text(),'Редагувати')]
  Execute Javascript  $('#navbar-main').remove()
  Wait Until Page Contains Element  xpath=//div[@class="lots_marker"]/descendant::input[@name="FileUpload[file]"]
  Choose File  xpath=//div[@class="lots_marker"]/descendant::input[@name="FileUpload[file]"]  ${filepath}
  ${last_doc_name}=  Get Element Attribute  xpath=(//input[contains(@name,"Tender[documents]")])[last()]@name
  ${doc_index}=  Set Variable  ${last_doc_name.split("][")[1]}
  Wait Until Element Is Visible  xpath=//input[@name="Tender[documents][${doc_index}][title]"]
  Input Text  xpath=//input[@name="Tender[documents][${doc_index}][title]"]  ${filepath.split("/")[-1]}
  Click Button  xpath=//button[contains(@class,'btn_submit_form')]
  Wait Until Page Contains Element  xpath=//div[contains(@class, "alert-success")]
  Дочекатися завантаження документу
  Sleep  60
  Capture Page Screenshot

Створити лот із предметом закупівлі
  [Arguments]  ${username}  ${tender_uaid}  ${lot}  ${item}
  25h8.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Click Element  xpath=//a[contains(text(),'Редагувати')]
  Click Element  xpath=//button[contains(@class, "add_lot")]
  25h8.Створити лот  ${username}  ${tender_uaid}  ${lot}  ${item}
  Click Element  xpath=//button[contains(@class,'btn_submit_form')]
  Wait Until Page Contains Element  xpath=//div[contains(@class, "alert-success")]

Додати предмет закупівлі в лот
  [Arguments]  ${username}  ${tender_uaid}  ${lot_id}  ${item}
  25h8.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Click Element  xpath=//a[contains(text(),'Редагувати')]
  Click Element  xpath=//*[contains(@value, "${lot_id}")]/ancestor::div[@class="lot"]/descendant::button[contains(@class,"add_item")]
  25h8.Додати предмет  ${item}
  Click Element  xpath=//button[contains(@class,'btn_submit_form')]
  Wait Until Page Contains Element  xpath=//div[contains(@class, "alert-success")]

Додати неціновий показник на тендер
  [Arguments]  ${username}  ${tender_uaid}  ${feature}
  25h8.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Click Element  xpath=//a[contains(text(),'Редагувати')]
  25h8.Додати нецінові критерії  ${feature}

###############################################################################################################
###########################################    ВИДАЛЕННЯ    ###################################################
###############################################################################################################

Видалити предмет закупівлі
  [Arguments]  ${username}  ${tender_uaid}  ${item_id}  ${lot_id}=${Empty}
  25h8.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Click Element  xpath=//a[contains(text(),'Редагувати')]
  Click Element  xpath=//textarea[contains(text(), "${item_id}")]/ancestor::div[@class="item"]/descendant::button[contains(@class, "delete_item")]
  Confirm Action
  Click Element  xpath=//button[contains(@class,'btn_submit_form')]
  Wait Until Page Contains Element  xpath=//div[contains(@class, "alert-success")]

Видалити лот
  [Arguments]  ${username}  ${tender_uaid}  ${lot_id}
  25h8.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Click Element  xpath=//a[contains(text(),'Редагувати')]
  Click Element  xpath=//*[contains(@value, "${lot_id}")]/ancestor::div[@class="lot"]/descendant::button[contains(@class,"delete_lot")]
  Click Element  xpath=//button[contains(@class,'btn_submit_form')]
  Wait Until Page Contains Element  xpath=//div[contains(@class, "alert-success")]

###############################################################################################################
############################################    ПИТАННЯ    ####################################################
###############################################################################################################

Задати питання
  [Arguments]  ${username}  ${tender_uaid}  ${question}  ${related_to}=False
  25h8.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Click Element  xpath=//a[contains(@href, '/questions')]
  Input Text  name=Question[title]  ${question.data.title}
  Input Text  name=Question[description]  ${question.data.description}
  ${label}=  Get Text  xpath=//select[@id="question-questionof"]/option[contains(text(), "${related_to}")]
  Run Keyword If  "${related_to}" != False  Select From List By Label  name=Question[questionOf]  ${label}
  Click Element  name=question_submit
  Wait Until Page Contains  ${question.data.description}
  
Відповісти на питання
  [Arguments]  ${username}  ${tenderID}  ${question}  ${answer_data}  ${question_id}
  25h8.Пошук тендера по ідентифікатору  ${username}  ${tenderID}
  Click Element  xpath=//a[contains(@href, '/questions')]
  Wait Until Element Is Visible  name=Tender[0][answer]
  Input text  name=Tender[0][answer]  ${answer_data.data.answer}
  Click Element  name=answer_question_submit
  Wait Until Page Contains  ${answer_data.data.answer}  30

Задати запитання на тендер
  [Arguments]  ${username}  ${tender_uaid}  ${question}
  Задати питання  ${username}  ${tender_uaid}  ${question}  Тендеру

Задати запитання на предмет
  [Arguments]  ${username}  ${tender_uaid}  ${item_id}  ${question}
  Задати питання  ${username}  ${tender_uaid}  ${question}  ${item_id}

Задати запитання на лот
  [Arguments]  ${username}  ${tender_uaid}  ${lot_id}  ${question}
  Задати питання  ${username}  ${tender_uaid}  ${question}  ${lot_id}

###############################################################################################################
############################################    ВИМОГИ    #####################################################
###############################################################################################################

Створити вимогу про виправлення умов закупівлі
  [Arguments]  ${username}  ${tender_uaid}  ${claim}  ${document}=${None}
  25h8.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Click Element  xpath=//a[contains(@href, '/complaints')]
  Click Element  xpath=//a[contains(@href, "status=claim")]
#  Run Keyword If   '${lot_index}' != '${None}'   Select From List By Index   name=relatedLot   1
  Input Text  name=Complaint[title]  ${claim.data.title}
  Input Text  name=Complaint[description]  ${claim.data.description}
  Run Keyword IF  '${document}' != '${None}'  Choose File  name=FileUpload[file]  ${document}
  Click Element  name=complaint_submit
  Wait Until Page Contains Element  xpath=//div[contains(@class, "alert-success")]
  Дочекатися завантаження документу
  Wait Until Keyword Succeeds  10 x  30 s  Page Should Contain Element  xpath=//*[text()="${claim.data.title}"]/preceding-sibling::*[@tid="complaint.complaintID"]
  ${complaintID}=   Get Text   xpath=(//*[@tid="complaint.complaintID"])[last()]
  [return]  ${complaintID}


###############################################################################################################
###################################    ВІДОБРАЖЕННЯ ІНФОРМАЦІЇ    #############################################
###############################################################################################################

Отримати інформацію із тендера
  [Arguments]  ${username}  ${tender_uaid}  ${field_name}
  ${red}=  Evaluate  "\\033[1;31m"
  capture page screenshot
  ${status_item_block}=  Run Keyword And Return Status  Element Should Not Be Visible  xpath=//*[@tid="items.description"]
  Run Keyword If  '${field_name}' == 'status'  Click Element   xpath=//a[text()='Інформація про закупівлю']
#  Run Keyword If  'items' in '${field_name}' and ${status_item_block}  run keywords
#  ...  Click Element  xpath=//h2[@class="acordion"]
#  ...  AND  Wait Until Element Is Visible   xpath=//*[@tid="items.deliveryDate.endDate"]
  ${value}=  Run Keyword If  'unit.code' in '${field_name}'  Log To Console   ${red}\n\t\t\t Це поле не виводиться на 25h8
  ...  ELSE IF  'unit' in '${field_name}'  Get Text  xpath=//*[@tid="items.quantity"]
  ...  ELSE IF  'deliveryLocation' in '${field_name}'  Log To Console  ${red}\n\t\t\t Це поле не виводиться на 25h8
  ...  ELSE IF  'items' in '${field_name}'  Get Text  xpath=//*[@tid="${field_name.replace('[0]', '')}"]
 # ...  ELSE IF  'questions' in '${field_name}'  25h8.Отримати інформацію із запитання  ${field_name}
  ...  ELSE IF  'value' in '${field_name}'  Get Text  xpath=//*[@tid="value.amount"]
  ...  ELSE  Get Text  xpath=//*[@tid="${field_name}"]
  capture page screenshot
  ${value}=  adapt_view_data  ${value}  ${field_name}
  [Return]  ${value}

Отримати інформацію із предмету
  [Arguments]  ${username}  ${tender_uaid}  ${item_id}  ${field_name}
  ${red}=  Evaluate  "\\033[1;31m"
  ${field_name}=  Set Variable If  '[' in '${field_name}'  ${field_name.split('[')[0]}${field_name.split(']')[1]}  ${field_name}
  ${value}=  Run Keyword If
  ...  'unit.code' in '${field_name}'  Log To Console   ${red}\n\t\t\t Це поле не виводиться на 25h8
  ...  ELSE IF  'deliveryLocation' in '${field_name}'  Log To Console  ${red}\n\t\t\t Це поле не виводиться на 25h8
  ...  ELSE IF  'unit' in '${field_name}'  Get Text  xpath=//i[contains(text(), '${item_id}')]/ancestor::div[@class="item no_border"]/descendant::*[@tid='items.quantity']
  ...  ELSE  Get Text  xpath=//i[contains(text(), '${item_id}')]/ancestor::div[@class="item no_border"]/descendant::*[@tid='items.${field_name}']
  ${value}=  adapt_view_item_data  ${value}  ${field_name}
  [return]  ${value}

Отримати інформацію із лоту
  [Arguments]  ${username}  ${tender_uaid}  ${lot_id}  ${field_name}
  ${red}=  Evaluate  "\\033[1;31m"
 # ${field_name}=  Set Variable If  '[' in '${field_name}'  ${field_name.split('[')[0]}${field_name.split(']')[1]}  ${field_name}
  ${value}=  Run Keyword If  'minimalStep' in '${field_name}'  Get Text  xpath=//*[@tid="lots.minimalStep.amount"]
 # ...  'unit.code' in '${field_name}'  Log To Console   ${red}\n\t\t\t Це поле не виводиться на 25h8
 # ...  ELSE IF  'deliveryLocation' in '${field_name}'  Log To Console  ${red}\n\t\t\t Це поле не виводиться на 25h8
 # ...  ELSE IF  'unit' in '${field_name}'  Get Text  xpath=//i[contains(text(), '${item_id}')]/ancestor::div[@class="item no_border"]/descendant::*[@tid='items.quantity']
  ...  ELSE  Get Text  xpath=//i[contains(text(),"${lot_id}")]/ancestor::div[@class="lots_marker"]/descendant::*[@tid='lots.${field_name}']
  ${value}=  adapt_view_data  ${value}  ${field_name}
  [return]  ${value}

Отримати інформацію із нецінового показника
  [Arguments]  ${username}  ${tender_uaid}  ${feature_id}  ${field_name}
  ${red}=  Evaluate  "\\033[1;31m"
 # ${field_name}=  Set Variable If  '[' in '${field_name}'  ${field_name.split('[')[0]}${field_name.split(']')[1]}  ${field_name}
  ${value}=  Run Keyword If
  ...  'featureOf' in '${field_name}'  Get Element Attribute  xpath=//i[contains(text(),"${feature_id}")]/ancestor::div[@class="feature"]/descendant::*[@tid='feature.${field_name}']@rel
 # ...  ELSE IF  'deliveryLocation' in '${field_name}'  Log To Console  ${red}\n\t\t\t Це поле не виводиться на 25h8
 # ...  ELSE IF  'unit' in '${field_name}'  Get Text  xpath=//i[contains(text(), '${item_id}')]/ancestor::div[@class="item no_border"]/descendant::*[@tid='items.quantity']
  ...  ELSE  Get Text  xpath=//i[contains(text(),"${feature_id}")]/ancestor::div[@class="feature"]/descendant::*[@tid='feature.${field_name}']
  ${value}=  adapt_view_item_data  ${value}  ${field_name}
  [return]  ${value}

Отримати інформацію із документа
  [Arguments]  ${username}  ${tender_uaid}  ${doc_id}  ${field}
#  25h8.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  ${file_title}=   Get Text   xpath=//a[contains(text(),'${doc_id}')]
  ${file_title}=   Set Variable   ${file_title.split('/')[-1]}
  ${file_title}=   Convert To String   ${file_title}
  [return]  ${file_title}

Отримати документ
  [Arguments]  ${username}  ${tender_uaid}  ${doc_id}
#  25h8.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  ${file_name}=   Get Text   xpath=//a[contains(text(),'${doc_id}')]
  ${url}=   Get Element Attribute   xpath=//a[contains(text(),'${doc_id}')]@href
  custom_download_file   ${url}  ${file_name.split('/')[-1]}  ${OUTPUT_DIR}
 # Click Element   xpath=//span[contains(text(),'${doc_id}')]
 # Wait Until Keyword Succeeds   10 x   10 s   Get File   ${OUTPUT_DIR}${/}${file_name}
 # ${doc_content}  ${path_to_file}=   Wait Until Keyword Succeeds   20 sec   1 sec   get_doc_content   ${file_name}
 # Wait Until Keyword Succeeds   20 sec   1 sec   delete_doc   ${path_to_file}
  [return]  ${file_name.split('/')[-1]}

Отримати документ до лоту
  [Arguments]  ${username}  ${tender_uaid}  ${lot_id}  ${doc_id}
  ${file_name}=   25h8.Отримати документ   ${username}  ${tender_uaid}  ${doc_id}
  [return]  ${file_name}

Отримати інформацію із запитання
  [Arguments]  ${username}  ${tender_uaid}  ${question_id}  ${field_name}
  25h8.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  Click Element  xpath=//a[contains(@href, '/questions')]
  ${value}=  Get Text  xpath=//*[contains(text(), "${question_id}")]/ancestor::div[contains(@class, "questions margin_b")]/descendant::*[@tid="questions.${field_name.replace('[0]', '')}"]
  [Return]  ${value}

Отримати інформацію із скарги
  [Arguments]  ${username}  ${tender_uaid}  ${complaintID}  ${field_name}  ${award_index}=${None}
  25h8.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  Click Element  xpath=//a[contains(@href,"/tender/complaints/")]
  ${value}=  Get Text  xpath=//*[contains(text(), "${complaintID}")]/ancestor::div[contains(@class, "questions margin_b")]/descendant::*[@tid="complaint.${field_name}"]
  ${value}=  convert_string_from_dict_25h8  ${value}
  [Return]  ${value}

Отримати інформацію із документа до скарги
  [Arguments]  ${username}  ${tender_uaid}  ${complaintID}  ${doc_id}  ${field_name}  ${award_id}=${None}
  25h8.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  Click Element  xpath=//a[contains(@href,"/tender/complaints/")]
  25h8.Отримати інформацію із документа  ${username}  ${tender_uaid}  ${doc_id}  ${field_name}

Отримати документ до скарги
  [Arguments]  ${username}  ${tender_uaid}  ${complaintID}  ${doc_id}  ${award_id}=${None}
  25h8.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  Click Element  xpath=//a[contains(@href,"/tender/complaints/")]
  25h8.Отримати документ   ${username}  ${tender_uaid}  ${doc_id}

###############################################################################################################
#######################################    ПОДАННЯ ПРОПОЗИЦІЙ    ##############################################
###############################################################################################################  
  
Подати цінову пропозицію
  [Arguments]  ${username}  ${tender_uaid}  ${bid}
  Capture Page Screenshot
  25h8.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  ConvToStr And Input Text  xpath=//input[contains(@name, '[value][amount]')]  ${bid.data.value.amount}
  Click Element  xpath=//button[@id="submit_bid"]
  Wait Until Element Is Visible  xpath=//div[contains(@class, 'alert-success')]
  
Скасувати цінову пропозицію
  [Arguments]  ${username}  ${tender_uaid}  ${bid}
  25h8.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  Execute Javascript  window.confirm = function(msg) { return true; }
  Click Element  xpath=//button[@name="delete_bids"]
  
Змінити цінову пропозицію
  [Arguments]  ${username}  ${tender_uaid}  ${fieldname}  ${fieldvalue}
  25h8.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  ConvToStr And Input Text  xpath=//input[contains(@name, '[value][amount]')]  ${fieldvalue}
  Click Element  xpath=//button[@id="submit_bid"]
  Wait Until Element Is Visible  xpath=//div[contains(@class, 'alert-success')]
  
Завантажити документ в ставку
  [Arguments]  ${username}  ${path}  ${tender_uaid}  ${doc_type}=documents
  25h8.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  Choose File  name=FileUpload[file]  ${path} 
  Click Element  xpath=//button[@id="submit_bid"]
  Wait Until Element Is Visible  xpath=//div[contains(@class, 'alert-success')]
  Дочекатися завантаження документу
  
Змінити документ в ставці
  [Arguments]  ${username}  ${path}  ${bidid}  ${docid}
  Wait Until Keyword Succeeds   30 x   10 s   Дочекатися вивантаження файлу до ЦБД
  Execute Javascript  window.confirm = function(msg) { return true; }; $('#navbar-main').remove()
  Choose File  xpath=//div[contains(text(), 'Замiнити')]/form/input  ${path}
  Click Element  xpath=//button[@id="submit_bid"]
  Wait Until Element Is Visible  xpath=//div[contains(@class, 'alert-success')]
  Дочекатися завантаження документу
  
###############################################################################################################
##############################################    АУКЦІОН    ##################################################
###############################################################################################################

Отримати посилання на аукціон для глядача
  [Arguments]  ${username}  ${tender_uaid}  ${lot_id}=${Empty}
  25h8.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  ${auction_url}=  Wait Until Keyword Succeeds  10 x  60 s  Дочекатися посилання на аукціон
  [Return]  ${auction_url}
  
Отримати посилання на аукціон для учасника
  [Arguments]  ${username}  ${tender_uaid}
  25h8.Пошук тендера по ідентифікатору   ${username}  ${tender_uaid}
  ${auction_url}=  Wait Until Keyword Succeeds  10 x  60 s  Дочекатися посилання на аукціон
  [Return]  ${auction_url}
  
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

Дочекатися вивантаження файлу до ЦБД
  Reload Page
  Wait Until Element Is Visible   xpath=//div[contains(text(), 'Замiнити')]
  
Ввести текст
  [Arguments]  ${locator}  ${text}
  Wait Until Element Is Visible  ${locator}
  Input Text  ${locator}  ${text}

Дочекатися посилання на аукціон
  ${auction_url}=  Get Element Attribute  xpath=(//a[contains(text(), 'Аукцiон')])[1]@href
  Should Not Be Equal  ${auction_url}  javascript:void(0)
  [Return]  ${auction_url}