/**
* Abstract component for fluent integration tests.
* Needs to be implemented for each framework it targets.
*
* @doc_abstract true
*/
component extends="testbox.system.compat.framework.TestCase" {

    // The DOM-specific assertion engine
    property name='domEngine' type='Integrated.Engines.Assertion.Contracts.DOMAssertionEngine';
    // The Framework-specific assertion engine
    property name='frameworkEngine' type='Integrated.Engines.Assertion.Contracts.FrameworkAssertionEngine';
    // The interaction engine
    property name='interactionEngine' type='Integrated.Engines.Interaction.Contracts.InteractionEngine';
    // The request engine
    property name='requestEngine' type='Integrated.Engines.Request.Contracts.RequestEngine';

    // Boolean flag to turn on automatic database transactions
    this.useDatabaseTransactions = false;
    // Boolean flag to turn on persisting of the session scope between specs
    this.persistSessionScope = false;


    /***************************** Set Up *******************************/

    /**
    * Sets up the needed dependancies for Integrated.
    *
    * @return Integrated.BaseSpecs.AbstractBaseSpec
    *
    * @beforeAll
    */
    public AbstractBaseSpec function beforeAll(
        DOMAssertionEngine domEngine = new Integrated.Engines.Assertion.JSoupAssertionEngine(),
        required FrameworkAssertionEngine frameworkEngine,
        InteractionEngine interactionEngine = new Integrated.Engines.Interaction.JSoupInteractionEngine(),
        required RequestEngine requestEngine,
        additionalMatchers = 'Integrated.BaseSpecs.DBMatchers'
    ) {
        // Prime the engines
        variables.domEngine = arguments.domEngine;
        variables.frameworkEngine = arguments.frameworkEngine;
        variables.interactionEngine = arguments.interactionEngine;
        variables.interactionEngine.setDOMAssertionEngine(variables.domEngine);
        variables.requestEngine = arguments.requestEngine;

        // Add the database matchers
        addMatchers(arguments.additionalMatchers);

        // Start with an empty request 
        setRequestMethod( "" );
        setEvent( "" );

        return this;
    }

    public void function afterAll() {}

    /**
    * Returns the framework route portion of a url.
    *
    * @url A full url
    *
    * @return string
    */
    private string function parseFrameworkRoute(required string url) {
        return variables.requestEngine.parseFrameworkRoute(argumentCollection = arguments);
    }


    /***************************** Lifecycle Methods *******************************/


    /**
    * Wraps each spec in a database transaction, if desired.
    * Automatically runs around each TestBox spec.
    *
    * @spec The TestBox spec to execute.
    *
    * @aroundEach
    */
    public void function shouldUseDatabaseTransactions(spec) {
        if (this.useDatabaseTransactions) {
            wrapInDatabaseTransaction(arguments.spec);
        }
        else {
            arguments.spec.body();
        }
    }

    /**
    * Wraps each spec in a database transaction.
    *
    * @spec The TestBox spec to execute.
    */
    private void function wrapInDatabaseTransaction(spec) {
        transaction action="begin" {
            try {
                arguments.spec.body();
            }
            catch (any e) {
                rethrow;
            }
            finally {
                transaction action="rollback";
            }
        }
    }

    /**
    * Clears the session scope before each spec, if desired.
    * Automatically runs around each TestBox spec.
    *
    * @beforeEach
    */
    public void function shouldPersistSessionScope() {
        if (! this.persistSessionScope) {
            clearSessionScope();
        }
    }

    /**
    * Clears the session scope
    */
    private void function clearSessionScope() {
        structClear(session);
    }


    /***************************** Interactions *******************************/


    /**
    * Makes a request to a ColdBox route.
    *
    * @route The ColdBox route to visit, e.g. `/login` or `/posts/4`. Integrated will build the full url based on ColdBox settings (including `index.cfm`, if needed).
    *
    * @return Integrated.BaseSpecs.AbstractBaseSpec
    */
    public AbstractBaseSpec function visit(required string route) {
        makeRequest(method = 'GET', route = arguments.route);

        return this;
    }

    /**
    * Makes a request to a ColdBox event.
    *
    * @event The ColdBox event to visit, e.g. `Main.index` or `Posts.4`.
    *
    * @return Integrated.BaseSpecs.AbstractBaseSpec
    */
    public AbstractBaseSpec function visitEvent(required string event) {
        makeRequest(method = 'GET', event = arguments.event);

        return this;
    }

    /**
    * Clicks on a link in the current page.
    *
    * @link A selector of a link or the text of the link to click.
    *
    * @return Integrated.BaseSpecs.AbstractBaseSpec
    */
    public AbstractBaseSpec function click(required string link) {
        var href = variables.domEngine.findLink(argumentCollection = arguments);

        var route = parseFrameworkRoute(href);
        route = isNull(route) ? '' : route;

        this.visit(route);

        return this;
    }

    /**
    * Types a value in to a form field.
    *
    * @text The value to type in the form field.
    * @element The element selector or name to type the value in to.
    *
    * @return Integrated.BaseSpecs.AbstractBaseSpec
    */
    public AbstractBaseSpec function type(required string text, required string element) {
        variables.interactionEngine.type(argumentCollection = arguments);

        return this;
    }

    /**
    * Checks a checkbox.
    *
    * @element The selector or name of the checkbox to check.
    *
    * @return Integrated.BaseSpecs.AbstractBaseSpec
    */
    public AbstractBaseSpec function check(required string element) {
        variables.interactionEngine.check(argumentCollection = arguments);

        return this;
    }

    /**
    * Unchecks a checkbox.
    *
    * @element The selector or name of the checkbox to uncheck.
    *
    * @return Integrated.BaseSpecs.AbstractBaseSpec
    */
    public AbstractBaseSpec function uncheck(required string element) {
        variables.interactionEngine.uncheck(argumentCollection = arguments);

        return this;
    }

    /**
    * Selects a given option in a given select field.
    *
    * @option The value or text to select.
    * @element The selector or name to choose the option in.
    *
    * @return Integrated.BaseSpecs.AbstractBaseSpec
    */
    public AbstractBaseSpec function select(required string option, required string element) {
        variables.interactionEngine.select(argumentCollection = arguments);

        return this;
    }

    /**
    * Press a submit button.
    *
    * @button The selector or name of the button to press.
    * @overrideEvent Optional. The event to run instead of the form's default. Default: ''.
    *
    * @return Integrated.BaseSpecs.AbstractBaseSpec
    */
    public AbstractBaseSpec function press(required string button, string overrideEvent = '') {
        return this.submitForm(
            button = arguments.button,
            overrideEvent = arguments.overrideEvent
        );
    }

    /**
    * Submits a form
    *
    * @button The selector or name of the button to press.
    * @inputs Optional. The form values to submit.  If not provided, uses the values stored in Integrated combined with any values on the current page. Default: {}.
    * @overrideEvent Optional. The event to run instead of the form's default. Defeault: ''.
    *
    * @return Integrated.BaseSpecs.AbstractBaseSpec
    */
    public AbstractBaseSpec function submitForm(
        required string button,
        struct inputs = {},
        string overrideEvent = ''
    ) {
        if (StructIsEmpty(arguments.inputs)) {
            // Send to the interactionEngine and get back the inputs
            var inputs = variables.domEngine.getFormInputs(arguments.button);
            
            // Put the form values from the current page in to the interactionEngine
            for (var input in inputs) {
                variables.interactionEngine.storeInput(
                    element = input.name,
                    value = input.value,
                    overwrite = false
                );
            }

            arguments.inputs = variables.interactionEngine.getInputs();
        }

        var method = variables.domEngine.getFormMethod(arguments.button);

        if (arguments.overrideEvent != '') {
            return makeRequest(
                method = method,
                event = arguments.overrideEvent,
                parameters = arguments.inputs
            );
        }
        else {
            var action = variables.domEngine.getFormAction(arguments.button);
            return makeRequest(
                method = method,
                route = parseFrameworkRoute(action),
                parameters = arguments.inputs
            );
        }
    }

    /**
    * Makes a request internally through ColdBox using `execute()`.
    * Either a route or an event must be passed in.
    *
    * @method The HTTP method to use for the request.
    * @route Optional. The ColdBox route to execute. Default: ''.
    * @event Optional. The ColdBox event to execute. Default: ''.
    * @parameters Optional. A struct of parameters to attach to the request.  The parameters are attached to ColdBox's RequestContext collection. Default: {}.
    *
    * @throws TestBox.AssertionFailed
    * @return Integrated.BaseSpecs.AbstractBaseSpec
    */
    public function makeRequest(
        required string method,
        string route,
        string event,
        struct parameters = {}
    ) {
        // Make sure the method is always all caps
        arguments.method = UCase(arguments.method);

        // Must pass in a route or an event.
        if (!StructKeyExists(arguments, 'route') && !StructKeyExists(arguments, 'event')) {
            throw(
                type = 'TestBox.AssertionFailed',
                message = 'Must pass either a route or an event to the makeRequest() method.'
            );
        }

        // Clear out the requestMethod in case the call fails
        setRequestMethod('');

        // Make a request through the request engine
        var event = variables.requestEngine.makeRequest(argumentCollection = arguments);
        setEvent(event);

        // Clear out the inputs for the next request.
        variables.interactionEngine.reset();

        // Set the requestMethod now that we've finished the request.
        if (StructKeyExists(arguments, 'route')) {
            setRequestMethod( 'visit' );
        }
        else {
            setRequestMethod( 'visitEvent' );
        }

        // Follow any redirects found
        if (variables.frameworkEngine.isRedirect()) {
            if (StructKeyExists(arguments, 'route')) {
                return makeRequest(
                    method = arguments.method,
                    route = variables.frameworkEngine.getRedirectEvent(),
                    parameters = variables.frameworkEngine.getRedirectInputs()
                );
            }
            else {
                return makeRequest(
                    method = arguments.method,
                    event = variables.frameworkEngine.getRedirectEvent(),
                    parameters = variables.frameworkEngine.getRedirectInputs()
                );
            }
        }

        // Make the request using the request driver;
        // var event = variables.requestEngine.makeRequest();
        // Send the event to the frameworkAssertionEngine
        variables.frameworkEngine.setEvent(event);
        // Send the html to the domEngine
        variables.domEngine.parse(
            variables.frameworkEngine.getHTML()
        );

        return this;
    }


    /***************************** Expectations *******************************/


    /**
    * Verifies the route of the current page.
    * This method cannot be used after visiting a page using an event.
    *
    * @route The expected route.
    *
    * @return Integrated.BaseSpecs.AbstractBaseSpec
    */
    public AbstractBaseSpec function seePageIs(required string route) {
        variables.frameworkEngine.seePageIs(argumentCollection = arguments);

        return this;
    }

    /**
    * Verifies the title of the current page.
    *
    * @title The expected title.
    *
    * @return Integrated.BaseSpecs.AbstractBaseSpec
    */
    public AbstractBaseSpec function seeTitleIs(required string title) {
        variables.domEngine.seeTitleIs(argumentCollection = arguments);

        return this;
    }

    /**
    * Verifies the ColdBox view of the current page.
    *
    * @view The expected view.
    *
    * @return Integrated.BaseSpecs.AbstractBaseSpec
    */
    public AbstractBaseSpec function seeViewIs(required string view) {
        variables.frameworkEngine.seeViewIs(argumentCollection = arguments);

        return this;
    }

    /**
    * Verifies the ColdBox handler of the current page.
    *
    * @handler The expected handler.
    *
    * @return Integrated.BaseSpecs.AbstractBaseSpec
    */
    public AbstractBaseSpec function seeHandlerIs(required string handler) {
        variables.frameworkEngine.seeHandlerIs(argumentCollection = arguments);

        return this;
    }

    /**
    * Verifies the ColdBox action of the current page.
    *
    * @action The expected action.
    *
    * @return Integrated.BaseSpecs.AbstractBaseSpec
    */
    public AbstractBaseSpec function seeActionIs(required string action) {
        variables.frameworkEngine.seeActionIs(argumentCollection = arguments);

        return this;
    }

    /**
    * Verifies the ColdBox event of the current page.
    *
    * @event The expected event.
    *
    * @return Integrated.BaseSpecs.AbstractBaseSpec
    */
    public AbstractBaseSpec function seeEventIs(required string event) {
        variables.frameworkEngine.seeEventIs(argumentCollection = arguments);

        return this;
    }

    /**
    * Verifies that the given text exists in any element on the current page.
    *
    * @text The expected text.
    * @negate Optional. If true, throw an exception if the text IS found on the current page. Default: false.
    *
    * @return Integrated.BaseSpecs.AbstractBaseSpec
    */
    public AbstractBaseSpec function see(required string text, boolean negate = false) {
        variables.domEngine.see(argumentCollection = arguments);

        return this;
    }

    /**
    * Verifies that the given text does not exist in any element on the current page.
    *
    * @text The text that should not appear.
    *
    * @return Integrated.BaseSpecs.AbstractBaseSpec
    */
    public AbstractBaseSpec function dontSee(required string text) {
        return this.see(text = arguments.text, negate = true);
    }

    /**
    * Verifies that the given element contains the given text on the current page.
    *
    * @element The provided element.
    * @text The expected text.
    * @negate Optional. If true, throw an exception if the element DOES contain the given text on the current page. Default: false.
    *
    * @return Integrated.BaseSpecs.AbstractBaseSpec
    */
    public AbstractBaseSpec function seeInElement(
        required string element,
        required string text,
        boolean negate = false
    ) {
        variables.domEngine.seeInElement(argumentCollection = arguments);

        return this;
    }

    /**
    * Verifies that the given element does not contain the given text on the current page.
    *
    * @element The provided element.
    * @text The text that should not be found.
    *
    * @return Integrated.BaseSpecs.AbstractBaseSpec
    */
    public AbstractBaseSpec function dontSeeInElement(
        required string element,
        required string text
    ) {
        return this.seeInElement(
            element = arguments.element,
            text = arguments.text,
            negate = true
        );
    }

    /**
    * Verifies that a link with the given text exists on the current page.
    * Can also take an optional url parameter.  If provided, it verifies the link found has the given url.
    *
    * @text The expected text of the link.
    * @url Optional. The expected url of the link. Default: ''.
    *
    * @return Integrated.BaseSpecs.AbstractBaseSpec
    */
    public AbstractBaseSpec function seeLink(required string text, string url = '') {
        variables.domEngine.seeLink(argumentCollection = arguments);

        return this;
    }

    /**
    * Verifies that a link with the given text does not exist on the current page.
    * Can also take an optional url parameter.  If provided, it verifies the link found does not have the given url.
    *
    * @text The text of the link that should not be found.
    * @url Optional. The url that should not be found. Default: ''.
    *
    * @return Integrated.BaseSpecs.AbstractBaseSpec
    */
    public AbstractBaseSpec function dontSeeLink(required string text, string url = '') {
        variables.domEngine.dontSeeLink(argumentCollection = arguments);

        return this;
    }

    /**
    * Verifies that a field with the given value exists on the current page.
    *
    * @element The selector or name of the field.
    * @value The expected value of the field.
    * @negate Optional. If true, throw an exception if the field DOES contain the given text on the current page. Default: false.
    *
    * @return Integrated.BaseSpecs.AbstractBaseSpec
    */
    public AbstractBaseSpec function seeInField(
        required string element,
        required string value,
        boolean negate = false
    ) {
        variables.domEngine.seeInField(argumentCollection = arguments);

        return this;
    }

    /**
    * Verifies that a field with the given value exists on the current page.
    *
    * @element The selector or name of the field.
    * @value The value of the field to not find.
    *
    * @return Integrated.BaseSpecs.AbstractBaseSpec
    */
    public AbstractBaseSpec function dontSeeInField(required string element, required string value) {
        return this.seeInField(
            element = arguments.element,
            value = arguments.value,
            negate = true
        );
    }

    /**
    * Verifies that a checkbox is checked on the current page.
    *
    * @element The selector or name of the checkbox.
    * @negate Optional. If true, throw an exception if the checkbox IS checked on the current page. Default: false.
    *
    * @return Integrated.BaseSpecs.AbstractBaseSpec
    */
    public AbstractBaseSpec function seeIsChecked(
        required string element,
        boolean negate = false
    ) {
        variables.domEngine.seeIsChecked(argumentCollection = arguments);

        return this;
    }

    /**
    * Verifies that a field with the given value exists on the current page.
    *
    * @element The selector or name of the field.
    *
    * @return Integrated.BaseSpecs.AbstractBaseSpec
    */
    public AbstractBaseSpec function dontSeeIsChecked(required string element) {
        return this.seeIsChecked(
            element = arguments.element,
            negate = true
        );
    }

    /**
    * Verifies that a given selector has a given option selected.
    *
    * @element The selector or name of the select field.
    * @value The value or text of the option that should exist.
    * @negate Optional. If true, throw an exception if the option IS selected in the given select field on the current page. Default: false.
    *
    * @return Integrated.BaseSpecs.AbstractBaseSpec
    */
    public AbstractBaseSpec function seeIsSelected(
        required string element,
        required string value,
        boolean negate = false
    ) {
        variables.domEngine.seeIsSelected(argumentCollection = arguments);

        return this;
    }

    /**
    * Verifies that a given selector does not have a given option selected.
    *
    * @element The selector or name of the select field.
    * @value The value or text of the option that should exist.
    *
    * @return Integrated.BaseSpecs.AbstractBaseSpec
    */
    public AbstractBaseSpec function dontSeeIsSelected(
        required string element,
        required string value
    ) {
        return this.seeIsSelected(
            element = arguments.element,
            value = arguments.value,
            negate = true
        );
    }

    /**
    * Verifies that the given key and optional value exists in the ColdBox request collection.
    *
    * @key The key to find in the collection.
    * @value The value to find in the collection with the given key.
    * @private If true, use the private collection instead of the default collection. Default: false.
    * @negate If true, verify that the key and value is not found in the collection. Default: false.
    *
    * @return string
    */
    public AbstractBaseSpec function seeInCollection(
        required string key,
        string value,
        boolean private = false,
        boolean negate = false
    ) {
        variables.frameworkEngine.seeInCollection(argumentCollection = arguments);

        return this;
    }

    /**
    * Verifies that the given key and optional value does not exist in the ColdBox request collection.
    *
    * @key The key that should not be found in the collection.
    * @value The value that should not be founc in the collection with the given key.
    * @private If true, use the private collection instead of the default collection. Default: false.
    *
    * @return string
    */
    public AbstractBaseSpec function dontSeeInCollection(
        required string key,
        string value,
        boolean private = false
    ) {
        arguments.negate = true;
        return seeInCollection(argumentCollection = arguments);
    }

    /**
    * Verifies that a given struct of keys and values exists in a row in a given table.
    *
    * @table The table name to look for the data in.
    * @data A struct of data to verify exists in a row in the given table.
    * @datasource Optional. A datasource to use instead of the default datasource. Default: ''.
    * @query Optional. A query to use for a query of queries.  Mostly useful for testing. Default: ''.
    * @negate Optional. If true, throw an exception if the data DOES exist in the given table. Default: false.
    *
    * @return Integrated.BaseSpecs.AbstractBaseSpec
    */
    public AbstractBaseSpec function seeInTable(
        required string table,
        required struct data,
        string datasource = '',
        any query = '',
        boolean negate = false
    ) {
        if (negate) {
            expect(arguments.data).notToBeInTable(
                table = arguments.table,
                datasource = arguments.datasource,
                query = arguments.query
            );
        }
        else {
            expect(arguments.data).toBeInTable(
                table = arguments.table,
                datasource = arguments.datasource,
                query = arguments.query
            );
        }

        return this;
    }

    /**
    * Verifies that a given struct of keys and values does not exist in a row in a given table.
    *
    * @table The table name to look for the data in.
    * @data A struct of data to verify exists in a row in the given table.
    * @datasource Optional. A datasource to use instead of the default datasource. Default: ''.
    * @query Optional. A query to use for a query of queries.  Mostly useful for testing. Default: ''.
    *
    * @return Integrated.BaseSpecs.AbstractBaseSpec
    */
    public AbstractBaseSpec function dontSeeInTable(
        required string table,
        required struct data,
        string datasource = '',
        any query = ''
    ) {
        return this.seeInTable(
            table = arguments.table,
            data = arguments.data,
            datasource = arguments.datasource,
            query = arguments.query,
            negate = true
        );
    }


    /**************************** Helper Methods ******************************/

    /**
    * Sets the framework event
    *
    * @event The framework event
    */
    private void function setEvent( required event ) {
        variables.event = arguments.event;
        variables.frameworkEngine.setEvent(arguments.event);

        return;
    }

    /**
    * Sets the request method
    *
    * @event The request method
    */
    private void function setRequestMethod( required string requestMethod ) {
        variables.frameworkEngine.setRequestMethod( arguments.requestMethod );
    }

    /**
    * Gets the request method
    *
    * @return string
    */
    public string function getRequestMethod() {
        return variables.frameworkEngine.getRequestMethod();
    }

    /**
    * Parses an html string.
    * If an empty string is passed in, the current page is set to an empty string instead of parsing the page.
    *
    * @htmlString The html string to parse.
    */
    private void function parse(required string htmlString) {
        variables.domEngine.parse(argumentCollection = arguments);
    }

    /**
    * Returns the inputs current on the page
    *
    * @return struct
    */
    public struct function getInputs() {
        return variables.interactionEngine.getInputs();
    }

    /**
    * Store values found in the parsed form in the in-memory input struct.
    *
    * @pageForm The form jsoup node. [org.jsoup.nodes.Element]
    *
    * @return string
    */
    private void function extractValuesFromForm(required pageForm) {
        var inputs = pageForm.select('[name]');

        for (var input in inputs) {
            variables.interactionEngine.storeInput(
                element = input.attr('name'),
                value = input.val(),
                overwrite = false
            );
        }

        return;
    }

}