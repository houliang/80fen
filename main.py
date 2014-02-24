# coding: u8

import sys
import logging
import json

import os.path as osp
sys.path[0] = osp.dirname(osp.abspath('.'))

import tornado.web
import tornado.websocket
from tornado.web import authenticated

from pycket.session import SessionMixin

from pokers import g, settings, urls
from pokers.models import User


class Handler(tornado.web.RequestHandler, SessionMixin):
    def initialize(self):
        pass

    @property
    def s80(self):
        return g.s80

    def get_current_user(self):
        return self.session.get('user')

    @property
    def current_nick(self):
        return self.session.get('nickname').decode('u8')

    def render(self, path, **kwargs):
        g.render.render(self, path, **kwargs)

    def render_html(self, path, **kwargs):
        '''返回html并不flush到浏览器'''
        kwargs['just_html'] = True
        return g.render.render(self, path, **kwargs)

    def macro(self, path):
        return g.render.macro(path)

    def input(self, name, default=None, strip=True):
        return super(Handler, self).get_argument(name, default, strip)


class Signup(Handler):
    def get(self):
        self.render('auth/signup.html')

    def post(self):
        username = self.input('username')
        password = self.input('password')
        nickname = self.input('nickname')

        ret = {'err': True}

        uid = User.get_uid_by_username(username)
        if uid is not None:
            ret['msg'] = u'登录名已存在！'
            return self.write(ret)

        validator = User.is_valid(**locals())
        if validator is not None:
            ret['filed'] = validator[0]
            ret['msg'] = validator[1]
            return self.write(ret)

        User.save(username, password, nickname)

        ret['err'] = False
        self.write(ret)


class Login(Handler):
    def get(self):
        next = self.input('next', '/')
        self.render('auth/login.html', next=next)

    def post(self):
        username = self.input('username')
        password = self.input('password')

        ret = {'err': True}

        uid = User.get_uid_by_username(username)
        if uid is None:
            ret['msg'] = u'登录名不存在！'
            return self.write(ret)

        is_pwd_ok = User.is_password_valid(uid, password)
        ret['err'] = not is_pwd_ok
        if not is_pwd_ok:
            ret['msg'] = u'登录名或密码错误！'
        else:
            self.session.set('user', username)
            nickname = User.get_nickname_by_uid(uid)
            self.session.set('nickname', nickname)

        self.write(ret)


class Logout(Handler):
    def get(self):
        self.session.delete('user')
        self.redirect('/')


class Home(Handler):
    def get(self):
        self.render('index.html', username=self.current_user)


class ShengJi(Handler):
    @authenticated
    def get(self):
        self.render('80.html', pos=self.s80.pos,
                cards=self.session.get('cards'))


