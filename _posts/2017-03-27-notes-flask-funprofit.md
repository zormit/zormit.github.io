---
title: "Notes on 'Flask for Fun and Profit'"
layout: post
date: 2017-03-27 8:08:32 -0400
tags: [rc]
categories: main
---

These are some notes I've taken while watching [Flask for Fun and Profit](https://youtu.be/1ByQhAM5c1I),
a PyCon Talk by Armin Ronacher, about some best practice approaches on different topics related to
[Flask](http://flask.pocoo.org).
I linked to the video and the slides for several sections.
Later I might add a template for a Flask based API thing which contains all of these snippets.

## Where does Flask come from? [▶](https://youtu.be/1ByQhAM5c1I?t=1m16s) [📖](https://speakerdeck.com/pybay2016/armin-ronacher-flask-for-fun-and-profit?slide=6)

### History

* Flask <- Werkzeug
* Werkzeug <- WSGITools
* WSGITools <- Colubrid
* Colubrid <- lots of PHP / "Pocoo"

### Motivation

* trac:
    * nice plugin design
    * wrote low level code for dealing with webserver itself. it's own:
        * fast_cgi driver
        * CGI implementation
        * driver for mod_python
* there was no base transport layer.
* idea: create a "standard" implementation.
* only provide the bare minimum


## Why do people like it? [▶](https://youtu.be/1ByQhAM5c1I?t=4m18s) [📖](https://speakerdeck.com/pybay2016/armin-ronacher-flask-for-fun-and-profit?slide=9)


* API reasonates with people
    * There is e.g. an Amazon Lambda in Python
* Small footprint

## What it's good at [▶](https://youtu.be/1ByQhAM5c1I?t=5m30s) [📖](https://speakerdeck.com/pybay2016/armin-ronacher-flask-for-fun-and-profit?slide=13)


* Small, HTML heavy CRUD sites, e.g. wiki, cms, community forum
* JSON APIs
* Good for micorservices

## What it's bad at [▶](https://youtu.be/1ByQhAM5c1I?t=6m15s) [📖](https://speakerdeck.com/pybay2016/armin-ronacher-flask-for-fun-and-profit?slide=18)


* High performance Async IO. Reason: WSGI.
* there are clones though, for e.g. twisted.

## My Favourite Flask App Structure [▶](https://youtu.be/1ByQhAM5c1I?t=7m13s) [📖](https://speakerdeck.com/pybay2016/armin-ronacher-flask-for-fun-and-profit?slide=20)


### create_app

{% highlight python %}
from flask import Flask

def create_app(config=None):
    app = Flask(__name__) # "dummy object"
    app.config.update(config or {})
    register_blueprints(app) # store all app code in blueprints.
    register_other_things(app)
    return app
{% endhighlight %}

Benefits of this:
* you can create multiple `create_app`'s, e.g. another one for unit testing purposes
* problem: application object is encapsulated in a function. thus put your stuff into blueprints.

### register_blueprints

{% highlight python %}
from werkzeug.utils import find_modules, import_string

def register_blueprints(app):
    for name in find_modules('myapp.blueprints'):
        mod = import_string(name)
        if hasattr(mod, 'blueprint'):
            app.register_blueprint(mod.blueprint)
{% endhighlight %}

* accesses modules via their path. expects common structure.

### Optional Contained App [▶](https://youtu.be/1ByQhAM5c1I?t=9m50s) [📖](https://speakerdeck.com/pybay2016/armin-ronacher-flask-for-fun-and-profit?slide=23)


{% highlight python %}
from flask import Flask

class MyThing(object):

    def __init__(self, config):
        self.flask_app = create_app(config)
        self.flask_app.my_thing = self

    def __call__(self, environ, start_response):
        return self.flask_app(environ, start_response)
{% endhighlight %}

* Goal: Clean up the namespace. Makes sense when you're exposing an (python?) API to others

### Development Runner [▶](https://youtu.be/1ByQhAM5c1I?t=11m30s) [📖](https://speakerdeck.com/pybay2016/armin-ronacher-flask-for-fun-and-profit?slide=24)


How to configure it?

{% highlight python %}
# devapp.py
from myapp import create_app
app = create_app({
        'DATABASE_URI': 'sqlite:////tmp/my-appdb.db',
})
{% endhighlight %}

To run this, use `flask` bash command, like this:

{% highlight bash %}
$ export FLASK_APP=`pwd`/devapp.py
$ export FALSK_DEBUG=1
$ flask run
# [... running via devapp.py ...]
{% endhighlight %}

Benefits of this (vs. `app.run()`):
* The runner will not die on syntax errors.
* Less work when reloading, setup code will only run once.
* No dropped connections, because the server runs on while reloading your app.

Don't deploy debugger!

## Context Locals [▶](https://youtu.be/1ByQhAM5c1I?t=15m55s) [📖](https://speakerdeck.com/pybay2016/armin-ronacher-flask-for-fun-and-profit?slide=27)


* Globals: `current_app` and `g` objects
* This splits opinions. "Global variables are terrible". But: they still have to be hidden somewhere, e.g. connection pooling in Django.
* Since it's needed, it could be "embraced", so everybody sees what's going on.

### Other Context Objects [▶](https://youtu.be/1ByQhAM5c1I?t=18m20s) [📖](https://speakerdeck.com/pybay2016/armin-ronacher-flask-for-fun-and-profit?slide=29)


* Two Contexts, four global variables for HTTP Requests:
    * request context bound:
        * `flask.request`
        * `flask.session`
    * app context bound:
        * `flask.g`
        * `flask.current_app`
* App context tears down at the end of a request. It's automatically created on request. This is cheap to create and not complex to understand.
* collects information for the current execution (request, cronjob, ...)
    * e.g. security context, language() context

### Resource Management [▶](https://youtu.be/1ByQhAM5c1I?t=21m00s) [📖](https://speakerdeck.com/pybay2016/armin-ronacher-flask-for-fun-and-profit?slide=32)


* cf. [documentation](http://flask.pocoo.org/docs/0.12/patterns/sqlite3/).
    * creates DB as soon as it's needed
    * end of request, it will be closed.
    * In Flask you need to do it explicitely, opposed to Django
    * Another example: User management.

## JSON APIs [▶](https://youtu.be/1ByQhAM5c1I?t=23m45s) [📖](https://speakerdeck.com/pybay2016/armin-ronacher-flask-for-fun-and-profit?slide=34)


### Result Wrapper

{% highlight python %}
from flask import json, Response

class ApiResult(object):

    def __init__(self, value, status=200):
        self.value = value
        self.status = status

    def to_response(self):
        return Response(json.dumps(self.value),
                        status=self.status,
                        mimetype='application/json')
{% endhighlight %}

* "I don't use extensions [...] because I want to have API endpoints to be consistent"
    * Headers
    * Whitespaces
    * Variables
    * Mimetype
    * Pagination (Link vs custom headers)
    * Rate Limiting Information

### Response Converter [▶](https://youtu.be/1ByQhAM5c1I?t=25m15s) [📖](https://speakerdeck.com/pybay2016/armin-ronacher-flask-for-fun-and-profit?slide=36)


{% highlight python %}
from flask import Flask

class ApiFlask(Flask):

    def make_response(self, rv):
        if isinstance(rv, ApiResult):
            return rv.to_response()
        # mimetype: text/html
        return Flask.make_response(self, rv)
{% endhighlight %}

### API Errors [▶](https://youtu.be/1ByQhAM5c1I?t=26m00s) [📖](https://speakerdeck.com/pybay2016/armin-ronacher-flask-for-fun-and-profit?slide=37)


{% highlight python %}
from flask import json, Response

class ApiException(object):

    def __init__(self, message, status=400):
        self.message = message
        self.status = status

    def to_result(self):
        return ApiResult({'message': self.message},
                            status=self.status)
{% endhighlight %}

Add Error Handler (I think, this should be called from `create_app`?):

{% highlight python %}
def register_error_handlers(app):
    app.register_error_handler(
        ApiException, lambda err: err.to_result())
{% endhighlight %}

### Demo API [▶](https://youtu.be/1ByQhAM5c1I?t=26m40s) [📖](https://speakerdeck.com/pybay2016/armin-ronacher-flask-for-fun-and-profit?slide=39)


{% highlight python %}
from flask import Blueprint

bp = Blueprint('demo', __name__)

@bp.route('/add')
def add_numbers():
    a = request.args('a', type=int) # you should use request.args.get...
    b = request.args('b', type=int)
    if a is None or b is None:
        rais ApiException('Numbers must be integers')
    return ApiResult({'sum': a + b})
{% endhighlight %}

* Functions return nice objects that can be *tested* easily.

## Validation / Serialization [▶](https://youtu.be/1ByQhAM5c1I?t=27m43s) [📖](https://speakerdeck.com/pybay2016/armin-ronacher-flask-for-fun-and-profit?slide=40)


* Python is bad at this. "I hate this"
* "One that works for me: voluptuous"

### voluptuous 101 [▶](https://youtu.be/1ByQhAM5c1I?t=29m00s) [📖](https://speakerdeck.com/pybay2016/armin-ronacher-flask-for-fun-and-profit?slide=43)


{% highlight python %}
from flask import request
from voluptuous import Invalid

def dataschema(schema):
    # "standard kebap"
    def decorator(f):
        def new_func(*args, **kwargs):
            try:
                kwargs.update(schema(request.get_json()))
            except Invalid as e:
                raise ApiException('Invalid data: %s (path "%s")' %
                                    (e.msg, '.'.join(e.path)))
            return f(*args, **kwargs)
        return update_wrapper(new_func, f)
    return decorator
{% endhighlight %}

### voluptuousified view

{% highlight python %}
from voluptuous import Schema, REMOVE_EXTRA

@app.route('/add', methods=['POST'])
@dataschema(Schema({
    'a': int,
    'b': int,
}, extra=REMOVE_EXTRA))
def add_numbers():
    return ApiResult({'sum': a + b})
{% endhighlight %}

* Handrolling gives you control and the error handling will be way nicer

### Control the API: Pagination [▶](https://youtu.be/1ByQhAM5c1I?t=32m00s) [📖](https://speakerdeck.com/pybay2016/armin-ronacher-flask-for-fun-and-profit?slide=47)

* Extend `ApiResult` slightly

## Security! [▶](https://youtu.be/1ByQhAM5c1I?t=32m35s) [📖](https://speakerdeck.com/pybay2016/armin-ronacher-flask-for-fun-and-profit?slide=48)


* You have to know how the context in Flask works
* You have to control the "tooling"
* You have to control where the user data comes from
* Make the code aware of the context it's executed at.
    * app with customers. each one is supposed to see customer related information.
    * it get's complicated with scaffolding, like being part of an organization
    * example: fixed filter `get_available_organizations`
* cf. to old PHP code that printed out strings. XSS vulnerable!
    * sanitization does not really work
    * you need to consider the context. where is the string used?
    * e.g. tmeplate -> HTML -> will be escaped accordingly
    * or: JSON Escaping ([▶](https://youtu.be/1ByQhAM5c1I?t=36m20s)). Serialize it as safe as possible.
* Simplify the API
* What does the data look like? Where is it used?

## Testing! [▶](https://youtu.be/1ByQhAM5c1I?t=38m00s) [📖](https://speakerdeck.com/pybay2016/armin-ronacher-flask-for-fun-and-profit?slide=52)


* Fixtures: Run common code as part of your test, before and after you tests, automatic management.

###  Basic Example [▶](https://youtu.be/1ByQhAM5c1I?t=38m40s) [📖](https://speakerdeck.com/pybay2016/armin-ronacher-flask-for-fun-and-profit?slide=54)


{% highlight python %}
import pytest

# entire model calls this only once.
@pytest.fixture(scope='module')
def app(request): # depends on "request" (dependency injection)
    from yourapp import create_app
    app = create_app(...)
    ctx = app.app_context()
    ctx.push()
    request.addfinalizer(ctx.pop)
    return app
{% endhighlight %}

Example Test:

{% highlight python %}
def test_app_name(app): # inject app fixture here.
    assert app.name == 'mypackage'
{% endhighlight %}

### More Fixtures

{% highlight python %}
@pytest.fiture(scope='module')
def test_client(request, app):
    client = app.test_client()
    client.__enter__()
    request.addfinalizer(
        lambda: client.__exit__(None, None, None))
    return client
{% endhighlight %}

### Example View Test

{% highlight python %}
def test_welcome_view(test_client):
    rv = test_client.get('/welcome')
    assert 'set-cookie' not in rv.headers
    assert b'Welcome' in rv.data
    assert rv.status_code == 200
{% endhighlight %}

* pytest used to do *a lot* of magic. It got better.
* The `assert`'s get rewritten behind the scenes

## Websockets and Stuff [▶](https://youtu.be/1ByQhAM5c1I?t=41m30s) [📖](https://speakerdeck.com/pybay2016/armin-ronacher-flask-for-fun-and-profit?slide=58)


* "You don't do that with Flask"

*I wasn't interested so much in the rest of the talk, so I stopped taking notes.*
