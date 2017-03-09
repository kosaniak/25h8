 #!/usr/bin/python
 # -*- coding: utf-8 -*-

from datetime import datetime
from iso8601 import parse_date
from pytz import timezone
import urllib


def convert_time(date):
    date = datetime.strptime(date, "%d/%m/%Y %H:%M:%S")
    return timezone('Europe/Kiev').localize(date).strftime('%Y-%m-%dT%H:%M:%S.%f%z')


def convert_datetime_to_25h8_format(isodate):
    iso_dt = parse_date(isodate)
    day_string = iso_dt.strftime("%d/%m/%Y %H:%M")
    return day_string


def convert_string_from_dict_25h8(string):
    return {
        u"грн": u"UAH",
        u"True": u"1",
        u"False": u"0",
        u"Відкриті торги": u"aboveThresholdUA",
        u'Код ДК 021-2015 (CPV)': u'CPV',
        u'Код ДК': u'ДКПП',
        u'з урахуванням ПДВ': True,
        u'без урахуванням ПДВ': False,
        u'ОЧIКУВАННЯ ПРОПОЗИЦIЙ': u'active.tendering',
        u'ПЕРIОД УТОЧНЕНЬ': u'active.enquires',
        u'АУКЦIОН': u'active.auction',
        u'вимога': u'claim',
        u'дано відповідь': u'answered',
        u'вирішено': u'resolved',
    }.get(string, string)


def adapt_procuringEntity(tender_data):
    tender_data['data']['procuringEntity']['name'] = u"Ольмек"
    return tender_data


def adapt_view_data(value, field_name):
    if 'value.amount' in field_name:
        value = float(value.split(' ')[0])
    elif 'currency' in field_name:
        value = value.split(' ')[1]    
    elif 'valueAddedTaxIncluded' in field_name:
        value = ' '.join(value.split(' ')[2:])
    elif 'minimalStep.amount' in field_name:
        value = float(value.split(' ')[0])
    elif 'unit.name' in field_name:
        value = value.split(' ')[1]
    elif 'quantity' in field_name:
        value = float(value.split(' ')[0])
    elif 'questions' in field_name and '.date' in field_name:
        value = convert_time(value.split(' - ')[0])
    elif 'Date' in field_name:
        value = convert_time(value)
    return convert_string_from_dict_25h8(value)


def adapt_view_item_data(value, field_name):
    if 'unit.name' in field_name:
        value = ' '.join(value.split(' ')[1:])
    elif 'quantity' in field_name:
        value = float(value.split(' ')[0])
    return convert_string_from_dict_25h8(value)


def get_related_elem_description(tender_data, feature):
    for elem in tender_data['data']['{}s'.format(feature['featureOf'])]:
        if feature['relatedItem'] == elem['id']:
            return elem['description']


def custom_download_file(url, file_name, output_dir):
    urllib.urlretrieve(url, ('{}/{}'.format(output_dir, file_name)))


def add_second_sign_after_point(amount):
    amount = str(repr(amount))
    if '.' in amount and len(amount.split('.')[1]) == 1:
        amount += '0'
    return amount
