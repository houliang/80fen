# coding:utf-8

__doc__ = 'url中有-的为ajax请求; 以.json结尾的url说明此请求要求返回json格式'
__all__ = ['urls']


urls = [
    (r'/', 'Home'),

    (r'/auth/signup', 'Signup'),
    (r'/auth/login', 'Login'),
    (r'/auth/logout', 'Logout'),

    (r'/80', 'ShengJi'),

    (r'/websocket', 'WebSocket'),
]
