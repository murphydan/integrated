# Integrated

## A TestBox package for even better Integration tests in ColdBox!

[![Master Branch Build Status](https://img.shields.io/travis/elpete/integrated/master.svg?style=flat-square&label=master)](https://travis-ci.org/elpete/integrated)
[![Development Branch Build Status](https://img.shields.io/travis/elpete/integrated/development.svg?style=flat-square&label=development)](https://travis-ci.org/elpete/integrated)

### Installation
Install the package from ForgeBox:

```bash
box install integrated
```

**Important:**
Add the Integrated lib directory to `this.javaSettings` in your `*tests*` directory's `Application.cfc`.

```cfc
this.javaSettings = { loadPaths = [ "Integrated/lib" ], reloadOnChange = false };
```

### Usage

Change your Integration tests to extend from `Integration.BaseSpec`. (Make sure to call the parent class's `beforeAll` method.)

```cfc
component extends="Integrated.BaseSpec" {
    function beforeAll() {
        // Make sure to call the parent class's beforeAll() method.
        super.beforeAll();
    }
}
```

Start using an easy, fluent API for your integration tests!

```cfc
function run() {
    describe( "Registering", function() {
        it( "allows a new user to register for the site", function() {
            this.visitEvent('register.new')
                .type('Eric', 'name')
                .type('mYAw$someP2ssw0rd!', 'password')
                .press('Register')
                .seePageIs('/')
                .seeOnPage('Welcome, Eric!');
        });
    });
}
```

You can see all the different methods you can call in the [API docs](http://elpete.github.io/integrated/).
