# coding: u8

import json

import redis

from pokers import utils, settings
from pokers.utils import template

from pokers.shengjilib import S80


__all__ = ['rds', 'render']

_dumps = json.dumps
json.dumps = lambda obj: _dumps(obj, default=utils.json_default)


rds = redis.StrictRedis(host=settings.REDIS_HOST, port=settings.REDIS_PORT,
        db=settings.REDIS_DB)

s80 = S80(2)


# jinja2
_extra = {}
if settings.DEBUG:
    _extra.update(__builtins__)
render = template.Render(
    template_path=settings.TEMPLATE_DIR,
    trim_blocks=True,
    auto_reload=settings.DEBUG,
    extra=_extra,
    extensions=['jinja2.ext.do'],
    line_statement_prefix='@',
    line_comment_prefix='@#',
    autoescape=True,
    undefined=template.UndefinedSilently,
)
