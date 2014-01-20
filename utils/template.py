# coding: utf-8

import jinja2
from jinja2 import evalcontextfilter


@evalcontextfilter
def clean(eval_ctx, value):
    import re
    return re.sub(r'[^\w]+', ' ', value)


@evalcontextfilter
def date(eval_ctx, value):
    if isinstance(value, str) or isinstance(value, unicode):
        import datetime
        value = datetime.datetime.strptime(value, '%Y-%m-%d')
    if value:
        return value.date()
    else:
        return ''


class Render(object):
    def __init__(self, template_path, **kw):
        from jinja2 import Environment, FileSystemLoader

        extra = kw.pop('extra', [])
        self._env = Environment(loader=FileSystemLoader(template_path), **kw)
        self._env.globals.update(extra)
        self._env.filters.update(dict(
            date=date,
            clean=clean,
        ))

    def render(self, handler, path, **kw):
        # 将tornado中的传递给模板的隐式参数'转移'到jinja2中
        args = dict(
            handler=handler,
            request=handler.request,
            #locale=handler.locale,
            #_=handler.locale.translate,
            loggedin=handler.current_user,
            static_url=handler.static_url,
            #xsrf_form_html=handler.xsrf_form_html,
            #reverse_url=handler.application.reverse_url
        )
        kw.update(args)

        just_html = kw.pop('just_html', False)
        html = self._env.get_template(path).render(**kw)

        if just_html:
            return html
        else:
            handler.write(html)

    def macro(self, path):
        return self._env.get_template(path).module


class UndefinedSilently(jinja2.Undefined):
    __unicode__ = __str__ = lambda *args, **kwargs: u''
    __call__ = __getattr__ = lambda *args, **kwargs: UndefinedSilently()
