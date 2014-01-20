# coding:utf-8

import os
import os.path as osp
import inspect

import pokers


DEBUG = 'SERVER_SOFTWARE' not in os.environ
DEBUG = True


if DEBUG:
    import logging
    logging.getLogger().setLevel(logging.DEBUG)


# 静态文件设置
POKER_PATH = osp.dirname(osp.abspath(inspect.getfile(pokers)))
STATIC_DIR = osp.join(POKER_PATH, 'static')
TEMPLATE_DIR = osp.join(POKER_PATH, 'templates')

# redis
REDIS_HOST = 'localhost'
REDIS_PORT = 6379
REDIS_DB = 0

# tornado设置
TORNADO_SETTINGS = {
    'autoescape': True,
    'cookie_secret': 'cu)X\r >pL?NZ~R=<aH\x0cj1l[h(6龙卷风',
    'debug': DEBUG,
    'login_url': '/auth/login',
    'logout_url': '/auth/logout',
    'static_path': STATIC_DIR,
    #'static_url_prefix': '/assets/',
    #'xsrf_cookies': True,
    'pycket': {
        'engine': 'redis',
        'storage': {
            'host': REDIS_HOST,
            'port': REDIS_PORT,
            'db_sessions': 10,
            'db_notifications': 10,
            'max_connections': 100,
        },
        'cookies': {
            'expires_days': 120,
        },
    },
}


del inspect, osp, pokers
