# coding: u8

import re

from pokers import g, utils


rds = g.rds


class User:
    # %s代表uid
    _username = 'user:%s:username'
    _password = 'user:%s:password'
    _nickname = 'user:%s:nickname'
    _point = 'user:%s:point'

    # %s代表username
    _uid = 'user:%s:id'

    RE_USERNAME = re.compile(r'^[0-9a-zA-Z]{2,}$')

    @staticmethod
    def get_uid_by_username(username):
        return rds.get(User._uid % username)

    @staticmethod
    def save(username, password, nickname):
        password = utils.md5(password)
        import uuid
        uid = uuid.uuid4().hex
        rds.set(User._uid % username, uid)
        rds.set(User._username % uid, username)
        rds.set(User._password % uid, password)
        rds.set(User._nickname % uid, nickname)
        rds.set(User._point % uid, 0)

    @staticmethod
    def get_nickname_by_uid(uid):
        return rds.get(User._nickname % uid)

    @staticmethod
    def is_password_valid(uid, password):
        return rds.get(User._password % uid) == utils.md5(password)

    @staticmethod
    def is_valid(**kwargs):
        username = kwargs.pop('username')
        if not User.RE_USERNAME.match(username):
            return 'username', u'用户名只能是数字字母组成，字符数不少于2'
        password = kwargs.pop('password')
        if not password:
            return 'password', u'请输入密码'

        nickname = kwargs.pop('nickname')
        if not nickname:
            return 'nickname', u'请输入昵称'
