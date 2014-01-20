import datetime
import hashlib


def now():
    return datetime.datetime.now()


def md5(string):
    return hashlib.md5(string).hexdigest()


def json_default(obj):
    _is = lambda type: isinstance(obj, type)
    if _is(datetime.datetime):
        return obj.strftime('%Y-%m-%d %H:%M:%S')
    if _is(datetime.date):
        return obj.strftime('%Y-%m-%d')
    if _is(set):
        return list(obj)