class WebSocket(Handler, tornado.websocket.WebSocketHandler):
    clients = set()

    def open(self):
        if len(WebSocket.clients) == 4:
            return self.write_message({'type': 'ping', 'data': 'overflow'})

        WebSocket.clients.add(self)
        WebSocket.broadcast({'type': 'online', 'nickname': self.current_nick,
            'data': u' 上线'})

    def on_close(self):
        WebSocket.clients.remove(self)
        WebSocket.broadcast({'type': 'offline', 'nickname': self.current_nick,
            'data': u' 离开'})

    def on_message(self, message):
        message = json.loads(message)
        _ = message['type']
        message['nickname'] = self.current_nick
        if _ == 'chat':
            WebSocket.broadcast(message)
        elif _ == 'ready':
            pos = message['pos']
            if self.s80.pos[pos]:
                self.write_message({'type': 'ready', 'suc': False})
            else:
                self.s80.pos[pos] = self
                message['data'] = u' 就绪'
                WebSocket.broadcast(message)

            if self.s80.pos.values().count(False) == 0:  # 所有都准备好了
                WebSocket.broadcast({'type': 'start',
                    'pos': {p: i.current_nick for p, i in self.s80.pos.items()}
                })
        elif _ == 'get-cards':  # 发牌
            pos = message['pos']
            cards = []
            for card in getattr(self.s80, pos):
                cards.append(card.js())
            #self.session.set('cards', cards)
            self.write_message({'type': 'get-cards', 'cards': cards,
                'current_point': int(self.s80.current_point)
            })
        elif _ == 'liangzhu':  # 亮主
            liang = message.pop('liang')
            color, point = liang[0], liang[1]
            num = message['num']
            cl = g.s80.current_liang
            suc = False

            # TODO: 检查color与point以及num是否在当前玩家的牌里
            pass

            if liang == 'hO':  # 两个大王
                suc = True
            elif liang == 'sO':  # 两个小王
                if not cl['point'] == 'O':
                    suc = True
            else:
                if cl['num'] == 0:
                    suc = True
                elif cl['num'] == 1:
                    if num == 2:
                        suc = True
            if suc:
                g.s80.current_liang['num'] = num
                g.s80.current_liang['who'] = message['nickname']
                g.s80.current_liang['color'] = color
                g.s80.current_liang['point'] = point
                message['color'] = color
                message['point'] = point
                message['suc'] = True
                WebSocket.broadcast(message)
                if g.s80.is_first:
                    g.s80.is_first = False
                    g.s80.last_zhuang = g.s80.current_zhuang = self
                    n = self.current_nick
                    WebSocket.broadcast({'type': 'zhuang', 'who': n})
            else:
                self.write_message({'type': 'liangzhu', 'suc': False})
        elif _ == 'fapai-over':  # 发牌完毕
            self.fapai_over = True
            four_over = True
            for c in WebSocket.clients:
                if not hasattr(c, 'fapai_over'):
                    four_over = False
                    break
            if four_over:
                WebSocket.broadcast({'type': 'countdown'})  # 倒计时
        elif _ == 'liang-over':  # 亮主完毕
            self.liang_over = True
            four_over = True
            for c in WebSocket.clients:
                if not hasattr(c, 'liang_over'):
                    four_over = False
                    break
            if four_over:
                if self.s80.current_liang['num'] == 0:
                    raise ValueError('nobody Liang Zhu...')
                zhuang = self.s80.current_zhuang
                zhuang.write_message({
                    'type': 'di', 'di': [d.js() for d in self.s80.di]})  # 底
                n = zhuang.current_nick
                for c in WebSocket.clients:
                    if c != zhuang:
                        c.write_message({'type': 'wait-maidi', 'zhuang': n})
        elif _ == 'refreshall':  # 刷新所有页面
            # 调试用(重新生成牌)： TODO: 删除下面两句话
            from pokers.shengjilib import S80
            g.s80 = S80.refresh()
            WebSocket.broadcast({'type': 'refresh'})
        elif _ == 'maidi':  # 埋底
            self.s80.make_di(message['di'])
            WebSocket.broadcast({'type': 'chupai',
                'who': self.s80.current_zhuang.current_nick})
        else:
            self.write_message({'type': 'lol'})

    @staticmethod
    def broadcast(message):
        '''向所有用户广播'''
        for c in WebSocket.clients:
            c.write_message(message)


class Application(tornado.web.Application):
    def __init__(self):
        us = []
        env = globals()
        for route in urls.urls:
            if len(route) > 2:
                continue
            url, handler_name = route
            handler = env.get(handler_name, None)
            if handler is not None:
                us.append((url, handler))
            else:
                logging.error('handler `{0}` not found'.format(handler_name))
        tornado.web.Application.__init__(self, us, **settings.TORNADO_SETTINGS)


application = Application()


def main():
    import tornado.options
    from tornado.options import define, options

    define('host', default='localhost', type=str)
    define('port', default=8888, type=int)
    tornado.options.parse_command_line()

    application.listen(options.port)

    print '* Starting server...'
    print '* Running on http://localhost:%s' % options.port
    tornado.ioloop.IOLoop.instance().start()


if __name__ == '__main__':
    main()
